import 'dart:math';

import 'package:diagnosis/model/device.dart';
import 'package:diagnosis/model/history.dart';
import 'package:diagnosis/service/devices.dart';
import 'package:diagnosis/service/history.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class DataAnalysisPage extends StatefulWidget {
  const DataAnalysisPage({super.key});

  @override
  createState() => _DataAnalysisPageState();
}

class _DataAnalysisPageState extends State<DataAnalysisPage> {
  final HistoryService _historyService = HistoryService();
  final DeviceService _deviceService = DeviceService();

  Device? selectedDevice;
  List<Device> _devices = [];
  List<DeviceData> _deviceHistoryData = [];
  List<DataPoint> currentWaveformData = [];
  List<DataPoint> currentSpectrumData = [];
  DeviceData? _selectedHistoryData;

  late ScrollController _scrollController;
  bool _isLoading = false;
  int _currentPage = 0;
  final int _itemsPerPage = 5;

  late ScrollController _historyScrollController;
  bool _isHistoryLoading = false;
  int _historyCurrentPage = 0;
  final int _historyItemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);

    _historyScrollController = ScrollController();
    _historyScrollController.addListener(_historyScrollListener);

    _loadMoreDevices();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _historyScrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && !_isLoading) {
      _loadMoreDevices();
    }
  }

  void _historyScrollListener() {
    if (_historyScrollController.position.pixels ==
        _historyScrollController.position.maxScrollExtent &&
        !_isHistoryLoading) {
      _loadMoreHistoryData(selectedDevice!);
    }
  }

  Future<void> _loadMoreDevices() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final devices = await _deviceService.getAllDevices(_currentPage + 1, _itemsPerPage);

    setState(() {
      _devices.addAll(devices);
      _currentPage++;
      _isLoading = false;

      if (_currentPage == 1 && _devices.isNotEmpty && selectedDevice == null) {
        selectedDevice = _devices.first;
        _loadMoreHistoryData(_devices.first);
      }
    });
  }

  Future<void> _refreshDevices() async {
    setState(() {
      _isLoading = true;
    });

    final d = await _deviceService.getAllDevices(0, _itemsPerPage);

    setState(() {
      _devices = d;
      _currentPage = 0;
      _isLoading = false;
    });
  }

  Future<List<ExtendedHistory>> fetchHistoryData({
    int page = 1,
    int limit = 10,
  }) async {
    return _historyService.getAllHistories(page, limit);
  }

  Future<void> _loadMoreHistoryData(Device device) async {
    if (_isHistoryLoading || selectedDevice == null) return;

    setState(() {
      _isHistoryLoading = true;
    });

    // 模拟API调用延迟
    await Future.delayed(const Duration(seconds: 1));

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
      _deviceHistoryData.addAll(mockHistory);
      _historyCurrentPage++;
      _isHistoryLoading = false;

      if (_historyCurrentPage == 1 && _selectedHistoryData == null) {
        _selectedHistoryData = _deviceHistoryData.first;
        _fetchDataDetails(mockHistory.last, shouldRebuildHistory: false);
      }
    });
  }

  Future<void> _refreshHistoryData() async {
    setState(() {
      _isHistoryLoading = true;
    });

    // 模拟刷新延迟
    await Future.delayed(const Duration(seconds: 1));

    final random = RandomDataGenerator(selectedDevice.hashCode);
    final now = DateTime.now();
    
    // 这里替换为你的实际刷新逻辑
    List<DeviceData> mockHistory = List.generate(20, (i) {
      final recordTime = now.subtract(Duration(minutes: 20 - i));
      return DeviceData(
        timestamp: recordTime,
        rmsValue: 2.0 + random.nextDouble() * 6.0,
      );
    });

    setState(() {
      _deviceHistoryData = mockHistory;
      _historyCurrentPage = 0;
      _isHistoryLoading = false;
    });
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
        _isLoading = true;
        currentWaveformData = [];
        currentSpectrumData = [];
      });
    }

    await Future.delayed(const Duration(milliseconds: 300));

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
      _selectedHistoryData = record;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('设备数据分析'), elevation: 0),
      body: Container(
        color: colorScheme.surfaceVariant.withOpacity(0.1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildLeftPanel(colorScheme, textTheme),
            Expanded(child: _buildRightPanel(colorScheme, textTheme)),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftPanel(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _buildDeviceListSection(colorScheme, textTheme),
          const SizedBox(height: 8),
          Expanded(child: _buildDataHistorySection(colorScheme, textTheme)),
        ],
      ),
    );
  }

  Widget _buildDeviceListSection(ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(Icons.device_hub, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  '设备列表',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          SizedBox(
            height: 220,
            child: RefreshIndicator(
              onRefresh: _refreshDevices,
              child: ListView.separated(
                controller: _scrollController,
                padding: EdgeInsets.zero,
                itemCount: _devices.length + (_isLoading ? 1 : 0),
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  if (index >= _devices.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final device = _devices[index];
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          selectedDevice = device;
                        });
                        _loadMoreHistoryData(selectedDevice!);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: device == selectedDevice
                              ? colorScheme.primary.withOpacity(0.08)
                              : Colors.transparent,
                          border: Border(
                            left: BorderSide(
                              color: device == selectedDevice
                                  ? colorScheme.primary
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
                                  ? colorScheme.primary
                                  : colorScheme.onSurface.withOpacity(0.6),
                              size: 22,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                device.name,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: device == selectedDevice
                                      ? colorScheme.onSurface
                                      : colorScheme.onSurface.withOpacity(0.8),
                                ),
                              ),
                            ),
                            if (device == selectedDevice)
                              Icon(
                                Icons.check_circle,
                                color: colorScheme.primary,
                                size: 18,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataHistorySection(ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(Icons.history, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  '数据记录',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.2),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(0),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    '时间',
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'RMS值',
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshHistoryData,
              child: _deviceHistoryData.isEmpty && !_isHistoryLoading
                  ? Center(
                child: Text(
                  '暂无数据',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              )
                  : ListView.separated(
                controller: _historyScrollController,
                padding: EdgeInsets.zero,
                itemCount: _deviceHistoryData.length + (_isHistoryLoading ? 1 : 0),
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  if (index >= _deviceHistoryData.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: colorScheme.primary,
                        ),
                      ),
                    );
                  }

                  final record = _deviceHistoryData[index];
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _fetchDataDetails(record),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedHistoryData == record
                              ? colorScheme.primary.withOpacity(0.08)
                              : Colors.transparent,
                          border: Border(
                            left: BorderSide(
                              color: _selectedHistoryData == record
                                  ? colorScheme.primary
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
                                DateFormat('HH:mm:ss').format(record.timestamp),
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.8),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                record.rmsValue.toStringAsFixed(2),
                                textAlign: TextAlign.right,
                                style: textTheme.bodyMedium?.copyWith(
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
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel(ColorScheme colorScheme, TextTheme textTheme) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDeviceInfoCard(colorScheme, textTheme),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: 280,
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: _buildChartCard(
                colorScheme: colorScheme,
                textTheme: textTheme,
                title: '时域波形',
                icon: Icons.show_chart,
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: colorScheme.primary,
                        ),
                      )
                    : currentWaveformData.isEmpty
                    ? Center(
                        child: Text(
                          '无波形数据',
                          style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      )
                    : _buildWaveformChart(colorScheme),
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: 280,
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: _buildChartCard(
                colorScheme: colorScheme,
                textTheme: textTheme,
                title: '频域频谱',
                icon: Icons.bar_chart,
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: colorScheme.primary,
                        ),
                      )
                    : currentSpectrumData.isEmpty
                    ? Center(
                        child: Text(
                          '无频谱数据',
                          style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      )
                    : _buildSpectrumChart(colorScheme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard({
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfoCard(ColorScheme colorScheme, TextTheme textTheme) {
    if (selectedDevice == null || _selectedHistoryData == null) {
      return const SizedBox();
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.analytics,
                size: 28,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedDevice!.name,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '最新记录: ${DateFormat('yyyy-MM-dd HH:mm').format(_selectedHistoryData!.timestamp)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _selectedHistoryData!.rmsValue.toStringAsFixed(2),
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getValueColor(_selectedHistoryData!.rmsValue),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_selectedHistoryData!.rmsValue),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _getStatusLabel(_selectedHistoryData!.rmsValue),
                    style: textTheme.labelSmall?.copyWith(
                      color: _getStatusTextColor(_selectedHistoryData!.rmsValue),
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

  Widget _buildWaveformChart(ColorScheme colorScheme) {
    final gradientColors = [colorScheme.primary, colorScheme.tertiary];

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
                  TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
            tooltipBorderRadius: BorderRadius.circular(8),
            tooltipPadding: const EdgeInsets.all(12),
            tooltipMargin: 8,
            getTooltipColor: (LineBarSpot touchedSpot) =>
                colorScheme.primary.withOpacity(0.9),
            fitInsideHorizontally: true,
            fitInsideVertically: true,
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _calculateGridInterval(),
          getDrawingHorizontalLine: (value) => FlLine(
            color: colorScheme.outline.withOpacity(0.2),
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: _calculateGridInterval(),
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    value.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurface.withOpacity(0.6),
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
              interval: (currentWaveformData.length / 5).roundToDouble(),
              getTitlesWidget: (value, meta) {
                if (value.toInt() < currentWaveformData.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat(
                        'ss.S',
                      ).format(currentWaveformData[value.toInt()].timestamp!),
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
              reservedSize: 28,
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.3),
            width: 1,
          ),
        ),
        minX: 0,
        maxX: currentWaveformData.length.toDouble() - 1,
        minY: 0,
        maxY:
            currentWaveformData
                .map((e) => e.value)
                .reduce((a, b) => a > b ? a : b) *
            1.3,
        lineBarsData: [
          LineChartBarData(
            spots: currentWaveformData.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.value);
            }).toList(),
            isCurved: true,
            curveSmoothness: 0.3,
            color: colorScheme.primary,
            barWidth: 3,
            shadow: BoxShadow(
              color: colorScheme.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.primary.withOpacity(0.3),
                  colorScheme.primary.withOpacity(0.05),
                ],
                stops: const [0.1, 1.0],
              ),
            ),
            aboveBarData: BarAreaData(
              show: true,
              color: colorScheme.primary.withOpacity(0.02),
            ),
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: colorScheme.primary,
                  strokeWidth: 2,
                  strokeColor: colorScheme.surface,
                );
              },
              checkToShowDot: (spot, barData) {
                final x = spot.x;
                final index = x.round();
                return index % 10 == 0;
              },
            ),
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateGridInterval() {
    final maxValue =
        currentWaveformData
            .map((e) => e.value)
            .reduce((a, b) => a > b ? a : b) *
        1.3;
    return (maxValue / 4).roundToDouble();
  }

  Widget _buildSpectrumChart(ColorScheme colorScheme) {
    return BarChart(
      BarChartData(
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final data = currentSpectrumData[group.x.toInt()];
              return BarTooltipItem(
                '${data.frequency!.toStringAsFixed(1)}Hz\n幅值: ${rod.toY.toStringAsFixed(2)}',
                TextStyle(color: colorScheme.onPrimary, fontSize: 12),
                textAlign: TextAlign.left,
              );
            },
            tooltipMargin: 8,
            tooltipPadding: const EdgeInsets.all(8),
            tooltipBorderRadius: BorderRadius.all(Radius.circular(8.0)),
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            direction: TooltipDirection.top,
            getTooltipColor: (BarChartGroupData group) => colorScheme.primary,
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: colorScheme.surfaceVariant.withOpacity(0.3),
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
                    color: colorScheme.onSurface.withOpacity(0.6),
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
                if (value % 5 == 0 &&
                    value.toInt() < currentSpectrumData.length) {
                  return Text(
                    '${currentSpectrumData[value.toInt()].frequency!.toStringAsFixed(0)}Hz',
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  );
                }
                return const SizedBox();
              },
              reservedSize: 20,
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: colorScheme.surfaceVariant.withOpacity(0.5),
          ),
        ),
        groupsSpace: 4,
        barGroups: currentSpectrumData.asMap().entries.map((entry) {
          final color = entry.value.value > 8
              ? colorScheme.error
              : entry.value.value > 5
              ? colorScheme.primary
              : colorScheme.tertiary;

          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                fromY: 0,
                toY: entry.value.value,
                color: color,
                width: 16,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
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
    if (value > 8) return Colors.red.withOpacity(0.2);
    if (value > 5) return Colors.orange.withOpacity(0.2);
    return Colors.green.withOpacity(0.2);
  }

  Color _getStatusTextColor(double value) {
    if (value > 8) return Colors.red;
    if (value > 5) return Colors.orange;
    return Colors.green;
  }

  Color _getValueColor(double value) {
    if (value > 8) return Colors.red;
    if (value > 5) return Colors.orange;
    return Colors.green;
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
