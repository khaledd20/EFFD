import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'AndroidProfileScreen .dart';
import 'AndroidRegistrationScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(home: AndroidLoginScreen()));
}

class AndroidLoginScreen extends StatelessWidget {
  // Firebase Firestore instance
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Text Editing Controllers to retrieve text field input
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Android Login Screen'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
                  Image.asset('assets/images/kl_towers.png', height: 300),
              SizedBox(height: 20),
              Text(
                'Stay prepared for floods.',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Receive real-time flood alerts and manage your flood insurance.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => performLogin(context),
                child: Text('Login'),
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: () => navigateToRegistration(context),
                child: Text('Sign up'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void performLogin(BuildContext context) async {
    String username = usernameController.text;
    String password = passwordController.text;

    // Query Firebase collection
    var users = await firestore
        .collection('androidUsers')
        .where('username', isEqualTo: username)
        .where('password', isEqualTo: password)
        .get();

    if (users.docs.isNotEmpty) {
      // Login successful
      var userData = users.docs.first.data();
      if (userData['userId'] != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AndroidProfileScreen(userId: userData['userId']),
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

  void navigateToRegistration(BuildContext context) {
    // Navigate to the registration screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AndroidRegistrationScreen()),
    );
  }
}
