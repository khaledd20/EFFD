import 'package:early_flash_flood_detection/models/ReportGeneration.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show Uint8List, rootBundle;

class ReportController {
  final ReportGeneration reportGeneration = ReportGeneration();

  Future<Map<String, dynamic>> getRegionData(String region) {
    return reportGeneration.getRegionData(region);
  }

  Stream<List<Map<String, dynamic>>> getFloodDataBasedOnTime() {
    return reportGeneration.getFloodDataBasedOnTime();
  }

  Future<Uint8List> generatePdfReport(String region, Map<String, dynamic> regionData) async {
    final pdf = pw.Document();
    final image = pw.MemoryImage(Uint8List.fromList((await rootBundle.load('assets/images/kl_towers.png')).buffer.asUint8List()));

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Image(image, width: 150, height: 150),
              pw.SizedBox(height: 20),
              pw.Text(
                'Flood Report:',
                style: pw.TextStyle(fontSize: 30),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Region: $region',
                style: pw.TextStyle(fontSize: 20),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Flood Risk Times:',
                style: pw.TextStyle(fontSize: 20),
              ),
              ...regionData['flood_risk_times'].entries.map((e) {
                return pw.Text('${e.key}: ${e.value}', style: pw.TextStyle(fontSize: 20));
              }).toList(),
              pw.SizedBox(height: 20),
              pw.Text(
                'Accuracy: ${regionData['accuracy']}%',
                style: pw.TextStyle(fontSize: 20),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
