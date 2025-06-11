import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:shots_studio/screens/screenshot_details_screen.dart';
import 'package:shots_studio/screens/screenshot_swipe_detail_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shots_studio/widgets/home_app_bar.dart';
import 'package:shots_studio/widgets/collections/collections_section.dart';
import 'package:shots_studio/widgets/screenshots/screenshots_section.dart';
import 'package:shots_studio/screens/app_drawer_screen.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/models/collection_model.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shots_studio/screens/search_screen.dart';
import 'package:shots_studio/widgets/privacy_dialog.dart';
import 'package:shots_studio/widgets/onboarding/api_key_guide_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:shots_studio/services/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shots_studio/services/snackbar_service.dart';
import 'package:shots_studio/utils/memory_utils.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:shots_studio/widgets/ai_processing_container.dart';
import 'package:shots_studio/services/background_service.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shots_studio/services/analytics_service.dart';
import 'package:shots_studio/services/file_watcher_service.dart';
import 'package:shots_studio/services/update_checker_service.dart';
import 'package:shots_studio/widgets/update_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Analytics (PostHog)
  await AnalyticsService().initialize();

  // Optimize image cache for better memory management
  MemoryUtils.optimizeImageCache();

  await NotificationService().init();

  // Initialize background service for AI processing only on non-web platforms
  if (!kIsWeb) {
    print("Main: Initial background service setup");
    // Set up notification channel for background service
    await _setupBackgroundServiceNotificationChannel();
    // Don't initialize service at app startup - we'll do it when needed
    // This prevents unnecessary background service running when not needed
    print("Main: Background service will be initialized when needed");
  }

  runApp(const MyApp());
}

