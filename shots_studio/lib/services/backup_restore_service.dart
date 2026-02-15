import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shots_studio/models/collection_model.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';
import 'package:shots_studio/services/logger_service.dart';

/// Result of a backup operation
class BackupResult {
  final bool success;
  final String message;
  final String? filePath;
  final int screenshotCount;
  final int collectionCount;

  BackupResult({
    required this.success,
    required this.message,
    this.filePath,
    this.screenshotCount = 0,
    this.collectionCount = 0,
  });
}

/// Result of a restore operation
class RestoreResult {
  final bool success;
  final String message;
  final int restoredScreenshots;
  final int skippedScreenshots;
  final int restoredCollections;
  final List<Screenshot> screenshots;
  final List<Collection> collections;

  RestoreResult({
    required this.success,
    required this.message,
    this.restoredScreenshots = 0,
    this.skippedScreenshots = 0,
    this.restoredCollections = 0,
    this.screenshots = const [],
    this.collections = const [],
  });
}

/// Progress callback for backup/restore operations
typedef BackupRestoreProgressCallback =
    void Function(int current, int total, String status);

/// Service for backing up and restoring app data
class BackupRestoreService {
  static const int _backupVersion = 1;

  /// Create a backup of all screenshots and collections
  static Future<BackupResult> createBackup({
    required List<Screenshot> screenshots,
    required List<Collection> collections,
    Map<String, dynamic>? settings,
    BackupRestoreProgressCallback? onProgress,
  }) async {
    try {
      onProgress?.call(0, 4, 'Selecting save location...');

      // Let user pick a directory to save the backup
      final selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Backup Location',
      );

      if (selectedDirectory == null) {
        return BackupResult(success: false, message: 'Backup cancelled');
      }

      onProgress?.call(1, 4, 'Preparing backup...');

      // Filter out deleted screenshots
      final activeScreenshots = screenshots.where((s) => !s.isDeleted).toList();

      // Create backup data structure
      final backupData = {
        'version': _backupVersion,
        'createdAt': DateTime.now().toIso8601String(),
        'screenshotCount': activeScreenshots.length,
        'collectionCount': collections.length,
        'screenshots': [],
        'collections': [],
        if (settings != null) 'settings': settings,
      };

      onProgress?.call(2, 4, 'Backing up screenshots...');

      // Serialize screenshots
      final screenshotsList = <Map<String, dynamic>>[];
      for (final screenshot in activeScreenshots) {
        // Create a slim version without bytes (paths only)
        final screenshotJson = screenshot.toJson();
        // Remove bytes to keep backup file small
        screenshotJson.remove('bytes');
        screenshotsList.add(screenshotJson);
      }
      backupData['screenshots'] = screenshotsList;

      onProgress?.call(3, 4, 'Backing up collections...');

      // Serialize collections
      final collectionsList = <Map<String, dynamic>>[];
      for (final collection in collections) {
        collectionsList.add(collection.toJson());
      }
      backupData['collections'] = collectionsList;

      onProgress?.call(4, 4, 'Saving backup file...');

      // Convert to JSON string
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      // Create backup file with timestamp
      final timestamp =
          DateTime.now()
              .toIso8601String()
              .replaceAll(':', '-')
              .split('.')
              .first;
      final fileName = 'shots_studio_backup_$timestamp.json';
      final backupFile = File('$selectedDirectory/$fileName');
      await backupFile.writeAsString(jsonString);

      AnalyticsService().logFeatureUsed('backup_created');

      return BackupResult(
        success: true,
        message: 'Backup saved to $fileName',
        filePath: backupFile.path,
        screenshotCount: activeScreenshots.length,
        collectionCount: collections.length,
      );
    } catch (e) {
      LoggerService.error('BackupRestoreService: Error creating backup', e);
      return BackupResult(
        success: false,
        message: 'Failed to create backup: $e',
      );
    }
  }

  /// Restore data from a backup file
  static Future<RestoreResult> restoreFromBackup({
    BackupRestoreProgressCallback? onProgress,
  }) async {
    try {
      onProgress?.call(0, 4, 'Selecting backup file...');

      // Let user pick a backup file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Select Shots Studio Backup File',
      );

      if (result == null || result.files.isEmpty) {
        return RestoreResult(success: false, message: 'Restore cancelled');
      }

      final filePath = result.files.first.path;
      if (filePath == null) {
        return RestoreResult(
          success: false,
          message: 'Could not access backup file',
        );
      }

      onProgress?.call(1, 4, 'Reading backup file...');

      // Read and parse backup file
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate backup version
      final version = backupData['version'] as int? ?? 0;
      if (version > _backupVersion) {
        return RestoreResult(
          success: false,
          message:
              'Backup file is from a newer version of the app. Please update the app.',
        );
      }

      onProgress?.call(2, 4, 'Restoring screenshots...');

      // Restore screenshots
      final screenshotsList = backupData['screenshots'] as List<dynamic>? ?? [];
      final restoredScreenshots = <Screenshot>[];
      int skippedCount = 0;

      for (final screenshotJson in screenshotsList) {
        try {
          final screenshot = Screenshot.fromJson(
            screenshotJson as Map<String, dynamic>,
          );

          // Check if file exists at the stored path
          if (screenshot.path != null) {
            final file = File(screenshot.path!);
            if (await file.exists()) {
              restoredScreenshots.add(screenshot);
            } else {
              skippedCount++;
              LoggerService.log(
                'BackupRestoreService: Skipped screenshot - file not found: ${screenshot.path}',
              );
            }
          } else {
            // Web screenshots (bytes only) - restore them
            restoredScreenshots.add(screenshot);
          }
        } catch (e) {
          skippedCount++;
          LoggerService.error(
            'BackupRestoreService: Error parsing screenshot',
            e,
          );
        }
      }

      onProgress?.call(3, 4, 'Restoring collections...');

      // Restore collections
      final collectionsList = backupData['collections'] as List<dynamic>? ?? [];
      final restoredCollections = <Collection>[];
      final restoredScreenshotIds =
          restoredScreenshots.map((s) => s.id).toSet();

      for (final collectionJson in collectionsList) {
        try {
          final collection = Collection.fromJson(
            collectionJson as Map<String, dynamic>,
          );

          // Filter screenshotIds to only include restored screenshots
          final filteredScreenshotIds =
              collection.screenshotIds
                  .where((id) => restoredScreenshotIds.contains(id))
                  .toList();

          final updatedCollection = collection.copyWith(
            screenshotIds: filteredScreenshotIds,
            screenshotCount: filteredScreenshotIds.length,
          );

          restoredCollections.add(updatedCollection);
        } catch (e) {
          LoggerService.error(
            'BackupRestoreService: Error parsing collection',
            e,
          );
        }
      }

      onProgress?.call(4, 4, 'Restore complete!');

      AnalyticsService().logFeatureUsed('backup_restored');

      return RestoreResult(
        success: true,
        message: _buildRestoreMessage(
          restoredScreenshots.length,
          skippedCount,
          restoredCollections.length,
        ),
        restoredScreenshots: restoredScreenshots.length,
        skippedScreenshots: skippedCount,
        restoredCollections: restoredCollections.length,
        screenshots: restoredScreenshots,
        collections: restoredCollections,
      );
    } catch (e) {
      LoggerService.error('BackupRestoreService: Error restoring backup', e);
      return RestoreResult(
        success: false,
        message: 'Failed to restore backup: $e',
      );
    }
  }

  static String _buildRestoreMessage(
    int restored,
    int skipped,
    int collections,
  ) {
    final parts = <String>[];

    if (restored > 0) {
      parts.add('$restored screenshot${restored == 1 ? '' : 's'} restored');
    }

    if (skipped > 0) {
      parts.add('$skipped skipped (files not found)');
    }

    if (collections > 0) {
      parts.add('$collections collection${collections == 1 ? '' : 's'}');
    }

    return parts.isEmpty ? 'No data restored' : parts.join(', ');
  }

  /// Show backup progress dialog
  static Future<BackupResult?> showBackupDialog({
    required BuildContext context,
    required List<Screenshot> screenshots,
    required List<Collection> collections,
    Map<String, dynamic>? settings,
  }) async {
    return showDialog<BackupResult>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => _BackupProgressDialog(
            screenshots: screenshots,
            collections: collections,
            settings: settings,
          ),
    );
  }

  /// Show restore progress dialog
  static Future<RestoreResult?> showRestoreDialog({
    required BuildContext context,
  }) async {
    return showDialog<RestoreResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _RestoreProgressDialog(),
    );
  }
}

