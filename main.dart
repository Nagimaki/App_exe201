// lib/main.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  int userId = prefs.getInt('userId') ?? 0;
  String userName = prefs.getString('userName') ?? '';
  String role     = prefs.getString('role')     ?? 'employee';

  runApp(MyApp(
    isLoggedIn: isLoggedIn,
    userId: userId,
    userName: userName,
    role: role,
  ));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final int userId;
  final String userName;
  final String role;

  const MyApp({
    Key? key,
    required this.isLoggedIn,
    required this.userId,
    required this.userName,
    required this.role,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mobile App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFcde9cc),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: isLoggedIn
          ? HomePage(
        userId: userId,
        userName: userName,
        role: role,
      )
          : LoginPage(),
    );
  }
}
