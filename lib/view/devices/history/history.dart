import 'dart:math' as math;

import 'package:diagnosis/l10n/app_localizations.dart';
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
  late Future<List<ExtendedHistory>> _historyFuture;
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.history,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: l10n.history_refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchFilterBar(l10n, theme),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              child: FutureBuilder<List<ExtendedHistory>>(
                future: _historyFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      _currentPage == 1) {
                    return _buildLoadingIndicator(l10n);
                  } else if (snapshot.hasError) {
                    return _buildErrorWidget(l10n, snapshot.error.toString());
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState(l10n);
                  }

                  final filteredData = _filterData(l10n, snapshot.data!);

                  return filteredData.isEmpty
                      ? _buildNoResultsWidget(l10n)
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
                                  return _buildHistoryCard(l10n, item, context);
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

  Widget _buildSearchFilterBar(AppLocalizations l10n, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              hintText: l10n.devices_search_tips_v1,
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
                _buildFilterChip(l10n.history_status_all, 'all'),
                _buildFilterChip(l10n.history_status_normal, 'normal'),
                _buildFilterChip(l10n.history_status_loader, 'overload'),
                _buildFilterChip(l10n.history_status_recent, 'week'),
                _buildDateRangeFilter(l10n),
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
        selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
        checkmarkColor: Theme.of(context).primaryColor,
        labelStyle: TextStyle(
          color: _filterValue == value
              ? Theme.of(context).primaryColor
              : Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
    );
  }

  Widget _buildDateRangeFilter(AppLocalizations l10n) {
    return IconButton(
      icon: const Icon(Icons.calendar_today, size: 20),
      onPressed: () async {
        final DateTimeRange? picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          currentDate: DateTime.now(),
          saveText: l10n.app_confirm,
        );

        if (picked != null) {
          setState(() {
            _filterValue = 'custom';
          });
        }
      },
      tooltip: l10n.history_date_range,
    );
  }

  Widget _buildHistoryCard(
    AppLocalizations l10n,
    ExtendedHistory item,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final isOverload = item.rotationSpeed != null && item.rotationSpeed! > 1000;
    final timeAgo = _timeAgo(
      l10n,
      DateTime.fromMillisecondsSinceEpoch(item.createdAt),
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  DetailPage(id: item.id!, deviceId: item.deviceId),
            ),
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
                          '${item.deviceName}',
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
                        label: l10n.history_sampling_rate,
                        value: '${item.samplingRate} Hz',
                      ),
                    ),
                    const VerticalDivider(thickness: 1, width: 16),
                    Expanded(
                      child: _buildDataPoint(
                        icon: Icons.rotate_right,
                        label: l10n.history_rotation_speed,
                        value: item.rotationSpeed != null
                            ? '${item.rotationSpeed} RPM'
                            : l10n.history_empty,
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
            ? Colors.red.withValues(alpha: 0.1)
            : Colors.green.withValues(alpha: 0.1),
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

  Widget _buildLoadingIndicator(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            l10n.history_loading,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(AppLocalizations l10n, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            l10n.history_failed_loading,
            style: Theme.of(context).textTheme.titleMedium,
          ),
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
            child: Text(l10n.app_retry),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
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
          Text(
            l10n.history_no_data,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.history_tips,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsWidget(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Theme.of(context).hintColor),
          const SizedBox(height: 16),
          Text(
            l10n.history_no_match,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.history_other_search,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }

  List<ExtendedHistory> _filterData(
    AppLocalizations l10n,
    List<ExtendedHistory> data,
  ) {
    var result = data.where((item) {
      final matchesSearch =
          item.deviceId.toLowerCase().contains(_searchQuery) ||
          (_searchQuery.contains(l10n.history_status_normal) &&
              !(item.rotationSpeed != null && item.rotationSpeed! > 1000)) ||
          (_searchQuery.contains(l10n.history_status_loader) &&
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

  String _timeAgo(AppLocalizations l10n, DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}${l10n.app_year_ago}';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}${l10n.app_month_ago}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}${l10n.app_day_ago}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}${l10n.app_hour_ago}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}${l10n.app_minute_ago}';
    } else {
      return l10n.app_just_now;
    }
  }

  Future<List<ExtendedHistory>> fetchHistoryData({
    int page = 1,
    int limit = 10,
  }) async {
    return _historyService.getAllHistories(page, limit);
  }
}
