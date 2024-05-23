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
  bool isEditing = false;
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
    setState(() => isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("User Profile"),
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 60,  // Slightly larger for easier visibility on mobile
                        backgroundColor: Colors.blueGrey,
                        child: userData!['profilePicture'] != null
                          ? ClipOval(
                              child: Image.network(userData!['profilePicture'], fit: BoxFit.cover, width: 120, height: 120)
                            )
                          : Icon(Icons.person, size: 60, color: Colors.white),  // Larger icon for mobile
                      ),
                    ),
                    SizedBox(height: 30),
                    Text('Email', style: TextStyle(color: Colors.blueAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: 'Enter your email',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                        enabled: isEditing,
                      ),
                    ),
                    SizedBox(height: 15),
                    Text('Password', style: TextStyle(color: Colors.blueAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        hintText: 'Enter new password',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                        enabled: isEditing,
                        
                      ),
                    ),
                    SizedBox(height: 30),
                    if (isEditing)
                      Center(
                        child: ElevatedButton(
                          onPressed: updateUserData,
                          child: Text('Save Changes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: EdgeInsets.symmetric(horizontal: 60, vertical: 20),  // Larger button for easier touch
                          ),
                        ),
                      )
                    else
                      Center(
                        child: ElevatedButton(
                          onPressed: () => setState(() => isEditing = true),
                          child: Text('Edit Profile'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: EdgeInsets.symmetric(horizontal: 60, vertical: 20),  // Larger button for easier touch
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
