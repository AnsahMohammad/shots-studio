import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:intl/intl.dart';
import 'dart:io';

class NotificationService {
  static final NotificationService _notificationService =
      NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Initialize timezone data
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    final initResult = await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        if (kDebugMode) {
          print('Notification response received: ${details.payload}');
        }
      },
    );

    if (kDebugMode && initResult != true) {
      print('Notification plugin initialization failed');
    }

    // Create notification channels explicitly
    await _createNotificationChannels();

    // Request notification permissions (but not exact alarm permission yet)
    final permissionResult = await requestNotificationPermissions();

    if (kDebugMode) {
      print('Notification permissions: $permissionResult');
    }
  }

  Future<void> _createNotificationChannels() async {
    final androidImplementation =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      // Screenshot reminder channel
      const AndroidNotificationChannel reminderChannel =
          AndroidNotificationChannel(
            'screenshot_reminder_channel',
            'Screenshot Reminders',
            description: 'Channel for screenshot reminder notifications',
            importance: Importance.max,
            enableVibration: true,
            playSound: true,
            showBadge: true,
          );

      // Server messages channel
      const AndroidNotificationChannel serverChannel =
          AndroidNotificationChannel(
            'server_messages_channel',
            'Server Messages',
            description: 'Channel for server messages and announcements',
            importance: Importance.high,
            enableVibration: true,
            playSound: true,
            showBadge: true,
          );

      // Urgent server messages channel
      const AndroidNotificationChannel urgentServerChannel =
          AndroidNotificationChannel(
            'server_messages_urgent',
            'Urgent Server Messages',
            description: 'Channel for urgent server messages',
            importance: Importance.max,
            enableVibration: true,
            playSound: true,
            showBadge: true,
          );

      await androidImplementation.createNotificationChannel(reminderChannel);
      await androidImplementation.createNotificationChannel(serverChannel);
      await androidImplementation.createNotificationChannel(
        urgentServerChannel,
      );
    } else {
      if (kDebugMode) {
        print(
          'WARNING: Could not get Android implementation for notification channels',
        );
      }
    }
  }

  Future<bool> requestNotificationPermissions() async {
    final status = await Permission.notification.request();

    // For Android 13+ (API 33+), also request POST_NOTIFICATIONS
    final bool? result =
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();

    return status == PermissionStatus.granted || result == true;
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    await scheduleNotificationWithImage(
      id: id,
      title: title,
      body: body,
      scheduledTime: scheduledTime,
    );
  }

  Future<void> scheduleNotificationWithImage({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? imagePath,
    Uint8List? imageBytes,
  }) async {
    if (kDebugMode) {
      print('Scheduling notification - ID: $id, Time: $scheduledTime');
    }

    // Check if scheduled time is in the future
    if (!scheduledTime.isAfter(DateTime.now())) {
      if (kDebugMode) {
        print('ERROR: Scheduled time is not in the future!');
      }
      return;
    }

    // Check exact alarm permission only when actually scheduling a reminder
    final hasPermission = await hasExactAlarmPermission();
    if (!hasPermission) {
      if (kDebugMode) {
        print(
          'Exact alarm permission not granted - notification may not work reliably',
        );
      }
      // Continue with scheduling anyway, but it may not be as reliable
      // The permission request should be handled at the UI level when user sets a reminder
    }

    try {
      // Cancel any existing notification with the same ID
      await flutterLocalNotificationsPlugin.cancel(id);

      // Convert DateTime to TZDateTime for proper timezone handling
      final tzDateTime = _convertToTZDateTime(scheduledTime);

      // Prepare notification details with image support
      AndroidNotificationDetails androidDetails =
          await _buildAndroidNotificationDetails(
            imagePath: imagePath,
            imageBytes: imageBytes,
            body: body,
          );

      // Use Android's persistent scheduling instead of Future.delayed
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzDateTime,
        NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      if (kDebugMode) {
        print('Notification scheduled successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error scheduling notification: $e');
      }
      // Fallback: try with simple scheduling if zonedSchedule fails
      try {
        await _scheduleWithFallback(
          id,
          title,
          body,
          scheduledTime,
          imagePath: imagePath,
          imageBytes: imageBytes,
        );
      } catch (fallbackError) {
        if (kDebugMode) {
          print('Fallback scheduling also failed: $fallbackError');
        }
      }
    }
  }

  /// Build Android notification details with optional image support
  Future<AndroidNotificationDetails> _buildAndroidNotificationDetails({
    String? imagePath,
    Uint8List? imageBytes,
    required String body,
  }) async {
    StyleInformation? styleInformation;

    // Try to create big picture style if we have image data
    if (imagePath != null || imageBytes != null) {
      try {
        AndroidBitmap<Object>? bigPicture;

        if (imagePath != null) {
          // Check if file exists and is accessible
          final file = File(imagePath);
          if (await file.exists()) {
            bigPicture = FilePathAndroidBitmap(imagePath);
          }
        } else if (imageBytes != null) {
          // Use bytes directly
          bigPicture = ByteArrayAndroidBitmap(imageBytes);
        }

        if (bigPicture != null) {
          styleInformation = BigPictureStyleInformation(
            bigPicture,
            largeIcon: const DrawableResourceAndroidBitmap(
              '@mipmap/ic_launcher',
            ),
            contentTitle: null, // Will use the main title
            htmlFormatContentTitle: false,
            summaryText: body,
            htmlFormatSummaryText: false,
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error creating big picture style: $e');
        }
      }
    }

    // Fallback to big text style if image processing failed or no image provided
    styleInformation ??= const BigTextStyleInformation('');

    return AndroidNotificationDetails(
      'screenshot_reminder_channel',
      'Screenshot Reminders',
      channelDescription: 'Channel for screenshot reminder notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      fullScreenIntent: true,
      autoCancel: false,
      ongoing: false,
      ticker: 'Screenshot reminder',
      icon: '@mipmap/ic_launcher_monochrome',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: styleInformation,
      visibility: NotificationVisibility.public,
    );
  }

  // Helper method to convert DateTime to TZDateTime
  tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    try {
      // Ensure we're working with local time if it's not UTC
      DateTime localDateTime = dateTime.isUtc ? dateTime.toLocal() : dateTime;

      // Try to use the local timezone
      final location = tz.local;
      final tzDateTime = tz.TZDateTime.from(localDateTime, location);

      return tzDateTime;
    } catch (e) {
      if (kDebugMode) {
        print('Error in timezone conversion, falling back to UTC: $e');
      }
      // Fallback to UTC if local timezone fails
      try {
        final utcDateTime = dateTime.isUtc ? dateTime : dateTime.toUtc();
        final result = tz.TZDateTime.from(utcDateTime, tz.UTC);
        return result;
      } catch (utcError) {
        if (kDebugMode) {
          print('UTC fallback also failed: $utcError');
        }
        // Last resort: create TZDateTime manually
        return tz.TZDateTime(
          tz.UTC,
          dateTime.year,
          dateTime.month,
          dateTime.day,
          dateTime.hour,
          dateTime.minute,
          dateTime.second,
          dateTime.millisecond,
          dateTime.microsecond,
        );
      }
    }
  }

  // Fallback method for devices that don't support zonedSchedule
  Future<void> _scheduleWithFallback(
    int id,
    String title,
    String body,
    DateTime scheduledTime, {
    String? imagePath,
    Uint8List? imageBytes,
  }) async {
    // For fallback, try to show immediately if close to the scheduled time
    final timeUntilScheduled = scheduledTime.difference(DateTime.now());

    if (timeUntilScheduled.inMinutes <= 1) {
      // If scheduled for within 1 minute, show immediately
      AndroidNotificationDetails androidDetails =
          await _buildAndroidNotificationDetails(
            imagePath: imagePath,
            imageBytes: imageBytes,
            body: body,
          );

      await flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        NotificationDetails(android: androidDetails),
      );
    } else {
      // For longer delays, we can't guarantee persistence without proper scheduling
      if (kDebugMode) {
        print(
          'Warning: Notification scheduling may not persist when app is closed',
        );
      }
    }
  }

  Future<void> showTestNotification() async {
    await flutterLocalNotificationsPlugin.show(
      999,
      'Test Notification',
      'This is a test notification to verify everything is working',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'screenshot_reminder_channel',
          'Screenshot Reminders',
          channelDescription: 'Channel for screenshot reminder notifications',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
          playSound: true,
          icon: '@mipmap/ic_launcher_monochrome',
        ),
      ),
    );
  }

  Future<void> debugScheduledNotifications() async {
    try {
      final pendingRequests =
          await flutterLocalNotificationsPlugin.pendingNotificationRequests();
      if (kDebugMode) {
        print('=== NOTIFICATION DEBUG INFO ===');
        print('Total pending notifications: ${pendingRequests.length}');
        for (var request in pendingRequests) {
          print(
            'ID: ${request.id}, Title: ${request.title}, Body: ${request.body}',
          );
          print('Payload: ${request.payload}');
        }
        print('================================');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting pending notifications: $e');
      }
    }
  }

  Future<void> testScheduleNotificationInMinute() async {
    final testTime = DateTime.now().add(const Duration(minutes: 1));

    if (kDebugMode) {
      print('=== SCHEDULING TEST NOTIFICATION ===');
      print('Current time: ${DateTime.now()}');
      print('Scheduled time: $testTime');
      print(
        'Time difference: ${testTime.difference(DateTime.now()).inSeconds} seconds',
      );
    }

    await scheduleNotification(
      id: 998,
      title: 'Test Scheduled Notification',
      body:
          'This notification was scheduled for 1 minute from now: ${DateFormat('h:mm:ss a').format(testTime)}',
      scheduledTime: testTime,
    );

    if (kDebugMode) {
      print('Test notification scheduled for: $testTime');
    }
  }

  Future<void> showServerMessage({
    required int id,
    required String title,
    required String body,
    String channelId = 'server_messages_channel',
    String channelName = 'Server Messages',
    String channelDescription = 'Channel for server messages and announcements',
    Importance importance = Importance.high,
    Priority priority = Priority.high,
  }) async {
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: importance,
          priority: priority,
          showWhen: true,
          enableVibration: true,
          playSound: true,
          autoCancel: true,
          ongoing: false,
          icon: '@mipmap/ic_launcher_monochrome',
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          styleInformation: const BigTextStyleInformation(''),
          visibility: NotificationVisibility.public,
        ),
      ),
    );
  }

  /// Schedule a server message notification for immediate display
  /// This can be called from background services
  Future<void> showServerMessageImmediate({
    required String messageId,
    required String title,
    required String body,
    bool isUrgent = false,
  }) async {
    final id = messageId.hashCode.abs();

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'server_messages_urgent',
          'Urgent Server Messages',
          channelDescription: 'Channel for urgent server messages',
          importance: isUrgent ? Importance.max : Importance.high,
          priority: isUrgent ? Priority.max : Priority.high,
          showWhen: true,
          enableVibration: true,
          playSound: true,
          autoCancel: true,
          ongoing: false,
          icon: '@mipmap/ic_launcher_monochrome',
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          styleInformation: const BigTextStyleInformation(''),
          visibility: NotificationVisibility.public,
          // Add action buttons if needed
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'view_action',
              'View',
              showsUserInterface: true,
            ),
            AndroidNotificationAction(
              'dismiss_action',
              'Dismiss',
              showsUserInterface: false,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  /// Check if exact alarm permission is granted (without requesting it)
  Future<bool> hasExactAlarmPermission() async {
    try {
      final androidImplementation =
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidImplementation == null) {
        return false;
      }

      // Just check the permission status without requesting
      return await Permission.scheduleExactAlarm.isGranted;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking exact alarm permission: $e');
      }
      return false;
    }
  }

  /// Request exact alarm permission and return the result
  Future<bool> requestExactAlarmPermission() async {
    try {
      final androidImplementation =
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidImplementation == null) {
        return false;
      }

      // Check current status first
      final hasExactAlarmPermission =
          await Permission.scheduleExactAlarm.isGranted;

      // Request SCHEDULE_EXACT_ALARM if not granted
      if (!hasExactAlarmPermission) {
        await Permission.scheduleExactAlarm.request();
      }

      // Return final permission status
      return await Permission.scheduleExactAlarm.isGranted;
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting exact alarm permission: $e');
      }
      return false;
    }
  }

  /// Check exact alarm permission and request if needed (legacy method for compatibility)
  Future<bool> checkExactAlarmPermission() async {
    return await requestExactAlarmPermission();
  }
}
