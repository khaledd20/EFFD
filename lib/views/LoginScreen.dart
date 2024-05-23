import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../controllers/UserAuthentication.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final UserAuthentication userAuth = UserAuthentication();

  @override
  Widget build(BuildContext context) {
    // Check if the platform is web
    bool isWeb = kIsWeb;

    return Scaffold(
      body: isWeb ? webLayout() : mobileLayout(), // Adjust the layout based on the platform
    );
  }

  Widget webLayout() {
    return Row(
      children: [
        // Left side with image and text
        Expanded(
          flex: 2,
          child: floodInfoPanel(),
        ),
        // Right side with login form
        Expanded(
          flex: 3,
          child: loginForm(),
        ),
      ],
    );
  }

  Widget mobileLayout() {
    return SingleChildScrollView( // Add SingleChildScrollView
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Aligns vertically center
          children: [
            floodInfoPanel(),
            SizedBox(height: 15), // Provide some spacing
            loginForm(),
          ],
        ),
      ),
    );
  }

  Widget floodInfoPanel() {
    return Container(
      color: Color(0xFF0175c2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Image.asset('assets/images/kl_towers.png', height: 500), // Ensure the image path is correct
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
    );
  }

  Widget loginForm() {
    return Container(
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
            controller: usernameController,
            decoration: InputDecoration(
              hintText: 'Enter your username',
              labelText: 'Username',
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
          SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => userAuth.performLogin(context, usernameController.text, passwordController.text),
            child: Text('Login'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white, backgroundColor: Colors.blue,
              minimumSize: Size(double.infinity, 50),
            ),
          ),
          SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => userAuth.navigateToRegistration(context),
            child: Text('Sign up'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.blue),
              minimumSize: Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }
}
