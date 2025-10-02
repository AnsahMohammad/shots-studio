import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shots_studio/l10n/app_localizations.dart';
import 'dart:async';
import 'package:shots_studio/screens/screenshot_details_screen.dart';
import 'package:shots_studio/screens/screenshot_swipe_detail_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shots_studio/widgets/home_app_bar.dart';
import 'package:shots_studio/widgets/collections/collections_section.dart';
import 'package:shots_studio/widgets/screenshots/screenshots_section.dart';
import 'package:shots_studio/widgets/expandable_fab.dart';
import 'package:shots_studio/screens/app_drawer_screen.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/models/collection_model.dart';
import 'package:shots_studio/screens/search_screen.dart';
import 'package:shots_studio/screens/reminders_screen.dart';
import 'package:shots_studio/screens/privacy_screen.dart';
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
import 'package:shots_studio/services/analytics/analytics_service.dart';
import 'package:shots_studio/services/file_watcher_service.dart';
import 'package:shots_studio/services/update_checker_service.dart';
import 'package:shots_studio/widgets/update_dialog.dart';
import 'package:shots_studio/widgets/server_message_dialog.dart';
import 'package:shots_studio/utils/theme_utils.dart';
import 'package:shots_studio/utils/theme_manager.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shots_studio/services/image_loader_service.dart';
import 'package:shots_studio/services/custom_path_service.dart';
import 'package:shots_studio/services/corrupt_file_service.dart';
import 'package:shots_studio/widgets/custom_paths_dialog.dart';
import 'package:shots_studio/utils/build_source.dart';
import 'package:shots_studio/utils/display_utils.dart';

void main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://6f96d22977b283fc325e038ac45e6e5e@o4509484018958336.ingest.us.sentry.io/4509484020072448';

      options.tracesSampleRate =
          kDebugMode ? 0 : 0.1; // 30% in debug, 10% in production
    },
    appRunner: () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize display refresh rate detection and optimization
      await DisplayUtils.initializeHighRefreshRate();

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
      }

      runApp(SentryWidget(child: const MyApp()));
    },
  );
}

