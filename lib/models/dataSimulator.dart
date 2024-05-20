import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

class DataGenerator {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Method to generate data for specific times of the day
  Map<String, dynamic> _generateDataForTime(String timeOfDay) {
    final random = Random();
    final season = ['Spring', 'Summer', 'Autumn', 'Winter'][random.nextInt(4)];
    final rainfallIntensity = random.nextDouble() * 10; // Random rainfall intensity (0 to 10)
    final cloudCover = random.nextInt(80) + 20; // 20 to 100%
    return {
      'weather': ['Sunny', 'Rainy', 'Cloudy', 'Snowy'][random.nextInt(4)],
      'humidity': random.nextInt(100), // 0 to 100%
      'cloudCover': cloudCover,
      'waterLevel': random.nextDouble() * 5, // 0 to 5 meters
      'timeOfDay': timeOfDay,
      'season': season,
      'rainfallIntensity': rainfallIntensity,
    };
  }

  // Method to check and generate data for today if not already generated
  Future<void> ensureDailyDataGeneration() async {
    final now = DateTime.now();
    final dateString = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    // Check if data already exists for today
    final documentReference = firestore.collection('simulatedData').doc(dateString);
    final documentSnapshot = await documentReference.get();

    if (!documentSnapshot.exists) {
      // Data for today doesn't exist, so generate and save it
      await _generateAndSaveDataForDay(documentReference, now);

      // After saving the data, trigger flood analysis in main.py
      if (kIsWeb) {
        await triggerFloodAnalysisWeb();
      } else {
        await triggerFloodAnalysisAndroid();
      }
    }
  }

  // Helper method to generate and save data for the specified day
  Future<void> _generateAndSaveDataForDay(DocumentReference documentReference, DateTime day) async {
    final times = ['6 am', '12 pm', '6 pm']; // Specified times of the day
    Map<String, dynamic> dailyData = {
      'date': day.toString(),
      'Gombak': times.map((time) => _generateDataForTime(time)).toList(),
      'Kajang': times.map((time) => _generateDataForTime(time)).toList(),
      'Ampang': times.map((time) => _generateDataForTime(time)).toList(),
    };

    await documentReference.set(dailyData);
  }

  // Method to trigger flood analysis in main.py for web
  Future<void> triggerFloodAnalysisWeb() async {
    final url = 'http://localhost:5000/analyze-flood';
    try {
      final response = await http.post(Uri.parse(url));
      if (response.statusCode == 200) {
        print('Flood analysis triggered successfully (web).');
      } else {
        print('Failed to trigger flood analysis (web): ${response.statusCode}');
      }
    } catch (e) {
      print('Error triggering flood analysis (web): $e');
    }
  }

  // Method to trigger flood analysis in main.py for Android
  Future<void> triggerFloodAnalysisAndroid() async {
    try {
      final ip = await _getLocalIpAddress();
      final url = 'http://$ip:5000/analyze-flood';
      final response = await http.post(Uri.parse(url));
      if (response.statusCode == 200) {
        print('Flood analysis triggered successfully (Android).');
      } else {
        print('Failed to trigger flood analysis (Android): ${response.statusCode}');
      }
    } catch (e) {
      print('Error triggering flood analysis (Android): $e');
    }
  }

  // Helper method to get the local IP address
  Future<String> _getLocalIpAddress() async {
    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
          if (_isPrivateIpAddress(addr.address)) {
            return addr.address;
          }
        }
      }
    }
    throw Exception('No IPv4 address found');
  }

  // Helper method to check if an IP address is private
  bool _isPrivateIpAddress(String ip) {
    final privateIpPattern = RegExp(
      r'^(10\.|192\.168|172\.(1[6-9]|2[0-9]|3[0-1]))'
    );
    return privateIpPattern.hasMatch(ip);
  }
}
