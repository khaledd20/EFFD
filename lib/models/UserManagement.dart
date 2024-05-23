import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // Import foundation to use kIsWeb
import 'package:flutter/material.dart';

class UserManagement {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> authenticateUser(String username, String password) async {
    // Determine the collection based on the platform
    String collectionName = kIsWeb ? 'webUsers' : 'androidUsers';
    var result = await firestore.collection(collectionName).where('username', isEqualTo: username).where('password', isEqualTo: password).get();
    if (result.docs.isNotEmpty) {
      return result.docs.first.data();
    }
    return null;
  }
  Future<bool> advancedcreateUser(String username, String email, String password, String role, String collection) async {
  try {
    UserCredential userCredential = await auth.createUserWithEmailAndPassword(email: email, password: password);

    // Determine the collection based on the role
    String collectionName = role == 'analyzer' ? 'webUsers' : 'androidUsers';

    await firestore.collection(collectionName).doc(userCredential.user!.uid).set({
      'username': username,
      'email': email,
      'password': password, // Note: Storing passwords in plain text is insecure
      'role': role,
      'userId': userCredential.user!.uid
    });
    return true;
  } catch (e) {
    print(e.toString());
    return false;
  }
}

  Future<bool> createUser(String username, String email, String password, String role) async {
    try {
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(email: email, password: password);
      // Determine the collection based on the platform
      String collectionName = kIsWeb ? 'webUsers' : 'androidUsers';
      await firestore.collection(collectionName).doc(userCredential.user!.uid).set({
        'username': username,
        'email': email,
        'password': password, // Note: Storing passwords in plain text is insecure
        'role': role,
        'userId': userCredential.user!.uid
      });
      return true;
    } catch (e) {
      print(e.toString());
      return false;
    }
  }


  void showCustomDialog(BuildContext context, String title, String content, {bool popOnClose = false}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
              if (popOnClose) {
                Navigator.of(context). pop(); // Optionally close the current screen
              }
            },
          ),
        ],
      ),
    );
  }
}
