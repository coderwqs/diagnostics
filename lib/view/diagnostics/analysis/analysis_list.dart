import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class DataAnalysisPage extends StatefulWidget {
  const DataAnalysisPage({super.key});

  @override
  _DataAnalysisPageState createState() => _DataAnalysisPageState();
}

class _DataAnalysisPageState extends State<DataAnalysisPage> {
  String? selectedDevice;
  List<String> devices = ['振动传感器#001', '温度传感器#002', '压力传感器#003', '电流传感器#004'];
  List<DeviceData> deviceDataHistory = [];
  List<DataPoint> currentWaveformData = [];
  List<DataPoint> currentSpectrumData = [];
  bool isLoading = false;
  DeviceData? selectedDataRecord;

  @override
  void initState() {
    super.initState();
    if (devices.isNotEmpty) {
      selectedDevice = devices.first;
      _fetchDeviceHistory(devices.first);
    }
  }

  Future<void> _fetchDeviceHistory(String device) async {
    setState(() {
      isLoading = true;
      deviceDataHistory = [];
    });

    await Future.delayed(Duration(milliseconds: 500));

    final random = RandomDataGenerator(device.hashCode);
    final now = DateTime.now();

    List<DeviceData> mockHistory = List.generate(20, (i) {
      final recordTime = now.subtract(Duration(minutes: 20 - i));
      return DeviceData(
        timestamp: recordTime,
        rmsValue: 2.0 + random.nextDouble() * 6.0,
      );
    });

    setState(() {
      deviceDataHistory = mockHistory;
      selectedDataRecord = mockHistory.last;
      isLoading = false;
    });

    _fetchDataDetails(mockHistory.last, shouldRebuildHistory: false);
  }

