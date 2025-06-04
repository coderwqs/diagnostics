import 'package:flutter/material.dart';

class AlertManagementPage extends StatelessWidget {
  const AlertManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('告警管理'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          AlertCard(
            color: Colors.red,
            icon: Icons.alarm,
            title: '设备故障',
            description: '检测到设备故障，请及时处理。',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('处理设备故障告警')),
              );
            },
          ),
          SizedBox(height: 16),
          AlertCard(
            color: Colors.orange,
            icon: Icons.warning,
            title: '电池电量低',
            description: '设备电池电量低，请充电。',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('处理电池电量低告警')),
              );
            },
          ),
          SizedBox(height: 16),
          AlertCard(
            color: Colors.yellow,
            icon: Icons.notifications,
            title: '系统更新',
            description: '有可用的系统更新，请及时检查。',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('处理系统更新告警')),
              );
            },
          ),
          SizedBox(height: 16),
          AlertCard(
            color: Colors.blue,
            icon: Icons.error,
            title: '网络异常',
            description: '检测到网络连接问题，请检查网络。',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('处理网络异常告警')),
              );
            },
          ),
          SizedBox(height: 16),
          AlertCard(
            color: Colors.purple,
            icon: Icons.security,
            title: '安全警报',
            description: '检测到安全威胁，请尽快处理。',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('处理安全警报')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class AlertCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  AlertCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.white),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(description, style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
