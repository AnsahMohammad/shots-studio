import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shots_studio/services/analytics_service.dart';

class AdvancedSettingsSection extends StatefulWidget {
  final int currentLimit;
  final Function(int) onLimitChanged;
  final int currentMaxParallel;
  final Function(int) onMaxParallelChanged;
  final bool? currentLimitEnabled;
  final Function(bool)? onLimitEnabledChanged;
  final bool? currentDevMode;
  final Function(bool)? onDevModeChanged;
  final bool? currentAnalyticsEnabled;
  final Function(bool)? onAnalyticsEnabledChanged;
  final VoidCallback? onResetAiProcessing;

  const AdvancedSettingsSection({
    super.key,
    required this.currentLimit,
    required this.onLimitChanged,
    required this.currentMaxParallel,
    required this.onMaxParallelChanged,
    this.currentLimitEnabled,
    this.onLimitEnabledChanged,
    this.currentDevMode,
    this.onDevModeChanged,
    this.currentAnalyticsEnabled,
    this.onAnalyticsEnabledChanged,
    this.onResetAiProcessing,
  });

  @override
  State<AdvancedSettingsSection> createState() =>
      _AdvancedSettingsSectionState();
}

class _AdvancedSettingsSectionState extends State<AdvancedSettingsSection> {
  late TextEditingController _limitController;
  late TextEditingController _maxParallelController;
  bool _isLimitEnabled = true;
  bool _devMode = false;
  bool _analyticsEnabled =
      !kDebugMode; // Default to false in debug mode, true in production

  static const String _limitPrefKey = 'limit';
  static const String _maxParallelPrefKey = 'maxParallel';
  static const String _limitEnabledPrefKey = 'limit_enabled';
  static const String _devModePrefKey = 'dev_mode';

  @override
  void initState() {
    super.initState();
    _limitController = TextEditingController(
      text: widget.currentLimit.toString(),
    );
    _maxParallelController = TextEditingController(
      text: widget.currentMaxParallel.toString(),
    );

    // Initialize with widget value if provided, otherwise load from prefs
    if (widget.currentLimitEnabled != null) {
      _isLimitEnabled = widget.currentLimitEnabled!;
    } else {
      _loadLimitEnabledPref();
    }

    if (widget.currentDevMode != null) {
      _devMode = widget.currentDevMode!;
    } else {
      _loadDevModePref();
    }

    // Initialize analytics consent state
    if (widget.currentAnalyticsEnabled != null) {
      _analyticsEnabled = widget.currentAnalyticsEnabled!;
    } else {
      _loadAnalyticsEnabledPref();
    }
  }

