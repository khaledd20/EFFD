import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    // Get the user data from Firestore
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
        title: Text('Analyzer Profile'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Welcome $_userName', // Display the welcome message with the user's name
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
            ),
            SizedBox(height: 10.0),
            Text(
              'Email:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Expanded(
                  child: _editEmail
                      ? TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: 'Enter new email',
                          ),
                        )
                      : Text(_emailController.text),
                ),
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    setState(() {
                      _editEmail = !_editEmail;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 20.0),
            Text(
              'Password:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Expanded(
                  child: _editPassword
                      ? TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: 'Enter new password',
                          ),
                        )
                      : Text(_passwordController.text.replaceAll(RegExp(r'.'), '*')), // Mask the password
                ),
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    setState(() {
                      _editPassword = !_editPassword;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () => updateProfile(context),
              child: Text('Update Profile'),
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
      try {
        // Perform the update operation with Firestore
        await FirebaseFirestore.instance.collection('webUsers').doc(widget.userId).update({
          'email': _emailController.text,
          'password': _passwordController.text,
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
    }
  }
}
