import 'package:flutter/material.dart';
import 'splash_screen.dart'; // import splash screen, same lib folder

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Splash',
      home: const SplashScreen(), // start splash screen as home
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState(); // Create the state
}

class _MyHomePageState extends State<MyHomePage> { // State class
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          widget.title,
          style: const TextStyle(
            fontFamily: 'MyFont', // Custom font family
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF007BA7),
      ),
      body: Container( // Use a Container to set the background color
        color: const Color(0xFFfaf3e0), // Set background color here
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Welcome to My Home Page!',
              style: TextStyle(
                fontFamily: 'MyFont', // Ensure this matches the family name in pubspec.yaml
              ),
            )
          ],
        ),
      ),
    );
  }
}