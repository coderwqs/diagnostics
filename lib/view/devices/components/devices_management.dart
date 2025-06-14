import 'dart:io';

import 'package:diagnosis/service/devices.dart';
import 'package:diagnosis/utils/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:diagnosis/model/device.dart';
import 'package:uuid/uuid.dart';

class DeviceManagementPage extends StatefulWidget {
  const DeviceManagementPage({super.key});

  @override
  State<DeviceManagementPage> createState() => _DeviceManagementPageState();
}

class _DeviceManagementPageState extends State<DeviceManagementPage> {
  DeviceService _deviceService = DeviceService();
  List<Device> _devices = [];
  List<Device> _filteredDevices = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  DeviceStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _fetchDevices();
    _searchController.addListener(_filterDevices);
  }

  Future<void> _fetchDevices() async {
    final devices = await _deviceService.getAllDevices();
    setState(() {
      _devices = devices;
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
    await _fetchDevices();
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
        child: Icon(Icons.add),
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
            print('已订阅主题: ${device.id}');
          } else {
            // 取消订阅
            print('已取消订阅主题: ${device.id}');
          }
          return d.copyWith(
            status: value ? DeviceStatus.online : DeviceStatus.offline,
            lastActive: DateTime.now().millisecondsSinceEpoch,
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
    final TextEditingController identityController = TextEditingController();
    final TextEditingController secretController = TextEditingController();
    String selectedType = '智能灯光';
    String? selectedImage;
    bool isFormValid = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // 检查表单是否有效
            void checkFormValidity() {
              setState(() {
                isFormValid =
                    nameController.text.isNotEmpty &&
                    identityController.text.isNotEmpty &&
                    secretController.text.isNotEmpty &&
                    selectedImage != null;
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: const Text(
                '添加新设备',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 设备名称
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: '设备名称',
                        hintText: '请输入设备名称',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (_) => checkFormValidity(),
                    ),
                    const SizedBox(height: 16),

                    // 设备类型
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: InputDecoration(
                        labelText: '设备类型',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 0,
                        ),
                      ),
                      items: ['智能灯光', '空调', '摄像头', '窗帘'].map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedType = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // 身份标识
                    TextField(
                      controller: identityController,
                      decoration: InputDecoration(
                        labelText: '身份标识',
                        hintText: '请输入设备身份标识',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (_) => checkFormValidity(),
                    ),
                    const SizedBox(height: 16),

                    // 密钥
                    TextField(
                      controller: secretController,
                      decoration: InputDecoration(
                        labelText: '密钥',
                        hintText: '请输入设备密钥',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (_) => checkFormValidity(),
                    ),
                    const SizedBox(height: 16),

                    // 图片选择区域
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '设备图片',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            side: BorderSide(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          onPressed: () async {
                            final ImagePicker _picker = ImagePicker();
                            final XFile? image = await _picker.pickImage(
                              source: ImageSource.gallery,
                            );
                            if (image != null) {
                              setState(() {
                                selectedImage = image.path;
                                checkFormValidity();
                              });
                            }
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.image, size: 20),
                              SizedBox(width: 8),
                              Text('选择设备图片'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (selectedImage != null)
                          Container(
                            height: 120,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(selectedImage!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFormValid
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  onPressed: isFormValid
                      ? () {
                          setState(() {
                            _devices.add(
                              Device(
                                id: Uuid().v4(),
                                name: nameController.text,
                                image: selectedImage!,
                                identity: identityController.text,
                                secret: secretController.text,
                                type: selectedType,
                                status: DeviceStatus.offline,
                                lastActive:
                                    DateTime.now().millisecondsSinceEpoch,
                                createdAt:
                                    DateTime.now().millisecondsSinceEpoch,
                              ),
                            );
                            _filterDevices();
                          });
                          Navigator.pop(context);
                        }
                      : null,
                  child: const Text(
                    '添加',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
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
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.devices, color: Colors.blue),
        ),
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

  String _formatTime(int timestamp) {
    final time = DateTime.fromMillisecondsSinceEpoch(timestamp);
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

  String _formatTime(int timestamp) {
    final time = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('yyyy-MM-dd HH:mm').format(time);
  }
}
