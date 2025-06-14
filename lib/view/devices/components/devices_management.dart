import 'dart:convert';
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
      _filteredDevices = devices;
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
    var d = _devices.map((d) {
      if (d.id == device.id) {
        if (value) {
          // 订阅主题
          print('已订阅主题: ${device.id}');
        } else {
          // 取消订阅
          print('已取消订阅主题: ${device.id}');
        }

        DeviceStatus status = value
            ? DeviceStatus.online
            : DeviceStatus.offline;

        _deviceService.updateDeviceStatus(device.id, status.value);

        return d.copyWith(
          status: status,
          lastActive: DateTime.now().millisecondsSinceEpoch,
        );
      }
      return d;
    }).toList();

    setState(() {
      _devices = d;
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
    MachineType selectedType = MachineType.motor;
    List<int>? selectedImage;
    bool isFormValid = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void checkFormValidity() {
              setState(() {
                isFormValid =
                    nameController.text.isNotEmpty &&
                    identityController.text.isNotEmpty &&
                    secretController.text.isNotEmpty &&
                    selectedImage != null;
              });
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 4,
              child: Container(
                padding: const EdgeInsets.all(24),
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题
                    const Text(
                      '添加新设备',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 20),

                    // 表单内容
                    SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 设备名称
                          TextField(
                            controller: nameController,
                            decoration: InputDecoration(
                              labelText: '设备名称',
                              hintText: '例如: 发电机',
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              prefixIcon: const Icon(Icons.devices, size: 20),
                            ),
                            onChanged: (_) => checkFormValidity(),
                          ),
                          const SizedBox(height: 20),

                          // 设备类型
                          DropdownButtonFormField<MachineType>(
                            value: selectedType,
                            decoration: InputDecoration(
                              labelText: '设备类型',
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 0,
                              ),
                              prefixIcon: const Icon(Icons.category, size: 20),
                            ),
                            items: MachineType.values.map((type) {
                              return DropdownMenuItem<MachineType>(
                                value: type,
                                child: Text(type.displayName),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() => selectedType = newValue!);
                            },
                          ),
                          const SizedBox(height: 20),

                          // 身份标识
                          TextField(
                            controller: identityController,
                            decoration: InputDecoration(
                              labelText: '身份标识',
                              hintText: '设备的唯一标识码',
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              prefixIcon: const Icon(Icons.qr_code, size: 20),
                            ),
                            onChanged: (_) => checkFormValidity(),
                          ),
                          const SizedBox(height: 20),

                          // 密钥
                          TextField(
                            controller: secretController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: '密钥',
                              hintText: '设备的连接密钥',
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              prefixIcon: const Icon(Icons.lock, size: 20),
                            ),
                            onChanged: (_) => checkFormValidity(),
                          ),
                          const SizedBox(height: 20),

                          // 图片选择区域
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '设备图片',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blueGrey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () async {
                                  final ImagePicker _picker = ImagePicker();
                                  final XFile? image = await _picker.pickImage(
                                    source: ImageSource.gallery,
                                  );

                                  if (image != null) {
                                    final file = File(image.path);
                                    final imgBlob = await file.readAsBytes();

                                    setState(() {
                                      selectedImage = imgBlob;
                                      checkFormValidity();
                                    });
                                  }
                                },
                                child: Container(
                                  height: 120,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selectedImage == null
                                          ? Colors.grey.shade300
                                          : Colors.transparent,
                                      width: 1.5,
                                    ),
                                    color: selectedImage == null
                                        ? Colors.grey.shade50
                                        : null,
                                  ),
                                  child: selectedImage == null
                                      ? Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Icon(
                                                Icons.add_photo_alternate,
                                                size: 32,
                                                color: Colors.grey,
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                '点击上传设备图片',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          child: Image.memory(
                                            Uint8List.fromList(selectedImage!),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 操作按钮
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            '取消',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFormValid
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade400,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            elevation: 0,
                          ),
                          onPressed: isFormValid
                              ? () {
                                  Device newDevice = Device(
                                    name: nameController.text,
                                    image: selectedImage!,
                                    identity: identityController.text,
                                    secret: secretController.text,
                                    type: selectedType,
                                    status: DeviceStatus.offline,
                                    lastActive:
                                        DateTime.now().millisecondsSinceEpoch,
                                  );

                                  setState(() {
                                    _devices.add(newDevice);
                                    _filterDevices();
                                  });

                                  _deviceService.addDevice(newDevice);

                                  Navigator.pop(context);
                                }
                              : null,
                          child: const Text(
                            '添加设备',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: screenWidth > 500 ? 500 : screenWidth,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部拖动指示器
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // 设备图片和基本信息
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 设备图片
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 100,
                      height: 100,
                      color: colorScheme.surfaceVariant,
                      child: device.image.isNotEmpty
                          ? Image.memory(
                              Uint8List.fromList(device.image),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildPlaceholderIcon(colorScheme),
                            )
                          : _buildPlaceholderIcon(colorScheme),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '类型: ${device.type}',
                          style: textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              device.status,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getStatusText(device.status),
                            style: TextStyle(
                              color: _getStatusColor(device.status),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // 设备详细信息
              _buildDetailItem(
                icon: Icons.fingerprint,
                label: '设备ID',
                value: device.id,
                context: context,
              ),
              _buildDetailItem(
                icon: Icons.qr_code,
                label: '身份标识',
                value: device.identity,
                context: context,
              ),
              _buildDetailItem(
                icon: Icons.lock,
                label: '密钥',
                value: '••••••••••••',
                context: context,
              ),
              _buildDetailItem(
                icon: Icons.access_time,
                label: '最后活动',
                value: _formatTime(device.lastActive),
                context: context,
              ),
              _buildDetailItem(
                icon: Icons.today,
                label: '创建时间',
                value: _formatTime(device.createdAt),
                context: context,
              ),

              const SizedBox(height: 24),

              // 操作按钮组
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('关闭'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        // 控制设备逻辑
                      },
                      child: const Text('控制设备'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon(ColorScheme colorScheme) {
    return Center(
      child: Icon(
        Icons.device_unknown,
        size: 40,
        color: colorScheme.onSurface.withOpacity(0.3),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required BuildContext context,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(DeviceStatus status) {
    return switch (status) {
      DeviceStatus.online => '在线',
      DeviceStatus.offline => '离线',
      DeviceStatus.warning => '警告',
    };
  }

  Color _getStatusColor(DeviceStatus status) {
    return switch (status) {
      DeviceStatus.online => Colors.green,
      DeviceStatus.offline => Colors.grey,
      DeviceStatus.warning => Colors.orange,
    };
  }

  String _formatTime(int timestamp) {
    final time = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(time);
  }
}
