import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'AdminDashboardScreen.dart';
import 'AnalyzerProfile .dart';
import 'web_login_screen.dart';

class AnalyzerDashboard extends StatefulWidget {
  final String userId; // Define userId as a required parameter

  const AnalyzerDashboard({Key? key, required this.userId}) : super(key: key);

  @override
  _AnalyzerDashboardState createState() => _AnalyzerDashboardState();
}

class _AnalyzerDashboardState extends State<AnalyzerDashboard> {
  late Future<DocumentSnapshot<Map<String, dynamic>>> _userFuture; // Define the type of DocumentSnapshot

  String _userName = '';

  @override
  void initState() {
    super.initState();
    _userFuture = _getUserData();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _getUserData() async {
    return FirebaseFirestore.instance.collection('webUsers').doc(widget.userId).get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
      ),
      drawer: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Drawer(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return Drawer(
              child: Text('Error loading user data'),
            );
          }
          var userData = snapshot.data?.data();
          _userName = userData?['username'] ?? ''; // Update _userName with the username
          return  Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                  ),
                  child: Text(
                    'Welcome: $_userName',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ),
                ListTile(
                  title: Text('Profile'),
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AnalyzerProfile(userId: userData?['userId'] ?? '')),
                    );
                  },
                ),
                ListTile(
                  title: Text('Manage Users'),
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AdminDashboardScreen()),
                    );
                  },
                ),
                ListTile(
                  title: Text('Logout'),
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => WebLoginScreen()),
                    );
                  },
                ),
              ],
            ),
        );
        },
      ),
      body: ListView(
        children: [
          LocationCard(
            image: 'images/kl_towers.png',
            title: 'Kuala Lumpur',
          ),
          LocationCard(
            image: 'images/selangor_view.png',
            title: 'Selangor',
          ),
          LocationCard(
            image: 'images/sarawak_building.png',
            title: 'Sarawak',
          ),
        ],
      ),
    );
  }
}

class LocationCard extends StatelessWidget {
  final String image;
  final String title;

  const LocationCard({Key? key, required this.image, required this.title})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(image, height: 150, fit: BoxFit.cover),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implement water level details navigation
                  print('Water Levels details for $title');
                },
                child: Text('Water Levels details'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.red,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void main() => runApp(MaterialApp(home: AnalyzerDashboard(userId: 'userId')));