/// Dialog showing backup progress
class _BackupProgressDialog extends StatefulWidget {
  final List<Screenshot> screenshots;
  final List<Collection> collections;
  final Map<String, dynamic>? settings;

  const _BackupProgressDialog({
    required this.screenshots,
    required this.collections,
    this.settings,
  });

  @override
  State<_BackupProgressDialog> createState() => _BackupProgressDialogState();
}

class _BackupProgressDialogState extends State<_BackupProgressDialog> {
  int _current = 0;
  int _total = 3;
  String _status = 'Starting backup...';
  BackupResult? _result;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _startBackup();
  }

  Future<void> _startBackup() async {
    final result = await BackupRestoreService.createBackup(
      screenshots: widget.screenshots,
      collections: widget.collections,
      settings: widget.settings,
      onProgress: (current, total, status) {
        if (mounted) {
          setState(() {
            _current = current;
            _total = total;
            _status = status;
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        _result = result;
        _isComplete = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _isComplete
                ? (_result?.success == true ? Icons.check_circle : Icons.error)
                : Icons.backup,
            color:
                _isComplete
                    ? (_result?.success == true
                        ? Colors.green
                        : theme.colorScheme.error)
                    : theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text(_isComplete ? 'Backup Complete' : 'Creating Backup'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isComplete) ...[
            LinearProgressIndicator(
              value: _total > 0 ? _current / _total : null,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _status,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
          if (_isComplete && _result != null) ...[
            Text(
              _result!.message,
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            if (_result!.success) ...[
              const SizedBox(height: 8),
              Text(
                '📸 ${_result!.screenshotCount} screenshots\n📁 ${_result!.collectionCount} collections',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ],
      ),
      actions: [
        if (_isComplete)
          TextButton(
            onPressed: () => Navigator.of(context).pop(_result),
            child: const Text('Done'),
          ),
      ],
    );
  }
}

/// Dialog showing restore progress
class _RestoreProgressDialog extends StatefulWidget {
  const _RestoreProgressDialog();

  @override
  State<_RestoreProgressDialog> createState() => _RestoreProgressDialogState();
}

class _RestoreProgressDialogState extends State<_RestoreProgressDialog> {
  int _current = 0;
  int _total = 4;
  String _status = 'Starting restore...';
  RestoreResult? _result;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _startRestore();
  }

  Future<void> _startRestore() async {
    final result = await BackupRestoreService.restoreFromBackup(
      onProgress: (current, total, status) {
        if (mounted) {
          setState(() {
            _current = current;
            _total = total;
            _status = status;
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        _result = result;
        _isComplete = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _isComplete
                ? (_result?.success == true ? Icons.check_circle : Icons.error)
                : Icons.restore,
            color:
                _isComplete
                    ? (_result?.success == true
                        ? Colors.green
                        : theme.colorScheme.error)
                    : theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text(_isComplete ? 'Restore Complete' : 'Restoring Data'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isComplete) ...[
            LinearProgressIndicator(
              value: _total > 0 ? _current / _total : null,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _status,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
          if (_isComplete && _result != null) ...[
            Text(
              _result!.success ? 'Restore completed!' : _result!.message,
              style: TextStyle(
                color:
                    _result!.success
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.error,
              ),
            ),
            if (_result!.success) ...[
              const SizedBox(height: 12),
              _buildStatRow(
                context,
                Icons.check_circle_outline,
                Colors.green,
                '${_result!.restoredScreenshots} images restored',
              ),
              if (_result!.skippedScreenshots > 0)
                _buildStatRow(
                  context,
                  Icons.warning_amber_outlined,
                  Colors.orange,
                  '${_result!.skippedScreenshots} images not found',
                ),
              _buildStatRow(
                context,
                Icons.folder_outlined,
                theme.colorScheme.primary,
                '${_result!.restoredCollections} collections',
              ),
            ],
          ],
        ],
      ),
      actions: [
        if (_isComplete)
          TextButton(
            onPressed: () => Navigator.of(context).pop(_result),
            child: const Text('Done'),
          ),
      ],
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    IconData icon,
    Color color,
    String text,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
