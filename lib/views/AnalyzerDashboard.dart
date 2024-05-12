import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:early_flash_flood_detection/views/UserProfileScreen.dart';
import 'package:early_flash_flood_detection/views/LoginScreen.dart';

class AnalyzerDashboard extends StatelessWidget {
  final String userId;

  AnalyzerDashboard({required this.userId});

  Stream<List<Map<String, dynamic>>> getTodayFloodData() {
    var today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return FirebaseFirestore.instance
        .collection('floodData')
        .where('date', isEqualTo: today)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .expand((doc) => (doc.data()['all_regions_data'] as List)
                .map((region) => region as Map<String, dynamic>))
            .toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Analyzer Dashboard"),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: Icon(Icons.account_circle),
              title: Text('Profile'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfileScreen(userId: userId)));
              },
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text('Logout'),
              onTap: () {
                // Navigate to LoginScreen
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
              },
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: getTodayFloodData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No flood data available for today."));
          }
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var data = snapshot.data![index];
              return Card(
                elevation: 4,
                child: ListTile(
                  title: Text(data['region'] ?? 'Unknown Region', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: data['flood_risk_times']?.entries.map<Widget>((entry) {
                      return Text('${entry.key}: ${entry.value ?? 'No Data'}');
                    })?.toList() ?? [Text('No risk times available')],
                  ),
                  trailing: Text("Accuracy: ${(data['accuracy'] ?? 0).toStringAsFixed(2)}"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
