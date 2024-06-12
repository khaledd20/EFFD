import 'package:flutter/material.dart';
import 'package:early_flash_flood_detection/controllers/ReportController.dart';
import 'package:early_flash_flood_detection/views/AnalyzerDashboard.dart';
import 'package:early_flash_flood_detection/views/UserProfileScreen.dart';
import 'package:early_flash_flood_detection/views/LoginScreen.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class GenerateReport extends StatelessWidget {
  final ReportController reportController = ReportController();
  final String userId; // Add userId parameter

  GenerateReport({required this.userId}); // Constructor with userId

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Generate Reports"),
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
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: reportController.getFloodDataBasedOnTime(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No flood data available.", style: TextStyle(color: Colors.grey, fontSize: 18)));
          }
          var regions = snapshot.data!;
          return ListView(
            children: regions.map((regionData) {
              return _buildReportTile(context, regionData);
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildReportTile(BuildContext context, Map<String, dynamic> regionData) {
    String region = regionData['region'];
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Image.asset(reportController.reportGeneration.getImageForRegion(region)),
        title: Text(region),
        trailing: ElevatedButton(
          onPressed: () async {
            var data = await reportController.getRegionData(region);
            final pdfData = await reportController.generatePdfReport(region, data);

            await Printing.layoutPdf(onLayout: (_) async => pdfData);
          },
          child: Text("Generate Report"),
        ),
      ),
    );
  }
}
