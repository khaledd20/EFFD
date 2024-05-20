import 'package:early_flash_flood_detection/views/analyzerDashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'LoginScreen.dart';
import 'UserProfileScreen.dart';

class NotificationsScreen extends StatefulWidget {
   final String userId;

  NotificationsScreen({required this.userId});
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();

  static Future<void> checkForHighRisk() async {
    var floodData = FloodData();
    var snapshot = await floodData.getFloodDataBasedOnTime().first;
    var currentTime = DateTime.now();
    var formattedDate = DateFormat('yyyy-MM-dd').format(currentTime);
    var timeFrame = _getTimeFrame(currentTime);

    for (var regionData in snapshot) {
      if (regionData['flood_risk'] == 'High Risk') {
        var region = regionData['region'];
        var message = 'High flood risk detected in $region on $formattedDate at $timeFrame';

        if (await _shouldSendNotification(region, formattedDate, timeFrame)) {
          await _addNotification(message, formattedDate, timeFrame);
        }
      }
    }
  }

  static String _getTimeFrame(DateTime currentTime) {
    if (currentTime.hour < 12) {
      return '6 am';
    } else if (currentTime.hour < 18) {
      return '12 pm';
    } else {
      return '6 pm';
    }
  }

  static Future<bool> _shouldSendNotification(String region, String formattedDate, String timeFrame) async {
    var docRef = FirebaseFirestore.instance.collection('notifications').doc(formattedDate);
    var existingDoc = await docRef.get();

    if (existingDoc.exists) {
      var data = existingDoc.data();
      if (data != null && data.containsKey('notifications') && data['notifications'].containsKey(timeFrame)) {
        List<String> existingNotifications = List<String>.from(data['notifications'][timeFrame]);
        for (var notification in existingNotifications) {
          if (notification.contains(region) && notification.contains('High flood risk')) {
            return false; // Found an existing notification for this region and time frame
          }
        }
      }
    }
    return true; // No existing notification found for this region and time frame
  }

  static Future<void> _addNotification(String newNotification, String currentDate, String timeFrame) async {
    var docRef = FirebaseFirestore.instance.collection('notifications').doc(currentDate);
    var existingDoc = await docRef.get();

    if (existingDoc.exists) {
      await docRef.update({
        'notifications.$timeFrame': FieldValue.arrayUnion([newNotification]),
      });
    } else {
      await docRef.set({
        'date': currentDate,
        'notifications': {
          timeFrame: [newNotification],
        },
      });
    }

    await NotificationsScreen._showNotification(newNotification);
  }

  static Future<void> _showNotification(String notificationDetail) async {
    var flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    var initializationSettingsAndroid =
        const AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);

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
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<String> notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    var currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    var docRef = FirebaseFirestore.instance.collection('notifications').doc(currentDate);
    var existingDoc = await docRef.get();

    if (existingDoc.exists) {
      var data = existingDoc.data();
      if (data != null && data.containsKey('notifications')) {
        List<String> allNotifications = [];
        var notificationsMap = data['notifications'] as Map<String, dynamic>;
        notificationsMap.forEach((timeFrame, notificationsList) {
          allNotifications.addAll(List<String>.from(notificationsList));
        });
        setState(() {
          notifications = allNotifications;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Welcome to EFFD',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.account_circle),
              title: Text('Dashboard'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => AnalyzerDashboard(userId: widget.userId)));
              },
            ),
            ListTile(
              leading: Icon(Icons.account_circle),
              title: Text('Profile'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfileScreen(userId: widget.userId)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NotificationsScreen(userId: widget.userId)),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text('Logout'),
              onTap: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
              },
            ),
          ],
        ),
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
