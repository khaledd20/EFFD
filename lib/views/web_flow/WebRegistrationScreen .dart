import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'web_login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(home: WebRegistrationScreen()));
}

class WebRegistrationScreen extends StatefulWidget {
  @override
  _WebRegistrationScreenState createState() => _WebRegistrationScreenState();
}

class _WebRegistrationScreenState extends State<WebRegistrationScreen> {
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Blue panel with image and text
          Expanded(
            flex: 2,
            child: Container(
              color: Color(0xFF0175c2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // Replace with your asset image for the flood illustration
                  Image.asset('images/kl_towers.png', height: 300),
                  Text(
                    'Stay prepared for floods.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Receive real-time flood alerts and manage your flood insurance.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Registration form
          Expanded(
            flex: 3,
            child: Container(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Early Flash Flood Detection',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 60),
                  Text(
                    'Sign up',
                    style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      hintText: 'Choose a username',
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: 'Enter your email address',
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      hintText: 'Confirm your password',
                      labelText: 'Confirm Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () => performRegistration(context),
                    child: Text('Sign up'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: Colors.blue,
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                        context,
                         MaterialPageRoute(builder: (context) => WebLoginScreen()),
                      );
                      },
                      child: Text('Already have an account? Log in'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  void performRegistration(BuildContext context) async {
    String username = _usernameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text;
    String confirmPassword = _confirmPasswordController.text;

    if (username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showDialog(context, 'Error', 'All fields are required.');
      return;
    }

    if (password.length < 8) {
      _showDialog(context, 'Error', 'Password must be at least 8 characters long.');
      return;
    }

    if (password != confirmPassword) {
      _showDialog(context, 'Error', 'Passwords do not match.');
      return;
    }

    try {
      // Create user with email and password
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Add user data to Firestore
      await firestore.collection('webUsers').doc(userCredential.user!.uid).set({
        'userId': userCredential.user!.uid, // Assigning the UID as userId
        'username': username,
        'email': email,
        'role': 'analyzer',
        'password': password, // Consider using a more secure way to handle passwords
      });

      _showDialog(context, 'Success', 'Registration successful! Please login.', popOnClose: true);
    } catch (e) {
      _showDialog(context, 'Error', e.toString());
    }
  }

  void _showDialog(BuildContext context, String title, String content, {bool popOnClose = false}) {
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
                Navigator.of(context).pop(); // Optionally close the current screen
              }
            },
          ),
        ],
      ),
    );
  }
}