// Set up notification channel for background service
Future<void> _setupBackgroundServiceNotificationChannel() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'ai_processing_channel', // id - matches BackgroundProcessingService.notificationChannelId
    'AI Processing Service', // title
    description: 'Channel for AI screenshot processing notifications',
    importance: Importance.low, // importance must be at low or higher level
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightScheme;
        ColorScheme darkScheme;

        if (lightDynamic != null && darkDynamic != null) {
          // Use dynamic colors if available (Material You)
          lightScheme = lightDynamic.harmonized();
          darkScheme = darkDynamic.harmonized();
        } else {
          // Fallback to custom color schemes if dynamic colors are not available
          lightScheme = ColorScheme.fromSeed(
            seedColor: Colors.amber,
            brightness: Brightness.light,
          );
          darkScheme = ColorScheme.fromSeed(
            seedColor: Colors.amber,
            brightness: Brightness.dark,
          );
        }

        return MaterialApp(
          title: 'Shots Studio',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightScheme,
            cardTheme: CardThemeData(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkScheme,
            cardTheme: CardThemeData(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          themeMode:
              ThemeMode.system, // Automatically switch between light and dark
          home: const HomeScreen(),
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final List<Screenshot> _screenshots = [];
  final List<Collection> _collections = [];
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();
  bool _isLoading = false;
  bool _isProcessingAI = false;
  int _aiProcessedCount = 0;
  int _aiTotalToProcess = 0;

  // Add a global key for the API key text field
  final GlobalKey<State> _apiKeyFieldKey = GlobalKey();

  // File watcher service for seamless autoscanning
  final FileWatcherService _fileWatcher = FileWatcherService();
  StreamSubscription<List<Screenshot>>? _fileWatcherSubscription;

  // Add loading progress tracking
  int _loadingProgress = 0;
  int _totalToLoad = 0;

  String? _apiKey;
  String _selectedModelName = 'gemini-2.0-flash';
  int _screenshotLimit = 1200;
  int _maxParallelAI = 4;
  bool _isScreenshotLimitEnabled = false;
  bool _devMode = false;
  bool _autoProcessEnabled = true;
  bool _analyticsEnabled =
      !kDebugMode; // Default to false in debug mode, true in production

  // update screenshots
  List<Screenshot> get _activeScreenshots {
    final activeScreenshots =
        _screenshots.where((screenshot) => !screenshot.isDeleted).toList();
    // Sort by addedOn date in descending order (newest first)
    activeScreenshots.sort((a, b) => b.addedOn.compareTo(a.addedOn));
    return activeScreenshots;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Log analytics for app startup and home screen view
    AnalyticsService().logScreenView('home_screen');
    AnalyticsService().logCurrentUsageTime();

    _loadDataFromPrefs();
    _loadSettings();
    if (!kIsWeb) {
      _loadAndroidScreenshots();
      _setupBackgroundServiceListeners();
      _setupFileWatcher();
    }
    // Show privacy dialog after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Show privacy dialog and only proceed to API key guide if accepted
      bool privacyAccepted = await showPrivacyDialogIfNeeded(context);
      if (privacyAccepted && context.mounted) {
        // Log install info when onboarding is completed
        AnalyticsService().logInstallInfo();

        // API key guide will only show after privacy is accepted
        await showApiKeyGuideIfNeeded(context, _apiKey, _updateApiKey);

        // Check for app updates after initial setup
        _checkForUpdates();

        // Automatically process any unprocessed screenshots
        _autoProcessWithGemini();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // Clean up file watcher
    _fileWatcherSubscription?.cancel();
    _fileWatcher.dispose();

    super.dispose();
  }

  /// Setup listeners for background service events
  void _setupBackgroundServiceListeners() {
    print("Setting up background service listeners...");

    final service = FlutterBackgroundService();

    // Listen for batch processing updates with the new channel name
    service.on('batch_processed').listen((event) {
      try {
        if (event != null && mounted) {
          final data = Map<String, dynamic>.from(event);
          final updatedScreenshotsJson = data['updatedScreenshots'] as String?;
          final responseJson = data['response'] as String?;
          final processedCount = data['processedCount'] as int? ?? 0;
          final totalCount = data['totalCount'] as int? ?? 0;

          print(
            "Main app: Processing batch update - $processedCount/$totalCount",
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

            // Process auto-categorization if response data is available
            Map<String, dynamic>? response;
            if (responseJson != null) {
              try {
                response = jsonDecode(responseJson) as Map<String, dynamic>;
              } catch (e) {
                print("Main app: Error parsing response JSON: $e");
              }
            }

            setState(() {
              _aiProcessedCount = processedCount;
              _aiTotalToProcess = totalCount;

              // Update screenshots in our list and handle auto-categorization
              for (var updatedScreenshot in updatedScreenshots) {
                final index = _screenshots.indexWhere(
                  (s) => s.id == updatedScreenshot.id,
                );
                if (index != -1) {
                  _screenshots[index] = updatedScreenshot;
                  print("Main app: Updated screenshot ${updatedScreenshot.id}");

                  // Handle auto-categorization for this screenshot
                  if (response != null &&
                      response['suggestedCollections'] != null) {
                    _handleAutoCategorization(updatedScreenshot, response);
                  }
                }
              }
            });

            // Log AI processing success analytics
            AnalyticsService().logAIProcessingSuccess(
              updatedScreenshots.length,
            );
            AnalyticsService().logTotalScreenshotsProcessed(
              _screenshots.where((s) => s.aiProcessed).length,
            );

            // Save updated data
            _saveDataToPrefs();
          }
        }
      } catch (e) {
        print("Main app: Error processing batch update: $e");
      }
    });

    // Listen for processing completion with the new channel name
    service.on('processing_completed').listen((event) {
      print("Main app: Received processing completed event: $event");

      try {
        if (event != null && mounted) {
          final data = Map<String, dynamic>.from(event);
          final success = data['success'] as bool? ?? false;
          final processedCount = data['processedCount'] as int? ?? 0;
          final totalCount = data['totalCount'] as int? ?? 0;
          final error = data['error'] as String?;
          final cancelled = data['cancelled'] as bool? ?? false;

          print(
            "Main app: Processing completed - Success: $success, Processed: $processedCount/$totalCount",
          );

          setState(() {
            _isProcessingAI = false;
            _aiProcessedCount = 0;
            _aiTotalToProcess = 0;
          });

          if (cancelled) {
            SnackbarService().showWarning(
              context,
              'Processing cancelled. Processed $processedCount of $totalCount screenshots.',
            );
          } else if (success) {
            SnackbarService().showSuccess(
              context,
              'Completed processing $processedCount of $totalCount screenshots.',
            );
          } else {
            SnackbarService().showError(
              context,
              error ?? 'Failed to process screenshots',
            );
          }

          // Save final data
          _saveDataToPrefs();
        }
      } catch (e) {
        print("Main app: Error processing completion event: $e");
      }
    });

    // Listen for processing errors with the new channel name
    service.on('processing_error').listen((event) {
      print("Main app: Received processing error event: $event");

      try {
        if (event != null && mounted) {
          final data = Map<String, dynamic>.from(event);
          final error = data['error'] as String? ?? 'Unknown error';

          print("Main app: Processing error: $error");

          setState(() {
            _isProcessingAI = false;
            _aiProcessedCount = 0;
            _aiTotalToProcess = 0;
          });

          SnackbarService().showError(context, 'Processing error: $error');

          // Save data even on error
          _saveDataToPrefs();
        }
      } catch (e) {
        print("Main app: Error handling processing error event: $e");
      }
    });

    // Listen for initialization confirmation
    service.on('initialize').listen((event) {
      print("Main app: Received service initialization event: $event");
    });

    print("Background service listeners setup complete");
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Only clear cache when app is completely detached to preserve collection thumbnails
    if (state == AppLifecycleState.detached) {
      MemoryUtils.clearImageCache();
    }

    // Manage file watcher based on app lifecycle
    if (!kIsWeb) {
      if (state == AppLifecycleState.resumed) {
        // Start file watching when app comes to foreground
        _fileWatcher.startWatching();
      } else if (state == AppLifecycleState.paused) {
        // Stop file watching when app goes to background to save resources
        _fileWatcher.stopWatching();
      }
    }

    // Auto-process unprocessed screenshots when the app comes to foreground
    if (state == AppLifecycleState.resumed) {
      // Add a small delay to ensure the UI is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        _autoProcessWithGemini();
      });
    }
  }

  Future<void> _saveDataToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedScreenshots = jsonEncode(
      _screenshots.map((s) => s.toJson()).toList(),
    );
    await prefs.setString('screenshots', encodedScreenshots);

    final String encodedCollections = jsonEncode(
      _collections.map((c) => c.toJson()).toList(),
    );
    await prefs.setString('collections', encodedCollections);
    print("Data saved to SharedPreferences");
  }

  Future<void> _loadDataFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final String? storedScreenshots = prefs.getString('screenshots');
    if (storedScreenshots != null && storedScreenshots.isNotEmpty) {
      final List<dynamic> decodedScreenshots = jsonDecode(storedScreenshots);
      setState(() {
        _screenshots.clear();
        _screenshots.addAll(
          decodedScreenshots.map(
            (json) => Screenshot.fromJson(json as Map<String, dynamic>),
          ),
        );
      });
    }

    final String? storedCollections = prefs.getString('collections');
    if (storedCollections != null && storedCollections.isNotEmpty) {
      final List<dynamic> decodedCollections = jsonDecode(storedCollections);
      setState(() {
        _collections.clear();
        _collections.addAll(
          decodedCollections.map(
            (json) => Collection.fromJson(json as Map<String, dynamic>),
          ),
        );
      });
    }
    print("Data loaded from SharedPreferences");
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKey = prefs.getString('apiKey');
      _selectedModelName = prefs.getString('modelName') ?? 'gemini-2.0-flash';
      _screenshotLimit = prefs.getInt('limit') ?? 1200;
      _maxParallelAI = prefs.getInt('maxParallel') ?? 4;
      _isScreenshotLimitEnabled = prefs.getBool('limit_enabled') ?? false;
      _devMode = prefs.getBool('dev_mode') ?? false;
      _autoProcessEnabled = prefs.getBool('auto_process_enabled') ?? true;
      _analyticsEnabled =
          prefs.getBool('analytics_consent_enabled') ?? !kDebugMode;
    });
  }

  void _updateApiKey(String newApiKey) {
    setState(() {
      _apiKey = newApiKey;
    });
    // Save to SharedPreferences
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('apiKey', newApiKey);
    });
  }

  void _updateModelName(String newModelName) {
    setState(() {
      _selectedModelName = newModelName;
    });
  }

  void _updateScreenshotLimit(int newLimit) {
    setState(() {
      _screenshotLimit = newLimit;
    });
  }

  void _updateScreenshotLimitEnabled(bool enabled) {
    setState(() {
      _isScreenshotLimitEnabled = enabled;
    });
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('limit_enabled', enabled);
    });
  }

  void _updateMaxParallelAI(int newMaxParallel) {
    setState(() {
      _maxParallelAI = newMaxParallel;
    });
  }

  void _updateDevMode(bool value) {
    setState(() {
      _devMode = value;
    });
    // Save to SharedPreferences
    _saveDevMode(value);
  }

  void _updateAutoProcessEnabled(bool enabled) {
    setState(() {
      _autoProcessEnabled = enabled;
    });
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('auto_process_enabled', enabled);
    });
  }

  void _updateAnalyticsEnabled(bool enabled) {
    setState(() {
      _analyticsEnabled = enabled;
    });
    // Analytics consent is handled by the AnalyticsService directly
    // The service saves the preference and manages the consent state
  }

  Future<void> _saveDevMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dev_mode', value);
  }

  /// Check for app updates from GitHub releases
  Future<void> _checkForUpdates() async {
    try {
      final updateInfo = await UpdateCheckerService.checkForUpdates();

      if (updateInfo != null && mounted) {
        // Show update dialog
        showDialog(
          context: context,
          builder: (context) => UpdateDialog(updateInfo: updateInfo),
        );

        AnalyticsService().logFeatureUsed('update_available');
      } else if (updateInfo == null) {
        print('MainApp: No update available');
      } else if (!mounted) {
        print('MainApp: Widget not mounted, cannot show dialog');
      }
    } catch (e) {
      // as this is a background feature and errors shouldn't interrupt user flow
      print('MainApp: Update check failed: $e');

      // Log analytics for update check failures
      AnalyticsService().logFeatureUsed('update_check_failed');
    }
  }

  Future<void> _processWithGemini() async {
    print("Main app: _processWithGemini called");

    // Check for API key
    if (_apiKey == null || _apiKey!.isEmpty) {
      print("Main app: No API key configured");
      SnackbarService().showError(
        context,
        'Gemini API key not configured. Please check app settings.',
      );
      return;
    }

    // Get unprocessed screenshots
    final unprocessedScreenshots =
        _activeScreenshots.where((s) => !s.aiProcessed).toList();

    if (unprocessedScreenshots.isEmpty) {
      print("Main app: No unprocessed screenshots found");
      SnackbarService().showInfo(
        context,
        'All screenshots have already been processed.',
      );
      return;
    }

    print(
      "Main app: Starting background processing for ${unprocessedScreenshots.length} screenshots",
    );

    // Update UI to show processing state
    setState(() {
      _isProcessingAI = true;
      _aiProcessedCount = 0;
      _aiTotalToProcess = unprocessedScreenshots.length;
    });

    // Get list of collections that have auto-add enabled
    final autoAddCollections =
        _collections
            .where((collection) => collection.isAutoAddEnabled)
            .map(
              (collection) => {
                'name': collection.name,
                'description': collection.description,
                'id': collection.id,
              },
            )
            .toList();

    print("Main app: Auto-add collections count: ${autoAddCollections.length}");

    try {
      // Use the background processing approach
      final backgroundService = BackgroundProcessingService();

      print("Main app: Initializing background service...");

      // Simple service initialization
      final serviceInitialized = await backgroundService.initializeService();

      if (!serviceInitialized) {
        print("Main app: Service initialization failed");
        setState(() {
          _isProcessingAI = false;
          _aiProcessedCount = 0;
          _aiTotalToProcess = 0;
        });

        SnackbarService().showError(
          context,
          'Failed to initialize background service. Please try again.',
        );
        return;
      }

      print("Main app: Background service initialized, starting processing...");

      // Start the processing with the initialized service
      print(
        "Main app: Calling startBackgroundProcessing with ${unprocessedScreenshots.length} screenshots",
      );
      final success = await backgroundService.startBackgroundProcessing(
        screenshots: unprocessedScreenshots,
        apiKey: _apiKey!,
        modelName: _selectedModelName,
        maxParallel: _maxParallelAI,
        autoAddCollections: autoAddCollections,
      );
      print("Main app: startBackgroundProcessing returned: $success");

      if (success) {
        print("Main app: Background processing started successfully");
        SnackbarService().showInfo(
          context,
          'Processing started for ${unprocessedScreenshots.length} screenshots.',
        );
      } else {
        print("Main app: Failed to start background processing");
        setState(() {
          _isProcessingAI = false;
          _aiProcessedCount = 0;
          _aiTotalToProcess = 0;
        });

        SnackbarService().showError(
          context,
          'Failed to start background processing. Please try again.',
        );
      }
    } catch (e) {
      print("Main app: Error starting background processing: $e");

      setState(() {
        _isProcessingAI = false;
        _aiProcessedCount = 0;
        _aiTotalToProcess = 0;
      });

      // Show error notification
      SnackbarService().showError(
        context,
        'Error starting background processing: $e',
      );
    }
  }

  Future<void> _stopProcessingAI() async {
    if (_isProcessingAI) {
      print("Main app: Stopping background processing...");

      // Update UI immediately to reflect stopping state
      setState(() {
        _aiTotalToProcess = 0;
      });

      try {
        // Use the new stopBackgroundProcessing method that doesn't shut down the service
        final backgroundService = BackgroundProcessingService();
        await backgroundService.stopBackgroundProcessing();
        print("Main app: Background processing stop requested");

        // No need to show notification here, the service will report back with a cancelled status
        // and the listener will handle showing the notification
      } catch (e) {
        print("Main app: Error stopping background processing: $e");

        // Show error notification only if an exception occurred during the stop request
        SnackbarService().showWarning(
          context,
          'Error stopping AI processing: $e',
        );
      }

      await _saveDataToPrefs();
      setState(() {
        _isProcessingAI = false;
      });
    }
  }

  /// Restart AI processing when a new auto-add enabled collection is created or enabled
  /// This ensures seamless operation by including the new collection in the processing workflow
  Future<void> _restartProcessingForNewAutoAddCollection() async {
    print("Main app: Restarting processing for new auto-add collection...");

    // Log analytics for restart operation
    AnalyticsService().logFeatureUsed('auto_add_processing_restart_initiated');

    try {
      // Stop current processing
      await _stopProcessingAI();

      // Wait a moment for the stop to complete
      await Future.delayed(const Duration(milliseconds: 500));

      // Check if there are any unprocessed screenshots to restart processing
      final unprocessedScreenshots =
          _activeScreenshots.where((s) => !s.aiProcessed).toList();

      if (unprocessedScreenshots.isNotEmpty) {
        // Restart processing with the updated collection list (including new auto-add collection)
        print(
          "Main app: Restarting processing with ${unprocessedScreenshots.length} unprocessed screenshots",
        );
        AnalyticsService().logFeatureUsed(
          'auto_add_processing_restart_success',
        );
        await _processWithGemini();
      } else {
        print("Main app: No unprocessed screenshots to restart processing");
        AnalyticsService().logFeatureUsed(
          'auto_add_processing_restart_no_screenshots',
        );
      }
    } catch (e) {
      print(
        "Main app: Error restarting processing for new auto-add collection: $e",
      );
      AnalyticsService().logFeatureUsed('auto_add_processing_restart_error');
      SnackbarService().showWarning(
        context,
        'Error restarting processing for new collection: $e',
      );
    }
  }

  Future<void> _takeScreenshot(ImageSource source) async {
    try {
      final startTime = DateTime.now();

      // Log feature usage
      String sourceStr = source == ImageSource.camera ? 'camera' : 'gallery';
      AnalyticsService().logFeatureUsed('image_picker_$sourceStr');

      List<XFile>? images;

      if (source == ImageSource.camera) {
        // Take a photo with the camera
        final XFile? image = await _picker.pickImage(source: source);
        if (image != null) {
          images = [image];
        }
      } else if (kIsWeb) {
        images = await _picker.pickMultiImage();
      } else {
        images = await _picker.pickMultiImage();
      }

      if (images != null && images.isNotEmpty) {
        setState(() {
          _isLoading = true;
        });

        List<Screenshot> newScreenshots = [];
        for (var image in images) {
          final bytes = await image.readAsBytes();
          final String imageId = _uuid.v4();
          final String imageName = image.name;

          // Check if a screenshot with the same path (if available) or bytes already exists
          // For web, path might be null, so rely on bytes if path is not distinctive
          bool exists = false;
          if (!kIsWeb && image.path.isNotEmpty) {
            exists = _screenshots.any((s) => s.path == image.path);
          } else {
            // for web, check is removed since path is not available
          }

          if (exists) {
            print(
              'Skipping already loaded image: ${image.path.isNotEmpty ? image.path : imageName}',
            );
            continue;
          }

          newScreenshots.add(
            Screenshot(
              id: imageId,
              path: kIsWeb ? null : image.path,
              bytes: kIsWeb || !File(image.path).existsSync() ? bytes : null,
              title: imageName,
              tags: [],
              aiProcessed: false,
              addedOn: DateTime.now(),
              fileSize: bytes.length,
            ),
          );
        }

        setState(() {
          _screenshots.addAll(newScreenshots);
          _isLoading = false;
          _loadingProgress = 0;
          _totalToLoad = 0;
        });
        await _saveDataToPrefs();

        // Log image loading analytics
        final loadTime = DateTime.now().difference(startTime).inMilliseconds;
        String sourceStr = source == ImageSource.camera ? 'camera' : 'gallery';
        AnalyticsService().logImageLoadTime(loadTime, sourceStr);
        AnalyticsService().logTotalScreenshotsProcessed(_screenshots.length);

        // Auto-process the newly added screenshots
        if (newScreenshots.isNotEmpty) {
          _autoProcessWithGemini();
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _loadingProgress = 0;
        _totalToLoad = 0;
      });

      // Log error analytics
      AnalyticsService().logNetworkError(e.toString(), 'image_picker');

      print('Error picking images: $e');
    }
  }

  Future<void> _loadAndroidScreenshots() async {
    if (kIsWeb) return;

    // Check if screenshots are already loaded to avoid redundant loading on hot reload/restart
    // This simple check might need refinement based on how often new screenshots are expected
    // if (_screenshots.isNotEmpty && !_isLoading) { // Basic check
    //   print("Android screenshots seem already loaded or loading is in progress.");
    //   return;
    // }

    try {
      // Android API level specific permission handling
      var status = await Permission.photos.request();

      // For Android 11 specifically, also check storage permission as a fallback
      if (!status.isGranted && Platform.isAndroid) {
        // Try legacy storage permission for Android 10/11 compatibility
        var storageStatus = await Permission.storage.request();
        if (storageStatus.isGranted) {
          status = storageStatus;
        }
      }

      if (!status.isGranted) {
        String errorMessage =
            'Photos permission denied. Cannot load screenshots.';
        if (Platform.isAndroid) {
          errorMessage +=
              '\n\nFor Android 11 users: Please ensure both Photos and Files permissions are granted in your device settings.';
        }
        SnackbarService().showError(context, errorMessage);
        return;
      }

      setState(() {
        _isLoading = true;
        _loadingProgress = 0;
        _totalToLoad = 0;
      });

      // Get common Android screenshot directories
      List<String> possibleScreenshotPaths = await _getScreenshotPaths();
      List<FileSystemEntity> allFiles = [];
      for (String dirPath in possibleScreenshotPaths) {
        final directory = Directory(dirPath);
        if (await directory.exists()) {
          allFiles.addAll(
            directory.listSync().whereType<File>().where(
              (file) =>
                  file.path.toLowerCase().endsWith('.png') ||
                  file.path.toLowerCase().endsWith('.jpg') ||
                  file.path.toLowerCase().endsWith('.jpeg'),
            ),
          );
        }
      }

      allFiles.sort((a, b) {
        return File(
          b.path,
        ).lastModifiedSync().compareTo(File(a.path).lastModifiedSync());
      });

      // Apply limit if enabled
      final limitedFiles =
          _isScreenshotLimitEnabled
              ? allFiles.take(_screenshotLimit).toList()
              : allFiles.toList();

      setState(() {
        _totalToLoad = limitedFiles.length;
      });

      List<Screenshot> loadedScreenshots = [];

      // Process files in batches to avoid memory spikes
      const int batchSize = 20;
      for (int i = 0; i < limitedFiles.length; i += batchSize) {
        final batch = limitedFiles.skip(i).take(batchSize);

        for (var fileEntity in batch) {
          final file = File(fileEntity.path);

          // Skip if already exists by path
          if (_screenshots.any((s) => s.path == file.path)) {
            print('Skipping already loaded file via path check: ${file.path}');
            setState(() {
              _loadingProgress++;
            });
            continue;
          }

          // Check if the file path contains ".trashed" and skip if it does
          if (file.path.contains('.trashed')) {
            print('Skipping trashed file: ${file.path}');
            setState(() {
              _loadingProgress++;
            });
            continue;
          }

          final fileSize = await file.length();

          // Skip very large files to prevent memory issues
          if (fileSize > 50 * 1024 * 1024) {
            // Skip files larger than 50MB
            print('Skipping large file: ${file.path} ($fileSize bytes)');
            setState(() {
              _loadingProgress++;
            });
            continue;
          }

          loadedScreenshots.add(
            Screenshot(
              id: _uuid.v4(), // Generate new UUID for each
              path: file.path,
              title: file.path.split('/').last,
              tags: [],
              aiProcessed: false,
              addedOn: await file.lastModified(),
              fileSize: fileSize,
            ),
          );

          setState(() {
            _loadingProgress++;
          });
        }

        // Update UI periodically to show progress
        if (i % batchSize == 0 && loadedScreenshots.isNotEmpty) {
          setState(() {
            _screenshots.insertAll(0, loadedScreenshots);
          });
          loadedScreenshots.clear();
          // Small delay to prevent UI blocking
          await Future.delayed(const Duration(milliseconds: 10));
        }
      }

      // Add any remaining screenshots
      if (loadedScreenshots.isNotEmpty) {
        setState(() {
          _screenshots.insertAll(0, loadedScreenshots);
        });
      }

      setState(() {
        _isLoading = false;
        _loadingProgress = 0;
        _totalToLoad = 0;
      });
      await _saveDataToPrefs();

      // Auto-process newly loaded screenshots
      if (_screenshots.isNotEmpty) {
        _autoProcessWithGemini();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _loadingProgress = 0;
        _totalToLoad = 0;
      });
      print('Error loading Android screenshots: $e');
    }
  }

  Future<List<String>> _getScreenshotPaths() async {
    List<String> paths = [];

    try {
      // Get external storage directory
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        String baseDir = externalDir.path.split('/Android')[0];

        // Common screenshot paths on different Android devices
        paths.addAll([
          '$baseDir/DCIM/Screenshots',
          '$baseDir/Pictures/Screenshots',
        ]);
      }
    } catch (e) {
      print('Error getting screenshot paths: $e');
    }

    return paths;
  }

  void _addCollection(Collection collection) {
    setState(() {
      _collections.add(collection);
    });
    _saveDataToPrefs();

    // Log analytics
    AnalyticsService().logCollectionCreated();
    AnalyticsService().logTotalCollections(_collections.length);
    _logCollectionStats();

    // If the new collection has autoAddEnabled, ensure processing starts/restarts
    // to include the new auto-add enabled collection
    if (collection.isAutoAddEnabled) {
      // Log analytics for auto-add collection creation
      AnalyticsService().logFeatureUsed('auto_add_collection_created');

      if (_isProcessingAI) {
        // If already processing, restart to include the new collection
        AnalyticsService().logFeatureUsed(
          'auto_add_collection_restart_processing',
        );
        _restartProcessingForNewAutoAddCollection();
      } else {
        // If not processing, start processing to handle the new auto-add collection
        AnalyticsService().logFeatureUsed(
          'auto_add_collection_start_processing',
        );
        _autoProcessWithGemini();
      }
    }
  }

  void _updateCollection(Collection updatedCollection) {
    // Check if autoAddEnabled was just turned on
    bool wasAutoAddJustEnabled = false;
    final index = _collections.indexWhere((c) => c.id == updatedCollection.id);
    if (index != -1) {
      final oldCollection = _collections[index];
      wasAutoAddJustEnabled =
          !oldCollection.isAutoAddEnabled && updatedCollection.isAutoAddEnabled;
    }

    setState(() {
      if (index != -1) {
        _collections[index] = updatedCollection;
      }
    });
    _saveDataToPrefs();

    // Log collection stats after update
    _logCollectionStats();

    // If autoAddEnabled was just turned on, ensure processing starts/restarts
    // to include the newly auto-add enabled collection
    if (wasAutoAddJustEnabled) {
      // Log analytics for auto-add being enabled on existing collection
      AnalyticsService().logFeatureUsed('auto_add_collection_enabled');

      if (_isProcessingAI) {
        // If already processing, restart to include the updated collection
        AnalyticsService().logFeatureUsed(
          'auto_add_enabled_restart_processing',
        );
        _restartProcessingForNewAutoAddCollection();
      } else {
        // If not processing, start processing to handle the newly enabled auto-add collection
        AnalyticsService().logFeatureUsed('auto_add_enabled_start_processing');
        _autoProcessWithGemini();
      }
    }
  }

  void _updateCollections(List<Collection> updatedCollections) {
    setState(() {
      _collections.clear();
      _collections.addAll(updatedCollections);
    });
    _saveDataToPrefs();

    AnalyticsService().logFeatureUsed('collections_bulk_updated');
  }

  void _deleteCollection(String collectionId) {
    setState(() {
      _collections.removeWhere((c) => c.id == collectionId);
      for (var screenshot in _screenshots) {
        screenshot.collectionIds.remove(collectionId);
      }
    });
    _saveDataToPrefs();

    // Log analytics
    AnalyticsService().logCollectionDeleted();
    AnalyticsService().logTotalCollections(_collections.length);
    _logCollectionStats();
  }

  void _logCollectionStats() {
    if (_collections.isEmpty) return;

    // Calculate collection statistics
    final screenshotCounts =
        _collections.map((c) => c.screenshotIds.length).toList();
    final totalScreenshots = screenshotCounts.fold(
      0,
      (sum, count) => sum + count,
    );
    final avgScreenshots = totalScreenshots / _collections.length;
    final minScreenshots = screenshotCounts.reduce((a, b) => a < b ? a : b);
    final maxScreenshots = screenshotCounts.reduce((a, b) => a > b ? a : b);

    // Log collection statistics
    AnalyticsService().logCollectionStats(
      _collections.length,
      avgScreenshots.round(),
      minScreenshots,
      maxScreenshots,
    );
  }

  void _deleteScreenshot(String screenshotId) {
    setState(() {
      // Mark screenshot as deleted instead of removing it
      final screenshotIndex = _screenshots.indexWhere(
        (s) => s.id == screenshotId,
      );
      if (screenshotIndex != -1) {
        _screenshots[screenshotIndex].isDeleted = true;
      }

      // Remove screenshot from all collections
      for (var collection in _collections) {
        if (collection.screenshotIds.contains(screenshotId)) {
          final updatedCollection = collection.removeScreenshot(screenshotId);
          _updateCollection(updatedCollection);
        }
      }
    });
    _saveDataToPrefs();
  }

  void _bulkDeleteScreenshots(List<String> screenshotIds) {
    if (screenshotIds.isEmpty) return;

    // Log bulk delete analytics
    AnalyticsService().logFeatureUsed('bulk_delete_screenshots');

    setState(() {
      // Mark all screenshots as deleted
      for (String screenshotId in screenshotIds) {
        final screenshotIndex = _screenshots.indexWhere(
          (s) => s.id == screenshotId,
        );
        if (screenshotIndex != -1) {
          _screenshots[screenshotIndex].isDeleted = true;
        }

        // Remove screenshot from all collections
        for (var collection in _collections) {
          if (collection.screenshotIds.contains(screenshotId)) {
            final updatedCollection = collection.removeScreenshot(screenshotId);
            _updateCollection(updatedCollection);
          }
        }
      }
    });

    _saveDataToPrefs();

    // Log analytics for the number of screenshots deleted
    AnalyticsService().logFeatureUsed(
      'bulk_delete_count_${screenshotIds.length}',
    );
  }

  void _navigateToSearchScreen() {
    // Log navigation analytics
    AnalyticsService().logScreenView('search_screen');
    AnalyticsService().logUserPath('home_screen', 'search_screen');
    AnalyticsService().logFeatureUsed('search');

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => SearchScreen(
              allScreenshots: _activeScreenshots,
              allCollections: _collections,
              onUpdateCollection: _updateCollection,
              onDeleteScreenshot: _deleteScreenshot,
            ),
      ),
    );
  }

  /// Handle auto-categorization for a screenshot based on AI suggestions
  void _handleAutoCategorization(
    Screenshot screenshot,
    Map<String, dynamic> response,
  ) {
    try {
      Map<dynamic, dynamic>? suggestionsMap;
      if (response['suggestedCollections'] is Map<String, List<String>>) {
        suggestionsMap =
            response['suggestedCollections'] as Map<String, List<String>>;
      } else if (response['suggestedCollections'] is Map<dynamic, dynamic>) {
        suggestionsMap =
            response['suggestedCollections'] as Map<dynamic, dynamic>;
      }

      List<String> suggestedCollections = [];
      if (suggestionsMap != null && suggestionsMap.containsKey(screenshot.id)) {
        final suggestions = suggestionsMap[screenshot.id];
        if (suggestions is List) {
          suggestedCollections = List<String>.from(
            suggestions.whereType<String>(),
          );
        } else if (suggestions is String) {
          suggestedCollections = [suggestions];
        }
      }

      if (suggestedCollections.isNotEmpty) {
        int autoAddedCount = 0;
        for (var collection in _collections) {
          if (collection.isAutoAddEnabled &&
              suggestedCollections.contains(collection.name) &&
              !screenshot.collectionIds.contains(collection.id) &&
              !collection.screenshotIds.contains(screenshot.id)) {
            // Auto-add screenshot to this collection
            final updatedCollection = collection.addScreenshot(
              screenshot.id,
              isAutoCategorized: true,
            );
            _updateCollection(updatedCollection);
            screenshot.collectionIds.add(collection.id);
            autoAddedCount++;
          }
        }

        if (autoAddedCount > 0) {
          print(
            "Main app: Auto-categorized screenshot ${screenshot.id} into $autoAddedCount collection(s)",
          );

          // Log auto-categorization analytics
          AnalyticsService().logScreenshotsAutoCategorized(autoAddedCount);
          AnalyticsService().logFeatureUsed('auto_categorization');
        }
      }
    } catch (e) {
      print('Main app: Error handling auto-categorization: $e');
    }
  }

  // Helper method to check and auto-process screenshots
  Future<void> _autoProcessWithGemini() async {
    // Only auto-process if enabled, we have an API key, we're not already processing,
    if (_autoProcessEnabled &&
        _apiKey != null &&
        _apiKey!.isNotEmpty &&
        !_isProcessingAI) {
      // Check if there are any unprocessed screenshots
      final unprocessedScreenshots =
          _activeScreenshots.where((s) => !s.aiProcessed).toList();
      if (unprocessedScreenshots.isNotEmpty) {
        // Add a small delay to allow UI to update before processing starts
        await Future.delayed(const Duration(milliseconds: 300));

        await _processWithGemini();
      }
    }
  }

  /// Setup file watcher for seamless autoscanning
  void _setupFileWatcher() {
    print("Setting up file watcher for seamless autoscanning...");

    // Listen to new screenshots from file watcher
    _fileWatcherSubscription = _fileWatcher.newScreenshotsStream.listen((
      newScreenshots,
    ) {
      print("FileWatcher: Detected ${newScreenshots.length} new screenshots");

      if (newScreenshots.isNotEmpty && mounted) {
        // Filter out screenshots we already have
        final uniqueScreenshots = <Screenshot>[];
        for (final screenshot in newScreenshots) {
          final exists = _screenshots.any((s) => s.path == screenshot.path);
          if (!exists) {
            uniqueScreenshots.add(screenshot);
          }
        }

        if (uniqueScreenshots.isNotEmpty) {
          setState(() {
            _screenshots.addAll(uniqueScreenshots);
          });

          // Save data and auto-process the new screenshots
          _saveDataToPrefs();

          print(
            "FileWatcher: Added ${uniqueScreenshots.length} new screenshots",
          );

          // Auto-process newly detected screenshots if enabled
          if (_autoProcessEnabled) {
            _autoProcessWithGemini();
          }

          // Show a subtle notification
          if (mounted && context.mounted) {
            SnackbarService().showInfo(
              context,
              'Found ${uniqueScreenshots.length} new screenshot${uniqueScreenshots.length == 1 ? '' : 's'}',
            );
          }
        }
      }
    });

    // Start watching for files
    _fileWatcher.startWatching();
    print("File watcher setup complete");
  }

  /// Reset AI processing status for all screenshots
  Future<void> _resetAiMetaData() async {
    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Reset AI Processing',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          content: Text(
            'This will reset the AI processing status for all screenshots, allowing you to re-request AI analysis. This action cannot be undone.\n\nContinue?',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text(
                'Reset',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      // Reset aiProcessed status for all screenshots
      setState(() {
        for (var screenshot in _screenshots) {
          screenshot.aiProcessed = false;
          screenshot.aiMetadata = null;
          // Optionally clear AI-generated data
          // screenshot.title = null;
          // screenshot.description = null;
          // screenshot.tags.clear();
        }

        // clear scannedSet from collections
        for (var collection in _collections) {
          collection.scannedSet.clear();
        }
      });

      // Save the updated data
      await _saveDataToPrefs();

      AnalyticsService().logFeatureUsed('ai_processing_reset');

      SnackbarService().showSuccess(context, 'AI processing status reset');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeAppBar(
        onProcessWithAI: _isProcessingAI ? null : _processWithGemini,
        isProcessingAI: _isProcessingAI,
        aiProcessedCount: _aiProcessedCount,
        aiTotalToProcess: _aiTotalToProcess,
        onSearchPressed: _navigateToSearchScreen,
        onStopProcessingAI: _stopProcessingAI,
        devMode: _devMode,
        autoProcessEnabled: _autoProcessEnabled,
      ),
      drawer: AppDrawer(
        currentApiKey: _apiKey,
        currentModelName: _selectedModelName,
        onApiKeyChanged: _updateApiKey,
        onModelChanged: _updateModelName,
        currentLimit: _screenshotLimit,
        onLimitChanged: _updateScreenshotLimit,
        currentMaxParallel: _maxParallelAI,
        onMaxParallelChanged: _updateMaxParallelAI,
        currentLimitEnabled: _isScreenshotLimitEnabled,
        onLimitEnabledChanged: _updateScreenshotLimitEnabled,
        currentDevMode: _devMode,
        onDevModeChanged: _updateDevMode,
        currentAutoProcessEnabled: _autoProcessEnabled,
        onAutoProcessEnabledChanged: _updateAutoProcessEnabled,
        currentAnalyticsEnabled: _analyticsEnabled,
        onAnalyticsEnabledChanged: _updateAnalyticsEnabled,
        apiKeyFieldKey: _apiKeyFieldKey,
        onResetAiProcessing: _resetAiMetaData,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show options for selecting screenshots
          showModalBottomSheet(
            context: context,
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder:
                (context) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.photo_library),
                        title: const Text('Select from gallery'),
                        onTap: () {
                          Navigator.pop(context);
                          _takeScreenshot(ImageSource.gallery);
                        },
                      ),
                      if (!kIsWeb) // Camera option only for mobile
                        ListTile(
                          leading: const Icon(Icons.camera_alt),
                          title: const Text('Take a photo'),
                          onTap: () {
                            Navigator.pop(context);
                            _takeScreenshot(ImageSource.camera);
                          },
                        ),
                      if (!kIsWeb) // Android screenshot loading option
                        ListTile(
                          leading: const Icon(Icons.folder_open),
                          title: const Text('Load device screenshots'),
                          onTap: () {
                            Navigator.pop(context);
                            _loadAndroidScreenshots();
                          },
                        ),
                    ],
                  ),
                ),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(
          Icons.add_a_photo,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text('Loading screenshots...'),
                    if (_totalToLoad > 0) ...[
                      const SizedBox(height: 8),
                      Text('$_loadingProgress / $_totalToLoad'),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value:
                            _totalToLoad > 0
                                ? _loadingProgress / _totalToLoad
                                : 0,
                      ),
                    ],
                  ],
                ),
              )
              : NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          // AI Processing Container
                          AIProcessingContainer(
                            isProcessing: _isProcessingAI,
                            processedCount: _aiProcessedCount,
                            totalCount: _aiTotalToProcess,
                          ),
                          // Collections Section
                          CollectionsSection(
                            collections: _collections,
                            screenshots: _activeScreenshots,
                            onCollectionAdded: _addCollection,
                            onUpdateCollection: _updateCollection,
                            onUpdateCollections: _updateCollections,
                            onDeleteCollection: _deleteCollection,
                            onDeleteScreenshot: _deleteScreenshot,
                          ),
                        ],
                      ),
                    ),
                  ];
                },
                body: ScreenshotsSection(
                  screenshots: _activeScreenshots,
                  onScreenshotTap: _showScreenshotDetail,
                  onBulkDelete: _bulkDeleteScreenshots,
                  screenshotDetailBuilder: (context, screenshot) {
                    final int initialIndex = _activeScreenshots.indexWhere(
                      (s) => s.id == screenshot.id,
                    );
                    return ScreenshotSwipeDetailScreen(
                      screenshots: List.from(_activeScreenshots),
                      initialIndex: initialIndex >= 0 ? initialIndex : 0,
                      allCollections: _collections,
                      allScreenshots: _screenshots,
                      onUpdateCollection: (updatedCollection) {
                        _updateCollection(updatedCollection);
                      },
                      onDeleteScreenshot: _deleteScreenshot,
                      onScreenshotUpdated: () {
                        setState(() {});
                      },
                    );
                  },
                ),
              ),
    );
  }

  void _showScreenshotDetail(Screenshot screenshot) {
    // Log navigation analytics
    AnalyticsService().logScreenView('screenshot_detail_screen');
    AnalyticsService().logUserPath('home_screen', 'screenshot_detail_screen');
    AnalyticsService().logFeatureUsed('screenshot_detail_view');

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder:
                (context) => ScreenshotDetailScreen(
                  screenshot: screenshot,
                  allCollections: _collections,
                  allScreenshots: _screenshots,
                  onUpdateCollection: (updatedCollection) {
                    _updateCollection(updatedCollection);
                  },
                  onDeleteScreenshot: _deleteScreenshot,
                  onScreenshotUpdated: () {
                    setState(() {});
                  },
                ),
          ),
        )
        .then((_) {
          _saveDataToPrefs();
          // Don't clear cache to preserve collection thumbnails
        });
  }
}
