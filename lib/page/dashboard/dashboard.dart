import 'package:flutter/material.dart';
import 'charts/trend_chart.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = AppBar().preferredSize.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final availableHeight = screenHeight - appBarHeight - statusBarHeight - 32;

    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeMessage(availableHeight),
            _buildSectionTitle('快速访问'),
            _buildQuickAccessGrid(context, availableHeight),
            _buildSectionTitle('今日统计'),
            _buildDailyStats(availableHeight),
            _buildSectionTitle('数据趋势（最近7天）'),
            _buildTrendChartArea(availableHeight),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeMessage(double availableHeight) {
    return Container(
      height: availableHeight * 0.1,
      width: double.infinity,
      alignment: Alignment.centerLeft,
      margin: EdgeInsetsGeometry.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          children: const [
            TextSpan(text: '欢迎回来，'),
            TextSpan(
              text: 'Coder',
              style: TextStyle(color: Colors.blue),
            ),
            TextSpan(text: '！'),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildQuickAccessGrid(BuildContext context, double availableHeight) {
    return Container(
      margin: EdgeInsetsGeometry.only(top: 8, bottom: 8),
      height: availableHeight * 0.16,
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        crossAxisCount: 4,
        childAspectRatio: 3.4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        padding: EdgeInsets.zero,
        children: [
          _buildFeatureButton(
            context,
            Icons.settings,
            '设备管理',
            Colors.blue,
            '/collection',
          ),
          _buildFeatureButton(
            context,
            Icons.analytics,
            '数据分析',
            Colors.green,
            '/analysis',
          ),
          _buildFeatureButton(
            context,
            Icons.notifications,
            '告警中心',
            Colors.orange,
            '/alert',
          ),
          _buildFeatureButton(
            context,
            Icons.people,
            '用户管理',
            Colors.purple,
            '/settings',
          ),
        ],
      ),
    );
  }

  Widget _buildDailyStats(double availableHeight) {
    return Container(
      margin: EdgeInsetsGeometry.only(top: 8, bottom: 16),
      height: availableHeight * 0.34,
      child: Column(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 20,
              children: [
                Expanded(child: _buildStatCard('设备总数', '86', Icons.devices)),
                Expanded(
                  child: _buildStatCard('在线设备', '72', Icons.check_circle),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(child: _buildStatCard('今日告警', '3', Icons.warning)),
        ],
      ),
    );
  }

  Widget _buildTrendChartArea(double availableHeight) {
    return Container(
      height: availableHeight * 0.26,
      width: double.infinity,
      padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
      margin: const EdgeInsetsGeometry.only(top: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade50, Colors.white],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100,
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TrendLineChart(),
    );
  }

  Widget _buildFeatureButton(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    String route,
  ) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.white],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade100,
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        margin: const EdgeInsets.all(4),
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(context, route);
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade50, Colors.white],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100,
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 16, color: Colors.blue),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
                Text(
                  '查看详情 →',
                  style: const TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ],
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
