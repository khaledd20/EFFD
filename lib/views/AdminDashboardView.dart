import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/UserController.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(home: AdminDashboardScreen()));
}

class AdminDashboardScreen extends StatelessWidget {
  final UserController userController = UserController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
      ),
      body: UserList(userController: userController),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddUserScreen(context),
        child: Icon(Icons.add),
      ),
    );
  }

  void _showAddUserScreen(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => AddUserScreen(userController: userController),
    );
  }
}

class UserList extends StatefulWidget {
  final UserController userController;

  UserList({required this.userController});

  @override
  _UserListState createState() => _UserListState();
}

class _UserListState extends State<UserList> {
  Future<List<DocumentSnapshot>> getUsers() async {
    QuerySnapshot webUsers = await FirebaseFirestore.instance.collection("webUsers").get();
    QuerySnapshot androidUsers = await FirebaseFirestore.instance.collection("androidUsers").get();
    List<DocumentSnapshot> combinedUsers = webUsers.docs;
    combinedUsers.addAll(androidUsers.docs);
    return combinedUsers;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DocumentSnapshot>>(
      future: getUsers(),
      builder: (BuildContext context, AsyncSnapshot<List<DocumentSnapshot>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text("Error: ${snapshot.error}");
        } else if (snapshot.hasData) {
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var user = snapshot.data![index];
              return ListTile(
                title: Text(user.get('username')),
                subtitle: Text(user.get('email')),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () => _showEditUserScreen(context, user),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => widget.userController.deleteUser(context, user.id, user.get('role')),
                    ),
                  ],
                ),
              );
            },
          );
        } else {
          return Text("No data available");
        }
      },
    );
  }

  void _showEditUserScreen(BuildContext context, DocumentSnapshot user) {
    showModalBottomSheet(
      context: context,
      builder: (_) => EditUserScreen(userController: widget.userController, user: user as QueryDocumentSnapshot),
    );
  }
}


class AddUserScreen extends StatefulWidget {
  final UserController userController;

  AddUserScreen({required this.userController});

  @override
  _AddUserScreenState createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _selectedRole = 'analyzer'; // Default role

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(labelText: 'Username'),
          ),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(labelText: 'Email'),
          ),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(labelText: 'Password'),
          ),
          DropdownButtonFormField<String>(
            value: _selectedRole,
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedRole = newValue;
                });
              }
            },
            decoration: InputDecoration(
              labelText: 'Role',
              border: OutlineInputBorder(), // Optional: Adds border to the dropdown
            ),
            items: <String>['analyzer', 'viewer']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          ElevatedButton(
            onPressed: () {
              widget.userController.addUser(
                context,
                _usernameController.text,
                _emailController.text,
                _passwordController.text,
                _selectedRole,
              );
            },
            child: Text('Add User'),
          ),
        ],
      ),
    );
  }
}
class EditUserScreen extends StatefulWidget {
  final UserController userController;
  final DocumentSnapshot user;

  EditUserScreen({required this.userController, required this.user});

  @override
  _EditUserScreenState createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _selectedRole = 'analyzer'; // Default role

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.user.get('username');
    _emailController.text = widget.user.get('email');
    _passwordController.text = widget.user.get('password');
    _selectedRole = widget.user.get('role');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(labelText: 'Username'),
          ),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(labelText: 'Email'),
          ),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(labelText: 'Password'),
          ),
          DropdownButtonFormField<String>(
            value: _selectedRole,
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedRole = newValue;
                });
              }
            },
            decoration: InputDecoration(
              labelText: 'Role',
              border: OutlineInputBorder(), // Optional: Adds border to the dropdown
            ),
            items: <String>['analyzer', 'viewer']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          ElevatedButton(
            onPressed: () {
              widget.userController.updateUser(
                context,
                widget.user.id,
                _usernameController.text,
                _emailController.text,
                _passwordController.text,
                _selectedRole,
              );
            },
            child: Text('Update User'),
          ),
        ],
      ),
    );
  }
}
 