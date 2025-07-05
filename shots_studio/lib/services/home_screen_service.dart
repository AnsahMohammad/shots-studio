import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/models/collection_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:shots_studio/services/snackbar_service.dart';
import 'package:shots_studio/services/background_service.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shots_studio/services/analytics_service.dart';
import 'package:shots_studio/services/file_watcher_service.dart';
import 'package:shots_studio/services/update_checker_service.dart';
import 'package:shots_studio/widgets/update_dialog.dart';
import 'package:shots_studio/widgets/server_message_dialog.dart';
import 'package:shots_studio/services/image_loader_service.dart';
import 'package:shots_studio/services/custom_path_service.dart';

class HomeScreenService {
  // Private constructor for singleton
  HomeScreenService._internal();
  static final HomeScreenService _instance = HomeScreenService._internal();
  factory HomeScreenService() => _instance;

  final ImageLoaderService _imageLoaderService = ImageLoaderService();
  final FileWatcherService _fileWatcher = FileWatcherService();
  StreamSubscription<List<Screenshot>>? _fileWatcherSubscription;

  // State variables
  bool _isLoading = false;
  bool _isProcessingAI = false;
  int _aiProcessedCount = 0;
  int _aiTotalToProcess = 0;
  int _loadingProgress = 0;
  int _totalToLoad = 0;

  // Settings
  String? _apiKey;
  String _selectedModelName = 'gemini-2.0-flash';
  int _screenshotLimit = 1200;
  int _maxParallelAI = 4;
  bool _isScreenshotLimitEnabled = false;
  bool _devMode = false;
  bool _autoProcessEnabled = true;
  bool _analyticsEnabled = !kDebugMode;
  bool _amoledModeEnabled = false;
  String _selectedTheme = 'Dynamic Theme';

  // Getters
  bool get isLoading => _isLoading;
  bool get isProcessingAI => _isProcessingAI;
  int get aiProcessedCount => _aiProcessedCount;
  int get aiTotalToProcess => _aiTotalToProcess;
  int get loadingProgress => _loadingProgress;
  int get totalToLoad => _totalToLoad;
  String? get apiKey => _apiKey;
  String get selectedModelName => _selectedModelName;
  int get screenshotLimit => _screenshotLimit;
  int get maxParallelAI => _maxParallelAI;
  bool get isScreenshotLimitEnabled => _isScreenshotLimitEnabled;
  bool get devMode => _devMode;
  bool get autoProcessEnabled => _autoProcessEnabled;
  bool get analyticsEnabled => _analyticsEnabled;
  bool get amoledModeEnabled => _amoledModeEnabled;
  String get selectedTheme => _selectedTheme;

  /// Initialize the service
  Future<void> initialize() async {
    await _loadSettings();
  }

