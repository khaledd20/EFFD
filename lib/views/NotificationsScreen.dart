import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(MaterialApp(home: NotificationsScreen()));

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<String> notifications = [
    "Flood alert in Kuala Lumpur",
    "Heavy rain expected in Selangor",
    "Maintenance scheduled in Sarawak",
  ];

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    var initializationSettingsAndroid = const AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
    _requestPermissions();
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

  void _addNotification() {
    var newNotification = "New notification at ${DateTime.now()}";
    setState(() {
      notifications.insert(0, newNotification);
    });

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
      floatingActionButton: FloatingActionButton(
        onPressed: _addNotification,
        tooltip: 'Create Notification',
        child: const Icon(Icons.add_alert),
      ),
    );
  }
}
