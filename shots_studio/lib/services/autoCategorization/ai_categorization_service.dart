// AutoCategorization Service
// This service handles the automatic categorization of screenshots which are
// already processed by AI.

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shots_studio/models/collection_model.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/services/ai_service_manager.dart';
import 'package:shots_studio/services/ai_service.dart';
import 'package:shots_studio/services/snackbar_service.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';
import 'package:shots_studio/utils/ai_provider_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shots_studio/services/logger_service.dart';
import 'package:shots_studio/services/openai_compatibility_service.dart';

class AICategorizer {
  final AIServiceManager _aiServiceManager = AIServiceManager();
  bool _isRunning = false;
  int _processedCount = 0;
  int _totalCount = 0;

  bool get isRunning => _isRunning;
  int get processedCount => _processedCount;
  int get totalCount => _totalCount;

  Future<AICategorizeResult> startScanning({
    required Collection collection,
    required List<Screenshot> allScreenshots,
    required List<String> currentScreenshotIds,
    required BuildContext context,
    required Function(Collection) onUpdateCollection,
    required Function(List<String> screenshotIds) onScreenshotsAdded,
    required Function(int processed, int total) onProgressUpdate,
    Function()? onCompleted,
    bool isRescan = false,
  }) async {
    // Prevent multiple scanning attempts
    if (_isRunning) {
      return AICategorizeResult(success: false, error: 'Already scanning');
    }

    final prefs = await SharedPreferences.getInstance();
    final String modelName =
        prefs.getString('modelName') ?? 'gemini-2.5-flash-lite';
    final String modelProvider =
      prefs.getString('modelProvider') ??
      AIProviderConfig.getProviderForModel(modelName);
    final String openAIBaseUrl =
      prefs.getString(OpenAICompatibilityService.baseUrlPrefKey) ??
      'http://localhost:11434';
    final String openAIApiKey =
      prefs.getString(OpenAICompatibilityService.apiKeyPrefKey) ?? '';
    final String? apiKey =
      modelProvider == 'openai_compatible'
        ? openAIApiKey
        : prefs.getString('apiKey');

    if (AIProviderConfig.requiresApiKey(modelName) &&
        (apiKey == null || apiKey.isEmpty)) {
      SnackbarService().showError(
        context,
        'API key missing. Please add it in settings.',
      );
      return AICategorizeResult(success: false, error: 'API key not set');
    }

    final int maxParallel = AIProviderConfig.getMaxCategorizationLimitForModel(
      modelName,
    );

    // Keep track of the current collection state as it gets updated
    Collection currentCollection = collection;

    // Filter candidate screenshots based on whether this is a rescan or not
    final List<Screenshot> candidateScreenshots;

    if (isRescan) {
      // For rescans, include all AI-processed, non-deleted screenshots
      candidateScreenshots =
          allScreenshots.where((s) => !s.isDeleted && s.aiProcessed).toList();
    } else {
      // For normal scans, exclude screenshots already in collection and already scanned
      candidateScreenshots =
          allScreenshots
              .where(
                (s) =>
                    !currentScreenshotIds.contains(s.id) &&
                    !s.isDeleted &&
                    !currentCollection.scannedSet.contains(s.id) &&
                    s.aiProcessed,
              )
              .toList();
    }

    _isRunning = true;
    _processedCount = 0;
    _totalCount = candidateScreenshots.length;

    onProgressUpdate(_processedCount, _totalCount);

    // Log analytics for scanning start
    if (isRescan) {
      AnalyticsService().logFeatureUsed('rescanning_started');
    } else {
      AnalyticsService().logFeatureUsed('scanning_started');
    }

    // If no candidate screenshots, show dialog with option to rescan
    if (candidateScreenshots.isEmpty) {
      _isRunning = false;
      onCompleted?.call(); // Notify completion for empty case too

      // Show dialog asking if user wants to scan again
      final bool? shouldRescan = await _showRescanDialog(context);

      // If user chose not to rescan, return empty result
      if (shouldRescan != true) {
        return AICategorizeResult(success: true, addedScreenshotIds: []);
      }

      // Clear the scanned set and recursively call the scanning function
      final clearedCollection = currentCollection.copyWith(
        scannedSet: <String>{},
      );
      onUpdateCollection(clearedCollection);

      // Recursively call startScanning with the cleared collection
      return await startScanning(
        collection: clearedCollection,
        allScreenshots: allScreenshots,
        currentScreenshotIds: currentScreenshotIds,
        context: context,
        onUpdateCollection: onUpdateCollection,
        onScreenshotsAdded: onScreenshotsAdded,
        onProgressUpdate: onProgressUpdate,
        onCompleted: onCompleted,
        isRescan: true,
      );
    }

    final config = AIConfig(
      apiKey: apiKey ?? '', // Handle null case for gemma model
      modelName: modelName,
      maxParallel: maxParallel,
      providerSpecificConfig: {
        'provider': modelProvider,
        'openaiBaseUrl': openAIBaseUrl,
        'openaiApiKey': openAIApiKey,
      },
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

          // Add all batch screenshot IDs to the scanned set
          // (regardless of whether they matched)
          final List<String> batchIds = batch.map((s) => s.id).toList();
          final updatedCollection = currentCollection.addScannedScreenshots(
            batchIds,
          );
          currentCollection = updatedCollection; // Update our local reference
          onUpdateCollection(updatedCollection);

          // Process batch results immediately if successful
          // TODO: Make sure that if API rate limit occurs we handle it
          // gracefully instead of considering it as processed
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

                    // Log analytics for scanned screenshots
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
              LoggerService.error('Error parsing batch response', e);
            }
          }
        },
      );

      _isRunning = false;
      onCompleted?.call(); // Notify completion immediately

      if (result.cancelled) {
        SnackbarService().showInfo(context, 'Scan cancelled.');
        AnalyticsService().logFeatureUsed('scanning_cancelled');
        return AICategorizeResult(
          success: false,
          cancelled: true,
          error: 'Cancelled by user',
        );
      }

      if (result.success) {
        final List<String> totalMatchingScreenshotIds = result.data ?? [];

        // Log final analytics for total scanned screenshots
        if (totalMatchingScreenshotIds.isNotEmpty) {
          AnalyticsService().logScreenshotsAutoCategorized(
            totalMatchingScreenshotIds.length,
          );
          AnalyticsService().logFeatureUsed('scanning_completed');
        }

        // Show final summary
        if (totalMatchingScreenshotIds.isNotEmpty) {
          SnackbarService().showInfo(
            context,
            'Scan complete. Added ${totalMatchingScreenshotIds.length} screenshots.',
          );
        } else {
          SnackbarService().showInfo(
            context,
            'Scan complete. No matches found.',
          );
        }

        return AICategorizeResult(
          success: true,
          addedScreenshotIds: totalMatchingScreenshotIds,
        );
      } else {
        SnackbarService().showError(context, result.error ?? 'Scan failed');
        AnalyticsService().logFeatureUsed('scanning_failed');
        return AICategorizeResult(
          success: false,
          error: result.error ?? 'Scan failed',
        );
      }
    } catch (e) {
      _isRunning = false;
      onCompleted?.call(); // Notify completion on error too
      AnalyticsService().logFeatureUsed('scanning_error');
      SnackbarService().showError(context, 'Scan error: ${e.toString()}');
      return AICategorizeResult(
        success: false,
        error: 'Scan error: ${e.toString()}',
      );
    } finally {
      _isRunning = false;
      onCompleted?.call();
      _processedCount = 0;
      _totalCount = 0;
    }
  }

  void stopScanning() {
    _aiServiceManager.cancelAllOperations();
    _isRunning = false;
    _processedCount = 0;
    _totalCount = 0;
  }

  /// Shows a dialog asking the user if they want to rescan all screenshots
  /// Returns true if user wants to rescan, false or null otherwise
  Future<bool?> _showRescanDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Expanded(child: Text('All Screenshots Scanned')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('All screenshots have been checked already.'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.refresh,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Scan Again:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'This will check all your screenshots again, including ones already in this collection. This is useful if you\'ve updated the collection description or want to find additional matches.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'No',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Yes, Scan Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
            ),
          ],
        );
      },
    );
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
