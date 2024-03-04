import 'package:flutter/material.dart';

import 'NotificationsScreen.dart';

void main() => runApp(MaterialApp(home: ViewerDashboard()));

class ViewerDashboard extends StatelessWidget {
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
  // The ListView contains the Drawer items
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
        leading: const Icon(Icons.home),
        title: const Text('Home'),
        onTap: () {
          // Navigate to home screen, if it's a separate screen
        },
      ),
      ListTile(
        leading: const Icon(Icons.notifications),
        title: const Text('Notifications'),
        onTap: () {
          // Close the drawer before navigating
          Navigator.pop(context);
          // Navigate to the notifications screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NotificationsScreen()),
          );
        },
      ),
      // Add other list tiles for drawer items here
    ],
  ),
),

      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          LocationCard(
            image: 'assets/images/kl_towers.png',
            title: 'Kuala Lumpur',
            riskLevel: 'Moderate flood risk',
            riskLevelColor: Colors.orange,
          ),
          LocationCard(
            image: 'assets/images/selangor_view.png',
            title: 'Selangor',
            riskLevel: 'High flood risk',
            riskLevelColor: Colors.red,
          ),
          LocationCard(
            image: 'assets/images/sarawak_building.png',
            title: 'Sarawak',
            riskLevel: 'Low flood risk',
            riskLevelColor: Colors.green,
          ),
        ],
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

