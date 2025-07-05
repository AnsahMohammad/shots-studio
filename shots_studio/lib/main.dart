import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shots_studio/screens/screenshot_details_screen.dart';
import 'package:shots_studio/screens/screenshot_swipe_detail_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shots_studio/widgets/home_app_bar.dart';
import 'package:shots_studio/widgets/collections/collections_section.dart';
import 'package:shots_studio/widgets/screenshots/screenshots_section.dart';
import 'package:shots_studio/screens/app_drawer_screen.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/models/collection_model.dart';
import 'package:shots_studio/screens/search_screen.dart';
import 'package:shots_studio/widgets/privacy_dialog.dart';
import 'package:shots_studio/widgets/onboarding/api_key_guide_dialog.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:shots_studio/widgets/ai_processing_container.dart';
import 'package:shots_studio/services/analytics_service.dart';
import 'package:shots_studio/utils/theme_utils.dart';
import 'package:shots_studio/utils/theme_manager.dart';
import 'package:shots_studio/utils/memory_utils.dart';
import 'package:shots_studio/widgets/custom_paths_dialog.dart';
import 'package:shots_studio/services/snackbar_service.dart';
import 'package:shots_studio/services/home_screen_service.dart';
import 'package:shots_studio/utils/auto_categorization_helper.dart';
import 'package:shots_studio/utils/collection_helper.dart';
import 'package:shots_studio/utils/app_initialization_helper.dart';

