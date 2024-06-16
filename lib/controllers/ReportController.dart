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
          return pw.Container(
            padding: pw.EdgeInsets.all(20),
            color: PdfColors.white,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Image(image, width: 150, height: 150),
                ),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    'EFFDS',
                    style: pw.TextStyle(fontSize: 30, fontWeight: pw.FontWeight.bold, color: PdfColors.blue),
                  ),
                ),
                pw.SizedBox(height: 20),
                
                pw.SizedBox(height: 20),
                pw.Text(
                  '$region',
                  style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Flood Risk Times:',
                  style: pw.TextStyle(fontSize: 20,  color: PdfColors.black),
                ),
                ...regionData['flood_risk_times'].entries.map((e) {
                  return pw.Text('${e.key}: ${e.value}', style: pw.TextStyle(fontSize: 20,fontWeight: pw.FontWeight.bold, color: PdfColors.black));
                }).toList(),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Accuracy: ${regionData['accuracy']*100}%',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.green),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Classification Report:',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                ),
                ..._buildClassificationReport(regionData['classification_report']),
                /*pw.SizedBox(height: 20),
                pw.Text(
                  'Analysis Figures:',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                ),
                if (regionData['bar_chart_url'] != null)
                  pw.Image(
                    pw.MemoryImage(Uint8List.fromList((await rootBundle.load(regionData['bar_chart_url'])).buffer.asUint8List())),
                    height: 200,
                  ),
                if (regionData['line_chart_url'] != null)
                  pw.Image(
                    pw.MemoryImage(Uint8List.fromList((await rootBundle.load(regionData['line_chart_url'])).buffer.asUint8List())),
                    height: 200,
                  ),*/
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  List<pw.Widget> _buildClassificationReport(String reportString) {
    var lines = reportString.split('\n').where((line) => line.trim().isNotEmpty).toList();
    if (lines.isEmpty) {
      return [pw.Text('No classification report available', style: pw.TextStyle(color: PdfColors.red))];
    }

    var headers = ['Class', 'Precision', 'Recall', 'F1-score', 'Support'];
    var dataRows = <pw.TableRow>[];

    dataRows.add(
      pw.TableRow(
        children: headers.map((header) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(4.0),
            child: pw.Text(
              header,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, color: PdfColors.blueGrey),
            ),
          );
        }).toList(),
      ),
    );

    for (var i = 1; i < lines.length; i++) {
      var values = lines[i].split(RegExp(r'\s+')).where((value) => value.isNotEmpty).toList();

      if (values.length >= 6) {
        String category = values[0] + ' ' + values[1];
        dataRows.add(
          pw.TableRow(
            children: [
              pw.Padding(padding: const pw.EdgeInsets.all(4.0), child: pw.Text(category)),
              pw.Padding(padding: const pw.EdgeInsets.all(4.0), child: pw.Text(values[2])),
              pw.Padding(padding: const pw.EdgeInsets.all(4.0), child: pw.Text(values[3])),
              pw.Padding(padding: const pw.EdgeInsets.all(4.0), child: pw.Text(values[4])),
              pw.Padding(padding: const pw.EdgeInsets.all(4.0), child: pw.Text(values[5])),
            ],
          ),
        );
      } else if (values.length >= 5) {
        dataRows.add(
          pw.TableRow(
            children: [
              pw.Padding(padding: const pw.EdgeInsets.all(4.0), child: pw.Text(values[0])),
              pw.Padding(padding: const pw.EdgeInsets.all(4.0), child: pw.Text(values[1])),
              pw.Padding(padding: const pw.EdgeInsets.all(4.0), child: pw.Text(values[2])),
              pw.Padding(padding: const pw.EdgeInsets.all(4.0), child: pw.Text(values[3])),
              pw.Padding(padding: const pw.EdgeInsets.all(4.0), child: pw.Text(values[4])),
            ],
          ),
        );
      }
    }

    return [
      pw.Table(
        children: dataRows,
        border: pw.TableBorder.all(color: PdfColors.grey, width: 1),
      ),
    ];
  }
}
