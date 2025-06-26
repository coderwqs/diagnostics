import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DataPoint {
  final double value;
  final double frequency;

  DataPoint({required this.value, required this.frequency});
}

class SpectrumChart extends StatefulWidget {
  final List<double> spectrum;
  final ColorScheme colorScheme;
  final bool isShowDot;

  const SpectrumChart({
    super.key,
    required this.spectrum,
    required this.colorScheme,
    required this.isShowDot,
  });

  @override
  createState() => _SpectrumChartState();
}

class _SpectrumChartState extends State<SpectrumChart> {
  List<DataPoint> _spectrum = [];
  final double _minY = 0;
  double _maxY = 10;

  @override
  void initState() {
    super.initState();

    if (widget.spectrum.isNotEmpty) {
      _maxY = widget.spectrum.reduce((a, b) => a > b ? a : b);

      _spectrum = List.generate(widget.spectrum.length, (i) {
        return DataPoint(value: widget.spectrum[i], frequency: (i + 1) * 5.0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _spectrum.isNotEmpty
        ? LineChart(
            LineChartData(
              lineTouchData: LineTouchData(
                enabled: true,
                getTouchLineStart: (LineChartBarData barData, int spotIndex) =>
                    0,
                getTouchLineEnd: (LineChartBarData barData, int spotIndex) =>
                    _maxY,
                getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                  return spotIndexes.map((spotIndex) {
                    final FlSpot spot = barData.spots[spotIndex];
                    return TouchedSpotIndicatorData(
                      FlLine(
                          color: Colors.red,
                          strokeWidth: 1,
                          dashArray: [4, 2]
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
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (List<LineBarSpot> touchedSpots) {
                    return touchedSpots.map((spot) {
                      final data = _spectrum[spot.x.toInt()];
                      return LineTooltipItem(
                        '${data.frequency.toStringAsFixed(1)}Hz\n幅值: ${spot.y.toStringAsFixed(2)}',
                        TextStyle(
                          color: widget.colorScheme.onPrimary,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.left,
                      );
                    }).toList();
                  },
                  getTooltipColor: (LineBarSpot touchedSpot) => Colors.grey,
                  tooltipBorderRadius: BorderRadius.circular(8),
                  tooltipPadding: const EdgeInsets.all(8),
                  tooltipMargin: 8,
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: widget.colorScheme.surfaceVariant.withValues(
                    alpha: 0.8,
                  ),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 10,
                          color: widget.colorScheme.onSurface.withValues(
                            alpha: 0.8,
                          ),
                        ),
                      );
                    },
                    reservedSize: 40,
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value % 5 == 0 && value.toInt() < _spectrum.length) {
                        return Text(
                          _spectrum[value.toInt()].frequency.toStringAsFixed(0),
                          style: TextStyle(
                            fontSize: 10,
                            color: widget.colorScheme.onSurface.withValues(
                              alpha: 0.8,
                            ),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                    reservedSize: 20,
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
                  color: widget.colorScheme.surfaceVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: _spectrum.asMap().entries.map((entry) {
                    return FlSpot(entry.key.toDouble(), entry.value.value);
                  }).toList(),
                  isCurved: false,
                  color: Colors.green,
                  barWidth: 1,
                  dotData: FlDotData(
                    show: widget.isShowDot,
                    getDotPainter: (spot, percent, barData, index) {
                      final color = spot.y > 8
                          ? widget.colorScheme.error
                          : spot.y > 5
                          ? widget.colorScheme.primary
                          : widget.colorScheme.tertiary;
                      return FlDotCirclePainter(
                        radius: 3,
                        color: color,
                        strokeWidth: 1,
                        strokeColor: widget.colorScheme.background,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
              minX: 0,
              maxX: _spectrum.length.toDouble() - 1,
              minY: _minY,
              maxY: _maxY,
            ),
          )
        : Center(
            child: Text(
              '无频谱数据',
              style: TextStyle(
                color: widget.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          );
  }
}
