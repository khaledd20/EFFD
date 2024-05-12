import 'package:flutter/material.dart';
import '../models/FloodData.dart'; // Importing the model

class FloodEventAnalysis {
  final floodData = FloodData(); // Instance of the model

  Stream<List<Map<String, dynamic>>> getFloodDataBasedOnTime() {
    return floodData.getFloodDataBasedOnTime();
  }
}
