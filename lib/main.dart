import 'dart:io';

import 'package:diagnosis/database/devices.dart';
import 'package:diagnosis/database/users.dart';
import 'package:diagnosis/view/alarms/alarms.dart';
import 'package:diagnosis/view/devices/components/devices_management.dart';
import 'package:diagnosis/view/devices/devices.dart';
import 'package:diagnosis/view/diagnostics/diagnostics.dart';
import 'package:diagnosis/view/settings/components/versions.dart';
import 'package:diagnosis/view/settings/settings.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'l10n/app_localizations.dart';
import 'package:diagnosis/view/dashboard/dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> initializeDB() async {
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    databaseFactory = databaseFactoryFfi;
  }

  await DeviceDatabase().initializeDatabase();
  await UserDatabase().initializeDatabase();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDB();

  final prefs = await SharedPreferences.getInstance();
  final savedLanguage = prefs.getString('language') ?? 'zh';

  runApp(DiagnosticsApp(locale: Locale(savedLanguage)));
}

class DiagnosticsApp extends StatelessWidget {
  final Locale locale;

  const DiagnosticsApp({super.key, required this.locale});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diagnostics',
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => DashboardPage(),
        '/settings': (context) => SystemSettingsPage(),
        '/device': (context) => DataCollectionPage(),
        '/analysis': (context) => DataAnalysisPage(),
        '/alert': (context) => AlertManagementPage(),

        '/versions': (context) => VersionsPage(),
        '/device/list': (context) => DeviceManagementPage(),
      },
      onGenerateTitle: (context) => AppLocalizations.of(context)!.app_title,
      navigatorObservers: [RouteObserver<ModalRoute>()],
    );
  }
}
