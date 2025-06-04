import 'package:flutter/material.dart';

class DataCollectionPage extends StatelessWidget {
  const DataCollectionPage({super.key});

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('数据采集')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              title: Text("实时数据采集"),
              subtitle: Text("监控实时数据流"),
              trailing: Icon(Icons.graphic_eq),
              onTap: () {
                // 处理实时数据采集
              },
            ),
            Divider(),
            ListTile(
              title: Text("数据历史记录"),
              subtitle: Text("查看历史数据记录"),
              trailing: Icon(Icons.history),
              onTap: () {
                // 处理查看历史记录
              },
            ),
            Divider(),
            ListTile(
              title: Text("数据导出"),
              subtitle: Text("导出数据至CSV"),
              trailing: Icon(Icons.file_download),
              onTap: () {
                // 处理数据导出
              },
            ),
            Divider(),
            ListTile(
              title: Text("数据上传"),
              subtitle: Text("上传数据至服务器"),
              trailing: Icon(Icons.cloud_upload),
              onTap: () {
                // 处理数据上传
              },
            ),
            Divider(),
            ListTile(
              title: Text("数据清理"),
              subtitle: Text("清理过期数据"),
              trailing: Icon(Icons.delete),
              onTap: () {
                // 处理数据清理
              },
            ),
          ],
        ),
      ),
    );
  }
}