void main() async {
  await AppInitializationHelper.initializeApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _amoledModeEnabled = false;
  String _selectedTheme = 'Dynamic Theme';

  @override
  void initState() {
    super.initState();
    _loadThemeSettings();
  }

  Future<void> _loadThemeSettings() async {
    final amoledMode = await ThemeManager.getAmoledMode();
    final selectedTheme = await ThemeManager.getSelectedTheme();
    setState(() {
      _amoledModeEnabled = amoledMode;
      _selectedTheme = selectedTheme;
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
          ),
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  final Function(bool)? onAmoledModeChanged;
  final Function(String)? onThemeChanged;

  const HomeScreen({super.key, this.onAmoledModeChanged, this.onThemeChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final List<Screenshot> _screenshots = [];
  final List<Collection> _collections = [];
  final HomeScreenService _homeScreenService = HomeScreenService();

  // Add a global key for the API key text field
  final GlobalKey<State> _apiKeyFieldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Log analytics for app startup and home screen view
    AnalyticsService().logScreenView('home_screen');
    AnalyticsService().logCurrentUsageTime();

    _initializeHomeScreen();
  }

  Future<void> _initializeHomeScreen() async {
    await _homeScreenService.initialize();
    await _loadDataFromService();

    if (!kIsWeb) {
      await _loadAndroidScreenshotsIfNeeded();
      _setupFileWatcher();
      _setupBackgroundServiceListeners();
    }

    // Show privacy dialog after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      bool privacyAccepted = await showPrivacyDialogIfNeeded(context);
      if (privacyAccepted && context.mounted) {
        AnalyticsService().logInstallInfo();
        await showApiKeyGuideIfNeeded(
          context,
          _homeScreenService.apiKey,
          _updateApiKey,
        );
        _homeScreenService.checkForUpdates(context);
        _homeScreenService.checkForServerMessages(context);
        _autoProcessWithGemini();
      }
    });
  }

  // Helper getters for clean UI access
  List<Screenshot> get _activeScreenshots {
    final activeScreenshots =
        _screenshots.where((screenshot) => !screenshot.isDeleted).toList();
    activeScreenshots.sort((a, b) => b.addedOn.compareTo(a.addedOn));
    return activeScreenshots;
  }

  Future<void> _loadDataFromService() async {
    final (screenshots, collections) =
        await _homeScreenService.loadDataFromPrefs();
    setState(() {
      _screenshots.clear();
      _screenshots.addAll(screenshots);
      _collections.clear();
      _collections.addAll(collections);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _homeScreenService.dispose();
    super.dispose();
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
        _homeScreenService.startFileWatcher();
      } else if (state == AppLifecycleState.paused) {
        _homeScreenService.stopFileWatcher();
      }
    }

    // Auto-process unprocessed screenshots when the app comes to foreground
    if (state == AppLifecycleState.resumed) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _autoProcessWithGemini();
      });

      Future.delayed(const Duration(seconds: 2), () {
        _homeScreenService.checkForServerMessages(context);
      });
    }
  }

  /// Setup background service listeners
  void _setupBackgroundServiceListeners() {
    _homeScreenService.setupBackgroundServiceListeners(
      onProcessingUpdate: (processedCount, totalCount) {
        // Handle processing updates in UI
        setState(() {
          // Update progress indicators
        });
      },
      onProcessingCompleted: (
        success,
        processedCount,
        totalCount,
        error,
        cancelled,
      ) {
        setState(() {
          // Reset processing state
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
        _saveDataToPrefs();
      },
      onProcessingError: (error) {
        setState(() {
          // Reset processing state
        });
        SnackbarService().showError(context, 'Processing error: $error');
        _saveDataToPrefs();
      },
      onBatchProcessed: (updatedScreenshots, response) {
        setState(() {
          // Update screenshots in our list
          for (var updatedScreenshot in updatedScreenshots) {
            final index = _screenshots.indexWhere(
              (s) => s.id == updatedScreenshot.id,
            );
            if (index != -1) {
              _screenshots[index] = updatedScreenshot;

              // Handle auto-categorization for this screenshot
              if (response != null) {
                AutoCategorizationHelper.handleAutoCategorization(
                  updatedScreenshot,
                  response,
                  _collections,
                  _updateCollection,
                );
              }
            }
          }
        });

        AnalyticsService().logAIProcessingSuccess(updatedScreenshots.length);
        AnalyticsService().logTotalScreenshotsProcessed(
          _screenshots.where((s) => s.aiProcessed).length,
        );
        _saveDataToPrefs();
      },
    );
  }

  Future<void> _saveDataToPrefs() async {
    await _homeScreenService.saveDataToPrefs(_screenshots, _collections);
  }

  /// API key and settings update methods
  void _updateApiKey(String newApiKey) {
    _homeScreenService.updateApiKey(newApiKey);
  }

  void _updateModelName(String newModelName) {
    _homeScreenService.updateModelName(newModelName);
  }

  void _updateScreenshotLimit(int newLimit) {
    _homeScreenService.updateScreenshotLimit(newLimit);
  }

  void _updateScreenshotLimitEnabled(bool enabled) {
    _homeScreenService.updateScreenshotLimitEnabled(enabled);
  }

  void _updateMaxParallelAI(int newMaxParallel) {
    _homeScreenService.updateMaxParallelAI(newMaxParallel);
  }

  void _updateDevMode(bool value) {
    _homeScreenService.updateDevMode(value);
  }

  void _updateAutoProcessEnabled(bool enabled) {
    _homeScreenService.updateAutoProcessEnabled(enabled);
  }

  void _updateAnalyticsEnabled(bool enabled) {
    _homeScreenService.updateAnalyticsEnabled(enabled);
  }

  void _updateAmoledModeEnabled(bool enabled) {
    _homeScreenService.updateAmoledModeEnabled(enabled);
    if (widget.onAmoledModeChanged != null) {
      widget.onAmoledModeChanged!(enabled);
    }
  }

  void _updateThemeSelection(String themeName) {
    _homeScreenService.updateThemeSelection(themeName);
    if (widget.onThemeChanged != null) {
      widget.onThemeChanged!(themeName);
    }
  }

  /// Load Android screenshots only if we don't already have screenshots loaded from preferences
  Future<void> _loadAndroidScreenshotsIfNeeded() async {
    await Future.delayed(const Duration(milliseconds: 100));

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

  Future<void> _loadAndroidScreenshots({bool forceReload = false}) async {
    if (kIsWeb) return;

    if (!forceReload && _screenshots.isNotEmpty) {
      print("Screenshots already loaded, skipping Android screenshot loading");
      return;
    }

    final newScreenshots = await _homeScreenService.loadAndroidScreenshots(
      existingScreenshots: _screenshots,
      forceReload: forceReload,
      onProgress: (current, total) {
        setState(() {
          // Progress tracking handled in service
        });
      },
    );

    if (newScreenshots.isNotEmpty) {
      setState(() {
        _screenshots.insertAll(0, newScreenshots);
      });

      await _saveDataToPrefs();
      _autoProcessWithGemini();
    }
  }

  /// Setup file watcher for seamless autoscanning
  void _setupFileWatcher() {
    _homeScreenService.setupFileWatcher(
      existingScreenshots: _screenshots,
      onNewScreenshots: (newScreenshots) {
        setState(() {
          _screenshots.addAll(newScreenshots);
        });

        _saveDataToPrefs();

        if (_homeScreenService.autoProcessEnabled) {
          _autoProcessWithGemini();
        }

        if (mounted && context.mounted) {
          SnackbarService().showInfo(
            context,
            'Found ${newScreenshots.length} new screenshot${newScreenshots.length == 1 ? '' : 's'}',
          );
        }
      },
    );
  }

  Future<void> _takeScreenshot(ImageSource source) async {
    final newScreenshots = await _homeScreenService.takeScreenshot(
      source,
      _screenshots,
    );

    if (newScreenshots.isNotEmpty) {
      setState(() {
        _screenshots.addAll(newScreenshots);
      });

      await _saveDataToPrefs();
      AnalyticsService().logTotalScreenshotsProcessed(_screenshots.length);
      _autoProcessWithGemini();
    }
  }

  /// Helper method to check and auto-process screenshots
  Future<void> _autoProcessWithGemini() async {
    if (_homeScreenService.autoProcessEnabled &&
        _homeScreenService.apiKey != null &&
        _homeScreenService.apiKey!.isNotEmpty &&
        !_homeScreenService.isProcessingAI) {
      final unprocessedScreenshots =
          _activeScreenshots.where((s) => !s.aiProcessed).toList();
      if (unprocessedScreenshots.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 300));
        await _processWithGemini();
      }
    }
  }

  Future<void> _processWithGemini() async {
    final unprocessedScreenshots =
        _activeScreenshots.where((s) => !s.aiProcessed).toList();
    final success = await _homeScreenService.startAIProcessing(
      context: context,
      unprocessedScreenshots: unprocessedScreenshots,
      collections: _collections,
    );

    if (success) {
      setState(() {
        // Processing state managed by service
      });
    }
  }

  Future<void> _stopProcessingAI() async {
    await _homeScreenService.stopAIProcessing();
    await _saveDataToPrefs();
    setState(() {
      // State reset handled by service
    });
  }

  /// Collection management methods
  void _addCollection(Collection collection) {
    setState(() {
      _collections.add(collection);
      CollectionHelper.addCollectionRelationships(collection, _screenshots);
    });

    _saveDataToPrefs();

    // Log analytics
    AnalyticsService().logCollectionCreated();
    AnalyticsService().logTotalCollections(_collections.length);
    CollectionHelper.logCollectionStats(_collections);

    // Handle auto-add enabled collections
    if (collection.isAutoAddEnabled) {
      AnalyticsService().logFeatureUsed('auto_add_collection_created');
      if (_homeScreenService.isProcessingAI) {
        AnalyticsService().logFeatureUsed(
          'auto_add_collection_restart_processing',
        );
        _restartProcessingForNewAutoAddCollection();
      } else {
        AnalyticsService().logFeatureUsed(
          'auto_add_collection_start_processing',
        );
        _autoProcessWithGemini();
      }
    }
  }

  void _updateCollection(Collection updatedCollection) {
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
        CollectionHelper.updateCollectionRelationships(
          updatedCollection,
          oldCollection,
          _screenshots,
        );
      }
    });

    _saveDataToPrefs();
    CollectionHelper.logCollectionStats(_collections);

    // Handle auto-add enabled collections
    if (wasAutoAddJustEnabled) {
      AnalyticsService().logFeatureUsed('auto_add_collection_enabled');
      if (_homeScreenService.isProcessingAI) {
        AnalyticsService().logFeatureUsed(
          'auto_add_enabled_restart_processing',
        );
        _restartProcessingForNewAutoAddCollection();
      } else {
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
      CollectionHelper.removeCollectionRelationships(
        collectionId,
        _screenshots,
      );
    });
    _saveDataToPrefs();

    AnalyticsService().logCollectionDeleted();
    AnalyticsService().logTotalCollections(_collections.length);
    CollectionHelper.logCollectionStats(_collections);
  }

  /// Screenshot management methods
  void _deleteScreenshot(String screenshotId) {
    setState(() {
      final screenshotIndex = _screenshots.indexWhere(
        (s) => s.id == screenshotId,
      );
      if (screenshotIndex != -1) {
        _screenshots[screenshotIndex].isDeleted = true;
      }

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

    AnalyticsService().logFeatureUsed('bulk_delete_screenshots');

    setState(() {
      for (String screenshotId in screenshotIds) {
        final screenshotIndex = _screenshots.indexWhere(
          (s) => s.id == screenshotId,
        );
        if (screenshotIndex != -1) {
          _screenshots[screenshotIndex].isDeleted = true;
        }

        for (var collection in _collections) {
          if (collection.screenshotIds.contains(screenshotId)) {
            final updatedCollection = collection.removeScreenshot(screenshotId);
            _updateCollection(updatedCollection);
          }
        }
      }
    });

    _saveDataToPrefs();
    AnalyticsService().logFeatureUsed(
      'bulk_delete_count_${screenshotIds.length}',
    );
  }

  /// Helper methods
  Future<void> _restartProcessingForNewAutoAddCollection() async {
    print("Main app: Restarting processing for new auto-add collection...");
    AnalyticsService().logFeatureUsed('auto_add_processing_restart_initiated');

    try {
      await _stopProcessingAI();
      await Future.delayed(const Duration(milliseconds: 500));

      final unprocessedScreenshots =
          _activeScreenshots.where((s) => !s.aiProcessed).toList();

      if (unprocessedScreenshots.isNotEmpty) {
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

  /// Navigation methods
  void _navigateToSearchScreen() {
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

  void _showScreenshotDetail(Screenshot screenshot) {
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
                    _saveDataToPrefs();
                  },
                ),
          ),
        )
        .then((_) {
          setState(() {});
          _saveDataToPrefs();
        });
  }

  Future<void> _resetAiMetaData() async {
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
      await _homeScreenService.resetAiMetadata(_screenshots, _collections);
      setState(() {
        // UI refresh after reset
      });
      await _saveDataToPrefs();
      SnackbarService().showSuccess(context, 'AI processing status reset');
    }
  }

  void _showCustomPathsDialog() {
    showDialog(
      context: context,
      builder:
          (context) => CustomPathsDialog(
            onPathAdded: () async {
              print(
                '📂 Custom path added, reloading images and restarting file watcher...',
              );
              await _homeScreenService.restartFileWatcher();
              await _homeScreenService.manualScanFileWatcher();
              await _loadAndroidScreenshots();
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeAppBar(
        onProcessWithAI:
            _homeScreenService.isProcessingAI ? null : _processWithGemini,
        isProcessingAI: _homeScreenService.isProcessingAI,
        aiProcessedCount: _homeScreenService.aiProcessedCount,
        aiTotalToProcess: _homeScreenService.aiTotalToProcess,
        onSearchPressed: _navigateToSearchScreen,
        onStopProcessingAI: _stopProcessingAI,
        devMode: _homeScreenService.devMode,
        autoProcessEnabled: _homeScreenService.autoProcessEnabled,
      ),
      drawer: AppDrawer(
        currentApiKey: _homeScreenService.apiKey,
        currentModelName: _homeScreenService.selectedModelName,
        onApiKeyChanged: _updateApiKey,
        onModelChanged: _updateModelName,
        currentLimit: _homeScreenService.screenshotLimit,
        onLimitChanged: _updateScreenshotLimit,
        currentMaxParallel: _homeScreenService.maxParallelAI,
        onMaxParallelChanged: _updateMaxParallelAI,
        currentLimitEnabled: _homeScreenService.isScreenshotLimitEnabled,
        onLimitEnabledChanged: _updateScreenshotLimitEnabled,
        currentDevMode: _homeScreenService.devMode,
        onDevModeChanged: _updateDevMode,
        currentAutoProcessEnabled: _homeScreenService.autoProcessEnabled,
        onAutoProcessEnabledChanged: _updateAutoProcessEnabled,
        currentAnalyticsEnabled: _homeScreenService.analyticsEnabled,
        onAnalyticsEnabledChanged: _updateAnalyticsEnabled,
        currentAmoledModeEnabled: _homeScreenService.amoledModeEnabled,
        onAmoledModeChanged: _updateAmoledModeEnabled,
        currentSelectedTheme: _homeScreenService.selectedTheme,
        onThemeChanged: _updateThemeSelection,
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
                            _loadAndroidScreenshots(forceReload: true).then((
                              _,
                            ) {
                              // Re-sync FileWatcher with newly loaded screenshots
                              _homeScreenService.syncFileWatcherWithScreenshots(
                                _screenshots,
                              );
                            });
                          },
                        ),
                      if (!kIsWeb) // Custom paths management
                        ListTile(
                          leading: const Icon(Icons.create_new_folder),
                          title: const Text('Manage custom paths'),
                          onTap: () {
                            Navigator.pop(context);
                            _showCustomPathsDialog();
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
          _homeScreenService.isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text('Loading screenshots...'),
                    if (_homeScreenService.totalToLoad > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${_homeScreenService.loadingProgress} / ${_homeScreenService.totalToLoad}',
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value:
                            _homeScreenService.totalToLoad > 0
                                ? _homeScreenService.loadingProgress /
                                    _homeScreenService.totalToLoad
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
                            isProcessing: _homeScreenService.isProcessingAI,
                            processedCount: _homeScreenService.aiProcessedCount,
                            totalCount: _homeScreenService.aiTotalToProcess,
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
}
