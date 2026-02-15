import 'package:flutter/material.dart';
import 'package:shots_studio/widgets/app_drawer/settings_section.dart';
import 'package:shots_studio/widgets/app_drawer/advanced_settings_section.dart';
import 'package:shots_studio/l10n/app_localizations.dart';
import 'package:shots_studio/models/collection_model.dart';
import 'package:shots_studio/models/screenshot_model.dart';

class SettingsScreen extends StatefulWidget {
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

  const SettingsScreen({
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
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool? _currentDevMode;
  int _currentMaxParallel = 4;
  int _currentLimit = 100;

  @override
  void initState() {
    super.initState();
    _currentDevMode = widget.currentDevMode;
    _currentMaxParallel = widget.currentMaxParallel;
    _currentLimit = widget.currentLimit;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.settings ?? 'Settings'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: Container(
        color: theme.scaffoldBackgroundColor,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          children: [
            SettingsSection(
              currentModelName: widget.currentModelName,
              onModelChanged: widget.onModelChanged,
              currentAutoProcessEnabled: widget.currentAutoProcessEnabled,
              onAutoProcessEnabledChanged: widget.onAutoProcessEnabledChanged,
              currentAmoledModeEnabled: widget.currentAmoledModeEnabled,
              onAmoledModeChanged: widget.onAmoledModeChanged,
              currentSelectedTheme: widget.currentSelectedTheme,
              onThemeChanged: widget.onThemeChanged,
              currentDevMode: _currentDevMode,
              onDevModeChanged: (bool value) {
                setState(() {
                  _currentDevMode = value;
                });
                if (widget.onDevModeChanged != null) {
                  widget.onDevModeChanged!(value);
                }
              },
              currentHardDeleteEnabled: widget.currentHardDeleteEnabled,
              onHardDeleteChanged: widget.onHardDeleteChanged,
              onLocaleChanged: widget.onLocaleChanged,
            ),
            if (_currentDevMode == true) ...[
              AdvancedSettingsSection(
                currentLimit: _currentLimit,
                onLimitChanged: (int value) {
                  setState(() {
                    _currentLimit = value;
                  });
                  widget.onLimitChanged(value);
                },
                currentMaxParallel: _currentMaxParallel,
                onMaxParallelChanged: (int value) {
                  setState(() {
                    _currentMaxParallel = value;
                  });
                  widget.onMaxParallelChanged(value);
                },
                currentDevMode: _currentDevMode,
                onDevModeChanged: (bool value) {
                  setState(() {
                    _currentDevMode = value;
                  });
                  if (widget.onDevModeChanged != null) {
                    widget.onDevModeChanged!(value);
                  }
                },
                currentAnalyticsEnabled: widget.currentAnalyticsEnabled,
                onAnalyticsEnabledChanged: widget.onAnalyticsEnabledChanged,
                currentServerMessagesEnabled:
                    widget.currentServerMessagesEnabled,
                onServerMessagesEnabledChanged:
                    widget.onServerMessagesEnabledChanged,
                currentBetaTestingEnabled: widget.currentBetaTestingEnabled,
                onBetaTestingEnabledChanged: widget.onBetaTestingEnabledChanged,
                onResetAiProcessing: widget.onResetAiProcessing,
                allScreenshots: widget.allScreenshots,
                onClearCorruptFiles: widget.onClearCorruptFiles,
                allCollections: widget.allCollections,
                onDataRestored: widget.onDataRestored,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
