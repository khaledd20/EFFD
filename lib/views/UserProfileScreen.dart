import 'package:flutter/material.dart';
import '../models/ProfileManagement.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  UserProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final ProfileManagement profileManagement = ProfileManagement();
  Map<String, dynamic>? userData;
  bool isLoading = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  void loadUserData() async {
    userData = await profileManagement.getProfileData(widget.userId);
    if (userData != null) {
      _emailController.text = userData!['email'] ?? '';
      _passwordController.text = userData!['password'] ?? '';

      setState(() => isLoading = false);
    }
  }

  void updateUserData() async {
    bool emailUpdated = false;
    if (_emailController.text != userData!['email']) {
      emailUpdated = await profileManagement.updateEmail(widget.userId, _emailController.text);
    }

    bool passwordUpdated = false;
    if (_passwordController.text.isNotEmpty) {
      passwordUpdated = await profileManagement.updatePassword(widget.userId, _passwordController.text);
    }

    String message = '';
    if (emailUpdated && passwordUpdated) {
      message = 'Email and password updated successfully.';
    } else if (emailUpdated) {
      message = 'Email updated successfully.';
    } else if (passwordUpdated) {
      message = 'Password updated successfully.';
    } else {
      message = 'No changes made or update failed.';
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("User Profile")),
      body: isLoading
        ? CircularProgressIndicator()
        : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(labelText: 'Email'),
                  ),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(labelText: 'New Password', hintText: 'Enter new password if changing'),
                    obscureText: true,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: updateUserData,
                    child: Text('Save Changes'),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
