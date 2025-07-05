import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/services/custom_path_service.dart';
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

  /// Start monitoring screenshot directories for new files
  Future<void> startWatching() async {
    if (kIsWeb) {
      print('FileWatcher: Web platform detected, file watching not supported');
      return; // Not supported on web
    }

    print('FileWatcher: Starting file watching...');

    try {
      final screenshotPaths = await _getScreenshotPaths();
      print('FileWatcher: Found ${screenshotPaths.length} paths to watch');

      if (screenshotPaths.isEmpty) {
        print('FileWatcher: No paths to watch');
        return;
      }

      for (final path in screenshotPaths) {
        print('FileWatcher: Setting up watcher for: $path');
        final directory = Directory(path);

        if (await directory.exists()) {
          print('FileWatcher: Directory exists, proceeding with setup');

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
                  print('FileWatcher: Directory watch error for $path: $error');
                },
              );

          _subscriptions.add(subscription);
          print('FileWatcher: Successfully added watcher for $path');
        } else {
          print('FileWatcher: Directory does not exist: $path');
        }
      }

      print(
        'FileWatcher: Setup complete. Watching ${_subscriptions.length} directories',
      );
    } catch (e) {
      print('FileWatcher: Error starting watcher: $e');
    }
  }

  /// Stop monitoring file system
  Future<void> stopWatching() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    _debounceTimer?.cancel();
    _processedFiles.clear();
  }

  /// Handle file system events with debouncing
  void _handleFileSystemEvent(FileSystemEvent event) {
    print(
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
        print('FileWatcher: Skipping trashed file: $filePath');
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

      print(
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
      print(
        'FileWatcher: Successfully processed and emitted new screenshot: ${screenshot.title}',
      );
    } catch (e) {
      print('FileWatcher: Error processing file $filePath: $e');
    }
  }

  /// Initial scan to populate known files and emit new screenshots
  Future<void> _scanDirectoryInitial(Directory directory) async {
    print('FileWatcher: Initial scan of ${directory.path}');

    try {
      final entities = directory.listSync();
      final files = entities.whereType<File>();
      final imageFiles = files.where((file) => _isImageFile(file.path));

      print(
        'FileWatcher: Found ${imageFiles.length} image files in ${directory.path}',
      );

      final newScreenshots = <Screenshot>[];

      for (final file in imageFiles) {
        // Skip trashed files (same logic as ImageLoaderService)
        if (_isTrashedFile(file.path)) {
          print(
            'FileWatcher: Skipping trashed file during initial scan: ${file.path}',
          );
          _processedFiles.add(
            file.path,
          ); // Mark as processed to avoid future checks
          continue;
        }

        // Only process files that exist, have content, and aren't already processed
        if (await file.exists() && !_processedFiles.contains(file.path)) {
          final fileSize = await file.length();
          if (fileSize > 0) {
            print(
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
        } else if (_processedFiles.contains(file.path)) {
          // File already processed, just skip
          continue;
        }
      }

      print(
        'FileWatcher: Initial scan processed ${newScreenshots.length} new screenshots from ${directory.path}',
      );

      // Emit new screenshots if any were found
      if (newScreenshots.isNotEmpty) {
        print(
          'FileWatcher: Emitting ${newScreenshots.length} screenshots from initial scan',
        );
        _newScreenshotsController?.add(newScreenshots);
      }
    } catch (e) {
      print('FileWatcher: Error in initial scan of ${directory.path}: $e');
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
    } catch (e) {
      print('FileWatcher: Error getting screenshot paths: $e');
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
    print('FileWatcher: Starting manual scan for new images...');

    try {
      final screenshotPaths = await _getScreenshotPaths();
      final newScreenshots = <Screenshot>[];

      for (final path in screenshotPaths) {
        final directory = Directory(path);
        if (await directory.exists()) {
          final entities = directory.listSync();
          final files = entities.whereType<File>();
          final imageFiles = files.where((file) => _isImageFile(file.path));

          for (final file in imageFiles) {
            // Skip trashed files (same logic as ImageLoaderService)
            if (_isTrashedFile(file.path)) {
              print(
                'FileWatcher: Skipping trashed file during manual scan: ${file.path}',
              );
              _processedFiles.add(
                file.path,
              ); // Mark as processed to avoid future checks
              continue;
            }

            // Only process files we haven't seen before
            if (!_processedFiles.contains(file.path)) {
              final fileSize = await file.length();
              if (fileSize > 0) {
                print(
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
          }
        }
      }

      if (newScreenshots.isNotEmpty) {
        print(
          'FileWatcher: Manual scan completed - found ${newScreenshots.length} new images',
        );
        _newScreenshotsController?.add(newScreenshots);
      } else {
        print('FileWatcher: Manual scan completed - no new images found');
      }
    } catch (e) {
      print('FileWatcher: Error during manual scan: $e');
    }
  }

  /// Clear the processed files list (useful for testing)
  void clearProcessedFiles() {
    _processedFiles.clear();
  }

  /// Sync processed files list with existing screenshots to avoid conflicts
  void syncWithExistingScreenshots(List<String> existingScreenshotPaths) {
    print(
      'FileWatcher: Syncing with ${existingScreenshotPaths.length} existing screenshots',
    );

    // Add all existing screenshot paths to processed files to avoid duplicates
    for (final path in existingScreenshotPaths) {
      if (!_processedFiles.contains(path)) {
        _processedFiles.add(path);
      }
    }

    print(
      'FileWatcher: Sync complete. Total processed files: ${_processedFiles.length}',
    );
  }

  /// Debug method to check current state and paths
  Future<void> debugWatcherState() async {
    print('FileWatcher: === DEBUG STATE ===');
    print('FileWatcher: Is watching: $isWatching');
    print('FileWatcher: Active watchers: $activeWatchersCount');
    print('FileWatcher: Processed files count: $processedFilesCount');

    final paths = await _getScreenshotPaths();
    print('FileWatcher: Screenshot paths to watch (${paths.length}):');
    for (int i = 0; i < paths.length; i++) {
      final path = paths[i];
      final dir = Directory(path);
      final exists = await dir.exists();
      print('  ${i + 1}. $path (exists: $exists)');

      if (exists) {
        try {
          final entities = dir.listSync();
          final files = entities.whereType<File>();
          final imageFiles = files.where((file) => _isImageFile(file.path));
          print(
            '     Total files: ${files.length}, Image files: ${imageFiles.length}',
          );

          // Show recent image files
          final recentImages = imageFiles.take(3).toList();
          for (final img in recentImages) {
            final lastModified = await img.lastModified();
            final isProcessed = _processedFiles.contains(img.path);
            final isTrashed = _isTrashedFile(img.path);
            print(
              '     - ${img.path.split('/').last} (modified: $lastModified, processed: $isProcessed, trashed: $isTrashed)',
            );
          }
        } catch (e) {
          print('     Error reading directory: $e');
        }
      }
    }
    print('FileWatcher: === END DEBUG ===');
  }

  /// Force check for the most recent screenshot
  Future<void> checkForRecentScreenshots() async {
    print('FileWatcher: Checking for recent screenshots...');

    final paths = await _getScreenshotPaths();
    DateTime? mostRecentTime;
    String? mostRecentFile;

    for (final path in paths) {
      final dir = Directory(path);
      if (await dir.exists()) {
        try {
          final entities = dir.listSync();
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
          print('FileWatcher: Error checking directory $path: $e');
        }
      }
    }

    if (mostRecentFile != null && mostRecentTime != null) {
      final timeDiff = DateTime.now().difference(mostRecentTime);
      final isProcessed = _processedFiles.contains(mostRecentFile);
      print('FileWatcher: Most recent screenshot: $mostRecentFile');
      print(
        'FileWatcher: Created: $mostRecentTime (${timeDiff.inMinutes} minutes ago)',
      );
      print('FileWatcher: Is processed: $isProcessed');

      if (!isProcessed) {
        print(
          'FileWatcher: Found unprocessed recent screenshot, processing now...',
        );
        await _processNewFile(mostRecentFile);
      }
    } else {
      print('FileWatcher: No screenshots found in any directory');
    }
  }
}
