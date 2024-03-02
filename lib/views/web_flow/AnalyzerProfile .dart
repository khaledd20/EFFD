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
    DocumentSnapshot userSnapshot =
        await FirebaseFirestore.instance.collection('webUsers').doc(widget.userId).get();

    setState(() {
      _userName = userSnapshot['username'];
      _emailController.text = userSnapshot['email'];
      // It's generally not secure to store and display passwords in clear text.
      _passwordController.text = userSnapshot['password'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: Color(0xFF0175c2),
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Text(
                'Welcome $_userName',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                  color: Colors.white,
                ),
              ),
            ),
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
                                  // Implement the logic to save the updated email
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
                                  // Implement the logic to save the updated password
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
                      primary: Color(0xFF0175c2),
                      onPrimary: Colors.white,
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
