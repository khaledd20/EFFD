import 'package:flutter/material.dart';
import '../models/UserManagement.dart';
import '../models/ProfileManagement.dart';
import '../views/LoginScreen.dart';
import '../views/RegistrationScreen.dart';
import '../views/AdminDashboardView.dart';
import '../views/analyzerDashboard.dart'; 
import '../views/ViewerDashboard.dart';  // Import ViewerDashboard if not already done
import 'package:flutter/foundation.dart' show kIsWeb;
class UserAuthentication {
  final UserManagement userManagement = UserManagement();
  final ProfileManagement profileManagement = ProfileManagement();

  Future<void> performLogin(BuildContext context, String username, String password) async {
    // Check if the credentials match the admin credentials
    if (username == "utmadmin" && password == "123456") {
      // Navigate to the AdminDashboardView if the user is the admin
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AdminDashboardScreen()));
      return;
    }

    // Perform regular user authentication
    var userData = await userManagement.authenticateUser(username, password);
    if (userData != null) {
      String userId = userData['userId'];
      // Check for platform and role to determine the dashboard
      if (kIsWeb) {
        // For web users, depending on role navigate to respective dashboards
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AnalyzerDashboard(userId: userId)));
        
      } else {
        // For Android users, you might want to use the same logic or keep it specific to roles
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ViewerDashboard(userId: userId)));
      }
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
