import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:early_flash_flood_detection/views/UserProfileScreen.dart';
import 'package:early_flash_flood_detection/views/LoginScreen.dart';

class AnalyzerDashboard extends StatelessWidget {
  final String userId;

  AnalyzerDashboard({required this.userId});

  Stream<Map<String, dynamic>> getTodayFloodData() {
    var today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return FirebaseFirestore.instance
        .collection('floodData')
        .where('date', isEqualTo: today)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .fold<Map<String, dynamic>>({}, (Map<String, dynamic> acc, doc) {
              (doc.data()['all_regions_data'] as List).forEach((regionData) {
                String region = regionData['region'];
                acc[region] = regionData;
              });
              return acc;
            }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Analyzer Dashboard"),
        backgroundColor: Color.fromARGB(255, 48, 174, 237),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Color.fromARGB(255, 48, 174, 237)),
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
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
              },
            ),
          ],
        ),
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: getTodayFloodData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No flood data available for today."));
          }
          var regions = snapshot.data!;
          return SingleChildScrollView(
            child: Column(
              children: regions.entries.map((entry) {
                var data = entry.value;
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    elevation: 5,
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(data['region'] ?? 'Unknown Region', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          subtitle: Text("Accuracy: ${(data['accuracy'] ?? 0).toStringAsFixed(2)}"),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: data['flood_risk_times'].entries.map<Widget>((e) => ListTile(
                              title: Text(e.key),
                              subtitle: Text(e.value),
                            )).toList(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text('Classification Report: ${data['classification_report']}'),
                        ),
                        if (data['bar_chart_url'] != null)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.network(
                              data['bar_chart_url'],
                              fit: BoxFit.cover,
                              errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                                return Text('Failed to load image');  // Custom error handling for images
                              },
                            ),
                          ),
                        if (data['line_chart_url'] != null)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.network(
                              data['line_chart_url'],
                              fit: BoxFit.cover,
                              errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                                return Text('Error loading line chart: $exception');  // Custom error handling for images
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
