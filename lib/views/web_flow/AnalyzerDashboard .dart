import 'package:flutter/material.dart';

class AnalyzerDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Analyzer Dashboard'),
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
                  primary: Colors.red,
                  onPrimary: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void main() => runApp(MaterialApp(home: AnalyzerDashboard()));
