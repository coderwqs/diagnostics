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

  @override
  void initState() {
    super.initState();

    if (widget.spectrum.isNotEmpty) {
      _spectrum = List.generate(widget.spectrum.length, (i) {
        return DataPoint(
          value: widget.spectrum[i],
          frequency: (i + 1) * 5.0, // 假设频率以 5.0 为增量
        );
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
                  getTooltipColor: (LineBarSpot touchedSpot) =>
                      widget.colorScheme.primary.withValues(alpha: 0.9),
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
                    alpha: 0.3,
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
                            alpha: 0.6,
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
                          '${_spectrum[value.toInt()].frequency.toStringAsFixed(0)}Hz',
                          style: TextStyle(
                            fontSize: 10,
                            color: widget.colorScheme.onSurface.withValues(
                              alpha: 0.6,
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
                  color: widget.colorScheme.primary,
                  barWidth: 2,
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
              minY: 0,
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
