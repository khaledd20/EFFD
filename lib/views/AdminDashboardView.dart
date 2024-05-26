import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/UserController.dart';
import 'LoginScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(home: AdminDashboardScreen()));
}

class AdminDashboardScreen extends StatefulWidget {
  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final UserController userController = UserController();

  void _showAddUserScreen(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => AddUserScreen(
        userController: userController,
        refreshData: () {
          setState(() {}); // Refresh the AdminDashboardScreen to update the UserList
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        backgroundColor: const Color.fromARGB(255, 39, 122, 247),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: const Color.fromARGB(255, 39, 122, 247)),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app, color: const Color.fromARGB(255, 39, 122, 247)),
              title: Text('Logout'),
              onTap: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
              },
            ),
          ],
        ),
      ),
      body: UserList(userController: userController),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddUserScreen(context),
        backgroundColor: const Color.fromARGB(255, 39, 122, 247),
        child: Icon(Icons.add),
      ),
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
  Future<List<DocumentSnapshot>>? _futureUsers;

  @override
  void initState() {
    super.initState();
    _futureUsers = getUsers();
  }

  Future<List<DocumentSnapshot>> getUsers() async {
    QuerySnapshot webUsers = await FirebaseFirestore.instance.collection("webUsers").get();
    QuerySnapshot androidUsers = await FirebaseFirestore.instance.collection("androidUsers").get();
    List<DocumentSnapshot> combinedUsers = webUsers.docs;
    combinedUsers.addAll(androidUsers.docs);
    return combinedUsers;
  }

  void refreshData() {
    setState(() {
      _futureUsers = getUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DocumentSnapshot>>(
      future: _futureUsers,
      builder: (BuildContext context, AsyncSnapshot<List<DocumentSnapshot>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (snapshot.hasData) {
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var user = snapshot.data![index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text(user.get('username')),
                  subtitle: Text(user.get('email')),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: const Color.fromARGB(255, 39, 122, 247)),
                        onPressed: () => _showEditUserScreen(context, user),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          bool success = await widget.userController.deleteUser(context, user.id, user.get('role'), refreshData);
                          if (!success) {
                            // Handle delete error if needed
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        } else {
          return Center(child: Text("No data available"));
        }
      },
    );
  }

  void _showEditUserScreen(BuildContext context, DocumentSnapshot user) {
    showModalBottomSheet(
      context: context,
      builder: (_) => EditUserScreen(userController: widget.userController, user: user as QueryDocumentSnapshot, refreshData: refreshData),
    );
  }
}
class AddUserScreen extends StatefulWidget {
  final UserController userController;
  final Function refreshData;

  AddUserScreen({required this.userController, required this.refreshData});

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
            decoration: InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
          ),
          SizedBox(height: 8),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
          ),
          SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
          ),
          SizedBox(height: 8),
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
              border: OutlineInputBorder(),
            ),
            items: <String>['analyzer', 'viewer']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              bool success = await widget.userController.addUser(
                context,
                _usernameController.text,
                _emailController.text,
                _passwordController.text,
                _selectedRole,
                widget.refreshData,
              );
              if (success) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 39, 122, 247)),
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
  final Function refreshData;

  EditUserScreen({required this.userController, required this.user, required this.refreshData});

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
            decoration: InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
          ),
          SizedBox(height: 8),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
          ),
          SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
          ),
          SizedBox(height: 8),
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
              border: OutlineInputBorder(),
            ),
            items: <String>['analyzer', 'viewer']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              bool success = await widget.userController.updateUser(
                context,
                widget.user.id,
                _usernameController.text,
                _emailController.text,
                _passwordController.text,
                _selectedRole,
                widget.refreshData,
              );
              if (success) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 39, 122, 247)),
            child: Text('Update User'),
          ),
        ],
      ),
    );
  }
}
