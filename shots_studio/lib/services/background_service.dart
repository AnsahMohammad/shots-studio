// Background Service for AI Processing - Simplified Version
import 'dart:async';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/services/ai_service_manager.dart';
import 'package:shots_studio/services/ai_service.dart';

@pragma('vm:entry-point')
class BackgroundProcessingService {
  static bool _serviceRunning = false;

  // Notification constants
  static const String notificationChannelId = 'ai_processing_channel';
  static const int notificationId = 888;

  static const String CHANNEL_INIT = "initialize";
  static const String CHANNEL_PROCESS = "process_screenshots";
  static const String CHANNEL_BATCH_UPDATE = "batch_processed";
  static const String CHANNEL_COMPLETED = "processing_completed";
  static const String CHANNEL_ERROR = "processing_error";
  static const String CHANNEL_STOP = "stop_processing";

  static final BackgroundProcessingService _instance =
      BackgroundProcessingService._internal();

  factory BackgroundProcessingService() {
    return _instance;
  }

  @pragma('vm:entry-point')
  BackgroundProcessingService._internal();

  // Initialize background service
  Future<bool> initializeService() async {
    try {
      final service = FlutterBackgroundService();

      // Always stop existing service first to ensure clean state
      if (await service.isRunning()) {
        service.invoke('stopService');
        await Future.delayed(const Duration(seconds: 2));
      }

      // Configure the service
      await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onStart,
          autoStart: false,
          isForegroundMode: true,
          notificationChannelId: notificationChannelId,
          initialNotificationTitle: 'AI Processing Service',
          initialNotificationContent: 'Starting...',
          foregroundServiceNotificationId: notificationId,
        ),
        iosConfiguration: IosConfiguration(
          autoStart: false,
          onForeground: onStart,
          onBackground: onIosBackground,
        ),
      );

      // Start the service explicitly
      await service.startService();

      // Wait longer for service to initialize
      await Future.delayed(const Duration(seconds: 5));

      // Check if service started successfully
      final isRunning = await service.isRunning();

      // Try to send a test message to trigger onStart if it hasn't been called
      if (isRunning) {
        service.invoke('test', {'message': 'wake_up'});
        await Future.delayed(const Duration(seconds: 2));
      }

