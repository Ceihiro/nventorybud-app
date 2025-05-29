import 'package:flutter/material.dart';
import 'main.dart';  // Adjust this import path if splash_screen.dart is in a subfolder

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const MyHomePage(title: 'Home Page'), // Pass title to MyHomePage
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset('assets/NventoryBud.png'), // PNG image path
      ),
    );
  }
}