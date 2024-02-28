import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: passwordController,
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
