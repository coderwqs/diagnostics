import 'dart:math' as math;

import 'package:diagnosis/model/history.dart';
import 'package:diagnosis/service/history.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryDataPage extends StatefulWidget {
  const HistoryDataPage({super.key});

  @override
  State<HistoryDataPage> createState() => _HistoryDataPageState();
}

class _HistoryDataPageState extends State<HistoryDataPage> {
  final HistoryService _historyService = HistoryService();
  late Future<List<History>> _historyFuture;
  String _searchQuery = '';
  String _filterValue = 'all';
  bool _isLoadingMore = false;
  int _currentPage = 1;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _historyFuture = fetchHistoryData(page: _currentPage);
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !_isLoadingMore) {
      _loadMoreData();
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    final newData = await fetchHistoryData(page: _currentPage + 1);

    setState(() {
      _historyFuture = _historyFuture.then((existingData) {
        return [...existingData, ...newData];
      });
      _currentPage++;
      _isLoadingMore = false;
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      _currentPage = 1;
      _historyFuture = fetchHistoryData(page: 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '历史数据',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: '刷新数据',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchFilterBar(theme),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              child: FutureBuilder<List<History>>(
                future: _historyFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      _currentPage == 1) {
                    return _buildLoadingIndicator();
                  } else if (snapshot.hasError) {
                    return _buildErrorWidget(snapshot.error.toString());
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState();
                  }

                  final filteredData = _filterData(snapshot.data!);

                  return filteredData.isEmpty
                      ? _buildNoResultsWidget()
                      : CustomScrollView(
                          controller: _scrollController,
                          slivers: [
                            SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                if (index < filteredData.length) {
                                  final item = filteredData[index];
                                  return _buildHistoryCard(item, context);
                                }
                                return null;
                              }, childCount: filteredData.length),
                            ),
                            if (_isLoadingMore)
                              const SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(
                                    child: SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFilterBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                    )
                  : null,
              hintText: '搜索设备ID或状态...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: theme.inputDecorationTheme.fillColor,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('全部', 'all'),
                _buildFilterChip('正常', 'normal'),
                _buildFilterChip('过载', 'overload'),
                _buildFilterChip('最近7天', 'week'),
                _buildDateRangeFilter(),
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
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
        checkmarkColor: Theme.of(context).primaryColor,
        labelStyle: TextStyle(
          color: _filterValue == value
              ? Theme.of(context).primaryColor
              : Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
    );
  }

  Widget _buildDateRangeFilter() {
    return IconButton(
      icon: const Icon(Icons.calendar_today, size: 20),
      onPressed: () {
        // 实现日期范围选择
        _showDateRangePicker();
      },
      tooltip: '选择日期范围',
    );
  }

  Future<void> _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      currentDate: DateTime.now(),
      saveText: '确认',
    );

    if (picked != null) {
      // 处理日期范围选择
      setState(() {
        _filterValue = 'custom';
        // 更新过滤逻辑
      });
    }
  }

  Widget _buildHistoryCard(History item, BuildContext context) {
    final theme = Theme.of(context);
    final isOverload = item.rotationSpeed != null && item.rotationSpeed! > 1000;
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final timeAgo = _timeAgo(
      DateTime.fromMillisecondsSinceEpoch(item.createdAt),
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.2), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '设备 ${item.deviceId}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: theme.hintColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeAgo,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: theme.hintColor),
                ],
              ),
              const SizedBox(height: 12),
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: _buildDataPoint(
                        icon: Icons.speed,
                        label: '采样率',
                        value: '${item.samplingRate} Hz',
                      ),
                    ),
                    const VerticalDivider(thickness: 1, width: 16),
                    Expanded(
                      child: _buildDataPoint(
                        icon: Icons.rotate_right,
                        label: '转速',
                        value: item.rotationSpeed != null
                            ? '${item.rotationSpeed} RPM'
                            : '无数据',
                        valueColor: isOverload ? Colors.red : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(bool isOverload) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isOverload
            ? Colors.red.withOpacity(0.1)
            : Colors.green.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isOverload ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
        color: isOverload ? Colors.red : Colors.green,
        size: 20,
      ),
    );
  }

  Widget _buildDataPoint({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: theme.hintColor),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: valueColor ?? theme.textTheme.bodyMedium?.color,
              ),
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
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text('加载数据中...', style: Theme.of(context).textTheme.bodyLarge),
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
          const SizedBox(height: 16),
          Text('加载失败', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshData,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('重试'),
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
          Icon(
            Icons.history_toggle_off,
            size: 64,
            color: Theme.of(context).hintColor,
          ),
          const SizedBox(height: 16),
          Text('暂无历史数据', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            '您还没有任何历史记录',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Theme.of(context).hintColor),
          const SizedBox(height: 16),
          Text('未找到匹配结果', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            '请尝试其他搜索条件',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
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

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}年前';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}个月前';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  Future<List<History>> fetchHistoryData({int page = 1, int limit = 10}) async {

    return  _historyService.getAllHistories(page, limit);
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
