import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shots_studio/widgets/app_drawer/index.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';
import 'package:shots_studio/services/snackbar_service.dart';
import 'package:shots_studio/l10n/app_localizations.dart';
import 'package:shots_studio/models/collection_model.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/screens/settings_screen.dart';

class AppDrawer extends StatefulWidget {
  final String currentModelName;
  final Function(String) onModelChanged;
  final int currentLimit;
  final Function(int) onLimitChanged;
  final int currentMaxParallel;
  final Function(int) onMaxParallelChanged;
  final bool? currentDevMode;
  final Function(bool)? onDevModeChanged;
  final bool? currentAutoProcessEnabled;
  final Function(bool)? onAutoProcessEnabledChanged;
  final bool? currentAnalyticsEnabled;
  final Function(bool)? onAnalyticsEnabledChanged;
  final bool? currentServerMessagesEnabled;
  final Function(bool)? onServerMessagesEnabledChanged;
  final bool? currentBetaTestingEnabled;
  final Function(bool)? onBetaTestingEnabledChanged;
  final bool? currentAmoledModeEnabled;
  final Function(bool)? onAmoledModeChanged;
  final String? currentSelectedTheme;
  final Function(String)? onThemeChanged;
  final bool? currentHardDeleteEnabled;
  final Function(bool)? onHardDeleteChanged;
  final VoidCallback? onResetAiProcessing;
  final Function(Locale)? onLocaleChanged;
  final List<Screenshot>? allScreenshots;
  final VoidCallback? onClearCorruptFiles;
  final List<Collection>? allCollections;
  final Function(List<Screenshot>, List<Collection>)? onDataRestored;

  const AppDrawer({
    super.key,
    required this.currentModelName,
    required this.onModelChanged,
    required this.currentLimit,
    required this.onLimitChanged,
    required this.currentMaxParallel,
    required this.onMaxParallelChanged,
    this.currentDevMode,
    this.onDevModeChanged,
    this.currentAutoProcessEnabled,
    this.onAutoProcessEnabledChanged,
    this.currentAnalyticsEnabled,
    this.onAnalyticsEnabledChanged,
    this.currentServerMessagesEnabled,
    this.onServerMessagesEnabledChanged,
    this.currentBetaTestingEnabled,
    this.onBetaTestingEnabledChanged,
    this.currentAmoledModeEnabled,
    this.onAmoledModeChanged,
    this.currentSelectedTheme,
    this.onThemeChanged,
    this.currentHardDeleteEnabled,
    this.onHardDeleteChanged,
    this.onResetAiProcessing,
    this.onLocaleChanged,
    this.allScreenshots,
    this.onClearCorruptFiles,
    this.allCollections,
    this.onDataRestored,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String _appVersion = '...';

  @override
  void initState() {
    super.initState();

    // Log analytics for app drawer view
    AnalyticsService().logScreenView('app_drawer_screen');
    AnalyticsService().logFeatureUsed('app_drawer');

    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
    });
  }

  void _navigateToSettings() {
    // Track analytics for settings navigation
    AnalyticsService().logFeatureUsed('settings_navigation');
    AnalyticsService().logScreenView('settings_screen');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => SettingsScreen(
              currentModelName: widget.currentModelName,
              onModelChanged: widget.onModelChanged,
              currentLimit: widget.currentLimit,
              onLimitChanged: widget.onLimitChanged,
              currentMaxParallel: widget.currentMaxParallel,
              onMaxParallelChanged: widget.onMaxParallelChanged,
              currentDevMode: widget.currentDevMode,
              onDevModeChanged: widget.onDevModeChanged,
              currentAutoProcessEnabled: widget.currentAutoProcessEnabled,
              onAutoProcessEnabledChanged: widget.onAutoProcessEnabledChanged,
              currentAnalyticsEnabled: widget.currentAnalyticsEnabled,
              onAnalyticsEnabledChanged: widget.onAnalyticsEnabledChanged,
              currentServerMessagesEnabled: widget.currentServerMessagesEnabled,
              onServerMessagesEnabledChanged:
                  widget.onServerMessagesEnabledChanged,
              currentBetaTestingEnabled: widget.currentBetaTestingEnabled,
              onBetaTestingEnabledChanged: widget.onBetaTestingEnabledChanged,
              currentAmoledModeEnabled: widget.currentAmoledModeEnabled,
              onAmoledModeChanged: widget.onAmoledModeChanged,
              currentSelectedTheme: widget.currentSelectedTheme,
              onThemeChanged: widget.onThemeChanged,
              currentHardDeleteEnabled: widget.currentHardDeleteEnabled,
              onHardDeleteChanged: widget.onHardDeleteChanged,
              onResetAiProcessing: widget.onResetAiProcessing,
              onLocaleChanged: widget.onLocaleChanged,
              allScreenshots: widget.allScreenshots,
              onClearCorruptFiles: widget.onClearCorruptFiles,
              allCollections: widget.allCollections,
              onDataRestored: widget.onDataRestored,
            ),
      ),
    );
  }

  void _handleAboutTap() {
    // No longer needed - developer mode is now always accessible
  }

  void _handleAboutLongPress() {
    if (widget.currentDevMode == true) {
      if (widget.onDevModeChanged != null) {
        widget.onDevModeChanged!(false);
        SnackbarService().showInfo(
          context,
          AppLocalizations.of(context)?.developerModeDisabled ??
              'Advanced settings disabled',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: Container(
        color: theme.scaffoldBackgroundColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const AppDrawerHeader(),
            QuickSettingsSection(
              currentModelName: widget.currentModelName,
              onModelChanged: widget.onModelChanged,
            ),
            ListTile(
              leading: Icon(Icons.settings, color: theme.colorScheme.primary),
              title: Text(
                AppLocalizations.of(context)?.settings ?? 'Settings',
                style: TextStyle(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Manage app preferences and settings',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              onTap: _navigateToSettings,
            ),
            AboutSection(
              appVersion: _appVersion,
              onTap: _handleAboutTap,
              onLongPress: _handleAboutLongPress,
            ),
            const PrivacySection(),
          ],
        ),
      ),
    );
  }
}
