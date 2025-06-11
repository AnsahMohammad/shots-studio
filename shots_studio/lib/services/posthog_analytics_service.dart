import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class PostHogAnalyticsService {
  static final PostHogAnalyticsService _instance =
      PostHogAnalyticsService._internal();
  factory PostHogAnalyticsService() => _instance;
  PostHogAnalyticsService._internal();

  bool _initialized = false;
  bool _analyticsEnabled =
      !kDebugMode; // Default to false in debug mode, true in production
  static const String _analyticsConsentKey = 'analytics_consent_enabled';

  // Initialize analytics
  Future<void> initialize() async {
    if (_initialized) return;

    // Load consent preference
    await _loadAnalyticsConsent();

    // PostHog is automatically initialized via platform-specific configurations
    // But we can set user properties and configure it here

    if (_analyticsEnabled) {
      // PostHog is enabled by default when initialized
      // No explicit opt-in needed as it's controlled via platform configs
    } else {
      // Disable PostHog by resetting the instance
      await Posthog().reset();
    }

    _initialized = true;

    // Log app startup only if consent is given
    if (_analyticsEnabled) {
      await logAppStartup();
    }
  }

  // Load analytics consent from SharedPreferences
  Future<void> _loadAnalyticsConsent() async {
    final prefs = await SharedPreferences.getInstance();
    _analyticsEnabled =
        prefs.getBool(_analyticsConsentKey) ??
        !kDebugMode; // Default to false in debug mode, true in production
  }

  // Save analytics consent to SharedPreferences
  Future<void> _saveAnalyticsConsent(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_analyticsConsentKey, enabled);
  }

  bool get analyticsEnabled => _analyticsEnabled;

  // Enable analytics and telemetry
  Future<void> enableAnalytics() async {
    _analyticsEnabled = true;
    await _saveAnalyticsConsent(true);

    if (_initialized) {
      // PostHog is enabled by default - no explicit action needed
      // Log that analytics was re-enabled
      await logFeatureUsed('analytics_enabled');
    }
  }

  // Disable analytics and telemetry
  Future<void> disableAnalytics() async {
    // Log that analytics is being disabled before we actually disable it
    if (_analyticsEnabled && _initialized) {
      await logFeatureUsed('analytics_disabled');
    }

    _analyticsEnabled = false;
    await _saveAnalyticsConsent(false);

    if (_initialized) {
      // Reset PostHog to clear all data
      await Posthog().reset();
    }
  }

  // Helper method to check if analytics should be logged
  bool _shouldLog() {
    return _initialized && _analyticsEnabled;
  }

  // Screenshot Processing Analytics
  Future<void> logBatchProcessingTime(
    int processingTimeMs,
    int screenshotCount,
  ) async {
    if (!_shouldLog()) return;

    await Posthog().capture(
      eventName: 'batch_processing_time',
      properties: {
        'processing_time_ms': processingTimeMs,
        'screenshot_count': screenshotCount,
        'avg_time_per_screenshot': processingTimeMs / screenshotCount,
      },
    );
  }

  Future<void> logAIProcessingSuccess(int screenshotCount) async {
    if (!_shouldLog()) return;

    await Posthog().capture(
      eventName: 'ai_processing_success',
      properties: {'screenshot_count': screenshotCount},
    );
  }

  Future<void> logAIProcessingFailure(String error, int screenshotCount) async {
    if (!_shouldLog()) return;

    await Posthog().capture(
      eventName: 'ai_processing_failure',
      properties: {'error': error, 'screenshot_count': screenshotCount},
    );

    // Also capture error details for debugging
    await Posthog().capture(
      eventName: 'ai_processing_exception',
      properties: {'error_details': error, 'screenshot_count': screenshotCount},
    );
  }

  // Collection Management
  Future<void> logCollectionCreated() async {
    if (!_shouldLog()) return;

    await Posthog().capture(eventName: 'collection_created');
  }

  Future<void> logCollectionDeleted() async {
    if (!_shouldLog()) return;

    await Posthog().capture(eventName: 'collection_deleted');
  }

  Future<void> logCollectionStats(
    int totalCollections,
    int avgScreenshots,
    int minScreenshots,
    int maxScreenshots,
  ) async {
    if (!_shouldLog()) return;

    await Posthog().capture(
      eventName: 'collection_screenshot_stats',
      properties: {
        'total_collections': totalCollections,
        'avg_screenshots_per_collection': avgScreenshots,
        'min_screenshots_per_collection': minScreenshots,
        'max_screenshots_per_collection': maxScreenshots,
      },
    );
  }

  // User Interaction
  Future<void> logScreenView(String screenName) async {
    if (!_shouldLog()) return;

    await Posthog().screen(screenName: screenName);
  }

  Future<void> logFeatureUsed(String featureName) async {
    if (!_shouldLog()) return;

    await Posthog().capture(
      eventName: 'feature_used',
      properties: {'feature_name': featureName},
    );
  }

  Future<void> logUserPath(String fromScreen, String toScreen) async {
    if (!_shouldLog()) return;

    await Posthog().capture(
      eventName: 'user_path',
      properties: {'from_screen': fromScreen, 'to_screen': toScreen},
    );
  }

  // Performance Metrics
  Future<void> logAppStartup() async {
    if (!_shouldLog()) return;

    await Posthog().capture(
      eventName: 'app_startup',
      properties: {'timestamp': DateTime.now().millisecondsSinceEpoch},
    );
  }

  Future<void> logImageLoadTime(int loadTimeMs, String imageSource) async {
    if (!_shouldLog()) return;

    await Posthog().capture(
      eventName: 'image_load_time',
      properties: {
        'load_time_ms': loadTimeMs,
        'image_source': imageSource, // 'gallery', 'camera', 'device'
      },
    );
  }

  // Error Tracking
  Future<void> logNetworkError(String error, String context) async {
    if (!_shouldLog()) return;

    await Posthog().capture(
      eventName: 'network_error',
      properties: {'error': error, 'context': context},
    );

    // Also capture error details for debugging
    await Posthog().capture(
      eventName: 'network_error_exception',
      properties: {'error_details': '$context: $error'},
    );
  }

  // User Engagement
  Future<void> logActiveDay() async {
    if (!_shouldLog()) return;

    await Posthog().capture(
      eventName: 'active_day',
      properties: {'date': DateTime.now().toIso8601String().split('T')[0]},
    );
  }

  Future<void> logFeatureAdopted(String featureName) async {
    if (!_shouldLog()) return;

    await Posthog().capture(
      eventName: 'feature_adopted',
      properties: {'feature_name': featureName},
    );
  }

  Future<void> logReturnUser(int daysSinceLastOpen) async {
    if (!_shouldLog()) return;

    await Posthog().capture(
      eventName: 'return_user',
      properties: {'days_since_last_open': daysSinceLastOpen},
    );
  }

  Future<void> logUsageTime(String timeOfDay) async {
    if (!_shouldLog()) return;

    await Posthog().capture(
      eventName: 'usage_time',
      properties: {'time_of_day': timeOfDay},
    );
  }

  // Search and Discovery
  Future<void> logSearchQuery(String query, int resultsCount) async {
    if (!_shouldLog()) return;

    await Posthog().capture(
      eventName: 'search_query',
      properties: {
        'query_length': query.length,
        'results_count': resultsCount,
        'has_results': resultsCount > 0,
      },
    );
  }

  Future<void> logSearchTimeToResult(int timeMs, bool successful) async {
    if (!_shouldLog()) return;

    await Posthog().capture(
      eventName: 'search_time_to_result',
      properties: {'time_ms': timeMs, 'successful': successful},
    );
  }

  Future<void> logSearchSuccess(String query, int timeMs) async {
    if (!_shouldLog()) return;

    await Posthog().capture(
      eventName: 'search_success',
      properties: {'query_length': query.length, 'time_to_success_ms': timeMs},
    );
  }

  // Storage and Resources
  Future<void> logStorageUsage(int totalSizeBytes, int screenshotCount) async {
    if (!_shouldLog()) return;

    await Posthog().capture(
      eventName: 'storage_usage',
      properties: {
        'total_size_bytes': totalSizeBytes,
        'screenshot_count': screenshotCount,
        'avg_size_per_screenshot': totalSizeBytes / screenshotCount,
      },
    );
  }

  Future<void> logBackgroundResourceUsage(
    int processingTimeMs,
    int memoryUsageMB,
  ) async {
    if (!_shouldLog()) return;

    await Posthog().capture(
      eventName: 'background_resource_usage',
      properties: {
        'processing_time_ms': processingTimeMs,
        'memory_usage_mb': memoryUsageMB,
      },
    );
  }

  // App Health
  Future<void> logBatteryImpact(String level) async {
    if (!_shouldLog()) return;

    await Posthog().capture(
      eventName: 'battery_impact',
      properties: {
        'impact_level': level, // 'low', 'medium', 'high'
      },
    );
  }

  Future<void> logNetworkUsage(int bytesUsed, String operation) async {
    if (!_shouldLog()) return;

    await Posthog().capture(
      eventName: 'network_usage',
      properties: {
        'bytes_used': bytesUsed,
        'operation': operation, // 'ai_processing', 'image_upload', etc.
      },
    );
  }

  Future<void> logBackgroundTaskCompleted(
    String taskName,
    bool successful,
    int durationMs,
  ) async {
    if (!_shouldLog()) return;

    await Posthog().capture(
      eventName: 'background_task_completed',
      properties: {
        'task_name': taskName,
        'successful': successful,
        'duration_ms': durationMs,
      },
    );
  }

  // Statistics (Very Important)
  Future<void> logTotalScreenshotsProcessed(int count) async {
    if (!_shouldLog()) return;

    await Posthog().capture(
      eventName: 'total_screenshots_processed',
      properties: {'count': count},
    );
  }

  Future<void> logTotalCollections(int count) async {
    if (!_shouldLog()) return;

    await Posthog().capture(
      eventName: 'total_collections',
      properties: {'count': count},
    );
  }

  Future<void> logScreenshotsInCollection(
    int collectionId,
    int screenshotCount,
  ) async {
    if (!_shouldLog()) return;

    await Posthog().capture(
      eventName: 'screenshots_in_collection',
      properties: {'collection_screenshot_count': screenshotCount},
    );
  }

  Future<void> logScreenshotsAutoCategorized(int count) async {
    if (!_shouldLog()) return;

    await Posthog().capture(
      eventName: 'screenshots_auto_categorized',
      properties: {'count': count},
    );
  }

  Future<void> logReminderSet() async {
    if (!_shouldLog()) return;

    await Posthog().capture(eventName: 'reminder_set');
  }

  Future<void> logInstallInfo() async {
    if (!_shouldLog()) return;

    try {
      final packageInfo = await PackageInfo.fromPlatform();

      String platform = 'unknown';
      String osVersion = 'unknown';

      if (!kIsWeb) {
        if (Platform.isAndroid) {
          platform = 'android';
        } else if (Platform.isIOS) {
          platform = 'ios';
        } else if (Platform.isLinux) {
          platform = 'linux';
        } else if (Platform.isWindows) {
          platform = 'windows';
        } else if (Platform.isMacOS) {
          platform = 'macos';
        }
      } else {
        platform = 'web';
      }

      await Posthog().capture(
        eventName: 'install_info',
        properties: {
          'install_date': DateTime.now().toIso8601String(),
          'app_version': packageInfo.version,
          'build_number': packageInfo.buildNumber,
          'platform': platform,
          'os_version': osVersion,
        },
      );

      // Set person properties for better analytics
      await Posthog().identify(
        userId: 'anonymous_${DateTime.now().millisecondsSinceEpoch}',
        userProperties: {
          'app_version': packageInfo.version,
          'platform': platform,
          'first_seen': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Error logging install info: $e');
    }
  }

  // Helper method to calculate time of day
  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
  }

  // Log current usage time
  Future<void> logCurrentUsageTime() async {
    await logUsageTime(_getTimeOfDay());
  }

  // Additional PostHog-specific methods

  // Identify a user (useful for authenticated users)
  Future<void> identifyUser(
    String userId, [
    Map<String, dynamic>? properties,
  ]) async {
    if (!_shouldLog()) return;

    final Map<String, Object>? objectProperties =
        properties?.cast<String, Object>();
    await Posthog().identify(userId: userId, userProperties: objectProperties);
  }

  // Set person properties by identifying the current user with new properties
  Future<void> setPersonProperties(Map<String, dynamic> properties) async {
    if (!_shouldLog()) return;

    final Map<String, Object> objectProperties =
        properties.cast<String, Object>();
    // Get current user ID or create anonymous one
    final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    await Posthog().identify(userId: userId, userProperties: objectProperties);
  }

  // Reset user (for logout)
  Future<void> reset() async {
    if (!_shouldLog()) return;

    await Posthog().reset();
  }

  // Feature flags (if you want to use PostHog's feature flag functionality)
  Future<bool> isFeatureEnabled(String featureKey) async {
    if (!_shouldLog()) return false;

    return await Posthog().isFeatureEnabled(featureKey);
  }

  // Alias user (link anonymous user to identified user)
  Future<void> alias(String alias) async {
    if (!_shouldLog()) return;

    await Posthog().alias(alias: alias);
  }

  // Group analytics (for organization-level analytics)
  Future<void> group(
    String groupType,
    String groupKey, [
    Map<String, dynamic>? properties,
  ]) async {
    if (!_shouldLog()) return;

    final Map<String, Object>? objectProperties =
        properties?.cast<String, Object>();
    await Posthog().group(
      groupType: groupType,
      groupKey: groupKey,
      groupProperties: objectProperties,
    );
  }
}
