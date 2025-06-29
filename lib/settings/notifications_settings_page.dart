import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/utils/preference_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsSettingsPage extends StatefulWidget {
  const NotificationsSettingsPage({super.key});

  @override
  _NotificationsSettingsPageState createState() => _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage> {
  bool _notificationsEnabled = true;
  bool _hasRefusedNotifications = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationStatus();
  }

  Future<void> _loadNotificationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    bool isSubscribed = OneSignal.User.pushSubscription.optedIn ?? false;
    bool hasRefused = prefs.getBool(PreferenceKeys.hasRefusedNotifications) ?? false;
    
    setState(() {
      _notificationsEnabled = isSubscribed;
      _hasRefusedNotifications = hasRefused;
    });
  }

  Future<void> _toggleNotificationStatus(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });

    if (value) {
      OneSignal.User.pushSubscription.optIn();
      // Réinitialiser le flag de refus si l'utilisateur active les notifications
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(PreferenceKeys.hasRefusedNotifications, false);
      setState(() {
        _hasRefusedNotifications = false;
      });
    } else {
      OneSignal.User.pushSubscription.optOut();
    }
  }

  Future<void> _resetNotificationChoice() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PreferenceKeys.hasRefusedNotifications, false);
    await prefs.setBool(PreferenceKeys.hasAskedNotifications, false);
    
    setState(() {
      _hasRefusedNotifications = false;
    });

    // Redemander la permission
    final hasPermission = await OneSignal.Notifications.requestPermission(true);
    await prefs.setBool(PreferenceKeys.hasAskedNotifications, true);
    
    if (hasPermission) {
      setState(() {
        _notificationsEnabled = true;
      });
      debugPrint("✅ Permissions de notifications accordées après réinitialisation");
    } else {
      await prefs.setBool(PreferenceKeys.hasRefusedNotifications, true);
      setState(() {
        _hasRefusedNotifications = true;
      });
      debugPrint("🚫 Permissions de notifications refusées après réinitialisation");
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(S.of(context).notifications),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(height: 12),
          _buildSectionHeader(context, "Notifications", CupertinoIcons.bell),
          _buildSettingsSection(
            context,
            children: [
              _buildSwitchItem(
                context,
                title: 'Activer les notifications',
                value: _notificationsEnabled,
                onChanged: _toggleNotificationStatus,
                isFirst: true,
                isLast: !_hasRefusedNotifications,
              ),
              if (_hasRefusedNotifications)
                _buildActionItem(
                  context,
                  title: 'Redemander l\'autorisation',
                  subtitle: 'Vous avez refusé les notifications au démarrage',
                  icon: CupertinoIcons.refresh,
                  onTap: _resetNotificationChoice,
                  isLast: true,
                ),
            ],
          ),
          if (_hasRefusedNotifications) ...[
            const SizedBox(height: 12),
            _buildInfoCard(context),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
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

  Widget _buildSettingsSection(
    BuildContext context, {
    required List<Widget> children,
  }) {
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

  Widget _buildSwitchItem(
    BuildContext context, {
    required String title,
    String? subtitle,
    required bool value,
    required Function(bool) onChanged,
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: borderRadius,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15.0 + appState.getTextSizeOffset(),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12.0 + appState.getTextSizeOffset(),
                            color: Colors.grey,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Transform.scale(
                scale: 0.8,
                child: CupertinoSwitch(
                  value: value,
                  onChanged: onChanged,
                  activeTrackColor: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.info_circle, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                'Notifications désactivées',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Vous avez refusé les notifications lors du premier démarrage. Utilisez le bouton ci-dessus pour redemander l\'autorisation si vous changez d\'avis.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: !isLast ? Colors.grey.withValues(alpha: 0.2) : Colors.transparent,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 24,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
