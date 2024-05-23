import 'package:flutter/material.dart';
import '../models/DataPreProcessing.dart'; // Importing the model
import '../models/FloodData.dart'; // Importing the original model

class FloodEventAnalysis {
  final dataPreProcessing = DataPreProcessing(); // Instance of the new model
  final floodData = FloodData(); // Instance of the original model

  Stream<Map<String, dynamic>> getTodayFloodData() {
    return dataPreProcessing.getTodayFloodData();
  }

  Stream<List<Map<String, dynamic>>> getFloodDataBasedOnTime() {
    return floodData.getFloodDataBasedOnTime();
  }
}
