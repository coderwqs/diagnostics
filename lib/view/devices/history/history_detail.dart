import 'package:diagnosis/model/history.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:file_saver/file_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DetailPage extends StatefulWidget {
  final History history;

  const DetailPage({Key? key, required this.history}) : super(key: key);

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late Future<void> _dataFuture;
  bool _isExporting = false;
  int _selectedChartType = 0; // 0: 折线图, 1: 柱状图
  int _selectedTimeRange = 0; // 0: 全部, 1: 最近100点, 2: 最近50点

  @override
  void initState() {
    super.initState();
    _dataFuture = Future.delayed(Duration.zero); // 模拟数据加载
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverload =
        widget.history.rotationSpeed != null &&
        widget.history.rotationSpeed! > 1000;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '数据详情',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.share, size: 22),
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
                    Icon(
                      Icons.download,
                      size: 20,
                      color: theme.iconTheme.color,
                    ),
                    SizedBox(width: 8),
                    Text('导出数据'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'analyze',
                child: Row(
                  children: [
                    Icon(
                      Icons.analytics,
                      size: 20,
                      color: theme.iconTheme.color,
                    ),
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
      body: FutureBuilder(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingIndicator();
          } else if (snapshot.hasError) {
            return _buildErrorWidget(snapshot.error.toString());
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 设备概览卡片
                _buildDeviceOverviewCard(isOverload, theme),
                SizedBox(height: 20),

                // 图表类型选择
                _buildChartTypeSelector(theme),
                SizedBox(height: 16),

                // 数据图表部分
                _buildChartSection(theme),
                SizedBox(height: 20),

                // 数据统计卡片
                _buildStatsCard(theme),
                SizedBox(height: 20),

   /*             // 原始数据表格
                _buildDataTableSection(theme),*/
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDeviceOverviewCard(bool isOverload, ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.2), width: 1),
      ),
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
                        '设备 ${widget.history.deviceId}',
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
                            widget.history.createdAt,
                          ),
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
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
                  icon: Icons.speed,
                  title: '采样率',
                  value: '${widget.history.samplingRate} Hz',
                  color: theme.primaryColor,
                ),
                if (widget.history.rotationSpeed != null)
                  _buildMetricTile(
                    icon: Icons.rotate_right,
                    title: '转速',
                    value: '${widget.history.rotationSpeed} RPM',
                    color: isOverload ? Colors.red : Colors.green,
                  ),
                _buildMetricTile(
                  icon: Icons.show_chart,
                  title: '数据点数',
                  value: '${widget.history.data.length}',
                  color: Colors.blueAccent,
                ),
                _buildMetricTile(
                  icon: Icons.timeline,
                  title: '数据范围',
                  value:
                      '${widget.history.data.reduce((a, b) => a < b ? a : b).toStringAsFixed(2)} - '
                      '${widget.history.data.reduce((a, b) => a > b ? a : b).toStringAsFixed(2)}',
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
            isOverload
                ? Icons.warning_amber_rounded
                : Icons.check_circle_rounded,
            size: 16,
            color: isOverload ? Colors.red : Colors.green,
          ),
          SizedBox(width: 6),
          Text(
            isOverload ? '过载' : '正常',
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
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
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

  Widget _buildChartTypeSelector(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: SegmentedButton<int>(
            segments: [
              ButtonSegment(
                value: 0,
                label: Text('折线图'),
                icon: Icon(Icons.show_chart, size: 18),
              ),
              ButtonSegment(
                value: 1,
                label: Text('柱状图'),
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
          ),
        ),
        SizedBox(width: 12),
        DropdownButton<int>(
          value: _selectedTimeRange,
          items: [
            DropdownMenuItem(value: 0, child: Text('全部数据')),
            DropdownMenuItem(value: 1, child: Text('最近100点')),
            DropdownMenuItem(value: 2, child: Text('最近50点')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedTimeRange = value!;
            });
          },
          underline: Container(),
          isDense: true,
        ),
      ],
    );
  }

  Widget _buildChartSection(ThemeData theme) {
    List<double> displayData = _getDisplayData();

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
        SizedBox(height: 12),
        Container(
          height: 280,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
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
                    ? _buildLineChart(displayData)
                    : _buildBarChart(displayData),
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
                      '${displayData.length}个数据点',
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

  Widget _buildLineChart(List<double> data) {
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
        interval: _calculateChartInterval(data as int),
        majorGridLines: MajorGridLines(
          color: Colors.grey.withOpacity(0.2),
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
        format: '点: point.x\n值: point.y',
      ),
    );
  }

  Widget _buildBarChart(List<double> data) {
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
        interval: _calculateChartInterval(data as int),
        majorGridLines: MajorGridLines(
          color: Colors.grey.withOpacity(0.2),
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
        format: '点: point.x\n值: point.y',
      ),
    );
  }

  double _calculateChartInterval(int dataLength) {
    if (dataLength <= 10) return 1;
    if (dataLength <= 50) return 5;
    return (dataLength / 10).ceilToDouble();
  }

  List<double> _getDisplayData() {
    switch (_selectedTimeRange) {
      case 1:
        return widget.history.data.length > 100
            ? widget.history.data.sublist(widget.history.data.length - 100)
            : widget.history.data;
      case 2:
        return widget.history.data.length > 50
            ? widget.history.data.sublist(widget.history.data.length - 50)
            : widget.history.data;
      default:
        return widget.history.data;
    }
  }

  Widget _buildStatsCard(ThemeData theme) {
    final displayData = _getDisplayData();
    final minVal = displayData.reduce((a, b) => a < b ? a : b);
    final maxVal = displayData.reduce((a, b) => a > b ? a : b);
    final avgVal = displayData.reduce((a, b) => a + b) / displayData.length;
    final stdDev = _calculateStdDev(displayData);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '数据统计',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              childAspectRatio: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildStatItem(
                  '最小值',
                  minVal.toStringAsFixed(2),
                  Icons.arrow_downward,
                  Colors.blue,
                ),
                _buildStatItem(
                  '最大值',
                  maxVal.toStringAsFixed(2),
                  Icons.arrow_upward,
                  Colors.red,
                ),
                _buildStatItem(
                  '平均值',
                  avgVal.toStringAsFixed(2),
                  Icons.trending_flat,
                  Colors.green,
                ),
                _buildStatItem(
                  '标准差',
                  stdDev.toStringAsFixed(2),
                  Icons.science,
                  Colors.purple,
                ),
                _buildStatItem(
                  '中位数',
                  _calculateMedian(displayData).toStringAsFixed(2),
                  Icons.line_weight,
                  Colors.orange,
                ),
                _buildStatItem(
                  '变异系数',
                  (stdDev / avgVal).toStringAsFixed(4),
                  Icons.compare,
                  Colors.teal,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).hintColor,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
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

  Widget _buildDataTableSection(ThemeData theme) {
    final displayData = _getDisplayData();

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
            TextButton.icon(
              onPressed: _isExporting ? null : () => _exportData(context),
              icon: _isExporting
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.download, size: 18),
              label: Text(_isExporting ? '导出中...' : '导出'),
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.dividerColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 24,
                horizontalMargin: 16,
                headingTextStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
                columns: [
                  DataColumn(label: Text('序号'), numeric: true),
                  DataColumn(label: Text('数值'), numeric: true),
                  DataColumn(label: Text('状态')),
                  DataColumn(label: Text('Z-Score'), numeric: true),
                ],
                rows: displayData.asMap().entries.map((entry) {
                  final isAnomaly = _isAnomaly(entry.value, displayData);
                  final zScore = _calculateZScore(entry.value, displayData);
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
                      DataCell(Text(zScore.toStringAsFixed(2))),
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

  bool _isAnomaly(double value, List<double> data) {
    final mean = data.reduce((a, b) => a + b) / data.length;
    final stdDev = _calculateStdDev(data);
    return (value - mean).abs() > 2 * stdDev;
  }

  double _calculateZScore(double value, List<double> data) {
    final mean = data.reduce((a, b) => a + b) / data.length;
    final stdDev = _calculateStdDev(data);
    return stdDev != 0 ? (value - mean) / stdDev : 0;
  }

  Future<void> _exportData(BuildContext context) async {
    setState(() {
      _isExporting = true;
    });

    try {
      final data = widget.history.data;
      final csvData = StringBuffer();

      // 添加CSV头部
      csvData.writeln('序号,数值,时间戳,状态,Z-Score');

      // 添加数据行
      final mean = data.reduce((a, b) => a + b) / data.length;
      final stdDev = _calculateStdDev(data);

      for (int i = 0; i < data.length; i++) {
        final value = data[i];
        final isAnomaly = (value - mean).abs() > 2 * stdDev;
        final zScore = stdDev != 0 ? (value - mean) / stdDev : 0;

        csvData.writeln(
          '${i + 1},${value.toStringAsFixed(2)},'
          '${widget.history.createdAt + i},'
          '${isAnomaly ? "异常" : "正常"},'
          '${zScore.toStringAsFixed(2)}',
        );
      }

      // 获取临时目录
      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}/device_${widget.history.deviceId}_data.csv',
      );
      await file.writeAsString(csvData.toString());

      // 保存文件
      await FileSaver.instance.saveFile(
        name: 'device_${widget.history.deviceId}_data.csv',
        bytes: await file.readAsBytes(),
        ext: 'csv',
        mimeType: MimeType.csv,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('数据已导出为CSV文件'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('导出失败: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  void _showFullscreenChart(BuildContext context) {
    final displayData = _getDisplayData();

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
                  '设备 ${widget.history.deviceId} - 数据趋势',
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
                  ? _buildLineChart(displayData)
                  : _buildBarChart(displayData),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () => _exportChartAsImage(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.image, size: 18),
                  SizedBox(width: 8),
                  Text('保存为图片'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportChartAsImage(BuildContext context) async {
    // 实际项目中需要实现图表截图功能
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('图表导出功能将在后续版本中提供'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _shareData(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('分享功能将在后续版本中提供'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _handleMenuSelection(String value, BuildContext context) {
    switch (value) {
      case 'export':
        _exportData(context);
        break;
      case 'analyze':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdvancedAnalysisPage(history: widget.history),
          ),
        );
        break;
    }
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
                _dataFuture = Future.delayed(Duration.zero);
              });
            },
            child: Text('重试'),
          ),
        ],
      ),
    );
  }
}

class AdvancedAnalysisPage extends StatelessWidget {
  final History history;

  const AdvancedAnalysisPage({Key? key, required this.history})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('高级分析')),
      body: Center(child: Text('高级分析功能开发中...')),
    );
  }
}
