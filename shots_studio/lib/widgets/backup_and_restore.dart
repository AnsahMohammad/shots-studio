import 'package:flutter/material.dart';
import 'package:shots_studio/models/collection_model.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';
import 'package:shots_studio/services/backup_restore_service.dart';
import '../../l10n/app_localizations.dart';

/// A card widget for backup and restore functionality
class BackupRestoreCard extends StatelessWidget {
  final List<Screenshot>? allScreenshots;
  final List<Collection>? allCollections;
  final Function(List<Screenshot>, List<Collection>)? onDataRestored;

  const BackupRestoreCard({
    super.key,
    this.allScreenshots,
    this.allCollections,
    this.onDataRestored,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.5),
          ),
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  AppLocalizations.of(context)?.dataManagement ??
                      'Data Management',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Description
            Text(
              AppLocalizations.of(context)?.dataManagementDescription ??
                  'Backup and restore your screenshots metadata, collections, and settings.',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            // Buttons row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleBackup(context),
                    icon: Icon(
                      Icons.upload_outlined,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    label: Text(
                      AppLocalizations.of(context)?.backup ?? 'Backup',
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.colorScheme.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleRestore(context),
                    icon: Icon(
                      Icons.download_outlined,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    label: Text(
                      AppLocalizations.of(context)?.restore ?? 'Restore',
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.colorScheme.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Handle backup button press
  Future<void> _handleBackup(BuildContext context) async {
    final screenshots = allScreenshots ?? [];
    final collections = allCollections ?? [];

    // Track analytics
    AnalyticsService().logFeatureUsed('backup_started');

    await BackupRestoreService.showBackupDialog(
      context: context,
      screenshots: screenshots,
      collections: collections,
    );
  }

  /// Handle restore button press
  Future<void> _handleRestore(BuildContext context) async {
    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(dialogContext).colorScheme.error,
            ),
            const SizedBox(width: 12),
            Text(
              AppLocalizations.of(dialogContext)?.restoreData ?? 'Restore Data',
            ),
          ],
        ),
        content: Text(
          AppLocalizations.of(dialogContext)?.restoreWarning ??
              'This will replace all your current data with the backup. Make sure you have a current backup before proceeding.\n\nImages that no longer exist on your device will be skipped.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(AppLocalizations.of(dialogContext)?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              AppLocalizations.of(dialogContext)?.restore ?? 'Restore',
              style: TextStyle(
                color: Theme.of(dialogContext).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Track analytics
    AnalyticsService().logFeatureUsed('restore_started');

    final result = await BackupRestoreService.showRestoreDialog(
      context: context,
    );

    if (result != null && result.success && onDataRestored != null) {
      onDataRestored!(result.screenshots, result.collections);
    }
  }
}
