import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:early_flash_flood_detection/models/FloodData.dart';

class AlertGeneration {
  final FloodData floodData = FloodData();

  Future<void> checkForHighRisk() async {
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

  String _getTimeFrame(DateTime currentTime) {
    if (currentTime.hour < 12) {
      return '6 am';
    } else if (currentTime.hour < 18) {
      return '12 pm';
    } else {
      return '6 pm';
    }
  }

  Future<bool> _shouldSendNotification(String region, String formattedDate, String timeFrame) async {
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

  Future<void> _addNotification(String newNotification, String currentDate, String timeFrame) async {
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

    await _showNotification(newNotification);
  }

  Future<void> _showNotification(String notificationDetail) async {
    var flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    var initializationSettingsAndroid = const AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
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
