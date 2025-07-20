import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:indian_guru/classroom_home_page.dart';
import 'package:indian_guru/firebase_options.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  // Ensure platform channels are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize path provider
  await getTemporaryDirectory();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Google Classroom App',
      home: ClassroomHomePage(),
    );
  }
}
