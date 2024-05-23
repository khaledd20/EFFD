import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DataPreProcessing {
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
}
