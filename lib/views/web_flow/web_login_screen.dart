import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'AnalyzerDashboard .dart';
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
      body: Row(
        children: [
          // Left side with image and text
          Expanded(
            flex: 2, // takes 40% of the screen width
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
          // Right side with login form
          Expanded(
            flex: 3, // takes 60% of the screen width
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
                    'Log in',
                    style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      hintText: 'Enter your username',
                      labelText: 'Username',
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
                  SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () => performLogin(),
                    child: Text('Login'),
                    style: ElevatedButton.styleFrom(
                      primary: Colors.blue,
                      onPrimary: Colors.white,
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),
                  SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: () => navigateToRegistration(),
                    child: Text('Sign up'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.blue),
                      minimumSize: Size(double.infinity, 50),
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
          /*MaterialPageRoute(
            builder: (context) => AnalyzerProfile(userId: userData['userId']),
          ),*/
          MaterialPageRoute(
          builder: (context) => AnalyzerDashboard(),
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
