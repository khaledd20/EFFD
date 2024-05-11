import 'package:flutter/material.dart';
import '../models/UserManagement.dart';
import '../models/ProfileManagement.dart';

class UserController {
  final UserManagement userManagement = UserManagement();
  final ProfileManagement profileManagement = ProfileManagement();

  Future<void> addUser(BuildContext context, String username, String email, String password, String role) async {
    String collection = role == 'analyzer' ? 'webUsers' : 'androidUsers';
    bool success = await userManagement.advancedcreateUser(username, email, password, role, collection);
    userManagement.showCustomDialog(context, success ? 'Success' : 'Error', success ? 'User added successfully!' : 'Failed to add user');
  }

  Future<void> updateUser(BuildContext context, String userId, String username, String email, String password, String role) async {
    String collection = role == 'analyzer' ? 'webUsers' : 'androidUsers';
    Map<String, dynamic> updatedData = {
      'username': username,
      'email': email,
      'password': password,
      'role': role
    };
    bool success = await profileManagement.advancedUpdateProfileData(userId, updatedData, collection);
    userManagement.showCustomDialog(context, success ? 'Success' : 'Error', success ? 'Profile updated successfully!' : 'Failed to update profile');
  }

  Future<void> deleteUser(BuildContext context, String userId, String role) async {
    String collection = role == 'analyzer' ? 'webUsers' : 'androidUsers';
    bool success = await profileManagement.firestore.collection(collection).doc(userId).delete().then((_) => true).catchError((e) {
      print("Failed to delete user: $e");
      return false;
    });
    userManagement.showCustomDialog(context, success ? 'Success' : 'Error', success ? 'User deleted successfully!' : 'Failed to delete user');
  }
}
