import 'package:diagnosis/main.dart';
import 'package:flutter/material.dart';
import 'package:diagnosis/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SystemSettingsPage extends StatefulWidget {
  const SystemSettingsPage({super.key});

  @override
  State<SystemSettingsPage> createState() => _SystemSettingsStatePage();
}

class _SystemSettingsStatePage extends State<SystemSettingsPage> {
  String _appName = '';
  String _version = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _getAppInfo();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.settings,
          // '系统设置',
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
              title: l10n.settings_group_personalized,
              children: [
                _buildLanguageSettingsItem(context),
                _buildSettingsItem(
                  context,
                  icon: Icons.notifications,
                  title: l10n.settings_notification,
                  subtitle: l10n.settings_manage_notification,
                  iconColor: Colors.orange,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSettingsSection(
              context,
              title: l10n.settings_group_accounts,
              children: [
                _buildSettingsItem(
                  context,
                  icon: Icons.account_circle,
                  title: l10n.settings_account,
                  subtitle: l10n.settings_manage_account,
                  iconColor: Colors.purple,
                  onTap: () {},
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.privacy_tip,
                  title: l10n.settings_privacy,
                  subtitle: l10n.settings_manage_privacy,
                  iconColor: Colors.green,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSettingsSection(
              context,
              title: l10n.settings_group_about,
              children: [
                _buildSettingsItem(
                  context,
                  icon: Icons.info,
                  title: l10n.settings_version,
                  subtitle: l10n.settings_view_version,
                  iconColor: Colors.grey,
                  onTap: () {
                    showAboutDialog(context);
                  },
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
              color: Colors.grey.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          elevation: 1,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
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
                color: iconColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: iconColor),
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
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  void _showLanguageSelectionDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLanguageCode = Localizations.localeOf(context).languageCode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settings_select_language),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile(
                value: 'zh',
                groupValue: currentLanguageCode,
                title: Text(
                  l10n.settings_language_chinese,
                ),
                onChanged: (value) => _changeLanguage(context, 'zh'),
              ),
              RadioListTile(
                value: 'en',
                groupValue: currentLanguageCode,
                title: Text(
                  l10n.settings_language_english,
                ),
                onChanged: (value) => _changeLanguage(context, 'en'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.app_cancel),
          ),
        ],
      ),
    );
  }

  Future<void> _getAppInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    setState(() {
      _appName = packageInfo.appName;
      _version = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
    });
  }

  void showAboutDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 48, color: colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                l10n.settings_about_app,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              _buildInfoRow(Icons.apps, l10n.settings_app_name, _appName),
              _buildInfoRow(Icons.tag, l10n.settings_app_version, _version),
              _buildInfoRow(Icons.build, l10n.settings_app_build, _buildNumber),
              const SizedBox(height: 16),
              _buildInfoRow(Icons.person, l10n.settings_app_developer, 'coderwqs'),
              _buildInfoRow(Icons.email, l10n.settings_app_connect, 'coderwqs@qq.com'),
              const SizedBox(height: 20),
              Text(
                l10n.settings_about_tips,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('关闭'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildLanguageSettingsItem(BuildContext context) {
    final currentLanguageCode = Localizations.localeOf(context).languageCode;
    final languageName = {
      'zh': AppLocalizations.of(context)!.settings_language_chinese,
      'en': AppLocalizations.of(context)!.settings_language_english,
    }[currentLanguageCode]!;

    return _buildSettingsItem(
      context,
      icon: Icons.language,
      title: AppLocalizations.of(context)!.settings_language,
      subtitle: AppLocalizations.of(
        context,
      )!.settings_current_language(languageName),
      iconColor: Colors.blue,
      onTap: () => _showLanguageSelectionDialog(context),
    );
  }

  void _changeLanguage(BuildContext context, String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode);

    // 重建MaterialApp
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => DiagnosticsApp(locale: Locale(languageCode)),
      ),
      (route) => false,
    );
  }
}
