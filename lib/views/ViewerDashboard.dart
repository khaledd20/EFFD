import 'package:flutter/material.dart';
import '../controllers/FloodEventAnalysis.dart'; 
import '../controllers/AlertGeneration.dart'; // Importing the controller for alert generation

import '../views/NotificationsScreen.dart';
import '../views/UserProfileScreen.dart';
import '../views/LoginScreen.dart';

class ViewerDashboard extends StatefulWidget {
  final String userId;

  ViewerDashboard({required this.userId});

  @override
  _ViewerDashboardState createState() => _ViewerDashboardState();
}

class _ViewerDashboardState extends State<ViewerDashboard> {
  final floodEventAnalysis = FloodEventAnalysis(); // Instance of the controller
  final alertGeneration = AlertGeneration(); // Instance of the alert generation controller


  @override
  void initState() {
    super.initState();
    alertGeneration.checkForHighRisk(); // Call the static method to check for high risk notifications
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flood Status Page'),
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
              leading: Icon(Icons.dashboard),
              title: Text('Dashboard'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ViewerDashboard(userId: widget.userId)));
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
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: floodEventAnalysis.getFloodDataBasedOnTime(), // Using controller method
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No flood data available."));
          }
          return ListView(
            padding: const EdgeInsets.all(8.0),
            children: snapshot.data!.map((data) => LocationCard(
              image: data['image'],
              title: data['region'],
              riskLevel: data['flood_risk'],
              riskLevelColor: data['riskLevelColor'],
            )).toList(),
          );
        },
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
