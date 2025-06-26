import 'package:diagnosis/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:diagnosis/model/device.dart';

class DeviceDetailSheet extends StatelessWidget {
  final Device device;

  const DeviceDetailSheet({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
                    color: colorScheme.onSurface.withValues(alpha: 0.1),
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
                          '${l10n.devices_type}: ${device.type.displayName(context)}',
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
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getStatusText(l10n, device.status),
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
                label: l10n.devices_id,
                value: device.id,
                context: context,
              ),
              _buildDetailItem(
                icon: Icons.qr_code,
                label: l10n.devices_identity,
                value: device.identity,
                context: context,
              ),
              _buildDetailItem(
                icon: Icons.lock,
                label: l10n.devices_secret,
                value: '••••••••••••',
                context: context,
              ),
              _buildDetailItem(
                icon: Icons.access_time,
                label: l10n.devices_last_active,
                value: _formatTime(device.lastActive),
                context: context,
              ),
              _buildDetailItem(
                icon: Icons.today,
                label: l10n.app_created_at,
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
                      child: Text(l10n.app_close),
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
                      child: Text(l10n.devices_control),
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
        color: colorScheme.onSurface.withValues(alpha: 0.3),
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
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
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

  String _getStatusText(AppLocalizations l10n, DeviceStatus status) {
    return switch (status) {
      DeviceStatus.online => l10n.devices_status_online,
      DeviceStatus.offline => l10n.devices_status_offline,
      DeviceStatus.warning => l10n.devices_status_warning,
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