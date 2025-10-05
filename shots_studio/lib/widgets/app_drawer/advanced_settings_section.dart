import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';
import 'package:shots_studio/services/corrupt_file_service.dart';
import 'package:shots_studio/services/xmp_metadata_service.dart';
import 'package:shots_studio/models/screenshot_model.dart';
// import 'package:shots_studio/screens/debug_notifications_screen.dart'; // Uncomment for debugging
import '../../l10n/app_localizations.dart';

class AdvancedSettingsSection extends StatefulWidget {
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
  });

  @override
  State<AdvancedSettingsSection> createState() =>
      _AdvancedSettingsSectionState();
}

class _AdvancedSettingsSectionState extends State<AdvancedSettingsSection> {
  bool _analyticsEnabled =
      !kDebugMode; // Default to false in debug mode, true in production
  bool _serverMessagesEnabled = true;
  bool _betaTestingEnabled = false;
  bool _xmpWritingEnabled = false;

  static const String _maxParallelPrefKey = 'maxParallel';
  static const String _serverMessagesPrefKey = 'server_messages_enabled';
  static const String _betaTestingPrefKey = 'beta_testing_enabled';
  static const String _xmpWritingPrefKey = 'xmp_writing_enabled';

  @override
  void initState() {
    super.initState();

    // Initialize analytics consent state
    if (widget.currentAnalyticsEnabled != null) {
      _analyticsEnabled = widget.currentAnalyticsEnabled!;
    } else {
      _loadAnalyticsEnabledPref();
    }

    // Initialize server messages state
    if (widget.currentServerMessagesEnabled != null) {
      _serverMessagesEnabled = widget.currentServerMessagesEnabled!;
    } else {
      _loadServerMessagesEnabledPref();
    }

    // Initialize beta testing state
    if (widget.currentBetaTestingEnabled != null) {
      _betaTestingEnabled = widget.currentBetaTestingEnabled!;
    } else {
      _loadBetaTestingEnabledPref();
    }

    // Initialize XMP writing state
    _loadXMPWritingEnabledPref();
  }

  void _loadAnalyticsEnabledPref() async {
    final analyticsService = AnalyticsService();
    setState(() {
      _analyticsEnabled = analyticsService.analyticsEnabled;
    });
  }

