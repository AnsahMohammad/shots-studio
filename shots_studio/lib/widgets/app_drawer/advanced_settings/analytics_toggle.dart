import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';
import 'package:shots_studio/l10n/app_localizations.dart';

/// A toggle switch for enabling/disabling analytics and telemetry.
class AnalyticsToggle extends StatefulWidget {
  final bool? currentAnalyticsEnabled;
  final Function(bool)? onAnalyticsEnabledChanged;

  const AnalyticsToggle({
    super.key,
    this.currentAnalyticsEnabled,
    this.onAnalyticsEnabledChanged,
  });

  @override
  State<AnalyticsToggle> createState() => _AnalyticsToggleState();
}

class _AnalyticsToggleState extends State<AnalyticsToggle> {
  bool _analyticsEnabled =
      !kDebugMode; // Default to false in debug mode, true in production

  @override
  void initState() {
    super.initState();
    if (widget.currentAnalyticsEnabled != null) {
      _analyticsEnabled = widget.currentAnalyticsEnabled!;
    } else {
      _loadAnalyticsEnabledPref();
    }
  }

  void _loadAnalyticsEnabledPref() {
    final analyticsService = AnalyticsService();
    setState(() {
      _analyticsEnabled = analyticsService.analyticsEnabled;
    });
  }

  @override
  void didUpdateWidget(covariant AnalyticsToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentAnalyticsEnabled != oldWidget.currentAnalyticsEnabled &&
        widget.currentAnalyticsEnabled != null) {
      _analyticsEnabled = widget.currentAnalyticsEnabled!;
    }
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

    return SwitchListTile(
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
    );
  }
}
