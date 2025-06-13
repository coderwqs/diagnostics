import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionsPage extends StatefulWidget {
  @override
  _VersionsPageState createState() => _VersionsPageState();
}

class _VersionsPageState extends State<VersionsPage> {
  String _appName = '';
  String _version = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _getAppInfo();
  }

  Future<void> _getAppInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appName = packageInfo.appName; // 获取应用名称
      _version = packageInfo.version; // 获取版本号
      _buildNumber = packageInfo.buildNumber; // 获取构建号
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('设置')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('应用名称: $_appName', style: TextStyle(fontSize: 20)),
            SizedBox(height: 10),
            Text('版本号: $_version', style: TextStyle(fontSize: 20)),
            SizedBox(height: 10),
            Text('构建号: $_buildNumber', style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