  Future<void> _fetchDataDetails(
    DeviceData record, {
    bool shouldRebuildHistory = true,
  }) async {
    if (!shouldRebuildHistory) {
      setState(() {
        currentWaveformData = [];
        currentSpectrumData = [];
      });
    } else {
      setState(() {
        isLoading = true;
        currentWaveformData = [];
        currentSpectrumData = [];
      });
    }

    await Future.delayed(Duration(milliseconds: 300));

    final random = RandomDataGenerator(selectedDevice.hashCode);
    final now = record.timestamp;

    currentWaveformData = List.generate(100, (i) {
      return DataPoint(
        timestamp: now.subtract(Duration(milliseconds: 100 - i)),
        value: random.nextWaveformValue(),
        frequency: null,
      );
    });

    currentSpectrumData = List.generate(20, (i) {
      return DataPoint(
        timestamp: null,
        value: random.nextSpectrumValue((i + 1).toDouble()),
        frequency: (i + 1) * 5.0,
      );
    });

    setState(() {
      selectedDataRecord = record;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        color: Colors.grey[50],
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLeftPanel(),
            Expanded(child: _buildRightPanel()),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(2, 0)),
        ],
      ),
      child: Column(
        children: [
          _buildDeviceListSection(),
          Expanded(child: _buildDataHistorySection()),
        ],
      ),
    );
  }

  Widget _buildDeviceListSection() {
    return Card(
      margin: EdgeInsets.all(12),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(Icons.device_hub, color: Colors.blueGrey),
                SizedBox(width: 8),
                Text(
                  '设备列表',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1),
          Container(
            height: 220,
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        selectedDevice = device;
                      });
                      _fetchDeviceHistory(device);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: device == selectedDevice
                            ? Colors.blueGrey[50]
                            : Colors.transparent,
                        border: Border(
                          left: BorderSide(
                            color: device == selectedDevice
                                ? Theme.of(context).primaryColor
                                : Colors.transparent,
                            width: 4,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.sensors,
                            color: device == selectedDevice
                                ? Theme.of(context).primaryColor
                                : Colors.grey[600],
                          ),
                          SizedBox(width: 12),
                          Text(
                            device,
                            style: TextStyle(
                              fontSize: 15,
                              color: device == selectedDevice
                                  ? Colors.blueGrey[800]
                                  : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataHistorySection() {
    return Card(
      margin: EdgeInsets.all(12),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(Icons.history, color: Colors.blueGrey),
                SizedBox(width: 8),
                Text(
                  '数据记录',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.blueGrey[50],
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    '时间',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'RMS值',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: deviceDataHistory.length,
                    itemBuilder: (context, index) {
                      final record = deviceDataHistory[index];
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            _fetchDataDetails(record);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: selectedDataRecord == record
                                  ? Colors.blue[50]
                                  : Colors.transparent,
                              border: Border(
                                left: BorderSide(
                                  color: selectedDataRecord == record
                                      ? Colors.blue
                                      : Colors.transparent,
                                  width: 4,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    DateFormat(
                                      'HH:mm:ss',
                                    ).format(record.timestamp),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.blueGrey[800],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    record.rmsValue.toStringAsFixed(2),
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _getValueColor(record.rmsValue),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDeviceInfoCard(),
            SizedBox(height: 16),
            _buildChartCard(
              title: '时域波形',
              icon: Icons.show_chart,
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : currentWaveformData.isEmpty
                  ? Center(
                      child: Text(
                        '无波形数据',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : _buildWaveformChart(),
            ),
            SizedBox(height: 16),
            _buildChartCard(
              title: '频域频谱',
              icon: Icons.bar_chart,
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : currentSpectrumData.isEmpty
                  ? Center(
                      child: Text(
                        '无频谱数据',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : _buildSpectrumChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blueGrey),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: 280,
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfoCard() {
    if (selectedDevice == null || selectedDataRecord == null) {
      return SizedBox();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blueGrey[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.analytics,
                size: 30,
                color: Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedDevice!,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '最新记录: ${DateFormat('yyyy-MM-dd HH:mm').format(selectedDataRecord!.timestamp)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${selectedDataRecord!.rmsValue.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _getValueColor(selectedDataRecord!.rmsValue),
                  ),
                ),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(selectedDataRecord!.rmsValue),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusLabel(selectedDataRecord!.rmsValue),
                    style: TextStyle(
                      color: _getStatusTextColor(selectedDataRecord!.rmsValue),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveformChart() {
    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                final data = currentWaveformData[spot.x.toInt()];
                return LineTooltipItem(
                  '${DateFormat('HH:mm:ss.S').format(data.timestamp!)}\n幅值: ${spot.y.toStringAsFixed(2)}',
                  TextStyle(color: Colors.white),
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey[200]!, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(fontSize: 10),
                );
              },
              reservedSize: 40,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value % 20 == 0 &&
                    value.toInt() < currentWaveformData.length) {
                  return Text(
                    DateFormat(
                      'ss.S',
                    ).format(currentWaveformData[value.toInt()].timestamp!),
                    style: TextStyle(fontSize: 10),
                  );
                }
                return SizedBox();
              },
              reservedSize: 20,
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[300]!),
        ),
        minX: 0,
        maxX: currentWaveformData.length.toDouble() - 1,
        minY: 0,
        maxY:
            currentWaveformData
                .map((e) => e.value)
                .reduce((a, b) => a > b ? a : b) *
            1.2,
        lineBarsData: [
          LineChartBarData(
            spots: currentWaveformData.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.value);
            }).toList(),
            isCurved: true,
            color: Colors.blueAccent,
            barWidth: 2,
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Colors.blueAccent.withOpacity(0.3),
                  Colors.blueAccent.withOpacity(0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            dotData: FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildSpectrumChart() {
    return BarChart(
      BarChartData(
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final data = currentSpectrumData[group.x.toInt()];
              return BarTooltipItem(
                '${data.frequency!.toStringAsFixed(1)}Hz\n幅值: ${rod.toY.toStringAsFixed(2)}',
                TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey[200]!, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(fontSize: 10),
                );
              },
              reservedSize: 40,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value % 5 == 0 &&
                    value.toInt() < currentSpectrumData.length) {
                  return Text(
                    '${currentSpectrumData[value.toInt()].frequency!.toStringAsFixed(0)}Hz',
                    style: TextStyle(fontSize: 10),
                  );
                }
                return SizedBox();
              },
              reservedSize: 20,
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[300]!),
        ),
        groupsSpace: 4,
        barGroups: currentSpectrumData.asMap().entries.map((entry) {
          final color = entry.value.value > 8
              ? Colors.red[400]!
              : entry.value.value > 5
              ? Colors.orange[400]!
              : Colors.green[400]!;

          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                fromY: 0,
                toY: entry.value.value,
                color: color,
                width: 12,
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _getStatusLabel(double value) {
    if (value > 8) return '危险';
    if (value > 5) return '警告';
    return '正常';
  }

  Color _getStatusColor(double value) {
    if (value > 8) return Colors.red[100]!;
    if (value > 5) return Colors.orange[100]!;
    return Colors.green[100]!;
  }

  Color _getStatusTextColor(double value) {
    if (value > 8) return Colors.red[800]!;
    if (value > 5) return Colors.orange[800]!;
    return Colors.green[800]!;
  }

  Color _getValueColor(double value) {
    if (value > 8) return Colors.red[800]!;
    if (value > 5) return Colors.orange[800]!;
    return Colors.green[800]!;
  }
}

class DeviceData {
  final DateTime timestamp;
  final double rmsValue;

  DeviceData({required this.timestamp, required this.rmsValue});
}

class DataPoint {
  final DateTime? timestamp;
  final double value;
  final double? frequency;

  DataPoint({this.timestamp, required this.value, this.frequency});
}

class RandomDataGenerator {
  int seed;

  RandomDataGenerator(this.seed);

  double nextDouble() {
    seed = (seed * 9301 + 49297) % 233280;
    return seed / 233280.0;
  }

  double nextWaveformValue() {
    return 2.0 + nextDouble() * 8.0 + sin(seed % 100 / 10.0);
  }

  double nextSpectrumValue(double frequency) {
    return (10.0 / frequency) * (0.8 + nextDouble() * 0.4);
  }
}
