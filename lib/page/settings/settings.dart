import 'package:flutter/material.dart';

class SystemSettingsPage extends StatelessWidget {
  const SystemSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '系统设置',
          style: textTheme.headlineSmall?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.blue.shade50.withValues(alpha: 0.2),
        iconTheme: IconThemeData(color: Colors.grey.shade700),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50.withValues(alpha: 0.3), Colors.white],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSettingsSection(
              context,
              title: "个性化设置",
              children: [
                _buildSettingsItem(
                  context,
                  icon: Icons.language,
                  title: "语言设置",
                  subtitle: "选择应用语言",
                  iconColor: Colors.blue, // 保持原有图标色
                  onTap: () {},
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.notifications,
                  title: "通知设置",
                  subtitle: "管理通知选项",
                  iconColor: Colors.orange, // 保持原有图标色
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSettingsSection(
              context,
              title: "账户与隐私",
              children: [
                _buildSettingsItem(
                  context,
                  icon: Icons.account_circle,
                  title: "账户管理",
                  subtitle: "管理用户账户",
                  iconColor: Colors.purple, // 保持原有图标色
                  onTap: () {},
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.privacy_tip,
                  title: "隐私设置",
                  subtitle: "管理隐私选项",
                  iconColor: Colors.green, // 保持原有图标色
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSettingsSection(
              context,
              title: "关于",
              children: [
                _buildSettingsItem(
                  context,
                  icon: Icons.info,
                  title: "版本信息",
                  subtitle: "查看应用版本",
                  iconColor: Colors.grey, // 保持原有图标色
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(
      BuildContext context, {
        required String title,
        required List<Widget> children,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.grey.shade700, // 保持原有文字颜色
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          elevation: 1,
          color: Colors.white, // 卡片背景保持白色
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Color iconColor, // 原有图标颜色参数
        required VoidCallback onTap,
      }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.2), // 保持原有图标背景透明度
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: iconColor), // 保持原有图标颜色
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Colors.black87, // 保持原有标题颜色
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600, // 保持原有副标题颜色
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400, // 保持原有箭头颜色
            ),
          ],
        ),
      ),
    );
  }
}