import 'package:flutter/foundation.dart';

class LoggerService {
  static const String _tag = 'ShotsStudio';

  /// Log a debug message
  static void log(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      if (error != null) {
        debugPrint('$_tag: $message\nError: $error');
        if (stackTrace != null) {
          debugPrint('Stack trace:\n$stackTrace');
        }
      } else {
        debugPrint('$_tag: $message');
      }
    }
  }

  /// Log an error message
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    // Always log errors, even in release mode (or consider using a crash reporting service here as well)
    // For now, we'll stick to debugPrint which strips in release builds on Android
    // unless we strictly want to see it in `adb logcat` in release.
    // Using `debugPrint` is generally safer/better.
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '$_tag [ERROR] $timestamp: $message';

    debugPrint(logMessage);
    if (error != null) {
      debugPrint('Error details: $error');
    }
    if (stackTrace != null) {
      debugPrint('Stack trace:\n$stackTrace');
    }
  }

  /// Log an info message
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('$_tag [INFO]: $message');
    }
  }
}
