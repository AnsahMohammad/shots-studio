import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';
import 'package:shots_studio/services/logger_service.dart';

/// Service for handling hard deletion of screenshot files from device storage
/// Uses native MediaStore API on Android 11+ for batch delete with single confirmation dialog
class HardDeleteService {
  static const bool _kDebugMode = kDebugMode;
  static const MethodChannel _mediaDeleteChannel = MethodChannel(
    'media_delete',
  );

  /// Check if hard delete is available on the current platform
  static bool isHardDeleteAvailable() {
    // Hard delete is only available on mobile platforms where we have file access
    return !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  }

  /// Check if native batch delete with single dialog is supported
  static Future<bool> isBatchDeleteSupported() async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _mediaDeleteChannel.invokeMethod<bool>(
        'isSupported',
      );
      return result ?? false;
    } catch (e) {
      if (_kDebugMode) {
        LoggerService.error(
          'HardDeleteService: Error checking batch delete support',
          e,
        );
      }
      return false;
    }
  }

  /// Attempt to hard delete a screenshot file from device storage
  /// For single file deletion, uses the batch method internally
  static Future<HardDeleteResult> hardDeleteScreenshot(
    Screenshot screenshot,
  ) async {
    if (!isHardDeleteAvailable()) {
      return HardDeleteResult(
        success: false,
        error: 'Hard delete not available on this platform',
        fileExisted: false,
      );
    }

    // Check if screenshot has a valid file path
    if (screenshot.path == null || screenshot.path?.isEmpty == true) {
      if (_kDebugMode) {
        LoggerService.log(
          'HardDeleteService: Screenshot has no file path, cannot hard delete',
        );
      }
      return HardDeleteResult(
        success: false,
        error: 'No file path available for deletion',
        fileExisted: false,
      );
    }

    try {
      final filePath = screenshot.path!;
      final file = File(filePath);

      // Check if file exists before attempting deletion
      final bool fileExisted = await file.exists();

      if (_kDebugMode) {
        LoggerService.log(
          'HardDeleteService: Attempting to delete file: $filePath',
        );
        LoggerService.log('HardDeleteService: File exists: $fileExisted');
      }

      if (!fileExisted) {
        return HardDeleteResult(
          success: true, // Consider this success since the file is already gone
          error: null,
          fileExisted: false,
          message: 'File was already deleted or moved',
        );
      }

      // Use batch delete method (works for single file too)
      final bulkResult = await hardDeleteScreenshots([screenshot]);

      if (bulkResult.successCount > 0) {
        AnalyticsService().logFeatureUsed('screenshot_hard_deleted');
        return HardDeleteResult(
          success: true,
          error: null,
          fileExisted: fileExisted,
          message: 'File successfully deleted from device',
        );
      } else {
        return HardDeleteResult(
          success: false,
          error:
              bulkResult.overallError ??
              'Deletion failed or was denied by user',
          fileExisted: fileExisted,
        );
      }
    } catch (e) {
      if (_kDebugMode) {
        LoggerService.error('HardDeleteService: Error during hard delete', e);
      }

      return HardDeleteResult(
        success: false,
        error: 'Failed to delete file: ${e.toString()}',
        fileExisted: true,
      );
    }
  }

  /// Delete a single file using native MediaStore API (for use by other services like ExportService)
  /// Returns true if deletion was successful, false otherwise
  static Future<bool> deleteFileWithMediaStore(String filePath) async {
    if (!isHardDeleteAvailable()) {
      return false;
    }

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return true; // Already deleted
      }

      if (Platform.isAndroid) {
        try {
          final result = await _mediaDeleteChannel
              .invokeMethod<Map<dynamic, dynamic>>('deleteMediaFiles', {
                'filePaths': [filePath],
              });

          final success = result?['success'] == true;
          if (_kDebugMode) {
            LoggerService.log(
              'HardDeleteService.deleteFileWithMediaStore: result=$result, success=$success',
            );
          }
          return success;
        } catch (e) {
          if (_kDebugMode) {
            LoggerService.error(
              'HardDeleteService.deleteFileWithMediaStore: Native delete error',
              e,
            );
          }
          // Fallback to direct deletion
          try {
            await file.delete();
            return !await file.exists();
          } catch (_) {
            return false;
          }
        }
      } else if (Platform.isIOS) {
        await file.delete();
        return !await file.exists();
      }

      return false;
    } catch (e) {
      if (_kDebugMode) {
        LoggerService.error(
          'HardDeleteService.deleteFileWithMediaStore: Error',
          e,
        );
      }
      return false;
    }
  }

  /// Perform hard delete on multiple screenshots with a SINGLE confirmation dialog
  /// On Android 11+, shows one dialog: "Delete X files?" instead of asking for each file
  static Future<BulkHardDeleteResult> hardDeleteScreenshots(
    List<Screenshot> screenshots,
  ) async {
    if (!isHardDeleteAvailable()) {
      return BulkHardDeleteResult(
        totalAttempted: screenshots.length,
        successCount: 0,
        failureCount: screenshots.length,
        results: [],
        overallError: 'Hard delete not available on this platform',
      );
    }

    if (screenshots.isEmpty) {
      return BulkHardDeleteResult(
        totalAttempted: 0,
        successCount: 0,
        failureCount: 0,
        results: [],
      );
    }

    if (_kDebugMode) {
      LoggerService.log(
        'HardDeleteService: Starting bulk hard delete of ${screenshots.length} screenshots',
      );
    }

    // Collect valid file paths
    final List<String> filePaths = [];
    final List<HardDeleteResult> results = [];

    for (final screenshot in screenshots) {
      if (screenshot.path != null && screenshot.path!.isNotEmpty) {
        final file = File(screenshot.path!);
        if (await file.exists()) {
          filePaths.add(screenshot.path!);
        } else {
          // File already gone - count as success
          results.add(
            HardDeleteResult(
              success: true,
              fileExisted: false,
              message: 'File was already deleted',
            ),
          );
        }
      } else {
        results.add(
          HardDeleteResult(
            success: false,
            error: 'No file path',
            fileExisted: false,
          ),
        );
      }
    }

    if (filePaths.isEmpty) {
      // All files were already deleted or had no path
      final successCount = results.where((r) => r.success).length;
      return BulkHardDeleteResult(
        totalAttempted: screenshots.length,
        successCount: successCount,
        failureCount: screenshots.length - successCount,
        results: results,
      );
    }

    try {
      if (Platform.isAndroid) {
        // Use native batch delete with single confirmation dialog
        final result = await _mediaDeleteChannel
            .invokeMethod<Map<dynamic, dynamic>>('deleteMediaFiles', {
              'filePaths': filePaths,
            });

        if (_kDebugMode) {
          LoggerService.log(
            'HardDeleteService: Native batch delete result: $result',
          );
        }

        final success = result?['success'] == true;
        final userApproved = result?['userApproved'] as bool? ?? false;
        final error = result?['error'] as String?;

        // Add results for the files we attempted to delete
        for (int i = 0; i < filePaths.length; i++) {
          if (success) {
            results.add(
              HardDeleteResult(
                success: true,
                fileExisted: true,
                message: 'File deleted',
              ),
            );
          } else {
            results.add(
              HardDeleteResult(
                success: false,
                error:
                    userApproved ? 'Deletion failed' : 'User denied deletion',
                fileExisted: true,
              ),
            );
          }
        }

        final totalSuccessCount = results.where((r) => r.success).length;
        final totalFailureCount = results.where((r) => !r.success).length;

        // Log analytics
        AnalyticsService().logFeatureUsed('screenshots_bulk_hard_deleted');
        AnalyticsService().logFeatureUsed(
          'hard_delete_success_count_$totalSuccessCount',
        );
        AnalyticsService().logFeatureUsed(
          'hard_delete_failure_count_$totalFailureCount',
        );

        if (_kDebugMode) {
          LoggerService.log(
            'HardDeleteService: Bulk hard delete completed - Success: $totalSuccessCount, Failed: $totalFailureCount',
          );
        }

        return BulkHardDeleteResult(
          totalAttempted: screenshots.length,
          successCount: totalSuccessCount,
          failureCount: totalFailureCount,
          results: results,
          overallError: success ? null : error,
        );
      } else if (Platform.isIOS) {
        // iOS - delete files directly one by one
        for (final path in filePaths) {
          try {
            final file = File(path);
            await file.delete();
            final stillExists = await file.exists();
            results.add(
              HardDeleteResult(
                success: !stillExists,
                fileExisted: true,
                error: stillExists ? 'File still exists after delete' : null,
              ),
            );
          } catch (e) {
            results.add(
              HardDeleteResult(
                success: false,
                error: e.toString(),
                fileExisted: true,
              ),
            );
          }
        }

        final successCount = results.where((r) => r.success).length;
        final failureCount = results.where((r) => !r.success).length;

        AnalyticsService().logFeatureUsed('screenshots_bulk_hard_deleted');

        return BulkHardDeleteResult(
          totalAttempted: screenshots.length,
          successCount: successCount,
          failureCount: failureCount,
          results: results,
        );
      }

      return BulkHardDeleteResult(
        totalAttempted: screenshots.length,
        successCount: 0,
        failureCount: screenshots.length,
        results: [],
        overallError: 'Unsupported platform',
      );
    } catch (e) {
      if (_kDebugMode) {
        LoggerService.error('HardDeleteService: Error during bulk delete', e);
      }

      return BulkHardDeleteResult(
        totalAttempted: screenshots.length,
        successCount: 0,
        failureCount: screenshots.length,
        results: [],
        overallError: 'Failed to delete files: ${e.toString()}',
      );
    }
  }
}

/// Result of a single hard delete operation
class HardDeleteResult {
  final bool success;
  final String? error;
  final bool fileExisted;
  final String? message;

  HardDeleteResult({
    required this.success,
    this.error,
    required this.fileExisted,
    this.message,
  });

  @override
  String toString() {
    return 'HardDeleteResult{success: $success, error: $error, fileExisted: $fileExisted, message: $message}';
  }
}

/// Result of bulk hard delete operations
class BulkHardDeleteResult {
  final int totalAttempted;
  final int successCount;
  final int failureCount;
  final List<HardDeleteResult> results;
  final String? overallError;

  BulkHardDeleteResult({
    required this.totalAttempted,
    required this.successCount,
    required this.failureCount,
    required this.results,
    this.overallError,
  });

  double get successRate =>
      totalAttempted > 0 ? successCount / totalAttempted : 0.0;

  @override
  String toString() {
    return 'BulkHardDeleteResult{totalAttempted: $totalAttempted, successCount: $successCount, failureCount: $failureCount, successRate: ${(successRate * 100).toStringAsFixed(1)}%}';
  }
}