  Future<void> _loadLimitEnabledPref() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLimitEnabled = prefs.getBool(_limitEnabledPrefKey) ?? true;
    });
  }

  Future<void> _loadDevModePref() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _devMode = prefs.getBool(_devModePrefKey) ?? false;
    });
  }

  void _loadAnalyticsEnabledPref() async {
    final analyticsService = AnalyticsService();
    setState(() {
      _analyticsEnabled = analyticsService.analyticsEnabled;
    });
  }

  @override
  void didUpdateWidget(covariant AdvancedSettingsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentLimit != oldWidget.currentLimit) {
      if (_limitController.text != widget.currentLimit.toString()) {
        _limitController.text = widget.currentLimit.toString();
        _limitController.selection = TextSelection.fromPosition(
          TextPosition(offset: _limitController.text.length),
        );
      }
    }
    if (widget.currentMaxParallel != oldWidget.currentMaxParallel) {
      if (_maxParallelController.text != widget.currentMaxParallel.toString()) {
        _maxParallelController.text = widget.currentMaxParallel.toString();
        _maxParallelController.selection = TextSelection.fromPosition(
          TextPosition(offset: _maxParallelController.text.length),
        );
      }
    }
    if (widget.currentAnalyticsEnabled != oldWidget.currentAnalyticsEnabled &&
        widget.currentAnalyticsEnabled != null) {
      _analyticsEnabled = widget.currentAnalyticsEnabled!;
    }
  }

  Future<void> _saveLimit(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_limitPrefKey, value);
  }

  Future<void> _saveMaxParallel(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_maxParallelPrefKey, value);
  }

  Future<void> _saveLimitEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_limitEnabledPrefKey, value);
  }

  Future<void> _saveDevMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_devModePrefKey, value);
  }

  Future<void> _saveAnalyticsEnabled(bool value) async {
    final analyticsService = AnalyticsService();
    if (value) {
      await analyticsService.enableAnalytics();
    } else {
      await analyticsService.disableAnalytics();
    }
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
            'Advanced Settings',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SwitchListTile(
          secondary: Icon(
            Icons.developer_mode,
            color: theme.colorScheme.primary,
          ),
          title: Text(
            'Developer Mode',
            style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
          ),
          subtitle: Text(
            _devMode
                ? 'Additional settings are enabled'
                : 'Additional settings are hidden',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          value: _devMode,
          activeColor: theme.colorScheme.primary,
          onChanged: (bool value) {
            setState(() {
              _devMode = value;
            });
            _saveDevMode(value);
            if (widget.onDevModeChanged != null) {
              widget.onDevModeChanged!(value);
            }
          },
        ),
        SwitchListTile(
          secondary: Icon(Icons.filter_list, color: theme.colorScheme.primary),
          title: Text(
            'Enable Screenshot Limit',
            style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
          ),
          subtitle: Text(
            _isLimitEnabled
                ? 'Limited to ${widget.currentLimit} screenshots'
                : 'All screenshots will be loaded',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          value: _isLimitEnabled,
          activeColor: theme.colorScheme.primary,
          onChanged: (bool value) {
            setState(() {
              _isLimitEnabled = value;
            });
            _saveLimitEnabled(value);
            if (widget.onLimitEnabledChanged != null) {
              widget.onLimitEnabledChanged!(value);
            }
          },
        ),
        if (_isLimitEnabled)
          ListTile(
            leading: const SizedBox(
              width: 24,
            ), // Keep alignment with icon above
            title: Text(
              'Screenshot Limit Value',
              style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
            ),
            subtitle: TextFormField(
              controller: _limitController,
              style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
              decoration: InputDecoration(
                hintText: 'e.g., 50',
                hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: theme.colorScheme.outline),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: theme.colorScheme.primary),
                ),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final intValue = int.tryParse(value);
                if (intValue != null) {
                  widget.onLimitChanged(intValue);
                  _saveLimit(intValue);
                }
              },
            ),
          ),
        ListTile(
          leading: Icon(Icons.sync_alt, color: theme.colorScheme.primary),
          title: Text(
            'Max Parallel AI Processes',
            style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
          ),
          subtitle: TextFormField(
            controller: _maxParallelController,
            style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
            decoration: InputDecoration(
              hintText: 'e.g., 4',
              hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: theme.colorScheme.outline),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: theme.colorScheme.primary),
              ),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final intValue = int.tryParse(value);
              if (intValue != null) {
                widget.onMaxParallelChanged(intValue);
                _saveMaxParallel(intValue);
              }
            },
          ),
        ),
        SwitchListTile(
          secondary: Icon(
            Icons.analytics_outlined,
            color: theme.colorScheme.primary,
          ),
          title: Text(
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
          activeColor: theme.colorScheme.primary,
          onChanged: (bool value) {
            setState(() {
              _analyticsEnabled = value;
            });
            _saveAnalyticsEnabled(value);
            if (widget.onAnalyticsEnabledChanged != null) {
              widget.onAnalyticsEnabledChanged!(value);
            }
          },
        ),
        // Reset AI Processing Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onResetAiProcessing,
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
      ],
    );
  }

  @override
  void dispose() {
    _limitController.dispose();
    _maxParallelController.dispose();
    super.dispose();
  }
}
