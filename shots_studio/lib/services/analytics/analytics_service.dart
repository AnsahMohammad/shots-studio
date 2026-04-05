// This is a compatibility wrapper that maintains the same interface as the Firebase AnalyticsService
// but uses provider underneath. This allows for a seamless migration without changing existing code.

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  // Initialize analytics
  Future<void> initialize() async {
    // Analytics is disabled, no-op
  }

  bool get analyticsEnabled => false;

  // Enable analytics and telemetry
  Future<void> enableAnalytics() async {
    // No-op
  }

  // Disable analytics and telemetry
  Future<void> disableAnalytics() async {
    // No-op
  }

  // Screenshot Processing Analytics
  Future<void> logBatchProcessingTime(
    int processingTimeMs,
    int screenshotCount,
  ) async {
    // No-op
  }

  Future<void> logAIProcessingSuccess(int screenshotCount) async {
    // No-op
  }

  Future<void> logAIProcessingFailure(String error, int screenshotCount) async {
    // No-op
  }

  // Collection Management
  Future<void> logCollectionCreated() async {
    // No-op
  }

  Future<void> logCollectionDeleted() async {
    // No-op
  }

  Future<void> logCollectionStats(
    int totalCollections,
    int avgScreenshots,
    int minScreenshots,
    int maxScreenshots,
  ) async {
    // No-op
  }

  // User Interaction
  Future<void> logScreenView(String screenName) async {
    // No-op
  }

  Future<void> logFeatureUsed(String featureName) async {
    // No-op
  }

  Future<void> logUserPath(String fromScreen, String toScreen) async {
    // No-op
  }

  // Performance Metrics
  Future<void> logAppStartup() async {
    // No-op
  }

  Future<void> logImageLoadTime(int loadTimeMs, String imageSource) async {
    // No-op
  }

  // Error Tracking
  Future<void> logNetworkError(String error, String context) async {
    // No-op
  }

  // User Engagement
  Future<void> logActiveDay() async {
    // No-op
  }

  Future<void> logFeatureAdopted(String featureName) async {
    // No-op
  }

  Future<void> logReturnUser(int daysSinceLastOpen) async {
    // No-op
  }

  Future<void> logUsageTime(String timeOfDay) async {
    // No-op
  }

  // Search and Discovery
  Future<void> logSearchQuery(String query, int resultsCount) async {
    // No-op
  }

  Future<void> logSearchTimeToResult(int timeMs, bool successful) async {
    // No-op
  }

  Future<void> logSearchSuccess(String query, int timeMs) async {
    // No-op
  }

  // Storage and Resources
  Future<void> logStorageUsage(int totalSizeBytes, int screenshotCount) async {
    // No-op
  }

  Future<void> logBackgroundResourceUsage(
    int processingTimeMs,
    int memoryUsageMB,
  ) async {
    // No-op
  }

  // App Health
  Future<void> logBatteryImpact(String level) async {
    // No-op
  }

  Future<void> logNetworkUsage(int bytesUsed, String operation) async {
    // No-op
  }

  Future<void> logBackgroundTaskCompleted(
    String taskName,
    bool successful,
    int durationMs,
  ) async {
    // No-op
  }

  // Statistics (Very Important)
  Future<void> logTotalScreenshotsProcessed(int count) async {
    // No-op
  }

  Future<void> logTotalCollections(int count) async {
    // No-op
  }

  Future<void> logScreenshotsInCollection(
    int collectionId,
    int screenshotCount,
  ) async {
    // No-op
  }

  Future<void> logScreenshotsAutoCategorized(int count) async {
    // No-op
  }

  Future<void> logReminderSet() async {
    // No-op
  }

  Future<void> logInstallInfo() async {
    // No-op
  }

  Future<void> logInstallSource(String source) async {
    // No-op
  }

  Future<void> logCurrentUsageTime() async {
    // No-op
  }

  // Gemma-specific AI processing analytics
  Future<void> logGemmaProcessingTime({
    required int processingTimeMs,
    required int screenshotCount,
    required int maxParallelAI,
    required String modelName,
    required String devicePlatform,
    required String? deviceModel,
    required bool useCPU,
  }) async {
    // No-op
  }

  // Additional PostHog-specific methods (optional to use)

  /// Set person properties for better user analytics
  Future<void> setPersonProperties(Map<String, dynamic> properties) async {
    // No-op
  }

  /// Reset user session (useful for logout)
  Future<void> reset() async {
    // No-op
  }

  /// Get device information for analytics
  Future<Map<String, String>> getDeviceInfo() async {
    return {};
  }
}
