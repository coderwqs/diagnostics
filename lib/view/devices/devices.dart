import 'package:flutter/material.dart';

class DevicesPage extends StatelessWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '数据采集',
          style: textTheme.headlineSmall?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.blue.shade50.withValues(alpha: 0.3),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50.withValues(alpha: 0.3), Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildFeatureCard(
                context,
                icon: Icons.sensors,
                title: "设备管理",
                subtitle: "查看设备列表信息",
                color: Colors.blue.shade100,
                iconColor: Colors.green,
                onTap: () {
                  Navigator.pushNamed(context, '/device/list');
                },
              ),
              const SizedBox(height: 12),
              _buildFeatureCard(
                context,
                icon: Icons.graphic_eq,
                title: "实时数据采集",
                subtitle: "监控实时数据流",
                color: Colors.blue.shade100,
                iconColor: Colors.blue,
                onTap: () {
                  Navigator.pushNamed(context, '/device/collection');
                },
              ),
              const SizedBox(height: 12),
              _buildFeatureCard(
                context,
                icon: Icons.history,
                title: "数据历史记录",
                subtitle: "查看历史数据记录",
                color: Colors.blue.shade100,
                iconColor: Colors.green,
                onTap: () {
                  Navigator.of(context).pushNamed('/device/history');
                },
              ),
              const SizedBox(height: 12),
              _buildFeatureCard(
                context,
                icon: Icons.import_export,
                title: "数据导入",
                subtitle: "导入CSV数据",
                color: Colors.blue.shade100,
                iconColor: Colors.orange,
                onTap: () {
                  Navigator.of(context).pushNamed('/device/history/import');
                },
              ),
              const SizedBox(height: 12),
              _buildFeatureCard(
                context,
                icon: Icons.delete,
                title: "数据清理",
                subtitle: "清理过期数据",
                color: Colors.blue.shade100,
                iconColor: Colors.red,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 24, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
