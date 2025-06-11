import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AlertManagementPage extends StatefulWidget {
  const AlertManagementPage({super.key});

  @override
  State<AlertManagementPage> createState() => _AlertManagementPageState();
}

class _AlertManagementPageState extends State<AlertManagementPage> {
  AlertFilter _currentFilter = AlertFilter.all;
  bool _isRefreshing = false;
  String _searchQuery = '';

  final List<Alert> _alerts = [
    Alert(
      id: '001',
      severity: AlertSeverity.critical,
      type: AlertType.equipment,
      title: '设备故障',
      description: '生产线3号设备发生严重故障，已停机，需要立即维修。故障代码：E-1023。',
      timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      isAcknowledged: false,
      isResolved: false,
    ),
    Alert(
      id: '002',
      severity: AlertSeverity.high,
      type: AlertType.battery,
      title: '电池电量低',
      description: '仓库传感器电池电量剩余10%，预计还能工作4小时，请及时更换。',
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      isAcknowledged: true,
      isResolved: false,
    ),
    Alert(
      id: '003',
      severity: AlertSeverity.medium,
      type: AlertType.system,
      title: '系统更新可用',
      description: '新版本v2.3.5可用，包含重要安全补丁和性能改进。建议在维护窗口期更新。',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isAcknowledged: false,
      isResolved: false,
    ),
    Alert(
      id: '004',
      severity: AlertSeverity.low,
      type: AlertType.network,
      title: '网络连接不稳定',
      description: '与服务器连接不稳定，数据同步延迟约15分钟，正在自动重连。',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      isAcknowledged: true,
      isResolved: true,
    ),
    Alert(
      id: '005',
      severity: AlertSeverity.critical,
      type: AlertType.security,
      title: '安全警报',
      description: '检测到未授权访问尝试，来源IP: 192.168.1.105，已自动阻止。',
      timestamp: DateTime.now(),
      isAcknowledged: false,
      isResolved: false,
    ),
    Alert(
      id: '006',
      severity: AlertSeverity.high,
      type: AlertType.equipment,
      title: '温度过高',
      description: '机房温度达到38°C，超过安全阈值，请检查空调系统。',
      timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
      isAcknowledged: false,
      isResolved: false,
    ),
  ];

  List<Alert> get _filteredAlerts {
    var filtered = _alerts.where((alert) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          alert.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          alert.description.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesFilter = switch (_currentFilter) {
        AlertFilter.all => true,
        AlertFilter.critical => alert.severity == AlertSeverity.critical,
        AlertFilter.active => !alert.isResolved,
        AlertFilter.resolved => alert.isResolved,
      };

      return matchesSearch && matchesFilter;
    }).toList();

