// Filewatcher Service that monitors directories for new screenshots
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/services/custom_path_service.dart';
import 'package:shots_studio/services/logger_service.dart';
import 'package:uuid/uuid.dart';

class FileWatcherService {
  static final FileWatcherService _instance = FileWatcherService._internal();
  factory FileWatcherService() => _instance;
  FileWatcherService._internal();

  StreamController<List<Screenshot>>? _newScreenshotsController;
  Stream<List<Screenshot>>? _newScreenshotsStream;

  final List<StreamSubscription> _subscriptions = [];
  final Set<String> _processedFiles = {};
  Timer? _debounceTimer;
  final Uuid _uuid = Uuid();

  bool _isOperationInProgress = false;

  /// Stream of newly detected screenshots
  Stream<List<Screenshot>> get newScreenshotsStream {
    _newScreenshotsController ??=
        StreamController<List<Screenshot>>.broadcast();
    _newScreenshotsStream ??= _newScreenshotsController!.stream;
    return _newScreenshotsStream!;
  }

  bool get isWatching => _subscriptions.isNotEmpty;

  int get activeWatchersCount => _subscriptions.length;

  int get processedFilesCount => _processedFiles.length;

  /// Add a file path to the processed list manually
  /// This is useful when a file is imported via other means (e.g., Share Intent)
  /// and we want to prevent the watcher from re-emitting it.
  void addProcessedFile(String path) {
    if (!_processedFiles.contains(path)) {
      _processedFiles.add(path);
      LoggerService.log('FileWatcher: Manually added processed file: $path');
    }
  }

  /// Start monitoring screenshot directories for new files
  Future<void> startWatching() async {
    if (kIsWeb) {
      LoggerService.log(
        'FileWatcher: Web platform detected, file watching not supported',
      );
      return; // Not supported on web
    }

    // Prevent concurrent operations
    if (_isOperationInProgress) {
      LoggerService.log('FileWatcher: Operation already in progress, skipping');
      return;
    }

    _isOperationInProgress = true;

    try {
      LoggerService.log('FileWatcher: Starting file watching...');

      final screenshotPaths = await _getScreenshotPaths();
      LoggerService.log(
        'FileWatcher: Found ${screenshotPaths.length} paths to watch',
      );

      if (screenshotPaths.isEmpty) {
        LoggerService.log('FileWatcher: No paths to watch');
        return;
      }

      for (final path in screenshotPaths) {
        LoggerService.log('FileWatcher: Setting up watcher for: $path');
        final directory = Directory(path);

        if (await directory.exists()) {
          LoggerService.log(
            'FileWatcher: Directory exists, proceeding with setup',
          );

          // Initial scan to populate known files
          await _scanDirectoryInitial(directory);

          // Watch for changes
          final subscription = directory
              .watch(
                events:
                    FileSystemEvent.create |
                    FileSystemEvent.modify |
                    FileSystemEvent.move,
              )
              .where(
                (event) =>
                    _isImageFile(event.path) && !_isTrashedFile(event.path),
              )
              .listen(
                _handleFileSystemEvent,
                onError: (error) {
                  LoggerService.error(
                    'FileWatcher: Directory watch error',
                    error,
                  );
                },
              );

          _subscriptions.add(subscription);
          LoggerService.log(
            'FileWatcher: Successfully added watcher for $path',
          );
        } else {
          LoggerService.log('FileWatcher: Directory does not exist: $path');
        }
      }

      LoggerService.log(
        'FileWatcher: Setup complete. Watching ${_subscriptions.length} directories',
      );
    } catch (e) {
      LoggerService.error('FileWatcher: Error starting watcher', e);
    } finally {
      _isOperationInProgress = false;
    }
  }

  /// Stop monitoring file system
  Future<void> stopWatching() async {
    // Prevent concurrent operations
    if (_isOperationInProgress) {
      LoggerService.log(
        'FileWatcher: Stop operation already in progress, skipping',
      );
      return;
    }

    _isOperationInProgress = true;

    try {
      // Create a copy of the subscriptions list to avoid concurrent modification
      final subscriptionsToCancel = List<StreamSubscription>.from(
        _subscriptions,
      );

      // Clear the original list immediately to prevent new additions
      _subscriptions.clear();

      // Cancel all subscriptions from the copy
      for (final subscription in subscriptionsToCancel) {
        try {
          await subscription.cancel();
        } catch (e) {
          LoggerService.error('FileWatcher: Error canceling subscription', e);
        }
      }

      _debounceTimer?.cancel();
      _processedFiles.clear();
    } finally {
      _isOperationInProgress = false;
    }
  }

