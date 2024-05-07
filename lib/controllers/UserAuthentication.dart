// filename: UserAuthentication.dart
import 'package:flutter/material.dart';
import '../models/UserManagement.dart';
import '../views/LoginScreen.dart';
import '../views/RegistrationScreen.dart';
import '../views/UserProfileScreen.dart';

class UserAuthentication {
  final UserManagement userManagement = UserManagement();

  Future<void> performLogin(BuildContext context, String username, String password) async {
    var userData = await userManagement.authenticateUser(username, password);
    if (userData != null) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfileScreen(userData: userData)));
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Login Failed'),
          content: Text('Invalid username or password.'),
        ),
      );
    }
  }

  void navigateToRegistration(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => RegistrationScreen()));
  }

  void navigateToLogin(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
  }
}
