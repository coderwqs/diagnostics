import 'dart:io';

import 'package:diagnosis/page/alarms/alarms.dart';
import 'package:diagnosis/page/devices/components/devices_management.dart';
import 'package:diagnosis/page/devices/devices.dart';
import 'package:diagnosis/page/diagnostics/diagnostics.dart';
import 'package:diagnosis/page/settings/components/versions.dart';
import 'package:diagnosis/page/settings/settings.dart';
import 'package:diagnosis/utils/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'l10n/app_localizations.dart';
import 'page/dashboard/dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> initializeDB() async {
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    databaseFactory = databaseFactoryFfi;
  }

  final db = DatabaseHelper.instance;

  db.addMigrations([
    Migration(1, '''
      CREATE TABLE devices (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        identity TEXT NOT NULL,
        secret TEXT NOT NULL,
        status TEXT CHECK(status IN ('online', 'offline', 'warning')),
        lastActive INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        image TEXT NOT NULL
      )
    '''),
  ]);

  await db.database;
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