  Future<void> _loadServerMessagesEnabledPref() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _serverMessagesEnabled = prefs.getBool(_serverMessagesPrefKey) ?? true;
    });
  }

  Future<void> _loadBetaTestingEnabledPref() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _betaTestingEnabled = prefs.getBool(_betaTestingPrefKey) ?? false;
    });
  }

  Future<void> _loadXMPWritingEnabledPref() async {
    final enabled = await XMPMetadataService.isXMPWritingEnabled();
    setState(() {
      _xmpWritingEnabled = enabled;
    });
  }

  @override
  void didUpdateWidget(covariant AdvancedSettingsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentAnalyticsEnabled != oldWidget.currentAnalyticsEnabled &&
        widget.currentAnalyticsEnabled != null) {
      _analyticsEnabled = widget.currentAnalyticsEnabled!;
    }
    if (widget.currentServerMessagesEnabled !=
            oldWidget.currentServerMessagesEnabled &&
        widget.currentServerMessagesEnabled != null) {
      _serverMessagesEnabled = widget.currentServerMessagesEnabled!;
    }
    if (widget.currentBetaTestingEnabled !=
            oldWidget.currentBetaTestingEnabled &&
        widget.currentBetaTestingEnabled != null) {
      _betaTestingEnabled = widget.currentBetaTestingEnabled!;
    }
  }

  Future<void> _saveMaxParallel(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_maxParallelPrefKey, value);
  }

  Future<void> _saveAnalyticsEnabled(bool value) async {
    final analyticsService = AnalyticsService();
    if (value) {
      await analyticsService.enableAnalytics();
    } else {
      await analyticsService.disableAnalytics();
    }
  }

  Future<void> _saveServerMessagesEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_serverMessagesPrefKey, value);
  }

  Future<void> _saveBetaTestingEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_betaTestingPrefKey, value);
  }

  Future<void> _saveXMPWritingEnabled(bool value) async {
    await XMPMetadataService.setXMPWritingEnabled(value);
  }

  /// Clear all corrupt files from the app using the CorruptFileService
  Future<void> _clearCorruptFiles() async {
    await CorruptFileService.clearCorruptFiles(
      context,
      widget.allScreenshots,
      widget.onClearCorruptFiles,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: theme.colorScheme.outline),
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
        ListTile(
          leading: Icon(Icons.sync_alt, color: theme.colorScheme.primary),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  AppLocalizations.of(context)?.maxParallelAI ??
                      'Max Parallel AI Processes',
                  style: TextStyle(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.help_outline,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Text(
                            'Max Parallel AI Processes',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          content: Text(
                            'Controls the maximum number of images sent in one AI request.\n\n'
                            '• Default: 4 (recommended for most users)\n'
                            '• Maximum: 8 (recommended for faster processing)\n'
                            '• Higher values require more internet bandwidth\n'
                            '• Gemma AI only supports 1 image regardless of this setting\n'
                            '• Adjust based on your internet connection speed',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                'Got it',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                  );
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${widget.currentMaxParallel}',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Controls parallel image processing. Higher values need more bandwidth. '
                'Default: 4. \nNote: Gemma only supports 1 image.',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '1',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  Expanded(
                    child: Slider(
                      value: widget.currentMaxParallel.toDouble(),
                      min: 1,
                      max: 8,
                      divisions: 7,
                      label: widget.currentMaxParallel.toString(),
                      activeColor: theme.colorScheme.primary,
                      onChanged: (value) {
                        final intValue = value.round();
                        widget.onMaxParallelChanged(intValue);
                        _saveMaxParallel(intValue);

                        // Track analytics for max parallel processes change
                        AnalyticsService().logFeatureUsed(
                          'settings_max_parallel_changed',
                        );
                      },
                    ),
                  ),
                  Text(
                    '8',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
        SwitchListTile(
          secondary: Icon(
            Icons.analytics_outlined,
            color: theme.colorScheme.primary,
          ),
          title: Text(
            AppLocalizations.of(context)?.analyticsAndTelemetry ??
                'Analytics & Telemetry',
            style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
          ),
          subtitle: Text(
            _analyticsEnabled
                ? 'Help improve the app by sharing usage data'
                : 'Analytics and crash reporting disabled',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          value: _analyticsEnabled,
          activeThumbColor: theme.colorScheme.primary,
          onChanged: (bool value) {
            setState(() {
              _analyticsEnabled = value;
            });
            _saveAnalyticsEnabled(value);

            // Track analytics for analytics setting (meta-analytics!)
            AnalyticsService().logFeatureUsed(
              'settings_analytics_${value ? 'enabled' : 'disabled'}',
            );

            if (widget.onAnalyticsEnabledChanged != null) {
              widget.onAnalyticsEnabledChanged!(value);
            }
          },
        ),
        SwitchListTile(
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
        ),
        SwitchListTile(
          secondary: Icon(
            Icons.science_outlined,
            color: theme.colorScheme.primary,
          ),
          title: Text(
            AppLocalizations.of(context)?.betaTesting ?? 'Beta Testing',
            style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
          ),
          subtitle: Text(
            _betaTestingEnabled
                ? 'Receive pre-release updates'
                : 'Only receive stable updates',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          value: _betaTestingEnabled,
          activeThumbColor: theme.colorScheme.primary,
          onChanged: (bool value) {
            setState(() {
              _betaTestingEnabled = value;
            });
            _saveBetaTestingEnabled(value);

            // Track analytics for beta testing setting
            AnalyticsService().logFeatureUsed(
              'settings_beta_testing_${value ? 'enabled' : 'disabled'}',
            );

            if (widget.onBetaTestingEnabledChanged != null) {
              widget.onBetaTestingEnabledChanged!(value);
            }
          },
        ),
        SwitchListTile(
          secondary: Icon(Icons.tag_outlined, color: theme.colorScheme.primary),
          title: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        AppLocalizations.of(context)?.writeTagsToXMP ??
                            'Write Tags to XMP',
                        style: TextStyle(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.help_outline,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Row(
                            children: [
                              Text(
                                'XMP Metadata',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'BETA',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          content: SingleChildScrollView(
                            child: Text(
                              '🔧 BETA FEATURE - Be carefully before enabling!\n\n'
                              'When enabled, AI-generated title will be embedded directly into your image files as searchable metadata.\n\n'
                              '✅ BENEFITS:\n'
                              '• Tags become searchable outside shots-studio\n'
                              '• Works with file managers and photo organizers\n'
                              '• Metadata travels with the image file\n'
                              '⚠️ IMPORTANT CHANGES:\n'
                              '• PNG screenshots → converted to JPEG (95% quality)\n'
                              '• WebP images → converted to JPEG for compatibility\n'
                              '• Original image files are permanently modified\n'
                              '• Existing EXIF data may be replaced\n\n',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                'Got it',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                  );
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          subtitle: Text(
            _xmpWritingEnabled
                ? 'Metadata embedded in image files (PNG→JPEG conversion)'
                : 'Embed tags in image files for external searchability',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          value: _xmpWritingEnabled,
          activeThumbColor: theme.colorScheme.primary,
          onChanged: (bool value) {
            setState(() {
              _xmpWritingEnabled = value;
            });
            _saveXMPWritingEnabled(value);

            // Track analytics for XMP writing setting
            AnalyticsService().logFeatureUsed(
              'settings_xmp_writing_${value ? 'enabled' : 'disabled'}',
            );
          },
        ),
        // Reset AI Processing Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Track analytics for reset AI processing
                AnalyticsService().logFeatureUsed(
                  'settings_reset_ai_processing',
                );

                if (widget.onResetAiProcessing != null) {
                  widget.onResetAiProcessing!();
                }
              },
              icon: Icon(Icons.refresh, color: theme.colorScheme.onPrimary),
              label: Text(
                'Reset AI Processing',
                style: TextStyle(color: theme.colorScheme.onPrimary),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
        ),
        // Clear Corrupt Files Button (only in debug mode)
        if (kDebugMode)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  _clearCorruptFiles();
                },
                icon: Icon(
                  Icons.delete_sweep_outlined,
                  color: theme.colorScheme.error,
                ),
                label: Text(
                  AppLocalizations.of(context)?.clearCorruptFiles ??
                      'Clear Corrupt Files',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.colorScheme.error),
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ),
          ),
        // Debug Notifications Button (only in debug mode)
        // Temporarily commented out - uncomment for debugging notification issues
        // if (kDebugMode)
        //   Padding(
        //     padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        //     child: SizedBox(
        //       width: double.infinity,
        //       child: OutlinedButton.icon(
        //         onPressed: () {
        //           Navigator.push(
        //             context,
        //             MaterialPageRoute(
        //               builder: (context) => const DebugNotificationsScreen(),
        //             ),
        //           );
        //         },
        //         icon: Icon(Icons.bug_report, color: theme.colorScheme.secondary),
        //         label: Text(
        //           'Debug Notifications',
        //           style: TextStyle(color: theme.colorScheme.secondary),
        //         ),
        //         style: OutlinedButton.styleFrom(
        //           side: BorderSide(color: theme.colorScheme.secondary),
        //           padding: const EdgeInsets.symmetric(vertical: 12.0),
        //           shape: RoundedRectangleBorder(
        //             borderRadius: BorderRadius.circular(8.0),
        //           ),
        //         ),
        //       ),
        //     ),
        //   ),
      ],
    );
  }
}
