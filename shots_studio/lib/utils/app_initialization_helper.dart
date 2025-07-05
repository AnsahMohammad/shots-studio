import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shots_studio/services/analytics_service.dart';
import 'package:shots_studio/services/notification_service.dart';
import 'package:shots_studio/utils/memory_utils.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class AppInitializationHelper {
  /// Initialize the app with all required services
  static Future<void> initializeApp(Widget app) async {
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
    }

    // Skip Sentry in debug mode for faster startup
    if (kDebugMode) {
      print("Debug mode: Skipping Sentry initialization");
      runApp(app);
    } else {
      await SentryFlutter.init((options) {
        options.dsn =
            'https://6f96d22977b283fc325e038ac45e6e5e@o4509484018958336.ingest.us.sentry.io/4509484020072448';
        options.tracesSampleRate = 0.1; // 10% in production
      }, appRunner: () => runApp(SentryWidget(child: app)));
    }
  }

  /// Set up notification channel for background service
  static Future<void> _setupBackgroundServiceNotificationChannel() async {
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
  }
}
