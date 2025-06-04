import 'package:flutter/material.dart';

class SystemSettingsPage extends StatelessWidget {
  const SystemSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('系统设置')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              title: Text("语言设置"),
              subtitle: Text("选择应用语言"),
              trailing: Icon(Icons.language),
              onTap: () {
                // 处理语言设置
              },
            ),
            Divider(),
            ListTile(
              title: Text("通知设置"),
              subtitle: Text("管理通知选项"),
              trailing: Icon(Icons.notifications),
              onTap: () {
                // 处理通知设置
              },
            ),
            Divider(),
            ListTile(
              title: Text("账户管理"),
              subtitle: Text("管理用户账户"),
              trailing: Icon(Icons.account_circle),
              onTap: () {
                // 处理账户管理
              },
            ),
            Divider(),
            ListTile(
              title: Text("隐私设置"),
              subtitle: Text("管理隐私选项"),
              trailing: Icon(Icons.privacy_tip),
              onTap: () {
                // 处理隐私设置
              },
            ),
            Divider(),
            ListTile(
              title: Text("版本信息"),
              subtitle: Text("查看应用版本"),
              trailing: Icon(Icons.info),
              onTap: () {
                // 显示版本信息
              },
            ),
          ],
        ),
      ),
    );
  }
}
