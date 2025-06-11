// This is a compatibility wrapper that maintains the same interface as the Firebase AnalyticsService
// but uses PostHog underneath. This allows for a seamless migration without changing existing code.

import 'posthog_analytics_service.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final PostHogAnalyticsService _postHogService = PostHogAnalyticsService();

  // Initialize analytics
  Future<void> initialize() async {
    await _postHogService.initialize();
  }

  bool get analyticsEnabled => _postHogService.analyticsEnabled;

  // Enable analytics and telemetry
  Future<void> enableAnalytics() async {
    await _postHogService.enableAnalytics();
  }

  // Disable analytics and telemetry
  Future<void> disableAnalytics() async {
    await _postHogService.disableAnalytics();
  }

  // Screenshot Processing Analytics
  Future<void> logBatchProcessingTime(
    int processingTimeMs,
    int screenshotCount,
  ) async {
    await _postHogService.logBatchProcessingTime(processingTimeMs, screenshotCount);
  }

  Future<void> logAIProcessingSuccess(int screenshotCount) async {
    await _postHogService.logAIProcessingSuccess(screenshotCount);
  }

  Future<void> logAIProcessingFailure(String error, int screenshotCount) async {
    await _postHogService.logAIProcessingFailure(error, screenshotCount);
  }

  // Collection Management
  Future<void> logCollectionCreated() async {
    await _postHogService.logCollectionCreated();
  }

  Future<void> logCollectionDeleted() async {
    await _postHogService.logCollectionDeleted();
  }

  Future<void> logCollectionStats(
    int totalCollections,
    int avgScreenshots,
    int minScreenshots,
    int maxScreenshots,
  ) async {
    await _postHogService.logCollectionStats(
      totalCollections,
      avgScreenshots,
      minScreenshots,
      maxScreenshots,
    );
  }

  // User Interaction
  Future<void> logScreenView(String screenName) async {
    await _postHogService.logScreenView(screenName);
  }

  Future<void> logFeatureUsed(String featureName) async {
    await _postHogService.logFeatureUsed(featureName);
  }

  Future<void> logUserPath(String fromScreen, String toScreen) async {
    await _postHogService.logUserPath(fromScreen, toScreen);
  }

  // Performance Metrics
  Future<void> logAppStartup() async {
    await _postHogService.logAppStartup();
  }

  Future<void> logImageLoadTime(int loadTimeMs, String imageSource) async {
    await _postHogService.logImageLoadTime(loadTimeMs, imageSource);
  }

  // Error Tracking
  Future<void> logNetworkError(String error, String context) async {
    await _postHogService.logNetworkError(error, context);
  }

  // User Engagement
  Future<void> logActiveDay() async {
    await _postHogService.logActiveDay();
  }

  Future<void> logFeatureAdopted(String featureName) async {
    await _postHogService.logFeatureAdopted(featureName);
  }

  Future<void> logReturnUser(int daysSinceLastOpen) async {
    await _postHogService.logReturnUser(daysSinceLastOpen);
  }

  Future<void> logUsageTime(String timeOfDay) async {
    await _postHogService.logUsageTime(timeOfDay);
  }

  // Search and Discovery
  Future<void> logSearchQuery(String query, int resultsCount) async {
    await _postHogService.logSearchQuery(query, resultsCount);
  }

  Future<void> logSearchTimeToResult(int timeMs, bool successful) async {
    await _postHogService.logSearchTimeToResult(timeMs, successful);
  }

  Future<void> logSearchSuccess(String query, int timeMs) async {
    await _postHogService.logSearchSuccess(query, timeMs);
  }

  // Storage and Resources
  Future<void> logStorageUsage(int totalSizeBytes, int screenshotCount) async {
    await _postHogService.logStorageUsage(totalSizeBytes, screenshotCount);
  }

  Future<void> logBackgroundResourceUsage(
    int processingTimeMs,
    int memoryUsageMB,
  ) async {
    await _postHogService.logBackgroundResourceUsage(processingTimeMs, memoryUsageMB);
  }

  // App Health
  Future<void> logBatteryImpact(String level) async {
    await _postHogService.logBatteryImpact(level);
  }

  Future<void> logNetworkUsage(int bytesUsed, String operation) async {
    await _postHogService.logNetworkUsage(bytesUsed, operation);
  }

  Future<void> logBackgroundTaskCompleted(
    String taskName,
    bool successful,
    int durationMs,
  ) async {
    await _postHogService.logBackgroundTaskCompleted(taskName, successful, durationMs);
  }

  // Statistics (Very Important)
  Future<void> logTotalScreenshotsProcessed(int count) async {
    await _postHogService.logTotalScreenshotsProcessed(count);
  }

  Future<void> logTotalCollections(int count) async {
    await _postHogService.logTotalCollections(count);
  }

  Future<void> logScreenshotsInCollection(
    int collectionId,
    int screenshotCount,
  ) async {
    await _postHogService.logScreenshotsInCollection(collectionId, screenshotCount);
  }

  Future<void> logScreenshotsAutoCategorized(int count) async {
    await _postHogService.logScreenshotsAutoCategorized(count);
  }

  Future<void> logReminderSet() async {
    await _postHogService.logReminderSet();
  }

  Future<void> logInstallInfo() async {
    await _postHogService.logInstallInfo();
  }

  Future<void> logCurrentUsageTime() async {
    await _postHogService.logCurrentUsageTime();
  }

  // Additional PostHog-specific methods (optional to use)
  
  /// Identify a user (useful for authenticated users)
  Future<void> identifyUser(String userId, [Map<String, dynamic>? properties]) async {
    await _postHogService.identifyUser(userId, properties);
  }

  /// Set person properties for better user analytics
  Future<void> setPersonProperties(Map<String, dynamic> properties) async {
    await _postHogService.setPersonProperties(properties);
  }

  /// Reset user session (useful for logout)
  Future<void> reset() async {
    await _postHogService.reset();
  }

  /// Check if a feature flag is enabled
  Future<bool> isFeatureEnabled(String featureKey) async {
    return await _postHogService.isFeatureEnabled(featureKey);
  }

  /// Alias user (link anonymous user to identified user)
  Future<void> alias(String alias) async {
    await _postHogService.alias(alias);
  }

  /// Group analytics (for organization-level analytics)
  Future<void> group(String groupType, String groupKey, [Map<String, dynamic>? properties]) async {
    await _postHogService.group(groupType, groupKey, properties);
  }
}
