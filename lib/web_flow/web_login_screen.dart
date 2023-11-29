import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
              onPressed: () => performLogin(context),
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
//integrating the login funtion
  void performLogin(BuildContext context) async {
    String username = _usernameController.text;
    String password = _passwordController.text;

    // Query Firebase collection
    var users = await firestore
        .collection('webUsers')
        .where('username', isEqualTo: username)
        .where('password', isEqualTo: password)
        .get();

    if (users.docs.isNotEmpty) {
      // Login successful
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Login Successful'),
          content: Text('Welcome, $username!'),
        ),
      );
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
}
