import 'dart:math' as math;

import 'package:diagnosis/model/history.dart';
import 'package:diagnosis/service/history.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'history_detail.dart';

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