    // 按时间排序，最新的在前面
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return filtered;
  }

  Future<void> _refreshAlerts() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isRefreshing = false);
  }

  void _changeFilter(AlertFilter? filter) {
    if (filter != null) {
      setState(() => _currentFilter = filter);
    }
  }

  void _toggleAcknowledge(Alert alert) {
    setState(() {
      alert.isAcknowledged = !alert.isAcknowledged;
    });
  }

  void _toggleResolve(Alert alert) {
    setState(() {
      alert.isResolved = !alert.isResolved;
      if (alert.isResolved) {
        alert.isAcknowledged = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasAlerts = _filteredAlerts.isNotEmpty;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '告警管理',
          style: textTheme.headlineSmall?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.blue.shade50.withValues(alpha: 0.3),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
            tooltip: '搜索告警',
          ),
          _buildFilterDropdown(),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50.withValues(alpha: 0.3), Colors.white],
          ),
        ),
        child: Column(
          children: [
            _buildAlertSummary(context),
            _buildFilterChips(context),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshAlerts,
                color: Theme.of(context).primaryColor,
                child: _isRefreshing
                    ? const Center(child: CircularProgressIndicator())
                    : hasAlerts
                    ? ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemCount: _filteredAlerts.length,
                        itemBuilder: (context, index) {
                          final alert = _filteredAlerts[index];
                          return _buildAlertCard(context, alert);
                        },
                      )
                    : _buildEmptyState(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade50,
        child: const Icon(Icons.add_alert, color: Colors.red, size: 28),
        onPressed: () => _showAddAlertDialog(context),
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AlertFilter>(
          value: _currentFilter,
          icon: const Icon(Icons.filter_list),
          onChanged: _changeFilter,
          items: AlertFilter.values.map((filter) {
            return DropdownMenuItem<AlertFilter>(
              value: filter,
              child: Row(
                children: [
                  Icon(_getFilterIcon(filter), size: 20),
                  const SizedBox(width: 8),
                  Text(filter.label),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  IconData _getFilterIcon(AlertFilter filter) {
    return switch (filter) {
      AlertFilter.all => Icons.list,
      AlertFilter.critical => Icons.warning,
      AlertFilter.active => Icons.error_outline,
      AlertFilter.resolved => Icons.check_circle,
    };
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('搜索告警'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: '输入告警标题或描述...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (query) {
            setState(() {
              _searchQuery = query;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _searchQuery = '');
              Navigator.pop(context);
            },
            child: const Text('清除'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showAddAlertDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    AlertSeverity selectedSeverity = AlertSeverity.medium;
    AlertType selectedType = AlertType.equipment;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('创建新告警'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: '告警标题',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: '告警描述',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<AlertSeverity>(
                    value: selectedSeverity,
                    decoration: const InputDecoration(
                      labelText: '严重程度',
                      border: OutlineInputBorder(),
                    ),
                    items: AlertSeverity.values.map((severity) {
                      return DropdownMenuItem<AlertSeverity>(
                        value: severity,
                        child: Row(
                          children: [
                            Icon(_getSeverityIcon(severity)),
                            const SizedBox(width: 8),
                            Text(severity.label),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedSeverity = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<AlertType>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: '告警类型',
                      border: OutlineInputBorder(),
                    ),
                    items: AlertType.values.map((type) {
                      return DropdownMenuItem<AlertType>(
                        value: type,
                        child: Row(
                          children: [
                            Icon(type.icon),
                            const SizedBox(width: 8),
                            Text(type.label),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedType = value);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (titleController.text.isEmpty) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('请输入告警标题')));
                    return;
                  }

                  final newAlert = Alert(
                    id: 'A${_alerts.length + 1}'.padLeft(3, '0'),
                    severity: selectedSeverity,
                    type: selectedType,
                    title: titleController.text,
                    description: descriptionController.text,
                    timestamp: DateTime.now(),
                    isAcknowledged: false,
                    isResolved: false,
                  );

                  setState(() {
                    _alerts.add(newAlert);
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('新告警已创建')));
                },
                child: const Text('创建'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAlertSummary(BuildContext context) {
    final criticalCount = _alerts
        .where((a) => a.severity == AlertSeverity.critical && !a.isResolved)
        .length;
    final activeCount = _alerts.where((a) => !a.isResolved).length;
    final resolvedCount = _alerts.where((a) => a.isResolved).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue.shade50.withValues(alpha: 0.3), Colors.white],
        ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '告警概览',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                context,
                _alerts.length.toString(),
                '总告警',
                Icons.alarm,
                Theme.of(context).primaryColor,
              ),
              _buildSummaryItem(
                context,
                criticalCount.toString(),
                '紧急告警',
                Icons.warning,
                Colors.red,
                isBlinking: criticalCount > 0,
              ),
              _buildSummaryItem(
                context,
                activeCount.toString(),
                '未解决',
                Icons.error_outline,
                Colors.orange,
              ),
              _buildSummaryItem(
                context,
                resolvedCount.toString(),
                '已解决',
                Icons.check_circle,
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String count,
    String label,
    IconData icon,
    Color color, {
    bool isBlinking = false,
  }) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (isBlinking)
              TweenAnimationBuilder(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(seconds: 2),
                // repeat: true,
                builder: (context, value, child) {
                  return Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2 * value),
                      shape: BoxShape.circle,
                    ),
                  );
                },
              ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          count,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: AlertFilter.values.map((filter) {
          final isSelected = _currentFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter.label),
              selected: isSelected,
              onSelected: (_) => _changeFilter(filter),
              selectedColor: Theme.of(context).primaryColor,
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).primaryColor,
              ),
              avatar: Icon(
                _getFilterIcon(filter),
                size: 18,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).primaryColor,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context, Alert alert) {
    final colors = _getAlertColors(context, alert.severity);
    final timeAgo = _formatTimeAgo(alert.timestamp);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showAlertDetails(context, alert),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              left: BorderSide(color: colors.borderColor, width: 6),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // 严重程度标签
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.severityBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        alert.severity.label,
                        style: TextStyle(
                          color: colors.severityTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // 时间标记
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          timeAgo,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // 标题和图标
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.iconBgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        alert.type.icon,
                        color: colors.iconColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        alert.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 描述文本
                Text(
                  alert.description,
                  style: TextStyle(color: Colors.grey.shade700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                // 状态和操作按钮
                _buildAlertActions(context, alert),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertActions(BuildContext context, Alert alert) {
    return Row(
      children: [
        if (!alert.isAcknowledged)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.orange),
                SizedBox(width: 4),
                Text(
                  '未确认',
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ],
            ),
          )
        else if (!alert.isResolved)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(Icons.verified, size: 14, color: Colors.blue),
                const SizedBox(width: 4),
                Text('已确认', style: TextStyle(color: Colors.blue, fontSize: 12)),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 14, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  '已解决',
                  style: TextStyle(color: Colors.green, fontSize: 12),
                ),
              ],
            ),
          ),
        const Spacer(),
        TextButton(
          onPressed: () => _toggleAcknowledge(alert),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: Row(
            children: [
              Icon(
                alert.isAcknowledged ? Icons.undo : Icons.verified,
                size: 18,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 4),
              Text(
                alert.isAcknowledged ? '取消确认' : '确认',
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () => _toggleResolve(alert),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: Row(
            children: [
              Icon(
                alert.isResolved ? Icons.replay : Icons.check,
                size: 18,
                color: alert.isResolved ? Colors.grey : Colors.green,
              ),
              const SizedBox(width: 4),
              Text(
                alert.isResolved ? '重新打开' : '解决',
                style: TextStyle(
                  color: alert.isResolved ? Colors.grey : Colors.green,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            '没有找到告警',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty ? '当前没有告警记录' : '没有找到匹配"$_searchQuery"的告警',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _refreshAlerts,
            child: const Text('刷新'),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAlertDetails(BuildContext context, Alert alert) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          final colors = _getAlertColors(context, alert.severity);

          return SingleChildScrollView(
            controller: scrollController,
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.iconBgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          alert.type.icon,
                          color: colors.iconColor,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'ID: ${alert.id}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildDetailItem(
                    context,
                    '严重程度',
                    alert.severity.label,
                    icon: _getSeverityIcon(alert.severity),
                  ),
                  _buildDetailItem(
                    context,
                    '告警类型',
                    alert.type.label,
                    icon: alert.type.icon,
                  ),
                  _buildDetailItem(
                    context,
                    '发生时间',
                    DateFormat('yyyy-MM-dd HH:mm:ss').format(alert.timestamp),
                    icon: Icons.access_time,
                  ),
                  _buildDetailItem(
                    context,
                    '状态',
                    alert.isResolved
                        ? '已解决'
                        : alert.isAcknowledged
                        ? '已确认'
                        : '未确认',
                    icon: alert.isResolved
                        ? Icons.check_circle
                        : alert.isAcknowledged
                        ? Icons.verified
                        : Icons.info_outline,
                    iconColor: alert.isResolved
                        ? Colors.green
                        : alert.isAcknowledged
                        ? Colors.blue
                        : Colors.orange,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '详细描述',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(alert.description),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _toggleAcknowledge(alert);
                            Navigator.pop(context);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                alert.isAcknowledged
                                    ? Icons.undo
                                    : Icons.verified,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(alert.isAcknowledged ? '取消确认' : '确认告警'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: alert.isResolved
                                ? Colors.grey
                                : Colors.green,
                          ),
                          onPressed: () {
                            _toggleResolve(alert);
                            Navigator.pop(context);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                alert.isResolved ? Icons.replay : Icons.check,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(alert.isResolved ? '重新打开' : '标记解决'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailItem(
    BuildContext context,
    String label,
    String value, {
    IconData? icon,
    Color iconColor = Colors.grey,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 80,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) return '刚刚';
    if (difference.inMinutes < 60) return '${difference.inMinutes}分钟前';
    if (difference.inHours < 24) return '${difference.inHours}小时前';
    if (difference.inDays < 7) return '${difference.inDays}天前';
    return DateFormat('MM-dd').format(timestamp);
  }

  IconData _getSeverityIcon(AlertSeverity severity) {
    return switch (severity) {
      AlertSeverity.critical => Icons.warning,
      AlertSeverity.high => Icons.error,
      AlertSeverity.medium => Icons.info_outline,
      AlertSeverity.low => Icons.notifications_none,
    };
  }

  AlertColors _getAlertColors(BuildContext context, AlertSeverity severity) {
    return switch (severity) {
      AlertSeverity.critical => AlertColors(
        iconBgColor: Colors.red.shade50,
        iconColor: Colors.red,
        severityBgColor: Colors.red,
        severityTextColor: Colors.white,
        borderColor: Colors.red,
      ),
      AlertSeverity.high => AlertColors(
        iconBgColor: Colors.orange.shade50,
        iconColor: Colors.orange,
        severityBgColor: Colors.orange,
        severityTextColor: Colors.white,
        borderColor: Colors.orange,
      ),
      AlertSeverity.medium => AlertColors(
        iconBgColor: Colors.yellow.shade50,
        iconColor: Colors.yellow.shade700,
        severityBgColor: Colors.yellow,
        severityTextColor: Colors.black87,
        borderColor: Colors.yellow.shade600,
      ),
      AlertSeverity.low => AlertColors(
        iconBgColor: Colors.blue.shade50,
        iconColor: Colors.blue,
        severityBgColor: Colors.blue,
        severityTextColor: Colors.white,
        borderColor: Colors.blue,
      ),
    };
  }
}

class Alert {
  final String id;
  final AlertSeverity severity;
  final AlertType type;
  final String title;
  final String description;
  final DateTime timestamp;
  bool isAcknowledged;
  bool isResolved;

  Alert({
    required this.id,
    required this.severity,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    this.isAcknowledged = false,
    this.isResolved = false,
  });
}

enum AlertSeverity {
  critical('紧急'),
  high('高'),
  medium('中'),
  low('低');

  final String label;

  const AlertSeverity(this.label);
}

enum AlertType {
  equipment('设备', Icons.build),
  battery('电池', Icons.battery_alert),
  system('系统', Icons.computer),
  network('网络', Icons.network_check),
  security('安全', Icons.security);

  final String label;
  final IconData icon;

  const AlertType(this.label, this.icon);
}

enum AlertFilter {
  all('全部'),
  critical('紧急'),
  active('未解决'),
  resolved('已解决');

  final String label;

  const AlertFilter(this.label);
}

class AlertColors {
  final Color iconBgColor;
  final Color iconColor;
  final Color severityBgColor;
  final Color severityTextColor;
  final Color borderColor;

  AlertColors({
    required this.iconBgColor,
    required this.iconColor,
    required this.severityBgColor,
    required this.severityTextColor,
    required this.borderColor,
  });
}
