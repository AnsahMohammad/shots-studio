import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shots_studio/models/collection_model.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/services/ai_service_manager.dart';
import 'package:shots_studio/services/ai_service.dart';
import 'package:shots_studio/services/snackbar_service.dart';
import 'package:shots_studio/services/analytics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AICategorizer {
  final AIServiceManager _aiServiceManager = AIServiceManager();
  bool _isRunning = false;
  int _processedCount = 0;
  int _totalCount = 0;

  bool get isRunning => _isRunning;
  int get processedCount => _processedCount;
  int get totalCount => _totalCount;

  Future<AICategorizeResult> startAutoCategorization({
    required Collection collection,
    required List<Screenshot> allScreenshots,
    required List<String> currentScreenshotIds,
    required BuildContext context,
    required Function(Collection) onUpdateCollection,
    required Function(List<String> screenshotIds) onScreenshotsAdded,
    required Function(int processed, int total) onProgressUpdate,
    Function()? onCompleted,
  }) async {
    // Prevent multiple auto-categorization attempts
    if (_isRunning) {
      return AICategorizeResult(
        success: false,
        error: 'Auto-categorization is already running',
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final String? apiKey = prefs.getString('apiKey');
    if (apiKey == null || apiKey.isEmpty) {
      SnackbarService().showError(
        context,
        'API key not set. Please configure it in settings.',
      );
      return AICategorizeResult(success: false, error: 'API key not set');
    }

    final String modelName =
        prefs.getString('selected_model') ?? 'gemini-2.0-flash';
    final int maxParallel = (prefs.getInt('max_parallel_ai') ?? 4) * 6;

    // Keep track of the current collection state as it gets updated
    Collection currentCollection = collection;

    final List<Screenshot> candidateScreenshots =
        allScreenshots
            .where(
              (s) =>
                  !currentScreenshotIds.contains(s.id) &&
                  !s.isDeleted &&
                  !currentCollection.scannedSet.contains(s.id) &&
                  s.aiProcessed,
            )
            .toList();

    _isRunning = true;
    _processedCount = 0;
    _totalCount = candidateScreenshots.length;

    onProgressUpdate(_processedCount, _totalCount);

    // Log analytics for auto-categorization start
    AnalyticsService().logFeatureUsed('auto_categorization_started');

    // If no candidate screenshots, silently return success without any snackbar
    if (candidateScreenshots.isEmpty) {
      _isRunning = false;
      onCompleted?.call(); // Notify completion for empty case too
      return AICategorizeResult(success: true, addedScreenshotIds: []);
    }

    final config = AIConfig(
      apiKey: apiKey,
      modelName: modelName,
      maxParallel: maxParallel,
      showMessage: ({
        required String message,
        Color? backgroundColor,
        Duration? duration,
      }) {
        SnackbarService().showInfo(context, message);
      },
    );

    try {
      // Initialize the AI service manager
      _aiServiceManager.initialize(config);

      final result = await _aiServiceManager.categorizeScreenshots(
        collection: currentCollection,
        screenshots: candidateScreenshots,
        onBatchProcessed: (batch, response) {
          _processedCount += batch.length;
          onProgressUpdate(_processedCount, _totalCount);

          // Add all batch screenshot IDs to the scanned set (regardless of whether they matched)
          final List<String> batchIds = batch.map((s) => s.id).toList();
          final updatedCollection = currentCollection.addScannedScreenshots(
            batchIds,
          );
          currentCollection = updatedCollection; // Update our local reference
          onUpdateCollection(updatedCollection);

          // Process batch results immediately if successful
          if (!response.containsKey('error') && response.containsKey('data')) {
            try {
              final String responseText = response['data'];
              final RegExp jsonRegExp = RegExp(r'\{.*\}', dotAll: true);
              final match = jsonRegExp.firstMatch(responseText);

              if (match != null) {
                final parsedResponse = jsonDecode(match.group(0)!);
                if (parsedResponse['matching_screenshots'] is List) {
                  final List<String> batchMatchingIds = List<String>.from(
                    parsedResponse['matching_screenshots'],
                  );

                  if (batchMatchingIds.isNotEmpty) {
                    // Update screenshot models immediately
                    for (String screenshotId in batchMatchingIds) {
                      final screenshot = allScreenshots.firstWhere(
                        (s) => s.id == screenshotId,
                      );
                      if (!screenshot.collectionIds.contains(
                        currentCollection.id,
                      )) {
                        screenshot.collectionIds.add(currentCollection.id);
                      }
                    }

                    // Log analytics for auto-categorized screenshots
                    AnalyticsService().logScreenshotsAutoCategorized(
                      batchMatchingIds.length,
                    );

                    // Notify about added screenshots
                    onScreenshotsAdded(batchMatchingIds);
                  }
                }
              }
            } catch (e) {
              // Silently handle parsing errors for individual batches
              print('Error parsing batch response: $e');
            }
          }
        },
      );

      _isRunning = false;
      onCompleted?.call(); // Notify completion immediately

      if (result.cancelled) {
        SnackbarService().showInfo(context, 'Auto-categorization cancelled.');
        AnalyticsService().logFeatureUsed('auto_categorization_cancelled');
        return AICategorizeResult(
          success: false,
          cancelled: true,
          error: 'Cancelled by user',
        );
      }

      if (result.success) {
        final List<String> totalMatchingScreenshotIds = result.data ?? [];

        // Log final analytics for total auto-categorized screenshots
        if (totalMatchingScreenshotIds.isNotEmpty) {
          AnalyticsService().logScreenshotsAutoCategorized(
            totalMatchingScreenshotIds.length,
          );
          AnalyticsService().logFeatureUsed('auto_categorization_completed');
        }

        // Show final summary
        if (totalMatchingScreenshotIds.isNotEmpty) {
          SnackbarService().showInfo(
            context,
            'Auto-categorization completed. Total: ${totalMatchingScreenshotIds.length} screenshots added.',
          );
        } else {
          SnackbarService().showInfo(
            context,
            'Auto-categorization completed. No matching screenshots found.',
          );
        }

        return AICategorizeResult(
          success: true,
          addedScreenshotIds: totalMatchingScreenshotIds,
        );
      } else {
        SnackbarService().showError(
          context,
          result.error ?? 'Auto-categorization failed',
        );
        AnalyticsService().logFeatureUsed('auto_categorization_failed');
        return AICategorizeResult(
          success: false,
          error: result.error ?? 'Auto-categorization failed',
        );
      }
    } catch (e) {
      _isRunning = false;
      onCompleted?.call(); // Notify completion on error too
      AnalyticsService().logFeatureUsed('auto_categorization_error');
      SnackbarService().showError(
        context,
        'Error during auto-categorization: ${e.toString()}',
      );
      return AICategorizeResult(
        success: false,
        error: 'Error during auto-categorization: ${e.toString()}',
      );
    } finally {
      _isRunning = false;
      onCompleted?.call();
      _processedCount = 0;
      _totalCount = 0;
    }
  }

  void stopAutoCategorization() {
    _aiServiceManager.cancelAllOperations();
    _isRunning = false;
    _processedCount = 0;
    _totalCount = 0;
  }
}

class AICategorizeResult {
  final bool success;
  final bool cancelled;
  final String? error;
  final List<String>? addedScreenshotIds;

  AICategorizeResult({
    required this.success,
    this.cancelled = false,
    this.error,
    this.addedScreenshotIds,
  });
}