      return isRunning;
    } catch (e) {
      return false;
    }
  }

  // iOS background handler
  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  // Main background service handler - simplified
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    try {
      // Initialize plugins
      DartPluginRegistrant.ensureInitialized();

      _serviceRunning = true;

      // Initialize flutter_local_notifications for custom notifications
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();

      // Configure Android service
      if (service is AndroidServiceInstance) {
        service.setAsForegroundService();

        service.on('setAsForeground').listen((event) {
          service.setAsForegroundService();
        });

        service.on('setAsBackground').listen((event) {
          service.setAsBackgroundService();
        });
      }

      // Helper method to update custom notification with progress
      void updateCustomNotification({
        required String title,
        required String content,
        bool showProgress = false,
        int? progress,
        int? maxProgress,
        bool ongoing = false,
      }) {
        if (service is AndroidServiceInstance) {
          // Use flutter_local_notifications for custom notification
          flutterLocalNotificationsPlugin.show(
            notificationId,
            title,
            content,
            NotificationDetails(
              android: AndroidNotificationDetails(
                notificationChannelId,
                'AI Processing Service',
                channelDescription:
                    'Channel for AI screenshot processing notifications',
                icon: '@mipmap/ic_launcher_monochrome',
                ongoing: ongoing,
                showProgress: showProgress,
                maxProgress: maxProgress ?? 100,
                progress: progress ?? 0,
                importance: Importance.low,
                priority: Priority.low,
                playSound: false,
                enableVibration: false,
                autoCancel: false,
                category: AndroidNotificationCategory.progress,
              ),
            ),
          );
        }
      }

      updateCustomNotification(
        title: 'Shots Studio AI Service',
        content: 'Service is ready',
        ongoing: false,
      );

      // Handle test/wake-up messages
      service.on('test').listen((event) {
        service.invoke('test_response', {
          'status': 'awake',
          'message': 'Service is running',
        });
      });

      // Handle test notification request
      service.on('test_notification').listen((event) {
        updateCustomNotification(
          title: 'Test Notification',
          content: 'This is a test notification with custom icon',
          showProgress: true,
          progress: 50,
          maxProgress: 100,
          ongoing: false,
        );
      });

      // Handle stop service request
      service.on('stopService').listen((event) {
        _serviceRunning = false;
        service.stopSelf();
      });

      // Handle processing requests
      service.on(CHANNEL_PROCESS).listen((event) async {
        if (event == null) {
          return;
        }

        try {
          // Update notification to show processing started
          final data = Map<String, dynamic>.from(event);
          final screenshotsJson = data['screenshots'] as String;
          final List<dynamic> screenshotListDynamic = jsonDecode(
            screenshotsJson,
          );
          final totalCount = screenshotListDynamic.length;

          updateCustomNotification(
            title: 'Processing Screenshots',
            content: 'Started processing $totalCount screenshots',
            showProgress: true,
            progress: 0,
            maxProgress: totalCount,
            ongoing: true,
          );

          await _processScreenshots(service, event, updateCustomNotification);
        } catch (e) {
          updateCustomNotification(
            title: 'Processing Error',
            content: 'Error: ${e.toString()}',
            ongoing: false,
          );
          service.invoke(CHANNEL_ERROR, {'error': e.toString()});
        }
      });

      // Handle stop processing requests
      service.on(CHANNEL_STOP).listen((event) {
        _serviceRunning = false;
        // Stop the service completely when processing is stopped
        service.stopSelf();
      });

      // Signal ready
      service.invoke(CHANNEL_INIT, {
        'ready': true,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      service.invoke(CHANNEL_INIT, {'ready': false, 'error': e.toString()});
    }
  }

  // Process screenshots method
  static Future<void> _processScreenshots(
    ServiceInstance service,
    Map<dynamic, dynamic> event,
    Function updateNotification,
  ) async {
    try {
      // Extract data from event
      final String screenshotsJson = event['screenshots'] as String;
      final String apiKey = event['apiKey'] as String;
      final String modelName = event['modelName'] as String;
      final int maxParallel = event['maxParallel'] as int;
      final String? collectionsJson = event['collections'] as String?;

      final List<dynamic> screenshotListDynamic = jsonDecode(screenshotsJson);
      final List<Screenshot> screenshots =
          screenshotListDynamic
              .map((json) => Screenshot.fromJson(json as Map<String, dynamic>))
              .toList();

      // Convert collections
      List<Map<String, String?>> autoAddCollections = [];
      if (collectionsJson != null && collectionsJson.isNotEmpty) {
        final List<dynamic> collectionListDynamic = jsonDecode(collectionsJson);
        autoAddCollections =
            collectionListDynamic
                .map((item) => Map<String, String?>.from(item as Map))
                .toList();
      }

      int processedCount = 0;
      final totalCount = screenshots.length;

      // Set up AI service
      final config = AIConfig(
        apiKey: apiKey,
        modelName: modelName,
        maxParallel: maxParallel,
      );

      final aiServiceManager = AIServiceManager();
      aiServiceManager.initialize(config);

      // Process screenshots
      final result = await aiServiceManager.analyzeScreenshots(
        screenshots: screenshots,
        onBatchProcessed: (batch, response) {
          // Check if we should continue processing
          if (!_serviceRunning) {
            throw Exception("Processing cancelled by user");
          }

          try {
            // Process batch results
            final updatedScreenshots = aiServiceManager
                .parseAndUpdateScreenshots(batch, response);
            processedCount += updatedScreenshots.length;

            // Update foreground notification with progress
            updateNotification(
              title: 'Processing Screenshots',
              content: 'Processing: $processedCount/$totalCount screenshots',
              showProgress: true,
              progress: processedCount,
              maxProgress: totalCount,
              ongoing: true,
            );

            // Send batch results to app
            service.invoke(CHANNEL_BATCH_UPDATE, {
              'updatedScreenshots': jsonEncode(
                updatedScreenshots.map((s) => s.toJson()).toList(),
              ),
              'response': jsonEncode(response),
              'processedCount': processedCount,
              'totalCount': totalCount,
            });
          } catch (e) {
            updateNotification(
              title: 'Processing Error',
              content: 'Batch processing error: $e',
              ongoing: false,
            );
            service.invoke(CHANNEL_ERROR, {
              'error': 'Batch processing error: $e',
            });
          }
        },
        autoAddCollections: autoAddCollections,
      );

      // Update notification based on final result
      if (result.success) {
        updateNotification(
          title: 'Processing Complete',
          content:
              'Completed processing $processedCount/$totalCount screenshots',
          ongoing: false,
        );
      } else if (!_serviceRunning) {
        // no notification if cancelled since user stopped the service
      } else {
        updateNotification(
          title: 'Processing Failed',
          content: 'Error: ${result.error ?? "Unknown error"}',
          ongoing: false,
        );
      }

      // Send final results
      service.invoke(CHANNEL_COMPLETED, {
        'success': result.success,
        'error': result.error,
        'statusCode': result.statusCode,
        'cancelled': !_serviceRunning,
        'processedCount': processedCount,
        'totalCount': totalCount,
      });

      // Stop the service after processing is complete
      // Allow a brief delay for the notification to be shown
      await Future.delayed(const Duration(seconds: 2));
      service.stopSelf();
    } catch (e) {
      updateNotification(
        title: 'Processing Error',
        content: 'Error: ${e.toString()}',
        ongoing: false,
      );
      service.invoke(CHANNEL_ERROR, {'error': e.toString()});

      // Stop the service on error as well
      // Allow a brief delay for the notification to be shown
      await Future.delayed(const Duration(seconds: 2));
      service.stopSelf();
    }
  }

  // Start background processing
  Future<bool> startBackgroundProcessing({
    required List<Screenshot> screenshots,
    required String apiKey,
    required String modelName,
    required int maxParallel,
    List<Map<String, String?>>? autoAddCollections,
  }) async {
    try {
      final service = FlutterBackgroundService();

      if (!await service.isRunning()) {
        final initialized = await initializeService();
        if (!initialized) {
          return false;
        }
      }

      _serviceRunning = true;

      // Prepare payload
      final screenshotsJson = jsonEncode(
        screenshots.map((s) => s.toJson()).toList(),
      );

      final payload = {
        'screenshots': screenshotsJson,
        'apiKey': apiKey,
        'modelName': modelName,
        'maxParallel': maxParallel,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      if (autoAddCollections != null && autoAddCollections.isNotEmpty) {
        payload['collections'] = jsonEncode(autoAddCollections);
      }

      // Send processing request
      service.invoke(CHANNEL_PROCESS, payload);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Stop background processing
  Future<bool> stopBackgroundProcessing() async {
    try {
      _serviceRunning = false;

      final service = FlutterBackgroundService();
      if (await service.isRunning()) {
        service.invoke(CHANNEL_STOP);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Shutdown service completely
  Future<bool> shutdownService() async {
    try {
      _serviceRunning = false;

      final service = FlutterBackgroundService();
      if (await service.isRunning()) {
        service.invoke('stopService');
        await Future.delayed(const Duration(seconds: 1));
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Check if service is running
  Future<bool> isServiceRunning() async {
    try {
      final service = FlutterBackgroundService();
      return await service.isRunning();
    } catch (e) {
      return false;
    }
  }

  // Test custom notification with progress
  Future<bool> testCustomNotification() async {
    try {
      final service = FlutterBackgroundService();

      if (!await service.isRunning()) {
        final initialized = await initializeService();
        if (!initialized) {
          return false;
        }
      }

      // Send test notification request
      service.invoke('test_notification');
      return true;
    } catch (e) {
      return false;
    }
  }
}