// Set up notification channel for background service
Future<void> _setupBackgroundServiceNotificationChannel() async {
  const AndroidNotificationChannel
  aiProcessingChannel = AndroidNotificationChannel(
    'ai_processing_channel', // id - matches BackgroundProcessingService.notificationChannelId
    'AI Processing Service',
    description: 'Channel for AI screenshot processing notifications',
    importance: Importance.low,
  );

  const AndroidNotificationChannel serverMessagesChannel =
      AndroidNotificationChannel(
        'server_messages_channel',
        'Server Messages',
        description: 'Channel for server messages and announcements',
        importance: Importance.high,
      );

  const AndroidNotificationChannel urgentServerMessagesChannel =
      AndroidNotificationChannel(
        'server_messages_urgent',
        'Urgent Server Messages',
        description: 'Channel for urgent server messages',
        importance: Importance.max,
      );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(aiProcessingChannel);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(serverMessagesChannel);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(urgentServerMessagesChannel);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _amoledModeEnabled = false;
  String _selectedTheme = 'Adaptive Theme';
  Locale _selectedLocale = const Locale('en'); // Default to English

  @override
  void initState() {
    super.initState();
    _loadThemeSettings();
    _loadLocaleSettings();
  }

  Future<void> _loadThemeSettings() async {
    final amoledMode = await ThemeManager.getAmoledMode();
    final selectedTheme = await ThemeManager.getSelectedTheme();
    setState(() {
      _amoledModeEnabled = amoledMode;
      _selectedTheme = selectedTheme;
    });
  }

  Future<void> _loadLocaleSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('selected_language') ?? 'en';
    setState(() {
      _selectedLocale = Locale(languageCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final (lightScheme, darkScheme) = ThemeManager.createColorSchemes(
          lightDynamic: lightDynamic,
          darkDynamic: darkDynamic,
          selectedTheme: _selectedTheme,
          amoledModeEnabled: _amoledModeEnabled,
        );

        return MaterialApp(
          title: 'Shots Studio',
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'), // English
            Locale('hi'), // Hindi
            Locale('de'), // German
            Locale('zh'), // Chinese
            Locale('pt'), // Portuguese
            Locale('ar'), // Arabic
            Locale('es'), // Spanish
            Locale('fr'), // French
            Locale('it'), // Italian
            Locale('ja'), // Japanese
            Locale('pl'), // Polish
            Locale('ru'), // Russian
          ],
          locale: _selectedLocale, // Use the selected locale
          theme: ThemeUtils.createLightTheme(lightScheme),
          darkTheme: ThemeUtils.createDarkTheme(darkScheme),
          themeMode:
              ThemeMode.system, // Automatically switch between light and dark
          home: HomeScreen(
            onAmoledModeChanged: (enabled) async {
              await ThemeManager.setAmoledMode(enabled);
              setState(() {
                _amoledModeEnabled = enabled;
              });
            },
            onThemeChanged: (themeName) async {
              await ThemeManager.setSelectedTheme(themeName);
              setState(() {
                _selectedTheme = themeName;
              });
            },
            onLocaleChanged: (locale) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('selected_language', locale.languageCode);
              setState(() {
                _selectedLocale = locale;
              });
            },
          ),
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  final Function(bool)? onAmoledModeChanged;
  final Function(String)? onThemeChanged;
  final Function(Locale)? onLocaleChanged;

  const HomeScreen({
    super.key,
    this.onAmoledModeChanged,
    this.onThemeChanged,
    this.onLocaleChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final List<Screenshot> _screenshots = [];
  final List<Collection> _collections = [];
  final ImageLoaderService _imageLoaderService = ImageLoaderService();
  bool _isLoading = false;
  bool _isProcessingAI = false;
  bool _isInitializingProcessing = false;
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
  String _selectedModelName = 'gemini-2.5-flash-lite';
  int _screenshotLimit = 1200;
  int _maxParallelAI = 4;
  bool _devMode = false;
  bool _autoProcessEnabled = true;
  bool _analyticsEnabled =
      false; // Default to false for privacy - analytics is opt-in only
  bool _amoledModeEnabled = false;
  bool _betaTestingEnabled = false;
  String _selectedTheme = 'Adaptive Theme';

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

    // Initialize server message checking in background
    if (!kIsWeb) {
      _initializeServerMessageChecking();
    }

    if (!kIsWeb) {
      _loadAndroidScreenshotsIfNeeded().then((_) {
        // Setup FileWatcher only AFTER initial loading is complete
        // This ensures no duplicates from initial scan
        _setupFileWatcher();
      });
      _setupBackgroundServiceListeners();
    }
    // Show privacy dialog after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Show privacy dialog and only proceed to API key guide if accepted
      bool privacyAccepted = await showPrivacyScreenIfNeeded(context);
      if (privacyAccepted && context.mounted) {
        // Log install info when onboarding is completed
        AnalyticsService().logInstallInfo();
        // Log install source analytics
        AnalyticsService().logInstallSource(BuildSource.current.value);

        // API key guide will only show after privacy is accepted
        await showApiKeyGuideIfNeeded(context, _apiKey, _updateApiKey);

        _checkForUpdates();
        _checkForServerMessages();
        _autoProcessWithGemini();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // Clean up file watcher
    _fileWatcherSubscription?.cancel();
    super.dispose();
  }

  /// Initialize server message checking with background service
  Future<void> _initializeServerMessageChecking() async {
    try {
      final backgroundService = BackgroundProcessingService();

      // Start the background service for server message checking
      await backgroundService.startServerMessageChecking();

      // Set up listeners for server message events
      final service = FlutterBackgroundService();

      service.on('server_message_checked').listen((event) {
        if (event != null && mounted) {
          final data = Map<String, dynamic>.from(event);
          final messageFound = data['messageFound'] as bool? ?? false;

          if (messageFound) {
            print('Server message notification sent: ${data['title']}');
          }
        }
      });

      service.on('server_message_error').listen((event) {
        if (event != null) {
          final data = Map<String, dynamic>.from(event);
          print('Server message check error: ${data['error']}');
        }
      });
    } catch (e) {
      print('Failed to initialize server message checking: $e');
    }
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
            _isInitializingProcessing = false;
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
            _isInitializingProcessing = false;
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

    // Listen for safety stops from background service
    service.on('safety_stop').listen((event) {
      print("Main app: Received safety stop event: $event");

      try {
        if (event != null && mounted) {
          final data = Map<String, dynamic>.from(event);
          final reason = data['reason'] as String? ?? 'unknown';
          final message =
              data['message'] as String? ??
              'Processing stopped for resource safety';
          final modelType = data['modelType'] as String? ?? '';

          print("Main app: Safety stop - Reason: $reason, Model: $modelType");

          // Update UI state to stop processing
          setState(() {
            _isProcessingAI = false;
            _isInitializingProcessing = false;
            _aiProcessedCount = 0;
            _aiTotalToProcess = 0;
          });

          // Show appropriate notification based on reason
          if (reason == 'battery_low') {
            final batteryLevel = data['batteryLevel'] as int? ?? 0;
            SnackbarService().showWarning(
              context,
              'Gemma processing stopped due to low battery ($batteryLevel%). Connect to charger to continue.',
            );
          } else if (reason == 'network_changed') {
            SnackbarService().showWarning(
              context,
              'Gemini processing stopped - network changed from WiFi to mobile data to prevent excessive data usage.',
            );
          } else {
            SnackbarService().showWarning(context, message);
          }

          // Save final data
          _saveDataToPrefs();
        }
      } catch (e) {
        print("Main app: Error handling safety stop event: $e");
      }
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
        // Start file watching when app comes to foreground (async to avoid blocking UI)
        _startFileWatchingAsync();
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

      Future.delayed(const Duration(seconds: 2), () {
        _checkForServerMessages();
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
      _selectedModelName =
          prefs.getString('modelName') ?? 'gemini-2.5-flash-lite';
      _screenshotLimit = prefs.getInt('limit') ?? 1200;
      _maxParallelAI = prefs.getInt('maxParallel') ?? 4;
      _devMode = prefs.getBool('dev_mode') ?? false;
      _autoProcessEnabled = prefs.getBool('auto_process_enabled') ?? true;
      _analyticsEnabled =
          prefs.getBool('analytics_consent_enabled') ?? !kDebugMode;
      _amoledModeEnabled = prefs.getBool('amoled_mode_enabled') ?? false;
      _betaTestingEnabled = prefs.getBool('beta_testing_enabled') ?? false;
      _selectedTheme = prefs.getString('selected_theme') ?? 'Adaptive Theme';
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

  void _updateMaxParallelAI(int newMaxParallel) {
    setState(() {
      _maxParallelAI = newMaxParallel;
    });
    // Save to SharedPreferences
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('maxParallel', newMaxParallel);
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

  void _updateBetaTestingEnabled(bool enabled) {
    setState(() {
      _betaTestingEnabled = enabled;
    });
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('beta_testing_enabled', enabled);
    });
  }

  void _updateAmoledModeEnabled(bool enabled) {
    setState(() {
      _amoledModeEnabled = enabled;
    });
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('amoled_mode_enabled', enabled);
    });
    // Notify the parent MyApp to rebuild with new theme
    if (widget.onAmoledModeChanged != null) {
      widget.onAmoledModeChanged!(enabled);
    }
  }

  void _updateThemeSelection(String themeName) {
    setState(() {
      _selectedTheme = themeName;
    });
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('selected_theme', themeName);
    });
    // Notify the parent MyApp to rebuild with new theme
    if (widget.onThemeChanged != null) {
      widget.onThemeChanged!(themeName);
    }
  }

  Future<void> _saveDevMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dev_mode', value);
  }

  /// Check for app updates from GitHub releases
  Future<void> _checkForUpdates() async {
    // Skip update check for F-Droid and Play Store builds
    final buildSource = BuildSource.current;
    if (!buildSource.allowsUpdateCheck) {
      print(
        'MainApp: Update check disabled for ${buildSource.displayName} builds',
      );
      return;
    }

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

  /// Check for server messages and notifications
  Future<void> _checkForServerMessages() async {
    try {
      print("MainApp: Checking for server messages...");
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        await ServerMessageDialog.showServerMessageDialogIfAvailable(context);
      }
    } catch (e) {
      print('MainApp: Server message check failed: $e');

      // Log analytics for server message check failures
      AnalyticsService().logFeatureUsed('server_message_check_failed');
    }
  }

  Future<void> _processWithGemini() async {
    print("Main app: _processWithGemini called");

    // Check for API key
    //  if gemma skip API key check
    if (_selectedModelName == 'gemma') {
      print("Main app: Using Gemma model, no API key required");
    } else if (_apiKey == null || _apiKey!.isEmpty) {
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

    // Update UI to show initializing state
    setState(() {
      _isProcessingAI = true;
      _isInitializingProcessing = true;
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
        apiKey: _apiKey ?? '',
        modelName: _selectedModelName,
        maxParallel: _maxParallelAI,
        autoAddCollections: autoAddCollections,
      );
      print("Main app: startBackgroundProcessing returned: $success");

      if (success) {
        print("Main app: Background processing started successfully");
        setState(() {
          _isInitializingProcessing = false; // No longer initializing
        });
        SnackbarService().showInfo(
          context,
          'Processing started for ${unprocessedScreenshots.length} screenshots.',
        );
      } else {
        print("Main app: Failed to start background processing");
        setState(() {
          _isProcessingAI = false;
          _isInitializingProcessing = false;
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
        _isInitializingProcessing = false;
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
        _isInitializingProcessing = false;
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
        _isInitializingProcessing = false;
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
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _imageLoaderService.loadFromImagePicker(
        source: source,
        existingScreenshots: _screenshots,
      );

      if (result.success) {
        setState(() {
          _screenshots.addAll(result.screenshots);
          _isLoading = false;
          _loadingProgress = 0;
          _totalToLoad = 0;
        });

        await _saveDataToPrefs();

        // Log total screenshots analytics
        AnalyticsService().logTotalScreenshotsProcessed(_screenshots.length);

        // Auto-process the newly added screenshots
        if (result.screenshots.isNotEmpty) {
          _autoProcessWithGemini();
        }
      } else {
        setState(() {
          _isLoading = false;
          _loadingProgress = 0;
          _totalToLoad = 0;
        });

        if (result.errorMessage != null) {
          print('Error taking screenshot: ${result.errorMessage}');
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _loadingProgress = 0;
        _totalToLoad = 0;
      });
      print('Unexpected error taking screenshot: $e');
    }
  }

  Future<void> _loadAndroidScreenshots({bool forceReload = false}) async {
    if (kIsWeb) return;

    // Skip loading if we already have screenshots and it's not a forced reload
    // This prevents unnecessary reloading when the app restarts
    if (!forceReload && _screenshots.isNotEmpty) {
      print("Screenshots already loaded, skipping Android screenshot loading");
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingProgress = 0;
      _totalToLoad = 0;
    });

    try {
      // Get custom paths from preferences
      final customPaths = await CustomPathService.getCustomPaths();

      final result = await _imageLoaderService.loadAndroidScreenshots(
        existingScreenshots: _screenshots,
        isLimitEnabled: false, // Always disabled
        screenshotLimit: _screenshotLimit,
        customPaths: customPaths,
        onProgress: (current, total) {
          setState(() {
            _loadingProgress = current;
            _totalToLoad = total;
          });
        },
      );

      if (result.success) {
        setState(() {
          _screenshots.insertAll(0, result.screenshots);
          _isLoading = false;
          _loadingProgress = 0;
          _totalToLoad = 0;
        });

        await _saveDataToPrefs();

        // Auto-process newly loaded screenshots
        if (result.screenshots.isNotEmpty) {
          _autoProcessWithGemini();
        }
      } else {
        setState(() {
          _isLoading = false;
          _loadingProgress = 0;
          _totalToLoad = 0;
        });

        if (result.errorMessage != null) {
          SnackbarService().showError(context, result.errorMessage!);
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _loadingProgress = 0;
        _totalToLoad = 0;
      });
      print('Unexpected error loading Android screenshots: $e');
    }
  }

  /// Load Android screenshots only if we don't already have screenshots loaded from preferences
  Future<void> _loadAndroidScreenshotsIfNeeded() async {
    // Wait a bit for _loadDataFromPrefs to complete
    await Future.delayed(const Duration(milliseconds: 100));

    // Only load if we don't have screenshots already
    if (_screenshots.isEmpty) {
      print(
        "No screenshots found in preferences, loading from Android device...",
      );
      await _loadAndroidScreenshots();
    } else {
      print(
        "Screenshots already loaded from preferences (${_screenshots.length} screenshots)",
      );
    }
  }

  void _addCollection(Collection collection) {
    setState(() {
      _collections.add(collection);

      // Update screenshots' collectionIds to maintain bidirectional relationship
      for (String screenshotId in collection.screenshotIds) {
        final screenshotIndex = _screenshots.indexWhere(
          (s) => s.id == screenshotId,
        );
        if (screenshotIndex != -1) {
          final screenshot = _screenshots[screenshotIndex];
          if (!screenshot.collectionIds.contains(collection.id)) {
            screenshot.collectionIds.add(collection.id);
          }
        }
      }
    });

    // Force immediate save to ensure consistency
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

  void _onScreenshotUpdated() {
    setState(() {
      // Refresh UI when screenshot data changes (like aiProcessed flag)
    });
  }

  void _updateCollection(Collection updatedCollection) {
    // Check if autoAddEnabled was just turned on
    bool wasAutoAddJustEnabled = false;
    final index = _collections.indexWhere((c) => c.id == updatedCollection.id);

    Collection? oldCollection;
    if (index != -1) {
      oldCollection = _collections[index];
      wasAutoAddJustEnabled =
          !oldCollection.isAutoAddEnabled && updatedCollection.isAutoAddEnabled;
    }

    setState(() {
      if (index != -1) {
        _collections[index] = updatedCollection;

        // Maintain bidirectional relationship between screenshots and collections
        if (oldCollection != null) {
          // Find screenshots that were added to the collection
          final addedScreenshots =
              updatedCollection.screenshotIds
                  .where((id) => !oldCollection!.screenshotIds.contains(id))
                  .toList();

          // Find screenshots that were removed from the collection
          final removedScreenshots =
              oldCollection.screenshotIds
                  .where((id) => !updatedCollection.screenshotIds.contains(id))
                  .toList();

          // Update added screenshots' collectionIds
          for (String screenshotId in addedScreenshots) {
            final screenshotIndex = _screenshots.indexWhere(
              (s) => s.id == screenshotId,
            );
            if (screenshotIndex != -1) {
              final screenshot = _screenshots[screenshotIndex];
              if (!screenshot.collectionIds.contains(updatedCollection.id)) {
                screenshot.collectionIds.add(updatedCollection.id);
              }
            }
          }

          // Update removed screenshots' collectionIds
          for (String screenshotId in removedScreenshots) {
            final screenshotIndex = _screenshots.indexWhere(
              (s) => s.id == screenshotId,
            );
            if (screenshotIndex != -1) {
              final screenshot = _screenshots[screenshotIndex];
              screenshot.collectionIds.remove(updatedCollection.id);
            }
          }
        }
      }
    });

    // Force immediate save to prevent data loss and ensure consistency
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

  /// Remove screenshots that belong to a specific custom path
  void _removeScreenshotsFromPath(String removedPath) {
    print('🗑️ Removing screenshots from removed path: $removedPath');

    // Find all screenshots that belong to the removed path
    final screenshotsToRemove =
        _screenshots.where((screenshot) {
          final screenshotPath = screenshot.path;
          if (screenshotPath == null) return false;

          // Check if the screenshot's path starts with the removed path
          return screenshotPath.startsWith(removedPath);
        }).toList();

    print(
      '🗑️ Found ${screenshotsToRemove.length} screenshots to remove from path',
    );

    if (screenshotsToRemove.isEmpty) {
      print('🗑️ No screenshots to remove from the removed path');
      return;
    }

    setState(() {
      // Remove screenshots from collections first
      for (final screenshot in screenshotsToRemove) {
        // Remove from all collections
        for (var collection in _collections) {
          if (collection.screenshotIds.contains(screenshot.id)) {
            final updatedCollection = collection.removeScreenshot(
              screenshot.id,
            );
            _updateCollection(updatedCollection);
          }
        }
      }

      // Actually remove the screenshots from the main list
      _screenshots.removeWhere((screenshot) {
        final screenshotPath = screenshot.path;
        if (screenshotPath == null) return false;

        final shouldRemove = screenshotPath.startsWith(removedPath);
        if (shouldRemove) {
          print('🗑️ Removed screenshot record: ${screenshot.path}');
        }
        return shouldRemove;
      });
    });

    // Save changes
    _saveDataToPrefs();

    // Log analytics
    AnalyticsService().logFeatureUsed(
      'custom_path_screenshots_removed_count_${screenshotsToRemove.length}',
    );

    print(
      'Successfully removed ${screenshotsToRemove.length} screenshot records from removed path',
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

  void _navigateToRemindersScreen() {
    // Log navigation analytics
    AnalyticsService().logScreenView('reminders_screen');
    AnalyticsService().logUserPath('home_screen', 'reminders_screen');
    AnalyticsService().logFeatureUsed('reminders_button_pressed');

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => RemindersScreen(
              allScreenshots: _activeScreenshots,
              allCollections: _collections,
              onUpdateCollection: _updateCollection,
              onDeleteScreenshot: _deleteScreenshot,
              onScreenshotUpdated: () {
                _saveDataToPrefs();
                setState(() {});
              },
            ),
      ),
    );
  }

  int get _getActiveRemindersCount {
    final now = DateTime.now();
    return _activeScreenshots
        .where(
          (screenshot) =>
              screenshot.reminderTime != null &&
              screenshot.reminderTime!.isAfter(now) &&
              !screenshot.isDeleted,
        )
        .length;
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
        !_isProcessingAI &&
        ((_apiKey != null && _apiKey!.isNotEmpty) ||
            _selectedModelName == 'gemma')) {
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
    print("📡 Setting up file watcher for seamless autoscanning...");
    print(
      "📊 Current screenshots count at watcher setup: ${_screenshots.length}",
    );

    // Cancel existing subscription if any
    _fileWatcherSubscription?.cancel();

    // Sync file watcher with existing screenshots to avoid conflicts
    final existingPaths =
        _screenshots.map((s) => s.path).whereType<String>().toList();
    print(
      "🔄 Syncing FileWatcher with ${existingPaths.length} existing screenshots",
    );
    _fileWatcher.syncWithExistingScreenshots(existingPaths);

    // Clear corrupt files when setting up file watcher (async to not affect performance)
    _clearCorruptFilesAsync();

    // Listen to new screenshots from file watcher
    _fileWatcherSubscription = _fileWatcher.newScreenshotsStream.listen(
      (newScreenshots) {
        print(
          "FileWatcher: STREAM EVENT RECEIVED! Detected ${newScreenshots.length} new screenshots",
        );

        if (newScreenshots.isNotEmpty && mounted) {
          print(
            "FileWatcher: Current screenshots count: ${_screenshots.length}",
          );

          // Filter out screenshots we already have
          final uniqueScreenshots = <Screenshot>[];
          for (final screenshot in newScreenshots) {
            final exists = _screenshots.any((s) => s.path == screenshot.path);
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
            setState(() {
              _screenshots.addAll(uniqueScreenshots);
            });

            // Save data and auto-process the new screenshots
            _saveDataToPrefs();

            print(
              "FileWatcher: Successfully added ${uniqueScreenshots.length} new screenshots",
            );

            // Auto-process newly detected screenshots if enabled
            if (_autoProcessEnabled) {
              print(
                "FileWatcher: Auto-processing enabled, starting AI processing...",
              );
              _autoProcessWithGemini();
            } else {
              print("FileWatcher: Auto-processing disabled");
            }

            // Show a subtle notification
            if (mounted && context.mounted) {
              print("FileWatcher: Showing notification to user...");
              SnackbarService().showInfo(
                context,
                'Found ${uniqueScreenshots.length} new screenshot${uniqueScreenshots.length == 1 ? '' : 's'}',
              );
            }
          } else {
            print("FileWatcher: No unique screenshots to add");
          }
        } else {
          if (newScreenshots.isEmpty) {
            print("FileWatcher: No new screenshots in the event");
          }
          if (!mounted) {
            print("FileWatcher: Widget not mounted, ignoring event");
          }
        }
      },
      onError: (error) {
        print("FileWatcher: Stream error: $error");
      },
      onDone: () {
        print("FileWatcher: Stream closed");
      },
    );

    print("FileWatcher: Starting file watching asynchronously...");
    _startFileWatchingAsync();
    print("FileWatcher: Setup complete (async initialization in progress)");
  }

  Future<void> _startFileWatchingAsync() async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));

      await _fileWatcher.startWatching();

      // Clear corrupt files when file watcher starts (completely non-blocking)
      _clearCorruptFilesAsync();

      print("FileWatcher: Async initialization completed successfully");
    } catch (e) {
      print("FileWatcher: Error during async initialization: $e");
    }
  }

  /// Clear all corrupt files from the app using the CorruptFileService
  /// This runs asynchronously to not affect the file watcher performance
  void _clearCorruptFilesAsync() {
    // Fire and forget - run completely in background without blocking
    Future.microtask(() {
      try {
        final clearedCount = CorruptFileService.clearCorruptFilesSilently(
          _screenshots,
          () {
            // Callback when corrupt files are cleared - refresh the UI
            if (mounted) {
              setState(() {
                // This will trigger a UI refresh after corrupt files are cleared
              });
              _saveDataToPrefs();
            }
          },
        );
        if (clearedCount > 0) {
          print(
            "FileWatcher: Silently cleared $clearedCount corrupt files in background",
          );
        } else {
          print("FileWatcher: No corrupt files found during background check");
        }
      } catch (e) {
        print("FileWatcher: Error during corrupt files clearing: $e");
      }
    });
    print(
      "FileWatcher: Corrupt files clearing started in background (non-blocking)",
    );
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

  Future<void> _clearCorruptFiles() async {
    setState(() {
      // The actual corruption detection and marking is handled in AdvancedSettingsSection
      // This callback is called after the cleanup to refresh the main screen
    });

    await _saveDataToPrefs();

    AnalyticsService().logFeatureUsed('corrupt_files_cleared_main');
  }

  /// Show dialog for managing custom screenshot paths
  void _showCustomPathsDialog() {
    showDialog(
      context: context,
      builder:
          (context) => CustomPathsDialog(
            onPathAdded: () async {
              print(
                '📂 Custom path added, reloading images and restarting file watcher...',
              );

              // Restart file watcher with updated paths
              await _fileWatcher.restart();

              // Perform manual scan to pick up any existing files in the new path
              await _fileWatcher.manualScan();

              // Also reload images from all paths (including new custom path)
              await _loadAndroidScreenshots();
            },
            onPathRemoved: (String removedPath) async {
              print(
                '📂 Custom path removed: $removedPath, cleaning up screenshots and restarting file watcher...',
              );

              // Remove screenshots that belong to the removed path
              _removeScreenshotsFromPath(removedPath);

              // Restart file watcher with updated paths (this will stop watching the removed path)
              await _fileWatcher.restart();

              // Sync file watcher with remaining screenshots to avoid conflicts
              final existingPaths =
                  _screenshots
                      .where((s) => !s.isDeleted && s.path != null)
                      .map((s) => s.path!)
                      .toList();
              _fileWatcher.syncWithExistingScreenshots(existingPaths);

              print('📂 Custom path cleanup completed');
            },
          ),
    );
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
        onRemindersPressed: _navigateToRemindersScreen,
        activeRemindersCount: _getActiveRemindersCount,
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
        currentDevMode: _devMode,
        onDevModeChanged: _updateDevMode,
        currentAutoProcessEnabled: _autoProcessEnabled,
        onAutoProcessEnabledChanged: _updateAutoProcessEnabled,
        currentAnalyticsEnabled: _analyticsEnabled,
        onAnalyticsEnabledChanged: _updateAnalyticsEnabled,
        currentBetaTestingEnabled: _betaTestingEnabled,
        onBetaTestingEnabledChanged: _updateBetaTestingEnabled,
        currentAmoledModeEnabled: _amoledModeEnabled,
        onAmoledModeChanged: _updateAmoledModeEnabled,
        currentSelectedTheme: _selectedTheme,
        onThemeChanged: _updateThemeSelection,
        apiKeyFieldKey: _apiKeyFieldKey,
        onResetAiProcessing: _resetAiMetaData,
        onLocaleChanged: widget.onLocaleChanged,
        allScreenshots: _screenshots,
        onClearCorruptFiles: _clearCorruptFiles,
      ),
      floatingActionButton: ExpandableFab(
        distance: 80,
        actions: [
          ExpandableFabAction(
            icon: Icons.photo_library,
            label: 'Gallery',
            onPressed: () {
              // Track gallery selection
              AnalyticsService().logFeatureUsed('fab_gallery_selected');
              _takeScreenshot(ImageSource.gallery);
            },
          ),
          if (!kIsWeb) // Camera option only for mobile
            ExpandableFabAction(
              icon: Icons.camera_alt,
              label: 'Camera',
              onPressed: () {
                // Track camera selection
                AnalyticsService().logFeatureUsed('fab_camera_selected');
                _takeScreenshot(ImageSource.camera);
              },
            ),
          if (!kIsWeb) // Android screenshot loading option
            ExpandableFabAction(
              icon: Icons.folder_open,
              label: 'Load Screenshots',
              onPressed: () {
                // Track load device screenshots
                AnalyticsService().logFeatureUsed(
                  'fab_load_device_screenshots',
                );
                _loadAndroidScreenshots(forceReload: true).then((_) {
                  // Re-sync FileWatcher with newly loaded screenshots
                  final existingPaths =
                      _screenshots
                          .map((s) => s.path)
                          .whereType<String>()
                          .toList();
                  _fileWatcher.syncWithExistingScreenshots(existingPaths);
                });
              },
            ),
          if (!kIsWeb) // Custom paths management
            ExpandableFabAction(
              icon: Icons.create_new_folder,
              label: 'Custom Paths',
              onPressed: () {
                // Track custom paths management
                AnalyticsService().logFeatureUsed('fab_manage_custom_paths');
                _showCustomPathsDialog();
              },
            ),
        ],
        child: const Icon(Icons.add_a_photo),
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
                            isInitializing: _isInitializingProcessing,
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
                  onScreenshotUpdated: _onScreenshotUpdated,
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
                    // Force save when screenshot is updated
                    _saveDataToPrefs();
                  },
                ),
          ),
        )
        .then((_) {
          // Force save and refresh when returning from screenshot detail
          setState(() {});
          _saveDataToPrefs();
          // Don't clear cache to preserve collection thumbnails
        });
  }
}
