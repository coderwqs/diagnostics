import 'dart:math' as math;

import 'package:diagnosis/model/history.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class HistoryDataPage extends StatefulWidget {
  const HistoryDataPage({super.key});

  @override
  State<HistoryDataPage> createState() => _HistoryDataPageState();
}

class _HistoryDataPageState extends State<HistoryDataPage> {
  late Future<List<History>> _historyFuture;
  String _searchQuery = '';
  String _filterValue = 'all';

  @override
  void initState() {
    super.initState();
    _historyFuture = fetchHistoryData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('历史数据'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _historyFuture = fetchHistoryData();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchFilterBar(),
          Expanded(
            child: FutureBuilder<List<History>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingIndicator();
                } else if (snapshot.hasError) {
                  return _buildErrorWidget(snapshot.error.toString());
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                final filteredData = _filterData(snapshot.data!);

                return filteredData.isEmpty
                    ? _buildNoResultsWidget()
                    : ListView.builder(
                        itemCount: filteredData.length,
                        itemBuilder: (context, index) {
                          final item = filteredData[index];
                          return _buildHistoryCard(item, context);
                        },
                      );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: '搜索设备ID或状态...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
          SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('全部', 'all'),
                _buildFilterChip('正常', 'normal'),
                _buildFilterChip('过载', 'overload'),
                _buildFilterChip('最近7天', 'week'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: _filterValue == value,
        onSelected: (bool selected) {
          setState(() {
            _filterValue = selected ? value : 'all';
          });
        },
      ),
    );
  }

  Widget _buildHistoryCard(History item, BuildContext context) {
    final isOverload = item.rotationSpeed != null && item.rotationSpeed! > 1000;
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Card(
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DetailPage(history: item)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildStatusIndicator(isOverload),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '设备 ${item.deviceId}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          dateFormat.format(
                            DateTime.fromMillisecondsSinceEpoch(item.createdAt),
                          ),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  _buildDataPoint(
                    icon: Icons.speed,
                    label: '采样率',
                    value: '${item.samplingRate} Hz',
                  ),
                  SizedBox(width: 16),
                  _buildDataPoint(
                    icon: Icons.rotate_right,
                    label: '转速',
                    value: item.rotationSpeed != null
                        ? '${item.rotationSpeed} RPM'
                        : '无数据',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(bool isOverload) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isOverload
            ? Colors.red.withOpacity(0.2)
            : Colors.green.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isOverload ? Icons.warning : Icons.check_circle,
        color: isOverload ? Colors.red : Colors.green,
        size: 20,
      ),
    );
  }