  /// Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString('apiKey');
    _selectedModelName = prefs.getString('modelName') ?? 'gemini-2.0-flash';
    _screenshotLimit = prefs.getInt('limit') ?? 1200;
    _maxParallelAI = prefs.getInt('maxParallel') ?? 4;
    _isScreenshotLimitEnabled = prefs.getBool('limit_enabled') ?? false;
    _devMode = prefs.getBool('dev_mode') ?? false;
    _autoProcessEnabled = prefs.getBool('auto_process_enabled') ?? true;
    _analyticsEnabled =
        prefs.getBool('analytics_consent_enabled') ?? !kDebugMode;
    _amoledModeEnabled = prefs.getBool('amoled_mode_enabled') ?? false;
    _selectedTheme = prefs.getString('selected_theme') ?? 'Dynamic Theme';
  }

  /// Save data to SharedPreferences
  Future<void> saveDataToPrefs(
    List<Screenshot> screenshots,
    List<Collection> collections,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedScreenshots = jsonEncode(
      screenshots.map((s) => s.toJson()).toList(),
    );
    await prefs.setString('screenshots', encodedScreenshots);

    final String encodedCollections = jsonEncode(
      collections.map((c) => c.toJson()).toList(),
    );
    await prefs.setString('collections', encodedCollections);
    print("Data saved to SharedPreferences");
  }

  /// Load data from SharedPreferences
  Future<(List<Screenshot>, List<Collection>)> loadDataFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    List<Screenshot> screenshots = [];
    List<Collection> collections = [];

    final String? storedScreenshots = prefs.getString('screenshots');
    if (storedScreenshots != null && storedScreenshots.isNotEmpty) {
      final List<dynamic> decodedScreenshots = jsonDecode(storedScreenshots);
      screenshots.addAll(
        decodedScreenshots.map(
          (json) => Screenshot.fromJson(json as Map<String, dynamic>),
        ),
      );
    }

    final String? storedCollections = prefs.getString('collections');
    if (storedCollections != null && storedCollections.isNotEmpty) {
      final List<dynamic> decodedCollections = jsonDecode(storedCollections);
      collections.addAll(
        decodedCollections.map(
          (json) => Collection.fromJson(json as Map<String, dynamic>),
        ),
      );
    }

    print("Data loaded from SharedPreferences");
    return (screenshots, collections);
  }

  /// Update API key
  void updateApiKey(String newApiKey) {
    _apiKey = newApiKey;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('apiKey', newApiKey);
    });
  }

  /// Update model name
  void updateModelName(String newModelName) {
    _selectedModelName = newModelName;
  }

  /// Update screenshot limit
  void updateScreenshotLimit(int newLimit) {
    _screenshotLimit = newLimit;
  }

  /// Update screenshot limit enabled
  void updateScreenshotLimitEnabled(bool enabled) {
    _isScreenshotLimitEnabled = enabled;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('limit_enabled', enabled);
    });
  }

  /// Update max parallel AI
  void updateMaxParallelAI(int newMaxParallel) {
    _maxParallelAI = newMaxParallel;
  }

  /// Update dev mode
  void updateDevMode(bool value) {
    _devMode = value;
    _saveDevMode(value);
  }

  /// Update auto process enabled
  void updateAutoProcessEnabled(bool enabled) {
    _autoProcessEnabled = enabled;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('auto_process_enabled', enabled);
    });
  }

  /// Update analytics enabled
  void updateAnalyticsEnabled(bool enabled) {
    _analyticsEnabled = enabled;
  }

  /// Update AMOLED mode enabled
  void updateAmoledModeEnabled(bool enabled) {
    _amoledModeEnabled = enabled;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('amoled_mode_enabled', enabled);
    });
  }

  /// Update theme selection
  void updateThemeSelection(String themeName) {
    _selectedTheme = themeName;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('selected_theme', themeName);
    });
  }

  /// Save dev mode setting
  Future<void> _saveDevMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dev_mode', value);
  }

  /// Check for app updates from GitHub releases
  Future<void> checkForUpdates(BuildContext context) async {
    try {
      final updateInfo = await UpdateCheckerService.checkForUpdates();

      if (updateInfo != null && context.mounted) {
        showDialog(
          context: context,
          builder: (context) => UpdateDialog(updateInfo: updateInfo),
        );
        AnalyticsService().logFeatureUsed('update_available');
      } else if (updateInfo == null) {
        print('HomeScreenService: No update available');
      } else if (!context.mounted) {
        print('HomeScreenService: Widget not mounted, cannot show dialog');
      }
    } catch (e) {
      print('HomeScreenService: Update check failed: $e');
      AnalyticsService().logFeatureUsed('update_check_failed');
    }
  }

  /// Check for server messages and notifications
  Future<void> checkForServerMessages(BuildContext context) async {
    try {
      print("HomeScreenService: Checking for server messages...");
      await Future.delayed(const Duration(milliseconds: 500));

      if (context.mounted) {
        await ServerMessageDialog.showServerMessageDialogIfAvailable(context);
      }
    } catch (e) {
      print('HomeScreenService: Server message check failed: $e');
      AnalyticsService().logFeatureUsed('server_message_check_failed');
    }
  }

  /// Take screenshot from camera or gallery
  Future<List<Screenshot>> takeScreenshot(
    ImageSource source,
    List<Screenshot> existingScreenshots,
  ) async {
    _isLoading = true;

    try {
      final result = await _imageLoaderService.loadFromImagePicker(
        source: source,
        existingScreenshots: existingScreenshots,
      );

      _isLoading = false;
      _loadingProgress = 0;
      _totalToLoad = 0;

      if (result.success) {
        AnalyticsService().logTotalScreenshotsProcessed(
          existingScreenshots.length + result.screenshots.length,
        );
        return result.screenshots;
      } else {
        if (result.errorMessage != null) {
          print('Error taking screenshot: ${result.errorMessage}');
        }
        return [];
      }
    } catch (e) {
      _isLoading = false;
      _loadingProgress = 0;
      _totalToLoad = 0;
      print('Unexpected error taking screenshot: $e');
      return [];
    }
  }

  /// Load Android screenshots
  Future<List<Screenshot>> loadAndroidScreenshots({
    required List<Screenshot> existingScreenshots,
    bool forceReload = false,
    Function(int, int)? onProgress,
  }) async {
    if (kIsWeb) return [];

    if (!forceReload && existingScreenshots.isNotEmpty) {
      print("Screenshots already loaded, skipping Android screenshot loading");
      return [];
    }

    _isLoading = true;
    _loadingProgress = 0;
    _totalToLoad = 0;

    try {
      final customPaths = await CustomPathService.getCustomPaths();

      final result = await _imageLoaderService.loadAndroidScreenshots(
        existingScreenshots: existingScreenshots,
        isLimitEnabled: _isScreenshotLimitEnabled,
        screenshotLimit: _screenshotLimit,
        customPaths: customPaths,
        onProgress: (current, total) {
          _loadingProgress = current;
          _totalToLoad = total;
          onProgress?.call(current, total);
        },
      );

      _isLoading = false;
      _loadingProgress = 0;
      _totalToLoad = 0;

      if (result.success) {
        return result.screenshots;
      } else {
        if (result.errorMessage != null) {
          print('Error loading Android screenshots: ${result.errorMessage}');
        }
        return [];
      }
    } catch (e) {
      _isLoading = false;
      _loadingProgress = 0;
      _totalToLoad = 0;
      print('Unexpected error loading Android screenshots: $e');
      return [];
    }
  }

  /// Setup background service listeners
  void setupBackgroundServiceListeners({
    required Function(int, int) onProcessingUpdate,
    required Function(bool, int, int, String?, bool) onProcessingCompleted,
    required Function(String) onProcessingError,
    required Function(List<Screenshot>, Map<String, dynamic>?) onBatchProcessed,
  }) {
    print("Setting up background service listeners...");

    final service = FlutterBackgroundService();

    // Listen for batch processing updates
    service.on('batch_processed').listen((event) {
      try {
        if (event != null) {
          final data = Map<String, dynamic>.from(event);
          final updatedScreenshotsJson = data['updatedScreenshots'] as String?;
          final responseJson = data['response'] as String?;
          final processedCount = data['processedCount'] as int? ?? 0;
          final totalCount = data['totalCount'] as int? ?? 0;

          print(
            "HomeScreenService: Processing batch update - $processedCount/$totalCount",
          );

          if (updatedScreenshotsJson != null) {
            final List<dynamic> updatedScreenshotsList = jsonDecode(
              updatedScreenshotsJson,
            );
            final List<Screenshot> updatedScreenshots =
                updatedScreenshotsList
                    .map(
                      (json) =>
                          Screenshot.fromJson(json as Map<String, dynamic>),
                    )
                    .toList();

            Map<String, dynamic>? response;
            if (responseJson != null) {
              try {
                response = jsonDecode(responseJson) as Map<String, dynamic>;
              } catch (e) {
                print("HomeScreenService: Error parsing response JSON: $e");
              }
            }

            _aiProcessedCount = processedCount;
            _aiTotalToProcess = totalCount;

            onBatchProcessed(updatedScreenshots, response);

            AnalyticsService().logAIProcessingSuccess(
              updatedScreenshots.length,
            );
          }
        }
      } catch (e) {
        print("HomeScreenService: Error processing batch update: $e");
      }
    });

    // Listen for processing completion
    service.on('processing_completed').listen((event) {
      print("HomeScreenService: Received processing completed event: $event");

      try {
        if (event != null) {
          final data = Map<String, dynamic>.from(event);
          final success = data['success'] as bool? ?? false;
          final processedCount = data['processedCount'] as int? ?? 0;
          final totalCount = data['totalCount'] as int? ?? 0;
          final error = data['error'] as String?;
          final cancelled = data['cancelled'] as bool? ?? false;

          print(
            "HomeScreenService: Processing completed - Success: $success, Processed: $processedCount/$totalCount",
          );

          _isProcessingAI = false;
          _aiProcessedCount = 0;
          _aiTotalToProcess = 0;

          onProcessingCompleted(
            success,
            processedCount,
            totalCount,
            error,
            cancelled,
          );
        }
      } catch (e) {
        print("HomeScreenService: Error processing completion event: $e");
      }
    });

    // Listen for processing errors
    service.on('processing_error').listen((event) {
      print("HomeScreenService: Received processing error event: $event");

      try {
        if (event != null) {
          final data = Map<String, dynamic>.from(event);
          final error = data['error'] as String? ?? 'Unknown error';

          print("HomeScreenService: Processing error: $error");

          _isProcessingAI = false;
          _aiProcessedCount = 0;
          _aiTotalToProcess = 0;

          onProcessingError(error);
        }
      } catch (e) {
        print("HomeScreenService: Error handling processing error event: $e");
      }
    });

    service.on('initialize').listen((event) {
      print("HomeScreenService: Received service initialization event: $event");
    });

    print("Background service listeners setup complete");
  }

  /// Start AI processing
  Future<bool> startAIProcessing({
    required BuildContext context,
    required List<Screenshot> unprocessedScreenshots,
    required List<Collection> collections,
  }) async {
    print("HomeScreenService: Starting AI processing");

    if (_apiKey == null || _apiKey!.isEmpty) {
      print("HomeScreenService: No API key configured");
      SnackbarService().showError(
        context,
        'Gemini API key not configured. Please check app settings.',
      );
      return false;
    }

    if (unprocessedScreenshots.isEmpty) {
      print("HomeScreenService: No unprocessed screenshots found");
      SnackbarService().showInfo(
        context,
        'All screenshots have already been processed.',
      );
      return false;
    }

    print(
      "HomeScreenService: Starting background processing for ${unprocessedScreenshots.length} screenshots",
    );

    _isProcessingAI = true;
    _aiProcessedCount = 0;
    _aiTotalToProcess = unprocessedScreenshots.length;

    final autoAddCollections =
        collections
            .where((collection) => collection.isAutoAddEnabled)
            .map(
              (collection) => {
                'name': collection.name,
                'description': collection.description,
                'id': collection.id,
              },
            )
            .toList();

    print(
      "HomeScreenService: Auto-add collections count: ${autoAddCollections.length}",
    );

    try {
      final backgroundService = BackgroundProcessingService();

      print("HomeScreenService: Initializing background service...");
      final serviceInitialized = await backgroundService.initializeService();

      if (!serviceInitialized) {
        print("HomeScreenService: Service initialization failed");
        _isProcessingAI = false;
        _aiProcessedCount = 0;
        _aiTotalToProcess = 0;

        SnackbarService().showError(
          context,
          'Failed to initialize background service. Please try again.',
        );
        return false;
      }

      print(
        "HomeScreenService: Background service initialized, starting processing...",
      );

      final success = await backgroundService.startBackgroundProcessing(
        screenshots: unprocessedScreenshots,
        apiKey: _apiKey!,
        modelName: _selectedModelName,
        maxParallel: _maxParallelAI,
        autoAddCollections: autoAddCollections,
      );

      print("HomeScreenService: startBackgroundProcessing returned: $success");

      if (success) {
        print("HomeScreenService: Background processing started successfully");
        SnackbarService().showInfo(
          context,
          'Processing started for ${unprocessedScreenshots.length} screenshots.',
        );
        return true;
      } else {
        print("HomeScreenService: Failed to start background processing");
        _isProcessingAI = false;
        _aiProcessedCount = 0;
        _aiTotalToProcess = 0;

        SnackbarService().showError(
          context,
          'Failed to start background processing. Please try again.',
        );
        return false;
      }
    } catch (e) {
      print("HomeScreenService: Error starting background processing: $e");

      _isProcessingAI = false;
      _aiProcessedCount = 0;
      _aiTotalToProcess = 0;

      SnackbarService().showError(
        context,
        'Error starting background processing: $e',
      );
      return false;
    }
  }

  /// Stop AI processing
  Future<void> stopAIProcessing() async {
    if (_isProcessingAI) {
      print("HomeScreenService: Stopping background processing...");

      _aiTotalToProcess = 0;

      try {
        final backgroundService = BackgroundProcessingService();
        await backgroundService.stopBackgroundProcessing();
        print("HomeScreenService: Background processing stop requested");
      } catch (e) {
        print("HomeScreenService: Error stopping background processing: $e");
      }

      _isProcessingAI = false;
    }
  }

  /// Setup file watcher
  void setupFileWatcher({
    required List<Screenshot> existingScreenshots,
    required Function(List<Screenshot>) onNewScreenshots,
  }) {
    print("📡 Setting up file watcher for seamless autoscanning...");
    print(
      "📊 Current screenshots count at watcher setup: ${existingScreenshots.length}",
    );

    _fileWatcherSubscription?.cancel();

    final existingPaths =
        existingScreenshots.map((s) => s.path).whereType<String>().toList();
    print(
      "🔄 Syncing FileWatcher with ${existingPaths.length} existing screenshots",
    );
    _fileWatcher.syncWithExistingScreenshots(existingPaths);

    _fileWatcherSubscription = _fileWatcher.newScreenshotsStream.listen(
      (newScreenshots) {
        print(
          "FileWatcher: STREAM EVENT RECEIVED! Detected ${newScreenshots.length} new screenshots",
        );

        if (newScreenshots.isNotEmpty) {
          print(
            "FileWatcher: Current screenshots count: ${existingScreenshots.length}",
          );

          final uniqueScreenshots = <Screenshot>[];
          for (final screenshot in newScreenshots) {
            final exists = existingScreenshots.any(
              (s) => s.path == screenshot.path,
            );
            print("FileWatcher: Checking ${screenshot.path} - exists: $exists");
            if (!exists) {
              uniqueScreenshots.add(screenshot);
              print("FileWatcher: Added unique screenshot: ${screenshot.path}");
            } else {
              print(
                "FileWatcher: Skipped duplicate screenshot: ${screenshot.path}",
              );
            }
          }

          print(
            "FileWatcher: Found ${uniqueScreenshots.length} unique screenshots",
          );

          if (uniqueScreenshots.isNotEmpty) {
            print(
              "FileWatcher: Adding ${uniqueScreenshots.length} screenshots to state...",
            );
            onNewScreenshots(uniqueScreenshots);
            print(
              "FileWatcher: Successfully added ${uniqueScreenshots.length} new screenshots",
            );
          } else {
            print("FileWatcher: No unique screenshots to add");
          }
        } else {
          print("FileWatcher: No new screenshots in the event");
        }
      },
      onError: (error) {
        print("FileWatcher: Stream error: $error");
      },
      onDone: () {
        print("FileWatcher: Stream closed");
      },
    );

    print("FileWatcher: Starting file watching...");
    _fileWatcher.startWatching();
    print("FileWatcher: Setup complete");
  }

  /// Sync file watcher with existing screenshots
  void syncFileWatcherWithScreenshots(List<Screenshot> screenshots) {
    final existingPaths =
        screenshots.map((s) => s.path).whereType<String>().toList();
    print(
      "🔄 Syncing FileWatcher with ${existingPaths.length} existing screenshots",
    );
    _fileWatcher.syncWithExistingScreenshots(existingPaths);
  }

  /// Manage file watcher lifecycle
  void startFileWatcher() => _fileWatcher.startWatching();
  void stopFileWatcher() => _fileWatcher.stopWatching();
  Future<void> restartFileWatcher() => _fileWatcher.restart();
  Future<void> manualScanFileWatcher() => _fileWatcher.manualScan();

  /// Reset AI metadata for all screenshots
  Future<void> resetAiMetadata(
    List<Screenshot> screenshots,
    List<Collection> collections,
  ) async {
    for (var screenshot in screenshots) {
      screenshot.aiProcessed = false;
      screenshot.aiMetadata = null;
    }

    for (var collection in collections) {
      collection.scannedSet.clear();
    }

    AnalyticsService().logFeatureUsed('ai_processing_reset');
  }

  /// Dispose resources
  void dispose() {
    _fileWatcherSubscription?.cancel();
  }
}
