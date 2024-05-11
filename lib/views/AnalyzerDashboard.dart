import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For formatting dates

class AnalyzerDashboard extends StatelessWidget {
  final String userId;

  AnalyzerDashboard({required this.userId});

  Stream<List<DocumentSnapshot>> getTodayFloodData() {
    var today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return FirebaseFirestore.instance
        .collection('floodData')
        .where('date', isEqualTo: today)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Analyzer Dashboard"),
      ),
      drawer: Drawer(
        // Sidebar navigation
        child: ListView(
          children: [
            DrawerHeader(child: Text('Navigation')),
            ListTile(
              title: Text('Profile'),
              onTap: () => Navigator.pushNamed(context, '/profile'),
            ),
            ListTile(
              title: Text('Logout'),
              onTap: () => Navigator.pushReplacementNamed(context, '/login'),
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<DocumentSnapshot>>(
        stream: getTodayFloodData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No flood data for today."));
          }
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var data = snapshot.data![index].data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  title: Text(data['region']),
                  subtitle: Text('Accuracy: ${data['accuracy'].toString()}'),
                  trailing: Text('Risk: ${data['flood_risk_times']['12 pm']} at 12 pm'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
