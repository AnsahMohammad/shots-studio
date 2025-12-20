import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';
import 'package:shots_studio/l10n/app_localizations.dart';

/// A toggle switch for enabling/disabling server messages.
class ServerMessagesToggle extends StatefulWidget {
  final bool? currentServerMessagesEnabled;
  final Function(bool)? onServerMessagesEnabledChanged;

  const ServerMessagesToggle({
    super.key,
    this.currentServerMessagesEnabled,
    this.onServerMessagesEnabledChanged,
  });

  @override
  State<ServerMessagesToggle> createState() => _ServerMessagesToggleState();
}

class _ServerMessagesToggleState extends State<ServerMessagesToggle> {
  bool _serverMessagesEnabled = true;

  static const String _serverMessagesPrefKey = 'server_messages_enabled';

  @override
  void initState() {
    super.initState();
    if (widget.currentServerMessagesEnabled != null) {
      _serverMessagesEnabled = widget.currentServerMessagesEnabled!;
    } else {
      _loadServerMessagesEnabledPref();
    }
  }

  Future<void> _loadServerMessagesEnabledPref() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _serverMessagesEnabled = prefs.getBool(_serverMessagesPrefKey) ?? true;
    });
  }

  @override
  void didUpdateWidget(covariant ServerMessagesToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentServerMessagesEnabled !=
            oldWidget.currentServerMessagesEnabled &&
        widget.currentServerMessagesEnabled != null) {
      _serverMessagesEnabled = widget.currentServerMessagesEnabled!;
    }
  }

  Future<void> _saveServerMessagesEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_serverMessagesPrefKey, value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SwitchListTile(
      secondary: Icon(
        Icons.notifications_outlined,
        color: theme.colorScheme.primary,
      ),
      title: Text(
        AppLocalizations.of(context)?.serverMessages ?? 'Server Messages',
        style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
      ),
      subtitle: Text(
        _serverMessagesEnabled
            ? 'Receive important updates and notifications'
            : 'Server messages and notifications disabled',
        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
      ),
      value: _serverMessagesEnabled,
      activeThumbColor: theme.colorScheme.primary,
      onChanged: (bool value) {
        setState(() {
          _serverMessagesEnabled = value;
        });
        _saveServerMessagesEnabled(value);

        // Track analytics for server messages setting
        AnalyticsService().logFeatureUsed(
          'settings_server_messages_${value ? 'enabled' : 'disabled'}',
        );

        if (widget.onServerMessagesEnabledChanged != null) {
          widget.onServerMessagesEnabledChanged!(value);
        }
      },
    );
  }
}
