import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';
import 'package:shots_studio/l10n/app_localizations.dart';

/// A toggle switch for enabling/disabling beta testing.
class BetaTestingToggle extends StatefulWidget {
  final bool? currentBetaTestingEnabled;
  final Function(bool)? onBetaTestingEnabledChanged;

  const BetaTestingToggle({
    super.key,
    this.currentBetaTestingEnabled,
    this.onBetaTestingEnabledChanged,
  });

  @override
  State<BetaTestingToggle> createState() => _BetaTestingToggleState();
}

class _BetaTestingToggleState extends State<BetaTestingToggle> {
  bool _betaTestingEnabled = false;

  static const String _betaTestingPrefKey = 'beta_testing_enabled';

  @override
  void initState() {
    super.initState();
    if (widget.currentBetaTestingEnabled != null) {
      _betaTestingEnabled = widget.currentBetaTestingEnabled!;
    } else {
      _loadBetaTestingEnabledPref();
    }
  }

  Future<void> _loadBetaTestingEnabledPref() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _betaTestingEnabled = prefs.getBool(_betaTestingPrefKey) ?? false;
    });
  }

  @override
  void didUpdateWidget(covariant BetaTestingToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentBetaTestingEnabled !=
            oldWidget.currentBetaTestingEnabled &&
        widget.currentBetaTestingEnabled != null) {
      _betaTestingEnabled = widget.currentBetaTestingEnabled!;
    }
  }

  Future<void> _saveBetaTestingEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_betaTestingPrefKey, value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SwitchListTile(
      secondary: Icon(Icons.science_outlined, color: theme.colorScheme.primary),
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
    );
  }
}
