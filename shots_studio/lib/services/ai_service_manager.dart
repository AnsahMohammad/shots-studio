// Unified AI Service Manager
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/models/collection_model.dart';
import 'package:shots_studio/services/ai_service.dart';
import 'package:shots_studio/services/ai_screenshot_analysis_service.dart';
import 'package:shots_studio/services/ai_collection_categorization_service.dart';

class AIServiceManager {
  static AIServiceManager? _instance;
  AIServiceManager._internal();

  factory AIServiceManager() {
    return _instance ??= AIServiceManager._internal();
  }

  ScreenshotAnalysisService? _analysisService;
  CollectionCategorizationService? _categorizationService;

  // Create services with configuration
  void initialize(AIConfig config) {
    _analysisService = ScreenshotAnalysisService(config);
    _categorizationService = CollectionCategorizationService(config);
  }

  // Screenshot Analysis Methods
  Future<AIResult<Map<String, dynamic>>> analyzeScreenshots({
    required List<Screenshot> screenshots,
    required BatchProcessedCallback onBatchProcessed,
    List<Map<String, String?>>? autoAddCollections,
  }) async {
    if (_analysisService == null) {
      throw StateError('AI Service not initialized. Call initialize() first.');
    }

    return await _analysisService!.analyzeScreenshots(
      screenshots: screenshots,
      onBatchProcessed: onBatchProcessed,
      autoAddCollections: autoAddCollections,
    );
  }

  List<Screenshot> parseAndUpdateScreenshots(
    List<Screenshot> screenshots,
    Map<String, dynamic> response,
  ) {
    if (_analysisService == null) {
      throw StateError('AI Service not initialized. Call initialize() first.');
    }

    return _analysisService!.parseAndUpdateScreenshots(screenshots, response);
  }

  // Collection Categorization Methods
  Future<AIResult<List<String>>> categorizeScreenshots({
    required Collection collection,
    required List<Screenshot> screenshots,
    required BatchProcessedCallback onBatchProcessed,
  }) async {
    if (_categorizationService == null) {
      throw StateError('AI Service not initialized. Call initialize() first.');
    }

    return await _categorizationService!.categorizeScreenshots(
      collection: collection,
      screenshots: screenshots,
      onBatchProcessed: onBatchProcessed,
    );
  }

  // Control Methods
  void cancelAllOperations() {
    _analysisService?.cancel();
    _categorizationService?.cancel();
  }

  void resetAllServices() {
    _analysisService?.reset();
    _categorizationService?.reset();
  }

  bool get isAnalysisInProgress => _analysisService?.isCancelled == false;
  bool get isCategorizationInProgress =>
      _categorizationService?.isCancelled == false;

  // Dispose services
  void dispose() {
    _analysisService = null;
    _categorizationService = null;
  }

  // Helper method to create AI config from preferences
  static AIConfig createConfigFromPreferences({
    required String apiKey,
    required String modelName,
    int maxParallel = 4,
    int timeoutSeconds = 120,
    ShowMessageCallback? showMessage,
  }) {
    return AIConfig(
      apiKey: apiKey,
      modelName: modelName,
      maxParallel: maxParallel,
      timeoutSeconds: timeoutSeconds,
      showMessage: showMessage,
    );
  }
}
