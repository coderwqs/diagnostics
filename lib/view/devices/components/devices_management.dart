import 'dart:io';
import 'package:diagnosis/l10n/app_localizations.dart';
import 'package:diagnosis/service/devices.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:diagnosis/model/device.dart';

import 'add_device.dart';
import 'device_detail.dart';
import 'edit_device.dart';

class DeviceManagementPage extends StatefulWidget {
  const DeviceManagementPage({super.key});

  @override
  State<DeviceManagementPage> createState() => _DeviceManagementPageState();
}

class _DeviceManagementPageState extends State<DeviceManagementPage> {
  final DeviceService _deviceService = DeviceService();
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
    final devices = await _deviceService.getAllDevices(0, 100);

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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.devices_manage),
        actions: [
          PopupMenuButton<DeviceStatus?>(
            onSelected: _filterByStatus,
            itemBuilder: (context) => [
              PopupMenuItem(value: null, child: Text(l10n.devices_status_all)),
              PopupMenuItem(
                value: DeviceStatus.online,
                child: Text(l10n.devices_status_online),
              ),
              PopupMenuItem(
                value: DeviceStatus.offline,
                child: Text(l10n.devices_status_offline),
              ),
              PopupMenuItem(
                value: DeviceStatus.warning,
                child: Text(l10n.devices_status_warning),
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
          _buildSearchBar(l10n),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredDevices.isEmpty
                ? _buildEmptyState(l10n)
                : _buildDeviceList(l10n),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addDevice(context),
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: l10n.devices_search_tips,
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

  Widget _buildDeviceList(AppLocalizations l10n) {
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
            onToggle: (value) => _toggleDevice(l10n, device, value),
            onEdit: () {
              print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
              _editDevice(context, device);
            },
            onDelete: () {
              _deviceService.deleteDevice(device.id);
              _fetchDevices();
            },
            onEnabled: () {
              _deviceService.updateDeviceStatus(
                device.id,
                DeviceStatus.online.value,
              );
              _fetchDevices();
            },
            onDisabled: () {
              _deviceService.updateDeviceStatus(
                device.id,
                DeviceStatus.offline.value,
              );
              _fetchDevices();
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.devices_other, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
                ? l10n.devices_list_empty
                : l10n.devices_list_not_found,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
          if (_searchController.text.isNotEmpty)
            TextButton(
              onPressed: () => _searchController.clear(),
              child: Text(l10n.app_clear_search),
            ),
        ],
      ),
    );
  }

  void _toggleDevice(AppLocalizations l10n, Device device, bool value) {
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
      SnackBar(
        content: Text(
          '${value ? l10n.devices_start : l10n.devices_stop} ${device.name}',
        ),
      ),
    );
  }

  void _addDevice(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AddDeviceDialog(
          onSubmit: (device) {
            _deviceService.addDevice(device);
            Navigator.pop(dialogContext);
            _fetchDevices();
          },
        );
      },
    );
  }

  void _editDevice(BuildContext context, Device device) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return EditDeviceDialog(
          device: device,
          onSubmit: (newDevice) {
            newDevice.id = device.id;
            _deviceService.updateDevice(newDevice);
            Navigator.pop(dialogContext);
            _fetchDevices();
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
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onEnabled;
  final VoidCallback? onDisabled;

  const DeviceCard({
    super.key,
    required this.device,
    required this.onTap,
    required this.onToggle,
    this.onEdit,
    this.onDelete,
    this.onEnabled,
    this.onDisabled,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(device.status);

    return GestureDetector(
      onSecondaryTapDown: (details) =>
          _showPopupMenu(context, details.globalPosition),
      onLongPress: () => _showPopupMenuAtCenter(context),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: ListTile(
          leading: Container(
            width: 50,
            height: 50,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              shape: BoxShape.circle,
            ),
            child: device.image.isNotEmpty
                ? Image.memory(
                    Uint8List.fromList(device.image),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.sensors, color: Colors.green),
                  )
                : Icon(Icons.sensors, color: Colors.green),
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
                    '${_getStatusText(l10n, device.status)} • ${l10n.devices_last_active}: ${_formatTime(l10n, device.lastActive)}',
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
      ),
    );
  }

  void _showPopupMenu(BuildContext context, Offset position) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final screenSize = MediaQuery.of(context).size;
    final menuWidth = 180.0;
    final menuHeight = 100.0;

    final left = position.dx;
    final top = position.dy;
    final right = left + menuWidth;
    final bottom = top + menuHeight;

    final adjustedLeft = right > screenSize.width
        ? screenSize.width - menuWidth
        : left;
    final adjustedTop = bottom > screenSize.height
        ? screenSize.height - menuHeight
        : top;

    final result = await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        adjustedLeft,
        adjustedTop,
        screenSize.width - adjustedLeft - menuWidth,
        screenSize.height - adjustedTop - menuHeight,
      ),
      items: [
        PopupMenuItem(
          height: 40,
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 20, color: theme.iconTheme.color),
              const SizedBox(width: 12),
              Text(l10n.devices_edit),
            ],
          ),
        ),
        PopupMenuItem(
          height: 40,
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 20, color: Colors.red[400]),
              const SizedBox(width: 12),
              Text(
                l10n.devices_delete,
                style: TextStyle(color: Colors.red[400]),
              ),
            ],
          ),
        ),
        if (device.status == DeviceStatus.offline)
          PopupMenuItem(
            height: 40,
            value: 'enabled',
            child: Row(
              children: [
                Icon(
                  Icons.desktop_windows_outlined,
                  size: 20,
                  color: Colors.green[400],
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.devices_enabled,
                  style: TextStyle(color: Colors.green[400]),
                ),
              ],
            ),
          ),
        if (device.status == DeviceStatus.online)
          PopupMenuItem(
            height: 40,
            value: 'disabled',
            child: Row(
              children: [
                Icon(
                  Icons.desktop_access_disabled,
                  size: 20,
                  color: Colors.red[400],
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.devices_disabled,
                  style: TextStyle(color: Colors.red[400]),
                ),
              ],
            ),
          ),
      ],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2), width: 1),
      ),
    );

    switch (result) {
      case 'edit':
        onEdit?.call();
        break;
      case 'delete':
        onDelete?.call();
        break;
      case 'enabled':
        onEnabled?.call();
        break;
      case 'disabled':
        onDisabled?.call();
        break;
    }
  }

  void _showPopupMenuAtCenter(BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final center =
        position + Offset(renderBox.size.width / 2, renderBox.size.height / 2);
    _showPopupMenu(context, center);
  }

  Color _getStatusColor(DeviceStatus status) {
    return switch (status) {
      DeviceStatus.online => Colors.green,
      DeviceStatus.offline => Colors.grey,
      DeviceStatus.warning => Colors.orange,
    };
  }

  String _getStatusText(AppLocalizations l10n, DeviceStatus status) {
    return switch (status) {
      DeviceStatus.online => l10n.devices_status_online,
      DeviceStatus.offline => l10n.devices_status_offline,
      DeviceStatus.warning => l10n.devices_status_warning,
    };
  }

  String _formatTime(AppLocalizations l10n, int timestamp) {
    final time = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) return l10n.app_just_now;
    if (diff.inMinutes < 60)
      return '${diff.inMinutes}${l10n.app_minute_ago}';
    if (diff.inHours < 24) return '${diff.inHours}${l10n.app_hour_ago}';
    return '${diff.inDays}${l10n.app_day_ago}';
  }
}
