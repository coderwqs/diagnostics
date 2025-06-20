import 'package:flutter/material.dart';

class DiagnosticsPage extends StatelessWidget {
  const DiagnosticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '数据分析',
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
              _buildAnalysisCard(
                context,
                icon: Icons.trending_up,
                title: "趋势分析",
                subtitle: "分析数据趋势",
                iconColor: Colors.blue,
                onTap: () {
                  // 处理趋势分析
                  Navigator.pushNamed(context, '/diagnostics/analysis');
                },
              ),
              const SizedBox(height: 12),
              _buildAnalysisCard(
                context,
                icon: Icons.warning,
                title: "异常检测",
                subtitle: "检测数据异常",
                iconColor: Colors.orange,
                onTap: () {
                  // 处理异常检测
                },
              ),
              const SizedBox(height: 12),
              _buildAnalysisCard(
                context,
                icon: Icons.picture_as_pdf,
                title: "报告生成",
                subtitle: "生成数据分析报告",
                iconColor: Colors.red,
                onTap: () {
                  // 处理报告生成
                },
              ),
              const SizedBox(height: 12),
              _buildAnalysisCard(
                context,
                icon: Icons.bar_chart,
                title: "数据可视化",
                subtitle: "以图表形式展示数据",
                iconColor: Colors.green,
                onTap: () {
                  // 处理数据可视化
                },
              ),
              const SizedBox(height: 12),
              _buildAnalysisCard(
                context,
                icon: Icons.file_download,
                title: "导出分析结果",
                subtitle: "将结果导出为文件",
                iconColor: Colors.purple,
                onTap: () {
                  // 处理导出分析结果
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
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
                        color: Colors.grey.shade800,
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
              Icon(Icons.chevron_right, color: Colors.grey.shade600, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}
