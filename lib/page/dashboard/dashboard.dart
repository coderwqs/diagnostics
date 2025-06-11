import 'package:flutter/material.dart';
import 'charts/trend_chart.dart';
import 'package:diagnosis/l10n/app_localizations.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
            colors: [
              Colors.blue.shade50.withValues(alpha: 0.3),
              Colors.white.withValues(alpha: 0.9),
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeMessage(context, availableHeight, l10n),
              const SizedBox(height: 24),
              _buildSectionTitle(l10n.quickAccess),
              _buildQuickAccessGrid(context, availableHeight, l10n),
              const SizedBox(height: 24),
              _buildSectionTitle(l10n.todayStatistics),
              _buildDailyStats(availableHeight, l10n),
              const SizedBox(height: 24),
              _buildSectionTitle('${l10n.dataTrend}（${l10n.recentSevenDay}）'),
              _buildTrendChartArea(availableHeight),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeMessage(
    BuildContext context,
    double availableHeight,
    AppLocalizations l10n,
  ) {
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.3,
            ),
            children: [
              TextSpan(text: '${l10n.welcomeBack}，\n'),
              TextSpan(
                text: 'Super Coder',
                style: TextStyle(
                  color: Colors.blue,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: Colors.blueAccent,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
              ),
              TextSpan(text: '！'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.greetingWithDate(now.month, now.day),
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.blue.shade800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildQuickAccessGrid(
    BuildContext context,
    double availableHeight,
    AppLocalizations l10n,
  ) {
    return Container(
      height: availableHeight * 0.18,
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        crossAxisCount: 4,
        childAspectRatio: 3.0,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        padding: EdgeInsets.zero,
        children: [
          _buildFeatureButton(
            context,
            Icons.settings_outlined,
            l10n.deviceManagement,
            Colors.blueAccent,
            '/collection',
          ),
          _buildFeatureButton(
            context,
            Icons.analytics_outlined,
            l10n.dataAnalysis,
            Colors.green,
            '/analysis',
          ),
          _buildFeatureButton(
            context,
            Icons.notifications_outlined,
            l10n.alarmCenter,
            Colors.orange,
            '/alert',
          ),
          _buildFeatureButton(
            context,
            Icons.people_outline,
            l10n.userManagement,
            Colors.purple,
            '/settings',
          ),
        ],
      ),
    );
  }

  Widget _buildDailyStats(double availableHeight, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      height: availableHeight * 0.34,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    l10n.deviceTotal,
                    '86',
                    Icons.devices_other,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    l10n.onlineDevice,
                    '72',
                    Icons.check_circle_outlined,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildStatCard(
              l10n.todayAlarm,
              '3',
              Icons.warning_amber_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChartArea(double availableHeight) {
    return Container(
      height: availableHeight * 0.3,
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withValues(alpha: 0.3),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: TrendLineChart(),
        ),
      ),
    );
  }

  Widget _buildFeatureButton(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    String route,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.pushNamed(context, route),
            splashColor: color.withValues(alpha: 0.1),
            highlightColor: color.withValues(alpha: 0.05),
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 14, // 略小的字体
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                          height: 1.2, // 更好的行高
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        splashColor: Colors.blue.withValues(alpha: 0.1),
        highlightColor: Colors.blue.withValues(alpha: 0.05),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 18, color: Colors.blue),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.blue.shade300,
                    size: 20,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
