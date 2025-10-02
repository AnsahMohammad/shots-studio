import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/services/notification_service.dart';
import 'package:shots_studio/services/snackbar_service.dart';
import 'package:shots_studio/widgets/screenshots/reminder_bottom_sheet.dart';

class ReminderUtils {
  static Future<Map<String, dynamic>?> showReminderBottomSheet(
    BuildContext context,
    DateTime? currentReminderTime,
    String? currentReminderText,
  ) async {
    return await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ReminderBottomSheet(
          initialReminderTime: currentReminderTime,
          initialReminderText: currentReminderText,
        );
      },
    );
  }

  static Future<DateTime?> selectReminderDateTime(
    BuildContext context,
    DateTime? currentReminderTime,
  ) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: currentReminderTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          currentReminderTime ?? DateTime.now(),
        ),
      );
      if (pickedTime != null) {
        return DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      }
    }
    return null;
  }

  static Future<void> setReminder(
    BuildContext context,
    Screenshot screenshot,
    DateTime? selectedReminderTime, {
    String? customMessage,
  }) async {
    if (selectedReminderTime != null &&
        selectedReminderTime.isAfter(DateTime.now())) {
      // Check if exact alarm permission is granted
      final notificationService = NotificationService();
      final hasPermission = await notificationService.hasExactAlarmPermission();

      if (!hasPermission) {
        // Show permission dialog
        if (!context.mounted) return;
        final shouldProceed = await _showExactAlarmPermissionDialog(context);
        if (!shouldProceed) {
          return; // User cancelled
        }

        // Request permission
        final permissionGranted =
            await notificationService.requestExactAlarmPermission();
        if (!permissionGranted) {
          if (!context.mounted) return;
          SnackbarService().showError(
            context,
            'Exact alarm permission is required for reliable reminders. You can enable it in system settings.',
          );
          return;
        }
      }

      final reminderMessage =
          customMessage?.isNotEmpty == true
              ? customMessage!
              : 'Reminder for screenshot: ${screenshot.title ?? 'Untitled'}';

      // Schedule notification with screenshot image
      NotificationService().scheduleNotificationWithImage(
        id: screenshot.id.hashCode,
        title: 'Screenshot Reminder',
        body: reminderMessage,
        scheduledTime: selectedReminderTime,
        imagePath: screenshot.path, // Pass the image path for mobile
        imageBytes: screenshot.bytes, // Pass the image bytes for web
      );

      if (!context.mounted) return;
      SnackbarService().showSuccess(
        context,
        'Reminder set for ${DateFormat('MMM d, yyyy, hh:mm a').format(selectedReminderTime)}',
      );
    } else {
      SnackbarService().showError(
        context,
        'Please select a future time for the reminder.',
      );
    }
  }

  static void clearReminder(BuildContext context, Screenshot screenshot) {
    NotificationService().cancelNotification(screenshot.id.hashCode);
    SnackbarService().showInfo(context, 'Reminder cleared');
  }

  static Future<void> showTestNotification() async {
    await NotificationService().showTestNotification();
  }

  static Future<void> showScheduledTestNotification() async {
    final scheduledTime = DateTime.now().add(const Duration(seconds: 10));

    await NotificationService().scheduleNotification(
      id: 9999,
      title: 'Scheduled Test Notification',
      body: 'This is a scheduled test notification (10 seconds)',
      scheduledTime: scheduledTime,
    );
  }

  static Future<void> debugNotifications() async {
    await NotificationService().debugScheduledNotifications();
  }

  static Future<void> testNotificationInMinute() async {
    await NotificationService().testScheduleNotificationInMinute();
  }

  /// Show a dialog asking user for exact alarm permission
  static Future<bool> _showExactAlarmPermissionDialog(
    BuildContext context,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Reminder Permission'),
              content: const Text(
                'To ensure your reminders work reliably, this app needs permission to schedule exact alarms.\n\n'
                'Without this permission, reminders may be delayed or not work when the device is in battery optimization mode.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Allow'),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}
