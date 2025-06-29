import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'appearance_settings_page.dart';
import 'personalization_settings_page.dart';
import 'synchronization_settings_page.dart';
import 'notifications_settings_page.dart';
import 'advanced_settings_page.dart';
import 'biometric_settings_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(S.of(context).settings),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(height: 12),
          _buildSectionHeader(
              context, S.of(context).settingsCategory, CupertinoIcons.gear),
          _buildSettingsSection(
            context,
            children: [
              _buildSettingsItem(
                context,
                icon: CupertinoIcons.color_filter,
                color: Colors.lime,
                title: S.of(context).appearance,
                onTap: () => _navigateTo(context, AppearanceSettingsPage()),
                isFirst: true,
              ),
              _buildSettingsItem(
                context,
                icon: CupertinoIcons.slider_horizontal_3,
                color: Colors.green,
                title: S.of(context).personalization,
                onTap: () =>
                    _navigateTo(context, PersonalizationSettingsPage()),
              ),
              _buildSettingsItem(
                context,
                icon: CupertinoIcons.arrow_2_circlepath,
                color: Colors.blue,
                title: S.of(context).synchronization,
                onTap: () =>
                    _navigateTo(context, SynchronizationSettingsPage()),
              ),
              _buildSettingsItem(
                context,
                icon: CupertinoIcons.bell,
                color: Colors.orange,
                title: S.of(context).notifications,
                onTap: () => _navigateTo(context, NotificationsSettingsPage()),
              ),
              _buildSettingsItem(
                context,
                icon: CupertinoIcons.lock_shield,
                color: Colors.red,
                title: S.of(context).security,
                onTap: () => _navigateTo(context, BiometricSettingsPage()),
              ),
              _buildSettingsItem(
                context,
                icon: CupertinoIcons.wrench,
                color: Colors.purple,
                title: S.of(context).advanced,
                onTap: () => _navigateTo(context, AdvancedSettingsPage()),
                isLast: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 6, top: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context,
      {required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final appState = Provider.of<AppState>(context);
    final borderRadius = BorderRadius.vertical(
      top: isFirst ? const Radius.circular(10) : Radius.zero,
      bottom: isLast ? const Radius.circular(10) : Radius.zero,
    );

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: borderRadius,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.0 + appState.getTextSizeOffset(),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const Icon(CupertinoIcons.chevron_right,
                    size: 14, color: Colors.grey),
              ],
            ),
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 46),
            child: Divider(
                height: 1,
                thickness: 0.5,
                color: Colors.grey.withValues(alpha: 0.3)),
          ),
      ],
    );
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.of(context).push(
      CupertinoPageRoute(builder: (context) => page),
    );
  }
}
