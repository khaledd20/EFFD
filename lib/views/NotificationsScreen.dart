import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<String> notifications = [];
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    var initializationSettingsAndroid =
        const AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
    _requestPermissions();
    _checkForHighRisk();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    if (await Permission.notification.request().isGranted) {
      // Permission is granted, continue with your app logic
    } else {
      // Permission is not granted, handle accordingly
    }
  }

  Future<void> _showNotification(String notificationDetail) async {
    var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
      'weather_alerts',
      'Weather Alerts',
      channelDescription: 'Notifications about weather conditions and alerts',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      'EFFD', // Notification Title
      notificationDetail, // Notification Body
      platformChannelSpecifics,
      payload: 'item x', // Additional data to pass
    );
  }

  Future<void> _checkForHighRisk() async {
    var floodData = FloodData();
    var snapshot = await floodData.getFloodDataBasedOnTime().first;
    var currentTime = DateTime.now();
    var formattedTime = '${currentTime.hour}:${currentTime.minute}';

    for (var regionData in snapshot) {
      if (regionData['flood_risk'] == 'High Risk') {
        var region = regionData['region'];
        var message = 'High flood risk detected in $region at $formattedTime!';
        _addNotification(message);
      }
    }
  }

  Future<void> _addNotification(String newNotification) async {
    setState(() {
      notifications.insert(0, newNotification);
    });

    var currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    var docRef = FirebaseFirestore.instance.collection('notifications').doc(currentDate);
    var existingDoc = await docRef.get();

    if (existingDoc.exists) {
      await docRef.update({
        'notifications': FieldValue.arrayUnion([newNotification]),
      });
    } else {
      await docRef.set({
        'date': currentDate,
        'notifications': [newNotification],
      });
    }

    _showNotification(newNotification);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
      ),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(notifications[index]),
            ),
          );
        },
      ),
    );
  }
}
class FloodData {
  Stream<List<Map<String, dynamic>>> getFloodDataBasedOnTime() {
    var now = DateTime.now().toLocal();
    var today = DateFormat('yyyy-MM-dd').format(now);
    String timeKey;

    if (now.hour < 12) {
      timeKey = '6 am';
    } else if (now.hour < 18) {
      timeKey = '12 pm';
    } else {
      timeKey = '6 pm';
    }
    // Logging the time key to the console
    debugPrint("Current time: ${now.hour}:${now.minute}");
    debugPrint("Displaying flood risk for: $timeKey");

    return FirebaseFirestore.instance
        .collection('floodData')
        .where('date', isEqualTo: today)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .expand((doc) => (doc.data()['all_regions_data'] as List)
                .where((region) =>
                    region['flood_risk_times'] != null &&
                    region['flood_risk_times'][timeKey] != null)
                .map((region) => {
                      'region': region['region'],
                      'flood_risk': region['flood_risk_times'][timeKey],
                         }))
            .toList());
  }
}
