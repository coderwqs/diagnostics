import 'package:flutter/material.dart';
import 'home.dart';

void main() {
  runApp(const DiagnosticsApp());
}

class DiagnosticsApp extends StatelessWidget {
  const DiagnosticsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diagnostics',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const HomePage(title: 'Diagnostics Home Page'),
    );
  }
}

