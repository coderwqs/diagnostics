import 'package:diagnosis/l10n/app_localizations.dart';
import 'package:diagnosis/model/history.dart';
import 'package:diagnosis/service/history.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:diagnosis/utils/app_files.dart';

class DetailPage extends StatefulWidget {
  final int id;
  final String deviceId;

  const DetailPage({super.key, required this.id, required this.deviceId});

  @override
  createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final HistoryService _historyService = HistoryService();
  late Future<void> _historyFuture;
  late ExtendedHistory _history;
  bool _isExporting = false;
  int _selectedChartType = 0; // 0: 折线图, 1: 柱状图

  @override
  void initState() {
    super.initState();
    _loadHistoryData();
  }

  void _loadHistoryData() async {
    final history = await fetchHistoryDataById();

    if (history != null) {
      setState(() {
        _history = history;
        _historyFuture = Future.value();
      });
    }
  }

  Future<ExtendedHistory?> fetchHistoryDataById() async {
    return await _historyService.viewHistory(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isOverload =
        _history.rotationSpeed != null && _history.rotationSpeed! > 1000;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.history_detail,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(
                      Icons.download,
                      size: 20,
                      color: theme.iconTheme.color,
                    ),
                    SizedBox(width: 8),
                    Text(l10n.app_export_data),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, size: 20, color: theme.iconTheme.color),
                    SizedBox(width: 8),
                    Text(l10n.app_share_data),
                  ],
                ),
              ),
            ],
            onSelected: (value) => _handleMenuSelection(value, context),
          ),
        ],
      ),
      body: FutureBuilder(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(l10n.history_loading),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                  SizedBox(height: 16),
                  Text(
                    l10n.history_failed_loading,
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(snapshot.error.toString(), textAlign: TextAlign.center),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _historyFuture = Future.delayed(Duration.zero);
                      });
                    },
                    child: Text(l10n.app_retry),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 设备概览卡片
                _buildDeviceOverviewCard(l10n, isOverload, theme),
                SizedBox(height: 20),

                // 图表类型选择
                _buildChartTypeSelector(l10n, theme),
                SizedBox(height: 16),

                // 数据图表部分
                _buildChartSection(l10n, theme),
                SizedBox(height: 20),

                // 数据统计卡片
                _buildStatsCard(l10n, theme),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDeviceOverviewCard(
    AppLocalizations l10n,
    bool isOverload,
    ThemeData theme,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusBadge(l10n, isOverload),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_history.deviceName}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        DateFormat('yyyy-MM-dd HH:mm:ss').format(
                          DateTime.fromMillisecondsSinceEpoch(
                            _history.createdAt,
                          ),
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.upload_rounded, size: 22),
                  onPressed: () => _exportData(context),
                  tooltip: l10n.app_export_data,
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
            Divider(height: 24, thickness: 1),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildMetricTile(
                  icon: Icons.speed_rounded,
                  title: l10n.history_sampling_rate,
                  value: '${_history.samplingRate} Hz',
                  color: theme.primaryColor,
                ),
                if (_history.rotationSpeed != null)
                  _buildMetricTile(
                    icon: Icons.rotate_right_rounded,
                    title: l10n.history_rotation_speed,
                    value: '${_history.rotationSpeed} RPM',
                    color: isOverload ? Colors.red : Colors.green,
                  ),
                _buildMetricTile(
                  icon: Icons.format_list_numbered_rounded,
                  title: l10n.history_data_point,
                  value: '${_history.data.length}',
                  color: Colors.blueAccent,
                ),
                _buildMetricTile(
                  icon: Icons.timeline_rounded,
                  title: l10n.history_data_range,
                  value:
                      '${_history.data.reduce((a, b) => a < b ? a : b).toStringAsFixed(2)} - '
                      '${_history.data.reduce((a, b) => a > b ? a : b).toStringAsFixed(2)}',
                  color: Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _exportData(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isExporting = true);

    try {
      final timestamp = DateFormat(
        'yyyyMMdd_HHmmss',
      ).format(DateTime.fromMillisecondsSinceEpoch(_history.dataTime));
      final defaultFileName = '${_history.deviceName}_$timestamp';

      final fileContent = _generateCsvData();

      final directory = await getDownloadsDirectory();
      if (directory == null) throw Exception(l10n.history_failed_access);

      final file = File('${directory.path}/$defaultFileName.csv');
      await file.writeAsString(fileContent);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.history_export_tips),
          duration: Duration(seconds: 3),
          action: SnackBarAction(
            label: l10n.app_view_file,
            onPressed: () async {
              try {
                await file.revealInFileExplorer();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${l10n.history_failed_open_dir}: ${e.toString()}',
                    ),
                  ),
                );
              }
            },
          ),
        ),
      );
    } catch (e) {
      _showExportFallbackDialog(context, e.toString());
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _showExportFallbackDialog(BuildContext context, String error) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.history_failed_export),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${l10n.history_auto_save_failed}: $error'),
            SizedBox(height: 16),
            Text('${l10n.history_get_data_tips}:'),
          ],
        ),
        actions: [
          TextButton(
            child: Text(l10n.app_cancel),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text(l10n.app_share_data),
            onPressed: () {
              Navigator.pop(context);
              _shareDataFile(context);
            },
          ),
        ],
      ),
    );
  }

  void _shareDataFile(BuildContext context) async {
    if (Platform.isLinux) return;

    final l10n = AppLocalizations.of(context)!;

    try {
      final csvData = _generateCsvData();
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_export.csv');
      await tempFile.writeAsString(csvData);

      final params = ShareParams(
        text: l10n.history_share_title(_history.deviceName as Object),
        files: [XFile(tempFile.path)],
      );

      final result = await SharePlus.instance.share(params);

      if (result.status == ShareResultStatus.success) {
        print('Thank you for sharing the picture!');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.history_share_failed}: ${e.toString()}'),
        ),
      );
    }
  }

  String _generateCsvData() {
    final buffer = StringBuffer();

    buffer.writeln('Value,Timestamp');

    final timeIncrement = (1000 / _history.samplingRate).round();

    _history.data.asMap().forEach((index, value) {
      final timestamp = _history.createdAt + (index * timeIncrement);
      buffer.write('$value,$timestamp\n');
    });

    return buffer.toString();
  }

  Widget _buildStatusBadge(AppLocalizations l10n, bool isOverload) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOverload
            ? Colors.red.withValues(alpha: 0.1)
            : Colors.green.withValues(alpha: 0.1),
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
            isOverload
                ? Icons.warning_amber_rounded
                : Icons.check_circle_rounded,
            size: 16,
            color: isOverload ? Colors.red : Colors.green,
          ),
          SizedBox(width: 6),
          Text(
            isOverload
                ? l10n.history_status_loader
                : l10n.history_status_normal,
            style: TextStyle(
              color: isOverload ? Colors.red : Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 12,
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
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
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
                style: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontSize: 12,
                ),
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

  Widget _buildChartTypeSelector(AppLocalizations l10n, ThemeData theme) {
    return SegmentedButton<int>(
      segments: [
        ButtonSegment(
          value: 0,
          label: Text(l10n.app_line_chart),
          icon: Icon(Icons.show_chart, size: 18),
        ),
        ButtonSegment(
          value: 1,
          label: Text(l10n.app_bar_chart),
          icon: Icon(Icons.bar_chart, size: 18),
        ),
      ],
      selected: {_selectedChartType},
      onSelectionChanged: (Set<int> newSelection) {
        setState(() {
          _selectedChartType = newSelection.first;
        });
      },
      style: ButtonStyle(visualDensity: VisualDensity.compact),
    );
  }

  Widget _buildChartSection(AppLocalizations l10n, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.history_trend_analysis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: Icon(Icons.fullscreen, size: 20),
              onPressed: () => _showFullscreenChart(context),
              tooltip: l10n.app_full_screen,
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          height: 280,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                _selectedChartType == 0
                    ? _buildLineChart(l10n, _history.data)
                    : _buildBarChart(l10n, _history.data),
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_history.data.length}${l10n.history_points}',
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

  Widget _buildLineChart(AppLocalizations l10n, List<double> data) {
    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      primaryXAxis: NumericAxis(
        minimum: 0,
        maximum: data.length.toDouble(),
        interval: _calculateChartInterval(data.length),
        majorGridLines: MajorGridLines(width: 0),
      ),
      primaryYAxis: NumericAxis(
        minimum: data.reduce((a, b) => a < b ? a : b) * 0.95,
        maximum: data.reduce((a, b) => a > b ? a : b) * 1.05,
        interval: _calculateChartInterval(data.length),
        majorGridLines: MajorGridLines(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      series: <CartesianSeries>[
        LineSeries<double, double>(
          dataSource: data,
          xValueMapper: (value, index) => index.toDouble(),
          yValueMapper: (value, index) => value,
          color: Colors.blueAccent,
          width: 2.5,
          markerSettings: MarkerSettings(
            isVisible: true,
            shape: DataMarkerType.circle,
            borderWidth: 1.5,
            borderColor: Colors.white,
            color: Colors.blueAccent,
          ),
        ),
      ],
      tooltipBehavior: TooltipBehavior(
        enable: true,
        format: '${l10n.app_time}: point.x\n${l10n.app_amplitude}: point.y',
      ),
    );
  }

  Widget _buildBarChart(AppLocalizations l10n, List<double> data) {
    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      primaryXAxis: NumericAxis(
        minimum: 0,
        maximum: data.length.toDouble(),
        interval: _calculateChartInterval(data.length),
        majorGridLines: MajorGridLines(width: 0),
      ),
      primaryYAxis: NumericAxis(
        minimum: 0,
        maximum: data.reduce((a, b) => a > b ? a : b) * 1.2,
        interval: _calculateChartInterval(data.length),
        majorGridLines: MajorGridLines(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      series: <CartesianSeries>[
        ColumnSeries<double, double>(
          dataSource: data,
          xValueMapper: (value, index) => index.toDouble(),
          yValueMapper: (value, index) => value,
          color: Colors.blueAccent,
          borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
      tooltipBehavior: TooltipBehavior(
        enable: true,
        format: '${l10n.app_time}: point.x\n${l10n.app_amplitude}: point.y',
      ),
    );
  }

  double _calculateChartInterval(int dataLength) {
    if (dataLength <= 10) return 1;
    if (dataLength <= 50) return 5;
    return (dataLength / 10).ceilToDouble();
  }

  Widget _buildStatsCard(AppLocalizations l10n, ThemeData theme) {
    final data = _history.data;
    final minVal = data.reduce((a, b) => a < b ? a : b);
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final avgVal = data.reduce((a, b) => a + b) / data.length;
    final stdDev = _calculateStdDev(data);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  l10n.history_data_statistics,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              spacing: 16,
              children: [
                _buildCompactStatItem(
                  l10n.app_min_value,
                  minVal.toStringAsFixed(2),
                  Icons.arrow_downward,
                  Colors.blue,
                ),
                _buildCompactStatItem(
                  l10n.app_max_value,
                  maxVal.toStringAsFixed(2),
                  Icons.arrow_upward,
                  Colors.red,
                ),
                _buildCompactStatItem(
                  l10n.app_average_value,
                  avgVal.toStringAsFixed(2),
                  Icons.trending_flat,
                  Colors.green,
                ),
                _buildCompactStatItem(
                  l10n.app_standard_deviation_value,
                  stdDev.toStringAsFixed(2),
                  Icons.science,
                  Colors.purple,
                ),
                _buildCompactStatItem(
                  l10n.app_median_value,
                  _calculateMedian(data).toStringAsFixed(2),
                  Icons.line_weight,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 210,
      height: 80,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          Container(
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateStdDev(List<double> data) {
    final mean = data.reduce((a, b) => a + b) / data.length;
    var sum = 0.0;
    for (var value in data) {
      sum += math.pow(value - mean, 2);
    }
    return math.sqrt(sum / data.length);
  }

  double _calculateMedian(List<double> data) {
    final sorted = List<double>.from(data)..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length % 2 == 1) {
      return sorted[middle];
    }
    return (sorted[middle - 1] + sorted[middle]) / 2;
  }

  void _showFullscreenChart(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_history.deviceName} - ${l10n.history_data_trend}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: _selectedChartType == 0
                  ? _buildLineChart(l10n, _history.data)
                  : _buildBarChart(l10n, _history.data),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuSelection(String value, BuildContext context) {
    switch (value) {
      case 'export':
        _exportData(context);
        break;
      case 'share':
        _shareDataFile(context);
        break;
    }
  }
}