  /// Handle file system events with debouncing
  void _handleFileSystemEvent(FileSystemEvent event) {
    LoggerService.log(
      'FileWatcher: Detected file system event: ${event.type} for ${event.path}',
    );

    // Debounce rapid file events (e.g., during file creation)
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _processNewFile(event.path);
    });
  }

  /// Process a newly detected file
  Future<void> _processNewFile(String filePath) async {
    try {
      final file = File(filePath);

      // Skip if already processed or file doesn't exist
      if (_processedFiles.contains(filePath) || !await file.exists()) {
        return;
      }

      // Skip trashed files (same logic as ImageLoaderService)
      if (_isTrashedFile(filePath)) {
        LoggerService.log('FileWatcher: Skipping trashed file: $filePath');
        _processedFiles.add(
          filePath,
        ); // Mark as processed to avoid future checks
        return;
      }

      // Add small delay to ensure file is fully written
      await Future.delayed(const Duration(milliseconds: 200));

      // Verify file is accessible and not empty
      final fileSize = await file.length();
      if (fileSize == 0) {
        return;
      }

      LoggerService.log(
        'FileWatcher: Found new unprocessed image: ${file.path} ($fileSize bytes)',
      );

      // Use centralized factory method for screenshot creation
      final screenshot = await Screenshot.fromFilePath(
        id: _uuid.v4(),
        filePath: filePath,
        knownFileSize: fileSize,
      );

      _processedFiles.add(filePath);

      // Emit new screenshot
      _newScreenshotsController?.add([screenshot]);
      LoggerService.log(
        'FileWatcher: Successfully processed and emitted new screenshot: ${screenshot.title}',
      );
    } catch (e) {
      LoggerService.error('FileWatcher: Error processing file $filePath', e);
    }
  }

  /// Initial scan to populate known files and emit new screenshots
  Future<void> _scanDirectoryInitial(Directory directory) async {
    LoggerService.log('FileWatcher: Initial scan of ${directory.path}');

    try {
      // Use async listSync to avoid blocking UI
      final List<FileSystemEntity> entities;
      try {
        entities = await directory.list().toList();
      } catch (e) {
        LoggerService.error(
          'FileWatcher: Error listing directory ${directory.path}',
          e,
        );
        return;
      }

      final files = entities.whereType<File>();
      final imageFiles =
          files.where((file) => _isImageFile(file.path)).toList();

      LoggerService.log(
        'FileWatcher: Found ${imageFiles.length} image files in ${directory.path}',
      );

      final newScreenshots = <Screenshot>[];

      // Process files in batches to avoid blocking UI for too long
      const batchSize = 10;
      for (int i = 0; i < imageFiles.length; i += batchSize) {
        final batch = imageFiles.skip(i).take(batchSize);

        for (final file in batch) {
          // Skip trashed files (same logic as ImageLoaderService)
          if (_isTrashedFile(file.path)) {
            LoggerService.log(
              'FileWatcher: Skipping trashed file during initial scan: ${file.path}',
            );
            _processedFiles.add(
              file.path,
            ); // Mark as processed to avoid future checks
            continue;
          }

          // Only process files that exist, have content, and aren't already processed
          if (!_processedFiles.contains(file.path)) {
            try {
              if (await file.exists()) {
                final fileSize = await file.length();
                if (fileSize > 0) {
                  LoggerService.log(
                    'FileWatcher: Initial scan found new unprocessed image: ${file.path}',
                  );

                  // Use centralized factory method for screenshot creation
                  final screenshot = await Screenshot.fromFilePath(
                    id: _uuid.v4(),
                    filePath: file.path,
                    knownFileSize: fileSize,
                  );

                  newScreenshots.add(screenshot);
                  _processedFiles.add(file.path);
                } else {
                  // Still mark empty files as processed to avoid future attempts
                  _processedFiles.add(file.path);
                }
              }
            } catch (e) {
              LoggerService.error(
                'FileWatcher: Error processing file ${file.path}',
                e,
              );
              _processedFiles.add(
                file.path,
              ); // Mark as processed to avoid retry
            }
          }
        }

        // Yield control back to the UI thread between batches
        if (i + batchSize < imageFiles.length) {
          await Future.delayed(const Duration(milliseconds: 1));
        }
      }

      LoggerService.log(
        'FileWatcher: Initial scan processed ${newScreenshots.length} new screenshots from ${directory.path}',
      );

      // Emit new screenshots if any were found
      if (newScreenshots.isNotEmpty) {
        LoggerService.log(
          'FileWatcher: Emitting ${newScreenshots.length} screenshots from initial scan',
        );
        _newScreenshotsController?.add(newScreenshots);
      }
    } catch (e) {
      LoggerService.error(
        'FileWatcher: Error in initial scan of ${directory.path}',
        e,
      );
    }
  }

  /// Check if file is an image
  bool _isImageFile(String path) {
    final extension = path.toLowerCase();
    return extension.endsWith('.png') ||
        extension.endsWith('.jpg') ||
        extension.endsWith('.jpeg');
  }

  /// Check if file is in trash/deleted
  bool _isTrashedFile(String path) {
    return isFileInTrash(path);
  }

  /// Static utility method to check if a file is in trash/deleted
  /// Can be used by other services for consistency
  static bool isFileInTrash(String path) {
    final lowercasePath = path.toLowerCase();
    return lowercasePath.contains('.trashed') ||
        lowercasePath.contains('/trash/') ||
        lowercasePath.contains('/recycle/') ||
        lowercasePath.contains('/.trash/') ||
        lowercasePath.contains('/deleted/');
  }

  /// Get screenshot directory paths
  Future<List<String>> _getScreenshotPaths() async {
    final List<String> paths = [];

    try {
      if (Platform.isAndroid) {
        final externalDir = await getExternalStorageDirectory();

        if (externalDir != null) {
          final baseDir = externalDir.path.split('/Android').first;
          final androidPaths = [
            '$baseDir/DCIM/Screenshots',
            '$baseDir/Pictures/Screenshots',
          ];

          paths.addAll(androidPaths);
        }
      } else if (Platform.isIOS) {
        final documentsDir = await getApplicationDocumentsDirectory();
        final iosPath = '${documentsDir.path}/Screenshots';
        paths.add(iosPath);
      }

      // Add custom paths
      final customPaths = await CustomPathService.getCustomPaths();
      paths.addAll(customPaths);

      // Add centralized shared images directory
      final appDir = await getApplicationDocumentsDirectory();
      final sharedImagesPath = '${appDir.path}/shared_images';
      paths.add(sharedImagesPath);
    } catch (e) {
      LoggerService.error('FileWatcher: Error getting screenshot paths', e);
    }

    return paths;
  }

  /// Restart file watching (useful when paths change)
  Future<void> restart() async {
    await stopWatching();
    await Future.delayed(const Duration(milliseconds: 100)); // Small delay
    await startWatching();
  }

  /// Manually scan all directories for new files
  Future<void> manualScan() async {
    LoggerService.log('FileWatcher: Starting manual scan for new images...');

    try {
      final screenshotPaths = await _getScreenshotPaths();
      final newScreenshots = <Screenshot>[];

      for (final path in screenshotPaths) {
        final directory = Directory(path);
        if (await directory.exists()) {
          // Use async listing to avoid blocking UI
          final List<FileSystemEntity> entities;
          try {
            entities = await directory.list().toList();
          } catch (e) {
            LoggerService.error(
              'FileWatcher: Error listing directory $path',
              e,
            );
            continue;
          }

          final files = entities.whereType<File>();
          final imageFiles =
              files.where((file) => _isImageFile(file.path)).toList();

          // Process files in batches to avoid blocking UI
          const batchSize = 10;
          for (int i = 0; i < imageFiles.length; i += batchSize) {
            final batch = imageFiles.skip(i).take(batchSize);

            for (final file in batch) {
              // Skip trashed files (same logic as ImageLoaderService)
              if (_isTrashedFile(file.path)) {
                LoggerService.log(
                  'FileWatcher: Skipping trashed file during manual scan: ${file.path}',
                );
                _processedFiles.add(
                  file.path,
                ); // Mark as processed to avoid future checks
                continue;
              }

              // Only process files we haven't seen before
              if (!_processedFiles.contains(file.path)) {
                try {
                  if (await file.exists()) {
                    final fileSize = await file.length();
                    if (fileSize > 0) {
                      LoggerService.log(
                        'FileWatcher: Manual scan found new unprocessed image: ${file.path}',
                      );

                      // Use centralized factory method for screenshot creation
                      final screenshot = await Screenshot.fromFilePath(
                        id: _uuid.v4(),
                        filePath: file.path,
                        knownFileSize: fileSize,
                      );

                      newScreenshots.add(screenshot);
                      _processedFiles.add(file.path);
                    }
                  }
                } catch (e) {
                  LoggerService.error(
                    'FileWatcher: Error processing file ${file.path}',
                    e,
                  );
                  _processedFiles.add(
                    file.path,
                  ); // Mark as processed to avoid retry
                }
              }
            }

            // Yield control back to the UI thread between batches
            if (i + batchSize < imageFiles.length) {
              await Future.delayed(const Duration(milliseconds: 1));
            }
          }
        }
      }

      if (newScreenshots.isNotEmpty) {
        LoggerService.log(
          'FileWatcher: Manual scan completed - found ${newScreenshots.length} new images',
        );
        _newScreenshotsController?.add(newScreenshots);
      } else {
        LoggerService.log(
          'FileWatcher: Manual scan completed - no new images found',
        );
      }
    } catch (e) {
      LoggerService.error('FileWatcher: Error during manual scan', e);
    }
  }

  /// Clear the processed files list (useful for testing)
  void clearProcessedFiles() {
    _processedFiles.clear();
  }

  /// Sync processed files list with existing screenshots to avoid conflicts
  void syncWithExistingScreenshots(List<String> existingScreenshotPaths) {
    LoggerService.log(
      'FileWatcher: Syncing with ${existingScreenshotPaths.length} existing screenshots',
    );

    // Add all existing screenshot paths to processed files to avoid duplicates
    for (final path in existingScreenshotPaths) {
      if (!_processedFiles.contains(path)) {
        _processedFiles.add(path);
      }
    }

    LoggerService.log(
      'FileWatcher: Sync complete. Total processed files: ${_processedFiles.length}',
    );
  }

  /// Debug method to check current state and paths
  Future<void> debugWatcherState() async {
    LoggerService.log('FileWatcher: === DEBUG STATE ===');
    LoggerService.log('FileWatcher: Is watching: $isWatching');
    LoggerService.log('FileWatcher: Active watchers: $activeWatchersCount');
    LoggerService.log(
      'FileWatcher: Processed files count: $processedFilesCount',
    );

    final paths = await _getScreenshotPaths();
    LoggerService.log(
      'FileWatcher: Screenshot paths to watch (${paths.length}):',
    );
    for (int i = 0; i < paths.length; i++) {
      final path = paths[i];
      final dir = Directory(path);
      final exists = await dir.exists();
      LoggerService.log('  ${i + 1}. $path (exists: $exists)');

      if (exists) {
        try {
          // Use async listing to avoid blocking UI
          final entities = await dir.list().toList();
          final files = entities.whereType<File>();
          final imageFiles = files.where((file) => _isImageFile(file.path));
          LoggerService.log(
            '     Total files: ${files.length}, Image files: ${imageFiles.length}',
          );

          // Show recent image files
          final recentImages = imageFiles.take(3).toList();
          for (final img in recentImages) {
            final lastModified = await img.lastModified();
            final isProcessed = _processedFiles.contains(img.path);
            final isTrashed = _isTrashedFile(img.path);
            LoggerService.log(
              '     - ${img.path.split('/').last} (modified: $lastModified, processed: $isProcessed, trashed: $isTrashed)',
            );
          }
        } catch (e) {
          LoggerService.error('     Error reading directory', e);
        }
      }
    }
    LoggerService.log('FileWatcher: === END DEBUG ===');
  }

  /// Force check for the most recent screenshot
  Future<void> checkForRecentScreenshots() async {
    LoggerService.log('FileWatcher: Checking for recent screenshots...');

    final paths = await _getScreenshotPaths();
    DateTime? mostRecentTime;
    String? mostRecentFile;

    for (final path in paths) {
      final dir = Directory(path);
      if (await dir.exists()) {
        try {
          // Use async listing to avoid blocking UI
          final entities = await dir.list().toList();
          final files = entities.whereType<File>();
          final imageFiles = files.where((file) => _isImageFile(file.path));

          for (final file in imageFiles) {
            // Skip trashed files
            if (_isTrashedFile(file.path)) {
              continue;
            }

            final lastModified = await file.lastModified();
            if (mostRecentTime == null ||
                lastModified.isAfter(mostRecentTime)) {
              mostRecentTime = lastModified;
              mostRecentFile = file.path;
            }
          }
        } catch (e) {
          LoggerService.error('FileWatcher: Error checking directory $path', e);
        }
      }
    }

    if (mostRecentFile != null && mostRecentTime != null) {
      final timeDiff = DateTime.now().difference(mostRecentTime);
      final isProcessed = _processedFiles.contains(mostRecentFile);
      LoggerService.log('FileWatcher: Most recent screenshot: $mostRecentFile');
      LoggerService.log(
        'FileWatcher: Created: $mostRecentTime (${timeDiff.inMinutes} minutes ago)',
      );
      LoggerService.log('FileWatcher: Is processed: $isProcessed');

      if (!isProcessed) {
        LoggerService.log(
          'FileWatcher: Found unprocessed recent screenshot, processing now...',
        );
        await _processNewFile(mostRecentFile);
      }
    } else {
      LoggerService.log('FileWatcher: No screenshots found in any directory');
    }
  }
}
