import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportGeneration {
  Future<Map<String, dynamic>> getRegionData(String region) async {
    var today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    var snapshot = await FirebaseFirestore.instance
        .collection('floodData')
        .where('date', isEqualTo: today)
        .get();
    if (snapshot.docs.isNotEmpty) {
      for (var doc in snapshot.docs) {
        var regions = (doc.data()['all_regions_data'] as List)
            .where((r) => r['region'] == region)
            .toList();
        if (regions.isNotEmpty) {
          return regions.first;
        }
      }
    }
    return {};
  }

  Stream<List<Map<String, dynamic>>> getFloodDataBasedOnTime() {
    var now = DateTime.now().toLocal();
    var today = DateFormat('yyyy-MM-dd').format(now);
    String timeKey;

    if (now.hour < 12) {
      timeKey = '6 am';
    } else if (now.hour < 18) {
      timeKey = '12 pm';
    } else {
      timeKey = '6 pm';
    }

    return FirebaseFirestore.instance
        .collection('floodData')
        .where('date', isEqualTo: today)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .expand((doc) => (doc.data()['all_regions_data'] as List)
                .where((region) => region['flood_risk_times'] != null && region['flood_risk_times'][timeKey] != null)
                .map((region) => {
                      'region': region['region'],
                      'flood_risk': region['flood_risk_times'][timeKey],
                      'accuracy': region['accuracy'],
                      'image': getImageForRegion(region['region']),
                      'riskLevelColor': getRiskColor(region['flood_risk_times'][timeKey]),
                    }))
            .toList());
  }

  String getImageForRegion(String region) {
    switch (region) {
      case 'Gombak':
        return 'assets/images/Gombak.png';
      case 'Kajang':
        return 'assets/images/Kajang.png';
      case 'Ampang':
        return 'assets/images/Ampang.png';
      default:
        return 'assets/images/kl_towers.png'; // Default image if region is unknown
    }
  }

  Color getRiskColor(String riskLevel) {
    switch (riskLevel) {
      case 'High Risk':
        return Colors.red;
      case 'Moderate Risk':
        return Colors.orange;
      default:
        return Colors.green; // Assume low risk or unknown
    }
  }
}
