import 'package:flutter/material.dart';
import 'package:early_flash_flood_detection/controllers/FloodEventAnalysis.dart';
import 'package:early_flash_flood_detection/views/UserProfileScreen.dart';
import 'package:early_flash_flood_detection/views/LoginScreen.dart';

import 'GenerateReport.dart';

class AnalyzerDashboard extends StatelessWidget {
  final String userId;
  final FloodEventAnalysis floodEventAnalysis = FloodEventAnalysis(); // Controller instance

  AnalyzerDashboard({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Analyzer Dashboard"),
        backgroundColor: Color.fromARGB(255, 48, 174, 237),
        actions: [
          
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Color.fromARGB(255, 48, 174, 237)),
              child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: Icon(Icons.dashboard),
              title: Text('Dashboard'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => AnalyzerDashboard(userId: userId)));
              },
            ),
            ListTile(
              leading: Icon(Icons.account_circle),
              title: Text('Profile'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfileScreen(userId: userId)));
              },
            ),
            ListTile(
              leading: Icon(Icons.description),
              title: Text('Generate Report'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => GenerateReport(userId: userId)));
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
        stream: floodEventAnalysis.getTodayFloodData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No flood data available for today.", style: TextStyle(color: Colors.grey, fontSize: 18)));
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: Text(
                              data['region'] ?? 'Unknown Region',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                            ),
                          ),
                          Divider(),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: data['flood_risk_times'].entries.map<Widget>((e) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    children: [
                                      Icon(
                                        e.value == 'High Risk' ? Icons.warning : Icons.info,
                                        color: e.value == 'High Risk' ? Colors.red : e.value == 'Moderate Risk' ? Colors.orange : Colors.green,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        e.key,
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                                      ),
                                      SizedBox(width: 8),
                                      Text(e.value, style: TextStyle(fontSize: 16, color: const Color.fromARGB(232, 0, 0, 0))),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          Divider(),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                Icon(Icons.verified, color: Colors.green),
                                SizedBox(width: 8),
                                Text(
                                  "Accuracy: ${(data['accuracy']*100 ?? 0).toStringAsFixed(2)}%",
                                  style: TextStyle(fontSize: 19, color: Colors.green),
                                ),
                              ],
                            ),
                          ),
                          Divider(),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Classification Report:',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueGrey),
                                ),
                                SizedBox(height: 8),
                                _buildClassificationReportTable(data['classification_report']),
                              ],
                            ),
                          ),
                          Divider(),
                          if (data['bar_chart_url'] != null || data['line_chart_url'] != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Analysis Figures:',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueGrey),
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      if (data['bar_chart_url'] != null)
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Colors.blueGrey, width: 2),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(10),
                                                child: Image.network(
                                                  data['bar_chart_url'],
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                                                    return Padding(
                                                      padding: const EdgeInsets.all(8.0),
                                                      child: Text('Failed to load bar chart image', style: TextStyle(color: Colors.red)),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      SizedBox(width: 10), // Space between the images
                                      if (data['line_chart_url'] != null)
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Colors.blueGrey, width: 2),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(10),
                                                child: Image.network(
                                                  data['line_chart_url'],
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                                                    return Padding(
                                                      padding: const EdgeInsets.all(8.0),
                                                      child: Text('Error loading line chart image', style: TextStyle(color: Colors.red)),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        color: Color.fromARGB(255, 48, 174, 237),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Flood Risk Dashboard - Stay Alert, Stay Safe!',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildClassificationReportTable(String reportString) {
    var lines = reportString.split('\n').where((line) => line.trim().isNotEmpty).toList();
    if (lines.isEmpty) {
      return Text('No classification report available', style: TextStyle(color: Colors.red));
    }

    var headers = ['Class', 'Precision', 'Recall', 'F1-score', 'Support'];
    var dataRows = <DataRow>[];

    for (var i = 1; i < lines.length; i++) {
      var values = lines[i].split(RegExp(r'\s+')).where((value) => value.isNotEmpty).toList();
      
      if (values.length >= 6) {
        String category = values[0] + ' ' + values[1];
        dataRows.add(
          DataRow(
            cells: [
              DataCell(Text(category)),
              DataCell(Text(values[2])),
              DataCell(Text(values[3])),
              DataCell(Text(values[4])),
              DataCell(Text(values[5])),
            ],
          ),
        );
      } else if (values.length >= 5) {
        dataRows.add(
          DataRow(
            cells: [
              DataCell(Text(values[0])),
              DataCell(Text(values[1])),
              DataCell(Text(values[2])),
              DataCell(Text(values[3])),
              DataCell(Text(values[4])),
            ],
          ),
        );
      }
    }

   
    if (dataRows.isEmpty) {
      return Text('No valid classification report data found', style: TextStyle(color: Colors.red));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: headers.map((header) {
          return DataColumn(
            label: Text(
              header,
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.blueGrey),
            ),
          );
        }).toList(),
        rows: dataRows,
      ),
    );
  }
}
