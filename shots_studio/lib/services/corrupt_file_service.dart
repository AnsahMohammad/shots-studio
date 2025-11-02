import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';
import 'package:shots_studio/services/snackbar_service.dart';
import 'package:shots_studio/l10n/app_localizations.dart';

/// Service for handling corrupt file detection and cleanup operations
class CorruptFileService {
  /// Check if a screenshot is corrupt (file doesn't exist or other issues)
  static bool isScreenshotCorrupt(Screenshot screenshot) {
    // Check if it's already marked as deleted
    if (screenshot.isDeleted) return true;

    // Check file-based screenshots
    if (screenshot.path != null) {
      final file = File(screenshot.path!);
      return !file.existsSync();
    }

    // Check memory-based screenshots (web/bytes)
    if (screenshot.bytes != null) {
      // For bytes, we assume they're valid if they exist
      // The actual corruption would be detected during rendering
      return false;
    }

    // If neither path nor bytes exist, it's corrupt
    return true;
  }

  /// Get list of all corrupt screenshots from the provided list
  static List<Screenshot> getCorruptScreenshots(
    List<Screenshot>? allScreenshots,
  ) {
    if (allScreenshots == null) return [];

    return allScreenshots
        .where(
          (screenshot) =>
              !screenshot.isDeleted && isScreenshotCorrupt(screenshot),
        )
        .toList();
  }

  /// Show confirmation dialog for clearing corrupt files
  static Future<bool?> showClearCorruptFilesDialog(
    BuildContext context,
    int corruptCount,
  ) async {
    final theme = Theme.of(context);

    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            AppLocalizations.of(context)?.clearCorruptFilesConfirm ??
                'Clear Corrupt Files?',
          ),
          content: Text(
            '${AppLocalizations.of(context)?.clearCorruptFilesMessage ?? 'Are you sure you want to remove all corrupt files? This action cannot be undone.'}\n\nFound $corruptCount corrupt file(s).',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text(
                'Clear',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
  }

  /// Show success message after clearing corrupt files
  static void showSuccessMessage(BuildContext context, int clearedCount) {
    if (!context.mounted) return;

    SnackbarService().showSuccess(
      context,
      '${AppLocalizations.of(context)?.corruptFilesCleared ?? 'Corrupt files cleared'} ($clearedCount files removed)',
    );
  }

  /// Show message when no corrupt files are found
  static void showNoCorruptFilesMessage(BuildContext context) {
    if (!context.mounted) return;

    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text(
    //       AppLocalizations.of(context)?.noCorruptFiles ??
    //           'No corrupt files found',
    //     ),
    //     backgroundColor: Theme.of(context).colorScheme.primary,
    //   ),
    // );
    print('No corrupt files found');
  }

  /// Mark corrupt screenshots as deleted and clear their collection references
  static int markCorruptScreenshotsAsDeleted(
    List<Screenshot> corruptScreenshots,
  ) {
    int deletedCount = 0;

    for (final screenshot in corruptScreenshots) {
      screenshot.isDeleted = true;
      // Clear all collection references
      screenshot.collectionIds.clear();
      deletedCount++;
    }

    return deletedCount;
  }

  /// Clear all corrupt files from the app with UI feedback
  /// Returns true if files were cleared, false if cancelled or no files found
  static Future<bool> clearCorruptFiles(
    BuildContext context,
    List<Screenshot>? allScreenshots,
    VoidCallback? onFilesCleared,
  ) async {
    final corruptScreenshots = getCorruptScreenshots(allScreenshots);

    // No corrupt files found
    if (corruptScreenshots.isEmpty) {
      showNoCorruptFilesMessage(context);
      return false;
    }

    // Show confirmation dialog
    final bool? confirm = await showClearCorruptFilesDialog(
      context,
      corruptScreenshots.length,
    );

    // User cancelled
    if (confirm != true) {
      return false;
    }

    // Track analytics for corrupt files cleanup
    AnalyticsService().logFeatureUsed('corrupt_files_cleared_global');

    // Mark screenshots as deleted
    final deletedCount = markCorruptScreenshotsAsDeleted(corruptScreenshots);

    // Call the callback to handle global cleanup (save data, refresh UI, etc.)
    onFilesCleared?.call();

    // Show success message
    showSuccessMessage(context, deletedCount);

    return true;
  }

  /// Clear corrupt files silently without any dialogs or user interaction
  /// This is used for background cleanup (e.g., file watcher startup)
  /// Returns the number of files cleared
  static int clearCorruptFilesSilently(
    List<Screenshot>? allScreenshots,
    VoidCallback? onFilesCleared,
  ) {
    final corruptScreenshots = getCorruptScreenshots(allScreenshots);

    // No corrupt files found
    if (corruptScreenshots.isEmpty) {
      return 0;
    }

    // Track analytics for silent corrupt files cleanup
    AnalyticsService().logFeatureUsed('corrupt_files_cleared_silent');

    // Mark screenshots as deleted
    final deletedCount = markCorruptScreenshotsAsDeleted(corruptScreenshots);

    // Call the callback to handle global cleanup (save data, refresh UI, etc.)
    onFilesCleared?.call();

    return deletedCount;
  }
}
