import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';
import 'package:shots_studio/services/corrupt_file_service.dart';
import 'package:shots_studio/services/snackbar_service.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/l10n/app_localizations.dart';

/// Action buttons for Reset AI Processing and Clear Corrupt Files.
class ActionButtons extends StatelessWidget {
  final VoidCallback? onResetAiProcessing;
  final List<Screenshot>? allScreenshots;
  final VoidCallback? onClearCorruptFiles;

  const ActionButtons({
    super.key,
    this.onResetAiProcessing,
    this.allScreenshots,
    this.onClearCorruptFiles,
  });

  /// Clear all corrupt files from the app using the CorruptFileService
  Future<void> _clearCorruptFiles(BuildContext context) async {
    await CorruptFileService.clearCorruptFiles(
      context,
      allScreenshots,
      onClearCorruptFiles,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
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

                if (onResetAiProcessing != null) {
                  onResetAiProcessing!();
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
                onPressed: () => _clearCorruptFiles(context),
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
        // Reset Onboarding Button (only in debug mode)
        if (kDebugMode)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('ai_setup_onboarding_completed', false);
                  if (context.mounted) {
                    SnackbarService().showSuccess(
                      context,
                      'Onboarding reset! Restart the app to see it again.',
                    );
                  }
                },
                icon: Icon(
                  Icons.restart_alt,
                  color: theme.colorScheme.tertiary,
                ),
                label: Text(
                  'Reset Onboarding',
                  style: TextStyle(color: theme.colorScheme.tertiary),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.colorScheme.tertiary),
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
}
