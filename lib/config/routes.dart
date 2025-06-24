import 'package:diagnosis/view/alarms/alarms.dart';
import 'package:diagnosis/view/dashboard/dashboard.dart';
import 'package:diagnosis/view/devices/components/devices_management.dart';
import 'package:diagnosis/view/devices/devices.dart';
import 'package:diagnosis/view/devices/guide/import_data.dart';
import 'package:diagnosis/view/devices/history/history.dart';
import 'package:diagnosis/view/diagnostics/analysis/analysis_list.dart';
import 'package:diagnosis/view/diagnostics/diagnostics.dart';
import 'package:diagnosis/view/settings/components/versions.dart';
import 'package:diagnosis/view/settings/settings.dart';
import 'package:flutter/cupertino.dart';

Map<String, WidgetBuilder> routes = {
  '/': (context) => DashboardPage(),
  '/settings': (context) => SystemSettingsPage(),
  '/device': (context) => DevicesPage(),
  '/diagnostics': (context) => DiagnosticsPage(),
  '/alert': (context) => AlertManagementPage(),

  '/versions': (context) => VersionsPage(),
  '/device/list': (context) => DeviceManagementPage(),
  '/device/history': (context) => HistoryDataPage(),
  '/device/history/import': (context) => DataImportScreen(),

  '/diagnostics/analysis': (context) => DataAnalysisPage(),
};
