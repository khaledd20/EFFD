import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/UserManagement.dart';
import '../models/ProfileManagement.dart';

class UserController {
  final UserManagement userManagement = UserManagement();
  final ProfileManagement profileManagement = ProfileManagement();

  Future<bool> addUser(BuildContext context, String username, String email, String password, String role, Function refreshData) async {
    String collection = role == 'analyzer' ? 'webUsers' : 'androidUsers';
    bool success = await userManagement.advancedcreateUser(username, email, password, role, collection);
    if (success) {
      userManagement.showCustomDialog(context, 'Success', 'User added successfully!');
      refreshData();
      userManagement.showCustomDialog(context, 'Success', 'User added successfully!');

    } else {
      userManagement.showCustomDialog(context, 'Error', 'Failed to add user');
    }
    return success;
  }

  Future<bool> updateUser(BuildContext context, String userId, String username, String email, String password, String newRole, Function refreshData) async {
    String? oldCollection;
    String? documentId;
    String? oldRole;

    QuerySnapshot webUsers = await profileManagement.firestore.collection('webUsers').where('userId', isEqualTo: userId).get();
    if (webUsers.docs.isNotEmpty) {
      oldCollection = 'webUsers';
      documentId = webUsers.docs.first.id;
      oldRole = 'analyzer';
    } else {
      QuerySnapshot androidUsers = await profileManagement.firestore.collection('androidUsers').where('userId', isEqualTo: userId).get();
      if (androidUsers.docs.isNotEmpty) {
        oldCollection = 'androidUsers';
        documentId = androidUsers.docs.first.id;
        oldRole = 'viewer';
      }
    }

    if (oldCollection != null && documentId != null) {
      Map<String, dynamic> updatedData = {
        'username': username,
        'email': email,
        'password': password,
        'role': newRole,
        'userId': userId,
      };

      if (oldRole != newRole) {
        String newCollection = newRole == 'analyzer' ? 'webUsers' : 'androidUsers';

        // Add user to the new collection
        await profileManagement.firestore.collection(newCollection).doc(userId).set(updatedData);

        // Delete user from the old collection
        await profileManagement.firestore.collection(oldCollection).doc(documentId).delete();
        userManagement.showCustomDialog(context, 'Success', 'Profile updated and moved successfully!');
        refreshData();
        userManagement.showCustomDialog(context, 'Success', 'Profile updated and moved successfully!');

        return true;
      } else {
        bool success = await profileManagement.advancedUpdateProfileData(documentId, updatedData, oldCollection);
         userManagement.showCustomDialog(context, 'Success', 'Profile updated successfully!');
        if (success) {
          refreshData();
          userManagement.showCustomDialog(context, 'Success', 'Profile updated successfully!');

        } else {
          userManagement.showCustomDialog(context, 'Error', 'Failed to update profile');
        }
        return success;
      }
    } else {
      userManagement.showCustomDialog(context, 'Error', 'Failed to find user in collections');
      return false;
    }
  }

  Future<bool> deleteUser(BuildContext context, String userId, String role, Function refreshData) async {
    String collection = role == 'analyzer' ? 'webUsers' : 'androidUsers';
    bool success = await profileManagement.firestore.collection(collection).doc(userId).delete().then((_) => true).catchError((e) {
      print("Failed to delete user: $e");
      return false;
    });
    if (success) {
      if (context.mounted) {
        userManagement.showCustomDialog(context, 'Success', 'User deleted successfully!');
        refreshData();
      }
    } else {
      if (context.mounted) {
        userManagement.showCustomDialog(context, 'Error', 'Failed to delete user');
      }
    }
    return success;
  }
}
