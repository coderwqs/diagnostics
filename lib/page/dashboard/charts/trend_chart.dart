import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class WeeklyLineChart extends StatelessWidget {
  final List<double> weeklyData;
  final double height;
  final double maxY;
  final Color primaryColor;

  const WeeklyLineChart({
    super.key,
    required this.weeklyData,
    this.height = 200,
    this.maxY = 30,
    this.primaryColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          gridData: _buildGridData(),
          titlesData: _buildTitlesData(),
          borderData: FlBorderData(
            show: true,
            border: Border(
              left: BorderSide(color: Colors.grey, width: 1),
              bottom: BorderSide(color: Colors.grey, width: 1),
              // 不设置 top 和 right 就不会显示
            ),
          ),
          minX: 0,
          maxX: 6, // 数据为最近7天
          minY: 0,
          maxY: _calculateMaxY(),
          lineBarsData: _buildLineBarsData(),
        ),
      ),
    );
  }

  double _calculateMaxY() {
    final maxDataValue = weeklyData.reduce((a, b) => a > b ? a : b);
    return maxDataValue > maxY ? maxDataValue * 1.2 : maxY;
  }

  FlTitlesData _buildTitlesData() {
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 28,
          getTitlesWidget: (value, meta) {
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _getDayName(value.toInt()),
                style: const TextStyle(fontSize: 12),
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 32,
          interval: _calculateInterval(),
          getTitlesWidget: (value, meta) {
            return Text(
              value.toInt().toString(),
              style: const TextStyle(fontSize: 12),
            );
          },
        ),
      ),
      rightTitles: AxisTitles(), // 隐藏右侧标题
      topTitles: AxisTitles(), // 隐藏上方标题
    );
  }

  double _calculateInterval() {
    final maxValue = _calculateMaxY();
    if (maxValue <= 10) return 2;
    if (maxValue <= 20) return 5;
    return 10;
  }

  FlGridData _buildGridData() {
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: _calculateInterval(),
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: Colors.grey.withOpacity(0.3),
          strokeWidth: 1,
        );
      },
    );
  }

  List<LineChartBarData> _buildLineBarsData() {
    return [
      LineChartBarData(
        spots: weeklyData.asMap().entries.map((entry) {
          final index = entry.key.toDouble();
          final value = entry.value;
          return FlSpot(index, value);
        }).toList(),
        isCurved: true,
        color: primaryColor,
        dotData: FlDotData(show: true),
        belowBarData: BarAreaData(show: false),
      ),
    ];
  }

  String _getDayName(int index) {
    const days = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return days[index % days.length];
  }
}