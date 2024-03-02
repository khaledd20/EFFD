import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'AnalyzerProfile .dart';
import 'WebRegistrationScreen .dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(home: WebLoginScreen()));
}

class WebLoginScreen extends StatefulWidget {
  @override
  _WebLoginScreenState createState() => _WebLoginScreenState();
}

class _WebLoginScreenState extends State<WebLoginScreen> {
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  // Firebase Firestore instance
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Web Login Screen'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            ElevatedButton(
              onPressed: () => performLogin(),
              child: Text('Login'),
            ),
            SizedBox(height: 20), // Adds space between buttons
            TextButton(
              onPressed: () => navigateToRegistration(),
              child: Text("Don't have an account? Register"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> performLogin() async {
    String username = _usernameController.text;
    String password = _passwordController.text;

    // Query Firebase collection
    var users = await firestore
        .collection('webUsers')
        .where('username', isEqualTo: username)
        .where('password', isEqualTo: password)
        .get();

    if (users.docs.isNotEmpty) {
      // Assuming the user data is in users.docs.first.data()
      var userData = users.docs.first.data();

      // Check if userId is null before accessing it
      if (userData['userId'] != null) {
        // Pass the user data to the analyzerProfile page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnalyzerProfile(userId: userData['userId']),
          ),
        );
      } else {
        // Handle case where userId is null
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Error'),
            content: Text('User data is incomplete.'),
          ),
        );
      }
    } else {
      // Login failed
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Login Failed'),
          content: Text('Invalid username or password.'),
        ),
      );
    }
  }

  void navigateToRegistration() {
    // Navigate to the registration screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => WebRegistrationScreen()),
    );
  }
}