  Widget _buildDataPoint({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey, fontSize: 12)),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('加载数据中...'),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 48),
          SizedBox(height: 16),
          Text('加载失败', style: TextStyle(fontSize: 18)),
          SizedBox(height: 8),
          Text(error, textAlign: TextAlign.center),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _historyFuture = fetchHistoryData();
              });
            },
            child: Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 48, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text('暂无历史数据', style: TextStyle(fontSize: 18)),
          SizedBox(height: 8),
          Text('您还没有任何历史记录', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildNoResultsWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text('未找到匹配结果', style: TextStyle(fontSize: 18)),
          SizedBox(height: 8),
          Text('请尝试其他搜索条件', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  List<History> _filterData(List<History> data) {
    var result = data.where((item) {
      final matchesSearch =
          item.deviceId.toLowerCase().contains(_searchQuery) ||
          (_searchQuery.contains('正常') &&
              !(item.rotationSpeed != null && item.rotationSpeed! > 1000)) ||
          (_searchQuery.contains('过载') &&
              (item.rotationSpeed != null && item.rotationSpeed! > 1000));

      final matchesFilter =
          _filterValue == 'all' ||
          (_filterValue == 'normal' &&
              !(item.rotationSpeed != null && item.rotationSpeed! > 1000)) ||
          (_filterValue == 'overload' &&
              (item.rotationSpeed != null && item.rotationSpeed! > 1000)) ||
          (_filterValue == 'week' &&
              item.createdAt >
                  DateTime.now()
                      .subtract(Duration(days: 7))
                      .millisecondsSinceEpoch);

      return matchesSearch && matchesFilter;
    }).toList();

    // 按时间倒序排列
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return result;
  }

  Future<List<History>> fetchHistoryData() async {
    await Future.delayed(Duration(seconds: 1)); // 模拟网络延迟
    return [
      History(
        id: 1,
        deviceId: 'A123',
        dataTime: 1625151600000,
        samplingRate: 10.0,
        rotationSpeed: 900,
        data: [1.0, 2.0, 3.0, 2.5, 1.8, 2.2, 3.1],
        createdAt: DateTime.now()
            .subtract(Duration(hours: 2))
            .millisecondsSinceEpoch,
      ),
      History(
        id: 2,
        deviceId: 'B456',
        dataTime: 1625155200000,
        samplingRate: 20.0,
        rotationSpeed: 1200,
        data: [2.0, 3.0, 4.0, 3.5, 2.8, 3.2, 4.1],
        createdAt: DateTime.now()
            .subtract(Duration(days: 1))
            .millisecondsSinceEpoch,
      ),
      History(
        id: 3,
        deviceId: 'C789',
        dataTime: 1625158800000,
        samplingRate: 15.0,
        rotationSpeed: null,
        data: [1.5, 2.5, 3.5, 2.8, 2.0, 2.7, 3.6],
        createdAt: DateTime.now()
            .subtract(Duration(days: 3))
            .millisecondsSinceEpoch,
      ),
      History(
        id: 4,
        deviceId: 'D012',
        dataTime: 1625162400000,
        samplingRate: 25.0,
        rotationSpeed: 800,
        data: [0.8, 1.8, 2.8, 2.0, 1.5, 2.0, 2.9],
        createdAt: DateTime.now()
            .subtract(Duration(days: 5))
            .millisecondsSinceEpoch,
      ),
    ];
  }
}

class DetailPage extends StatelessWidget {
  final History history;

  DetailPage({required this.history});

  @override
  Widget build(BuildContext context) {
    final isOverload =
        history.rotationSpeed != null && history.rotationSpeed! > 1000;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('数据详情', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.share, size: 24),
            tooltip: '分享数据',
            onPressed: () => _shareData(context),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download, size: 20),
                    SizedBox(width: 8),
                    Text('导出数据'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'analyze',
                child: Row(
                  children: [
                    Icon(Icons.analytics, size: 20),
                    SizedBox(width: 8),
                    Text('高级分析'),
                  ],
                ),
              ),
            ],
            onSelected: (value) => _handleMenuSelection(value, context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 设备概览卡片
            _buildDeviceOverviewCard(isOverload, colorScheme),
            SizedBox(height: 24),

            // 数据图表部分
            _buildChartSection(context, theme),
            SizedBox(height: 24),

            // 数据统计卡片
            _buildStatsCard(colorScheme),
            SizedBox(height: 24),

            // 原始数据表格
            _buildDataTableSection(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceOverviewCard(bool isOverload, ColorScheme colorScheme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusBadge(isOverload),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '设备 ${history.deviceId}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '最后记录: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.fromMillisecondsSinceEpoch(history.createdAt))}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Divider(height: 24, thickness: 1),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                _buildMetricTile(
                  icon: Icons.speed,
                  title: '采样率',
                  value: '${history.samplingRate} Hz',
                  color: colorScheme.primary,
                ),
                if (history.rotationSpeed != null)
                  _buildMetricTile(
                    icon: Icons.rotate_right,
                    title: '转速',
                    value: '${history.rotationSpeed} RPM',
                    color: isOverload ? Colors.red : Colors.green,
                  ),
                _buildMetricTile(
                  icon: Icons.show_chart,
                  title: '数据点数',
                  value: '${history.data.length}',
                  color: Colors.blueAccent,
                ),
                _buildMetricTile(
                  icon: Icons.timeline,
                  title: '数据范围',
                  value:
                      '${history.data.reduce((a, b) => a < b ? a : b).toStringAsFixed(2)} - '
                      '${history.data.reduce((a, b) => a > b ? a : b).toStringAsFixed(2)}',
                  color: Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isOverload) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOverload
            ? Colors.red.withOpacity(0.1)
            : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOverload ? Colors.red : Colors.green,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOverload ? Icons.warning : Icons.check_circle,
            size: 16,
            color: isOverload ? Colors.red : Colors.green,
          ),
          SizedBox(width: 6),
          Text(
            isOverload ? '过载' : '正常',
            style: TextStyle(
              color: isOverload ? Colors.red : Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      width: 160,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '数据趋势分析',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: Icon(Icons.fullscreen, size: 20),
              onPressed: () => _showFullscreenChart(context),
              tooltip: '全屏查看',
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          height: 280,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                _buildInteractiveChart(),
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${history.data.length}个数据点',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInteractiveChart() {
    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '值: ${spot.y.toStringAsFixed(2)}\n时间点: ${spot.x.toInt() + 1}',
                  const TextStyle(color: Colors.white),
                );
              }).toList();
            },
            tooltipPadding: const EdgeInsets.all(8),
            fitInsideHorizontally: true,
            fitInsideVertically: true,
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: _calculateChartInterval(history.data),
          verticalInterval: _calculateVerticalInterval(history.data.length),
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
          getDrawingVerticalLine: (value) =>
              FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: _calculateVerticalInterval(history.data.length),
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    '${value.toInt() + 1}',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: _calculateChartInterval(history.data),
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        minX: 0,
        maxX: (history.data.length - 1).toDouble(),
        minY: history.data.reduce((a, b) => a < b ? a : b) * 0.95,
        maxY: history.data.reduce((a, b) => a > b ? a : b) * 1.05,
        lineBarsData: [
          LineChartBarData(
            spots: history.data
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value))
                .toList(),
            isCurved: true,
            curveSmoothness: 0.3,
            color: Colors.blueAccent,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: Colors.blueAccent,
                  strokeWidth: 1.5,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Colors.blueAccent.withOpacity(0.3),
                  Colors.blueAccent.withOpacity(0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            aboveBarData: BarAreaData(
              show: true,
              spotsLine: BarAreaSpotsLine(
                show: true,
                flLineStyle: FlLine(
                  color: Colors.blueAccent.withOpacity(0.2),
                  strokeWidth: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateChartInterval(List<double> data) {
    final range =
        data.reduce((a, b) => a > b ? a : b) -
        data.reduce((a, b) => a < b ? a : b);
    return range / 4;
  }

  double _calculateVerticalInterval(int dataLength) {
    if (dataLength <= 10) return 1;
    if (dataLength <= 50) return 5;
    return (dataLength / 10).ceilToDouble();
  }

  Widget _buildStatsCard(ColorScheme colorScheme) {
    final minVal = history.data.reduce((a, b) => a < b ? a : b);
    final maxVal = history.data.reduce((a, b) => a > b ? a : b);
    final avgVal = history.data.reduce((a, b) => a + b) / history.data.length;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '数据统计',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(
                  '最小值',
                  minVal.toStringAsFixed(2),
                  colorScheme.primary,
                ),
                _buildStatItem(
                  '最大值',
                  maxVal.toStringAsFixed(2),
                  colorScheme.error,
                ),
                _buildStatItem(
                  '平均值',
                  avgVal.toStringAsFixed(2),
                  colorScheme.secondary,
                ),
                _buildStatItem(
                  '标准差',
                  _calculateStdDev().toStringAsFixed(2),
                  colorScheme.tertiary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        SizedBox(height: 4),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  double _calculateStdDev() {
    final mean = history.data.reduce((a, b) => a + b) / history.data.length;
    var sum = 0.0;
    for (var value in history.data) {
      sum += math.pow(value - mean, 2);
    }
    return math.sqrt(sum / history.data.length);
  }

  Widget _buildDataTableSection(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '原始数据',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => _exportData(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download, size: 18),
                  SizedBox(width: 4),
                  Text('导出'),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 24,
                horizontalMargin: 16,
                columns: [
                  DataColumn(
                    label: Text(
                      '序号',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text(
                      '数值',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text(
                      '状态',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows: history.data.asMap().entries.map((entry) {
                  final isAnomaly = _isAnomaly(entry.value);
                  return DataRow(
                    cells: [
                      DataCell(Text('${entry.key + 1}')),
                      DataCell(Text(entry.value.toStringAsFixed(2))),
                      DataCell(
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isAnomaly
                                ? Colors.red.withOpacity(0.1)
                                : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isAnomaly ? '异常' : '正常',
                            style: TextStyle(
                              color: isAnomaly ? Colors.red : Colors.green,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _isAnomaly(double value) {
    final mean = history.data.reduce((a, b) => a + b) / history.data.length;
    final stdDev = _calculateStdDev();
    return (value - mean).abs() > 2 * stdDev;
  }

  void _showFullscreenChart(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '数据趋势图 - 设备 ${history.deviceId}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(child: _buildInteractiveChart()),
            ],
          ),
        ),
      ),
    );
  }

  void _shareData(BuildContext context) {
    // 实现分享功能
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('分享功能将在后续版本中提供')));
  }

  void _exportData(BuildContext context) {
    // 实现导出功能
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('数据导出功能将在后续版本中提供')));
  }

  void _handleMenuSelection(String value, BuildContext context) {
    switch (value) {
      case 'export':
        _exportData(context);
        break;
      case 'analyze':
        // 高级分析功能
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('高级分析功能将在后续版本中提供')));
        break;
    }
  }
}
