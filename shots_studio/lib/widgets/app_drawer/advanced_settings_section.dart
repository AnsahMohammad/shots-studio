import 'package:flutter/material.dart';
import 'package:shots_studio/models/collection_model.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/widgets/backup_and_restore.dart';
import 'package:shots_studio/widgets/app_drawer/advanced_settings/index.dart';
import '../../l10n/app_localizations.dart';

/// The advanced settings section of the app drawer.
///
/// This section contains various advanced configuration options including:
/// - Performance Menu (navigation to performance monitor)
/// - Max Parallel AI Processes (slider)
/// - Analytics & Telemetry toggle
/// - Server Messages toggle
/// - Beta Testing toggle
/// - XMP Settings (disabled)
/// - Backup & Restore card
/// - Action buttons (Reset AI, Clear Corrupt Files)
class AdvancedSettingsSection extends StatelessWidget {
  final int currentLimit;
  final Function(int) onLimitChanged;
  final int currentMaxParallel;
  final Function(int) onMaxParallelChanged;
  final bool? currentDevMode;
  final Function(bool)? onDevModeChanged;
  final bool? currentAnalyticsEnabled;
  final Function(bool)? onAnalyticsEnabledChanged;
  final bool? currentServerMessagesEnabled;
  final Function(bool)? onServerMessagesEnabledChanged;
  final bool? currentBetaTestingEnabled;
  final Function(bool)? onBetaTestingEnabledChanged;
  final VoidCallback? onResetAiProcessing;
  final List<Screenshot>? allScreenshots;
  final VoidCallback? onClearCorruptFiles;
  final List<Collection>? allCollections;
  final Function(List<Screenshot>, List<Collection>)? onDataRestored;

  const AdvancedSettingsSection({
    super.key,
    required this.currentLimit,
    required this.onLimitChanged,
    required this.currentMaxParallel,
    required this.onMaxParallelChanged,
    this.currentDevMode,
    this.onDevModeChanged,
    this.currentAnalyticsEnabled,
    this.onAnalyticsEnabledChanged,
    this.currentServerMessagesEnabled,
    this.onServerMessagesEnabledChanged,
    this.currentBetaTestingEnabled,
    this.onBetaTestingEnabledChanged,
    this.onResetAiProcessing,
    this.allScreenshots,
    this.onClearCorruptFiles,
    this.allCollections,
    this.onDataRestored,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: theme.colorScheme.outline),
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            AppLocalizations.of(context)?.advancedSettings ??
                'Advanced Settings',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Max Parallel AI Processes
        MaxParallelTile(
          currentMaxParallel: currentMaxParallel,
          onMaxParallelChanged: onMaxParallelChanged,
        ),
        // Analytics & Telemetry Toggle
        AnalyticsToggle(
          currentAnalyticsEnabled: currentAnalyticsEnabled,
          onAnalyticsEnabledChanged: onAnalyticsEnabledChanged,
        ),
        // Server Messages Toggle
        ServerMessagesToggle(
          currentServerMessagesEnabled: currentServerMessagesEnabled,
          onServerMessagesEnabledChanged: onServerMessagesEnabledChanged,
        ),
        // Beta Testing Toggle
        BetaTestingToggle(
          currentBetaTestingEnabled: currentBetaTestingEnabled,
          onBetaTestingEnabledChanged: onBetaTestingEnabledChanged,
        ),
        // XMP Settings (disabled)
        const XmpSettingsTile(),
        // Performance Menu
        const PerformanceMenuTile(),
        // Data Management Card (Backup & Restore)
        BackupRestoreCard(
          allScreenshots: allScreenshots,
          allCollections: allCollections,
          onDataRestored: onDataRestored,
        ),
        // Action Buttons (Reset AI Processing, Clear Corrupt Files)
        ActionButtons(
          onResetAiProcessing: onResetAiProcessing,
          allScreenshots: allScreenshots,
          onClearCorruptFiles: onClearCorruptFiles,
        ),
      ],
    );
  }
}
