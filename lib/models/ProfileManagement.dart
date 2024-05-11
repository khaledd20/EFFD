import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Import foundation to use kIsWeb

class ProfileManagement {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  String get collectionName => kIsWeb ? 'webUsers' : 'androidUsers'; // Dynamic collection name based on platform

  Future<Map<String, dynamic>?> getProfileData(String userId) async {
    DocumentSnapshot snapshot = await firestore.collection(collectionName).doc(userId).get();
    return snapshot.data() as Map<String, dynamic>?;
  }

  Future<bool> updateProfileData(String userId, Map<String, dynamic> updatedData) async {
    try {
      await firestore.collection(collectionName).doc(userId).update(updatedData);
      return true;
    } catch (e) {
      print("Failed to update profile data: $e");
      return false;
    }
  }

  Future<bool> advancedUpdateProfileData(String userId, Map<String, dynamic> updatedData, String collection) async {
    try {
      await firestore.collection(collectionName).doc(userId).update(updatedData);
      return true;
    } catch (e) {
      print("Failed to update profile data: $e");
      return false;
    }
  }

  Future<bool> updateEmail(String userId, String newEmail) async {
    try {
      await firestore.collection(collectionName).doc(userId).update({'email': newEmail});
      return true;
    } catch (e) {
      print("Failed to update email: $e");
      return false;
    }
  }

  Future<bool> updatePassword(String userId, String newPassword) async {
    try {
      await firestore.collection(collectionName).doc(userId).update({'password': newPassword});
      return true;
    } catch (e) {
      print("Failed to update password: $e");
      return false;
    }
  }
}
