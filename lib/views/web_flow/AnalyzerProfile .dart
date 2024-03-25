import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'AnalyzerDashboard .dart';
import 'web_login_screen.dart';

class AnalyzerProfile extends StatefulWidget {
  final String userId;

  const AnalyzerProfile({Key? key, required this.userId}) : super(key: key);

  @override
  _AnalyzerProfileState createState() => _AnalyzerProfileState();
}

class _AnalyzerProfileState extends State<AnalyzerProfile> {
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  bool _editEmail = false;
  bool _editPassword = false;
  String _userName = '';

  // Store the updated email and password
  String _updatedEmail = '';
  String _updatedPassword = '';

  @override
  void initState() {
    super.initState();
    // Initialize Firebase authentication
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        // User is signed in
        _getUserData();
      } else {
        // User is signed out
        // You might want to handle this case accordingly
      }
    });
  }

  Future<void> _getUserData() async {
    DocumentSnapshot userSnapshot =
        await FirebaseFirestore.instance.collection('webUsers').doc(widget.userId).get();

    setState(() {
      _userName = userSnapshot['username'];
      _emailController.text = userSnapshot['email'];
      _passwordController.text = userSnapshot['password'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile page'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Welcome $_userName',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AnalyzerDashboard(userId: widget.userId)),
                );
              },
            ),
            ListTile(
              title: Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => WebLoginScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      suffixIcon: _editEmail
                          ? IconButton(
                              icon: Icon(Icons.done),
                              onPressed: () {
                                setState(() {
                                  _editEmail = false;
                                  // Save the updated email
                                  _updatedEmail = _emailController.text;
                                });
                              },
                            )
                          : IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                setState(() {
                                  _editEmail = true;
                                });
                              },
                            ),
                    ),
                    readOnly: !_editEmail,
                  ),
                  SizedBox(height: 20.0),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      suffixIcon: _editPassword
                          ? IconButton(
                              icon: Icon(Icons.done),
                              onPressed: () {
                                setState(() {
                                  _editPassword = false;
                                  // Save the updated password
                                  _updatedPassword = _passwordController.text;
                                });
                              },
                            )
                          : IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                setState(() {
                                  _editPassword = true;
                                });
                              },
                            ),
                    ),
                    readOnly: !_editPassword,
                    obscureText: true,
                  ),
                  SizedBox(height: 20.0),
                  ElevatedButton(
                    onPressed: () => updateProfile(context),
                    child: Text('Update Profile'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Color(0xFF0175c2),
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

 void updateProfile(BuildContext context) async {
  // Get the current user
  User? user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    // Initialize updated email and password here
    String updatedEmail = _emailController.text;
    String updatedPassword = _passwordController.text;

    try {
      // Perform the update operation with Firestore using the updated email and password
      await FirebaseFirestore.instance.collection('webUsers').doc(widget.userId).update({
        'email': updatedEmail, // Use the updated email
        'password': updatedPassword, // Use the updated password
      });

      // Show a success message or navigate to another screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      // Show an error message if update fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile')),
      );
      print(e.toString());
    }
  } else {
    // Handle the case when user is null (not logged in)
    // You can prompt the user to log in or handle it according to your app's logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$_userName, you need to log in to update your profile')),
    );
  }
}

}
