import 'package:diagnosis/page/alarms/alarms.dart';
import 'package:diagnosis/page/devices/devices.dart';
import 'package:diagnosis/page/diagnostics/diagnostics.dart';
import 'package:diagnosis/page/settings/settings.dart';
import 'package:flutter/material.dart';
import 'page/dashboard/dashboard.dart';

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
        // scaffoldBackgroundColor: Colors.lightBlue,
      ),
      // home: const HomePage(title: 'Diagnostics Home Page'),
      initialRoute: '/',
      routes: {
        '/': (context) => DashboardPage(),
        // '/': (context) => HomePage(title: 'Diagnostics Home Page'),
        '/settings': (context) => SystemSettingsPage(),
        '/collection': (context) => DataCollectionPage(),
        '/analysis': (context) => DataAnalysisPage(),
        '/alert': (context) => AlertManagementPage(),
      },
    );
  }
}

