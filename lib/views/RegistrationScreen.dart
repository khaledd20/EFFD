import 'package:flutter/material.dart';
import '../controllers/UserAuthentication.dart';
import '../models/UserManagement.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final UserAuthentication userAuth = UserAuthentication();
  final UserManagement userManagement = UserManagement();

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
                  Image.asset('images/kl_towers.png', height: 500), // Adjust the image path as necessary
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
                    controller: usernameController,
                    decoration: InputDecoration(
                      hintText: 'Choose a username',
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      hintText: 'Enter your email address',
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: confirmPasswordController,
                    decoration: InputDecoration(
                      hintText: 'Confirm your password',
                      labelText: 'Confirm Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () => performRegistration(),
                    child: Text('Sign up'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: Colors.blue,
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: TextButton(
                      onPressed: () => userAuth.navigateToLogin(context),
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

  void performRegistration() async {
    String username = usernameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      userManagement.showCustomDialog(context, 'Error', 'All fields are required.');
      return;
    }

    if (password.length < 8) {
      userManagement.showCustomDialog(context, 'Error', 'Password must be at least 8 characters long.');
      return;
    }

    if (password != confirmPassword) {
      userManagement.showCustomDialog(context, 'Error', 'Passwords do not match.');
      return;
    }

    // This uses the UserManagement model to handle user creation
    bool success = await userManagement.createUser(username, email, password, 'analyzer');
    if (success) {
      userManagement.showCustomDialog(context, 'Success', 'Registration successful! Please login.', popOnClose: true);
    } else {
      userManagement.showCustomDialog(context, 'Error', 'Registration failed.');
    }
  }
}