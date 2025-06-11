import 'package:diagnosis/page/alarms/alarms.dart';
import 'package:diagnosis/page/devices/devices.dart';
import 'package:diagnosis/page/diagnostics/diagnostics.dart';
import 'package:diagnosis/page/settings/settings.dart';
import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';
import 'page/dashboard/dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        '/collection': (context) => DataCollectionPage(),
        '/analysis': (context) => DataAnalysisPage(),
        '/alert': (context) => AlertManagementPage(),
      },
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      navigatorObservers: [RouteObserver<ModalRoute>()],
    );
  }
}
