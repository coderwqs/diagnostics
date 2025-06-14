import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:diagnosis/utils/color_extensions.dart';
import 'package:diagnosis/utils/app_utils.dart';

class TrendLineChart extends StatefulWidget {
  const TrendLineChart({super.key});

  @override
  State<TrendLineChart> createState() => _TrendLineChartState();
}

class _TrendLineChartState extends State<TrendLineChart> {
  List<(DateTime, double)>? _bitcoinPriceHistory;

  @override
  void initState() {
    _reloadData();
    super.initState();
  }

  void _reloadData() async {
    final dataStr = await rootBundle.loadString(
      'assets/data/btc_last_year_price.json',
    );
    if (!mounted) {
      return;
    }
    final json = jsonDecode(dataStr) as Map<String, dynamic>;
    setState(() {
      _bitcoinPriceHistory = (json['prices'] as List).map((item) {
        final timestamp = item[0] as int;
        final price = item[1] as double;
        return (DateTime.fromMillisecondsSinceEpoch(timestamp), price);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    const leftReservedSize = 36.0;
    return AspectRatio(
      aspectRatio: 1.4,
      child: Padding(
        padding: const EdgeInsets.only(top: 0.0, right: 1.0),
        child: LineChart(
          LineChartData(
            borderData: FlBorderData(
              show: true,
              border: Border(
                top: BorderSide.none,
                right: BorderSide.none,
                left: BorderSide(color: Colors.grey),
                bottom: BorderSide(color: Colors.grey),
              ),
            ),
            gridData: FlGridData(
              verticalInterval: 8,
              getDrawingVerticalLine: (double value) => const FlLine(
                color: Colors.grey,
                strokeWidth: 0.4,
                dashArray: [5, 2],
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots:
                    _bitcoinPriceHistory?.asMap().entries.map((e) {
                      final index = e.key;
                      final item = e.value;
                      final value = item.$2;
                      return FlSpot(index.toDouble(), value);
                    }).toList() ??
                    [],
                dotData: const FlDotData(show: false),
                color: Colors.blue,
                barWidth: 0.8,
                shadow: const Shadow(color: Colors.blue, blurRadius: 2),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.withValues(alpha: 0.2),
                      Colors.blue.withValues(alpha: 0.0),
                    ],
                    stops: const [0.5, 1.0],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              touchSpotThreshold: 5,
              getTouchLineStart: (_, __) => -double.infinity,
              getTouchLineEnd: (_, __) => double.infinity,
              getTouchedSpotIndicator:
                  (LineChartBarData barData, List<int> spotIndexes) {
                    return spotIndexes.map((spotIndex) {
                      return TouchedSpotIndicatorData(
                        const FlLine(
                          color: Colors.red,
                          strokeWidth: 1.5,
                          dashArray: [5, 2],
                        ),
                        FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: Colors.orange,
                              strokeWidth: 0,
                              strokeColor: Colors.orange,
                            );
                          },
                        ),
                      );
                    }).toList();
                  },
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                  return touchedBarSpots.map((barSpot) {
                    final price = barSpot.y;
                    final date = _bitcoinPriceHistory![barSpot.x.toInt()].$1;
                    return LineTooltipItem(
                      '',
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: '${date.year}/${date.month}/${date.day}',
                          style: TextStyle(
                            color: Colors.white.darken(20),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        TextSpan(
                          text:
                              '\n${AppUtils.getFormattedCurrency(context, price, noDecimals: true)}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    );
                  }).toList();
                },
                getTooltipColor: (LineBarSpot barSpot) => Colors.black,
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                drawBelowEverything: true,
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: leftReservedSize,
                  maxIncluded: false,
                  minIncluded: false,
                  getTitlesWidget: (double value, TitleMeta meta) =>
                      SideTitleWidget(
                        meta: meta,
                        child: Text(
                          meta.formattedValue,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 38,
                  maxIncluded: false,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    final date = _bitcoinPriceHistory![value.toInt()].$1;
                    return SideTitleWidget(
                      meta: meta,
                      child: Transform.rotate(
                        angle: -45 * 3.14 / 180,
                        child: Text(
                          '${date.month}/${date.day}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          duration: Duration.zero,
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
