import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'models/dataGenerator.dart';
import 'views/android_flow/android_login_screen.dart';
import 'views/android_flow/viewer_dashboard.dart';
import 'views/web_flow/web_login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyB6FsLrrbF4jN7VcfqKAe3TMPKErwm4k5M",
      authDomain: "early-flash-flood-detection.firebaseapp.com",
      projectId: "early-flash-flood-detection",
      storageBucket: "early-flash-flood-detection.appspot.com",
      messagingSenderId: "625125091387",
      appId: "1:625125091387:web:9f738a479d68d06a07541e",
    ),
  );

    // Initialize and call DataGenerator here
  final dataGenerator = DataGenerator();
  await dataGenerator.ensureDailyDataGeneration();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EFFD',
      builder: EasyLoading.init(),
      home: kIsWeb ? WebLoginScreen() : ViewerDashboard(),
    );
  }
}