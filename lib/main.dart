import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:indian_guru/classroom_home_page.dart';
import 'package:indian_guru/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Classroom App',
      home: ClassroomHomePage(),
    );
  }
}
