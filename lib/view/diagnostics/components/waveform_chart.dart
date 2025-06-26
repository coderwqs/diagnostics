import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DataPoint {
  final DateTime? timestamp;
  final double value;

  DataPoint({this.timestamp, required this.value});
}

class WaveformChart extends StatefulWidget {
  final int dataTime;
  final List<double> waveform;
  final bool isShowDot;
  final ColorScheme colorScheme;

  const WaveformChart({
    super.key,
    required this.dataTime,
    required this.waveform,
    required this.colorScheme,
    required this.isShowDot,
  });

  @override
  State<StatefulWidget> createState() => _WaveformChartState();
}

class _WaveformChartState extends State<WaveformChart> {
  List<DataPoint> _waveform = [];
  double _maxY = 10;
  double _minY = 0;
  double _interval = 0.1;

  late final List<Color> gradientColors;

  @override
  void initState() {
    super.initState();

    gradientColors = [widget.colorScheme.primary, widget.colorScheme.tertiary];

    DateTime ts = DateTime.fromMillisecondsSinceEpoch(widget.dataTime);

    if (widget.waveform.isNotEmpty) {
      _maxY = widget.waveform.reduce((a, b) => a > b ? a : b);

      _minY = widget.waveform.reduce((a, b) => a < b ? a : b);

      _interval = double.parse(((_maxY - _minY) / 8).toStringAsFixed(1));

      _waveform = List.generate(widget.waveform.length, (i) {
        return DataPoint(
          timestamp: ts.subtract(
            Duration(milliseconds: widget.waveform.length - i),
          ),
          value: widget.waveform[i],
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _waveform.isNotEmpty
        ? LineChart(
            LineChartData(
              lineTouchData: LineTouchData(
                enabled: true,
                getTouchLineStart: (LineChartBarData barData, int spotIndex) =>
                _minY,
                getTouchLineEnd: (LineChartBarData barData, int spotIndex) =>
                _maxY,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (List<LineBarSpot> touchedSpots) {
                    return touchedSpots.map((spot) {
                      final d = _waveform[spot.x.toInt()];
                      return LineTooltipItem(
                        '${DateFormat('HH:mm:ss.S').format(d.timestamp!)}\n幅值: ${spot.y.toStringAsFixed(2)}',
                        TextStyle(
                          color: widget.colorScheme.onPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList();
                  },
                  tooltipBorderRadius: BorderRadius.circular(8),
                  tooltipPadding: const EdgeInsets.all(12),
                  tooltipMargin: 8,
                  getTooltipColor: (LineBarSpot touchedSpot) => Colors.grey,
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                ),
                getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                  return spotIndexes.map((spotIndex) {
                    final FlSpot spot = barData.spots[spotIndex];
                    // 自定义指示器样式
                    return TouchedSpotIndicatorData(
                      FlLine(
                        color: Colors.red,
                        strokeWidth: 1,
                        dashArray: [3, 2]
                      ),
                      FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 3,
                            color: Colors.red,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                    );
                  }).toList();
                },
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: _interval,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: widget.colorScheme.outline.withValues(alpha: 0.2),
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: _interval,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          value.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 10,
                            color: widget.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      );
                    },
                    reservedSize: 42,
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: (_waveform.length / 5).roundToDouble(),
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() < _waveform.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat(
                              'ss.S',
                            ).format(_waveform[value.toInt()].timestamp!),
                            style: TextStyle(
                              fontSize: 10,
                              color: widget.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                    reservedSize: 28,
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(
                  color: widget.colorScheme.outline.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              minX: 0,
              maxX: _waveform.length.toDouble() - 1,
              minY: _minY,
              maxY: _maxY,
              lineBarsData: [
                LineChartBarData(
                  spots: _waveform.asMap().entries.map((entry) {
                    return FlSpot(entry.key.toDouble(), entry.value.value);
                  }).toList(),
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: Colors.green,
                  barWidth: 1,
                  shadow: BoxShadow(
                    color: widget.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                  belowBarData: BarAreaData(
                    show: false,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        widget.colorScheme.primary.withValues(alpha: 0.3),
                        widget.colorScheme.primary.withValues(alpha: 0.05),
                      ],
                      stops: const [0.1, 1.0],
                    ),
                  ),
                  aboveBarData: BarAreaData(
                    show: true,
                    color: widget.colorScheme.primary.withValues(alpha: 0.02),
                  ),
                  dotData: FlDotData(
                    show: widget.isShowDot,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 3,
                        color: widget.colorScheme.primary,
                        strokeWidth: 2,
                        strokeColor: widget.colorScheme.surface,
                      );
                    },
                    checkToShowDot: (spot, barData) {
                      final x = spot.x;
                      final index = x.round();
                      return index % 10 == 0;
                    },
                  ),
                  // gradient: LinearGradient(
                  //   colors: gradientColors,
                  //   begin: Alignment.centerLeft,
                  //   end: Alignment.centerRight,
                  // ),
                ),
              ],
            ),
          )
        : Center(
            child: Text(
              '无波形数据',
              style: TextStyle(
                color: widget.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          );
  }
}
