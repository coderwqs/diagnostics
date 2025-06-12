import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class DeviceManagementPage extends StatefulWidget {
  const DeviceManagementPage({super.key});

  @override
  State<DeviceManagementPage> createState() => _DeviceManagementPageState();
}

class _DeviceManagementPageState extends State<DeviceManagementPage> {
  List<Device> _devices = [];
  List<Device> _filteredDevices = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  DeviceStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadDevices();
    _searchController.addListener(_filterDevices);
  }

  Future<void> _loadDevices() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _devices = [
        Device(
          id: 'DEV-001',
          name: '智能空调',
          type: '空调',
          status: DeviceStatus.online,
          lastActive: DateTime.now().subtract(const Duration(minutes: 5)),
          topic: 'ac_topic',
          icon: 'ac_unit'
        ),
        Device(
          id: 'DEV-002',
          name: '客厅灯光',
          type: '灯光',
          status: DeviceStatus.offline,
          lastActive: DateTime.now().subtract(const Duration(hours: 2)),
          topic: 'light_topic',
          icon: 'light'
        ),
        Device(
          id: 'DEV-003',
          name: '卧室窗帘',
          type: '窗帘',
          status: DeviceStatus.online,
          lastActive: DateTime.now().subtract(const Duration(minutes: 30)),
          topic: 'curtain_topic',
          icon: 'camera'
        ),
        Device(
          id: 'DEV-004',
          name: '厨房摄像头',
          type: '摄像头',
          status: DeviceStatus.warning,
          lastActive: DateTime.now().subtract(const Duration(minutes: 15)),
          topic: 'camera_topic',
          icon: 'camera'
        ),
      ];
      _filteredDevices = _devices;
      _isLoading = false;
    });
  }

  void _filterDevices() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredDevices = _devices.where((device) {
        return (device.name.toLowerCase().contains(query) ||
                device.id.toLowerCase().contains(query)) &&
            (_selectedStatus == null || device.status == _selectedStatus);
      }).toList();
    });
  }

  Future<void> _refreshDevices() async {
    setState(() => _isLoading = true);
    await _loadDevices();
  }

  void _showDeviceDetails(Device device) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DeviceDetailSheet(device: device),
    );
  }

  void _filterByStatus(DeviceStatus? status) {
    setState(() {
      _selectedStatus = status;
      _filterDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设备管理'),
        actions: [
          PopupMenuButton<DeviceStatus?>(
            onSelected: _filterByStatus,
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('全部')),
              const PopupMenuItem(
                value: DeviceStatus.online,
                child: Text('在线'),
              ),
              const PopupMenuItem(
                value: DeviceStatus.offline,
                child: Text('离线'),
              ),
              const PopupMenuItem(
                value: DeviceStatus.warning,
                child: Text('警告'),
              ),
            ],
            icon: const Icon(Icons.filter_list),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDevices,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredDevices.isEmpty
                ? _buildEmptyState()
                : _buildDeviceList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: _addNewDevice,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜索设备名称或ID',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _searchController.clear(),
                )
              : null,
        ),
        inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
      ),
    );
  }

  Widget _buildDeviceList() {
    return RefreshIndicator(
      onRefresh: _refreshDevices,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: _filteredDevices.length,
        itemBuilder: (context, index) {
          final device = _filteredDevices[index];
          return DeviceCard(
            device: device,
            onTap: () => _showDeviceDetails(device),
            onToggle: (value) => _toggleDevice(device, value),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.devices_other, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty ? '暂无设备，请点击添加' : '未找到匹配设备',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
          if (_searchController.text.isNotEmpty)
            TextButton(
              onPressed: () => _searchController.clear(),
              child: const Text('清除搜索条件'),
            ),
        ],
      ),
    );
  }

  void _toggleDevice(Device device, bool value) {
    setState(() {
      _devices = _devices.map((d) {
        if (d.id == device.id) {
          if (value) {
            // 订阅主题
            print('已订阅主题: ${device.topic}');
          } else {
            // 取消订阅
            print('已取消订阅主题: ${device.topic}');
          }
          return d.copyWith(
            status: value ? DeviceStatus.online : DeviceStatus.offline,
            lastActive: DateTime.now(),
          );
        }
        return d;
      }).toList();
      _filterDevices();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已${value ? '启用' : '停用'} ${device.name}')),
    );
  }

  void _addNewDevice() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController typeController = TextEditingController();
    final TextEditingController topicController = TextEditingController();
    String selectedIcon = '灯光'; // 默认选中图标

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('添加新设备'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(hintText: '设备名称'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: typeController,
                  decoration: const InputDecoration(hintText: '设备类型（如：智能灯光）'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: topicController,
                  decoration: const InputDecoration(hintText: '订阅主题'),
                ),
                const SizedBox(height: 10),
                DropdownButton<String>(
                  value: selectedIcon,
                  items: ['灯光', '空调', '摄像头', '窗帘'].map((String iconName) {
                    return DropdownMenuItem<String>(
                      value: iconName,
                      child: Text(iconName),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedIcon = newValue!;
                    });
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
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    typeController.text.isNotEmpty &&
                    topicController.text.isNotEmpty) {
                  setState(() {
                    _devices.add(
                      Device(
                        id: 'DEV-${_devices.length + 1}',
                        name: nameController.text,
                        type: typeController.text,
                        status: DeviceStatus.online,
                        lastActive: DateTime.now(),
                        topic: topicController.text,
                        icon: selectedIcon,
                      ),
                    );
                    _filterDevices();
                  });
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('请填写所有字段')));
                }
              },
              child: const Text('添加'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;

  const DeviceCard({
    super.key,
    required this.device,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(device.status);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: _buildDeviceIcon(),
        title: Text(device.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${device.id}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${_getStatusText(device.status)} • 最后活动: ${_formatTime(device.lastActive)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        trailing: Switch(
          value: device.status != DeviceStatus.offline,
          onChanged: onToggle,
          activeColor: theme.primaryColor,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDeviceIcon() {
    final iconData = switch (device.icon) {
      '灯光' => Icons.lightbulb_outline,
      '空调' => Icons.ac_unit,
      '摄像头' => Icons.videocam,
      '窗帘' => Icons.curtains_closed,
      _ => Icons.devices, // 默认图标
    };

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
      child: Icon(iconData, color: Colors.blue),
    );
  }

  Color _getStatusColor(DeviceStatus status) {
    return switch (status) {
      DeviceStatus.online => Colors.green,
      DeviceStatus.offline => Colors.grey,
      DeviceStatus.warning => Colors.orange,
    };
  }

  String _getStatusText(DeviceStatus status) {
    return switch (status) {
      DeviceStatus.online => '在线',
      DeviceStatus.offline => '离线',
      DeviceStatus.warning => '警告',
    };
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    return '${diff.inDays}天前';
  }
}

class DeviceDetailSheet extends StatelessWidget {
  final Device device;

  const DeviceDetailSheet({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.device_thermostat, size: 40, color: Colors.blue),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    '设备ID: ${device.id}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildDetailRow('设备类型', device.type),
          _buildDetailRow('当前状态', _getStatusText(device.status)),
          _buildDetailRow('最后活动', _formatTime(device.lastActive)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label)),
          Text(value),
        ],
      ),
    );
  }

  String _getStatusText(DeviceStatus status) {
    return switch (status) {
      DeviceStatus.online => '在线 (运行正常)',
      DeviceStatus.offline => '离线 (设备未连接)',
      DeviceStatus.warning => '警告 (需要检查)',
    };
  }

  String _formatTime(DateTime time) {
    return DateFormat('yyyy-MM-dd HH:mm').format(time);
  }
}

// 数据模型
enum DeviceStatus { online, offline, warning }

class Device {
  final String id;
  final String name;
  final String type; // 使用字符串表示设备类型
  final DeviceStatus status;
  final DateTime lastActive;
  final String topic; // 订阅主题
  final String icon; // 设备图标

  Device({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.lastActive,
    required this.topic,
    required this.icon,
  });

  Device copyWith({
    String? id,
    String? name,
    String? type,
    DeviceStatus? status,
    DateTime? lastActive,
    String? topic,
    String? icon,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      status: status ?? this.status,
      lastActive: lastActive ?? this.lastActive,
      topic: topic ?? this.topic,
      icon: icon ?? this.icon,
    );
  }
}
