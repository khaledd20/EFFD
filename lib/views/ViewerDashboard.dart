import 'package:flutter/material.dart';
import '../controllers/FloodEventAnalysis.dart'; // Importing the controller

class ViewerDashboard extends StatefulWidget {
  final String userId;

  ViewerDashboard({required this.userId});

  @override
  _ViewerDashboardState createState() => _ViewerDashboardState();
}

class _ViewerDashboardState extends State<ViewerDashboard> {
  final floodEventAnalysis = FloodEventAnalysis(); // Instance of the controller

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flood Status Page'),
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
