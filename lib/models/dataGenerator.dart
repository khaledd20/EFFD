import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DataGenerator {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Method to generate random data for a specific time
  Map<String, dynamic> _generateDataForTime() {
    final random = Random();
    return {
      'weather': ['Sunny', 'Rainy', 'Cloudy', 'Snowy'][random.nextInt(4)],
      'humidity': random.nextInt(100), // 0 to 100%
      'temperature': random.nextInt(35) + 5, // 5 to 40 degrees Celsius
      'waterLevel': random.nextDouble() * 5, // 0 to 5 meters
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
      await triggerFloodAnalysis();
    }
  }

  // Helper method to generate and save data for the specified day
  Future<void> _generateAndSaveDataForDay(DocumentReference documentReference, DateTime day) async {
    final times = ['06:00', '12:00', '18:00']; // Specified times to generate data
    Map<String, dynamic> dailyData = {
      'date': day.toString(),
      'dataPoints': times.map((time) => _generateDataForTime()).toList(),
    };

    await documentReference.set(dailyData);
  }

  // Method to trigger flood analysis in main.py
  Future<void> triggerFloodAnalysis() async {
    final url = 'http://localhost:5000/analyze-flood';
    await http.post(Uri.parse(url));
  }
}

