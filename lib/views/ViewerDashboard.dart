import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting

import 'LoginScreen.dart';
import 'NotificationsScreen.dart';
import 'UserProfileScreen.dart';

class ViewerDashboard extends StatefulWidget {
  final String userId;

  ViewerDashboard({required this.userId});

  @override
  _ViewerDashboardState createState() => _ViewerDashboardState();
}

class _ViewerDashboardState extends State<ViewerDashboard> {
  Map<String, String> riskLevels = {};
  Map<String, Color> riskColors = {
    'High flood risk': Colors.red,
    'Moderate flood risk': Colors.orange,
    'Low flood risk': Colors.green,
    'Unknown risk': Colors.grey,
  };

  @override
  void initState() {
    super.initState();
    fetchRiskData();
  }

  String determineClosestTimeSlot() {
    DateTime now = DateTime.now();
    int currentHour = now.hour;
    // Determine which time slot is closest
    if (currentHour < 9) { // Before 9 AM shows 6 AM data
      return '6 am';
    } else if (currentHour < 15) { // Before 3 PM shows 12 PM data
      return '12 pm';
    } else { // After 3 PM shows 6 PM data
      return '6 pm';
    }
  }

  Future<void> fetchRiskData() async {
    String timeKey = determineClosestTimeSlot();
    String today = DateFormat('yyyyMMdd').format(DateTime.now());
    
    FirebaseFirestore.instance
      .collection('floodData')
      .where('date', isEqualTo: today)
      .where('time', isEqualTo: timeKey)
      .get()
      .then((snapshot) {
        Map<String, String> newRiskLevels = {};
        for (var doc in snapshot.docs) {
          String location = doc.data()['region'] ?? 'Unknown';
          String risk = doc.data()['classification_report'] ?? 'Unknown risk';
          newRiskLevels[location] = risk;
        }
        setState(() {
          riskLevels = newRiskLevels;
        });
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flood Status Page'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Hello, John!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.account_circle),
              title: Text('Profile'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfileScreen(userId: widget.userId)));
              },
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text('Logout'),
              onTap: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationsScreen()));
              },
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: riskLevels.keys.map((location) => LocationCard(
          image: 'assets/images/${location.toLowerCase().replaceAll(" ", "_")}.png', // Ensure images are named appropriately
          title: location,
          riskLevel: riskLevels[location] ?? 'Loading...',
          riskLevelColor: riskColors[riskLevels[location]] ?? Colors.grey,
        )).toList(),
      ),
    );
  }
}

class LocationCard extends StatelessWidget {
  final String image;
  final String title;
  final String riskLevel;
  final Color riskLevelColor;

  const LocationCard({
    Key? key,
    required this.image,
    required this.title,
    required this.riskLevel,
    required this.riskLevelColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(image, height: 150, width: double.infinity, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: riskLevelColor,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    riskLevel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
