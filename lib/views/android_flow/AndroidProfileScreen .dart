import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'android_login_screen.dart'; // Import your Android login screen

class AndroidProfileScreen extends StatefulWidget {
  final String userId;

  const AndroidProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _AndroidProfileScreenState createState() => _AndroidProfileScreenState();
}

class _AndroidProfileScreenState extends State<AndroidProfileScreen> {
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
        await FirebaseFirestore.instance.collection('androidUsers').doc(widget.userId).get();

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
    appBar: AppBar(
      title: Text('Android Profile'),
    ),
    body: SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Welcome $_userName',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20.0,
            ),
          ),
          SizedBox(height: 20.0),
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
            onPressed: () => _updateProfile(context),
            child: Text('Save Changes'),
          ),
          SizedBox(height: 20.0),
        ],
      ),
    ),
  );
}


 void _updateProfile(BuildContext context) async {
  // Get the current user
  User? user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    // Validate email
    if (!_isValidEmail(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid email address')),
      );
      return;
    }

    // Validate password
    if (!_isValidPassword(_passwordController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password must be at least 8 characters long')),
      );
      return;
    }

    try {
      // Perform the update operation with Firestore
      await FirebaseFirestore.instance.collection('androidUsers').doc(widget.userId).update({
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

bool _isValidEmail(String email) {
  // Use a regular expression to validate email format
  String emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  RegExp regex = RegExp(emailPattern);
  return regex.hasMatch(email);
}

bool _isValidPassword(String password) {
  // Validate password length
  return password.length >= 8;
}

}
