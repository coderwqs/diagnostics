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
        onPressed: () => _addNewDevice(context),
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

  void _addNewDevice(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AddDeviceDialog(
          onSubmit: (device) {
            _deviceService.addDevice(device);
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

  const DeviceCard({
    super.key,
    required this.device,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
    );
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

    if (diff.inSeconds < 60) return l10n.devices_just_now;
    if (diff.inMinutes < 60)
      return '${diff.inMinutes}${l10n.devices_minute_ago}';
    if (diff.inHours < 24) return '${diff.inHours}${l10n.devices_hour_ago}';
    return '${diff.inDays}${l10n.devices_day_ago}';
  }
}
