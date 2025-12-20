// Unified AI Service Manager
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/models/collection_model.dart';
import 'package:shots_studio/services/ai_service.dart';
import 'package:shots_studio/services/screenshot_analysis_service.dart';
import 'package:shots_studio/services/autoCategorization/collection_categorization_service.dart';
import 'package:shots_studio/utils/ai_provider_config.dart';

class AIServiceManager {
  static AIServiceManager? _instance;
  AIServiceManager._internal();

  factory AIServiceManager() {
    return _instance ??= AIServiceManager._internal();
  }

  // Screenshot analysis handles the analysis of screenshots
  ScreenshotAnalysisService? _analysisService;
  // Collection categorization handles the categorization of screenshots into collections
  CollectionCategorizationService? _categorizationService;

  void initialize(AIConfig config) {
    // Calculate effective maxParallel using model-specific limits and global preference
    final effectiveMaxParallel = AIProviderConfig.getEffectiveMaxParallel(
      config.modelName,
      config.maxParallel,
    );

    // Create adjusted config with the effective maxParallel value
    AIConfig adjustedConfig = AIConfig(
      apiKey: config.apiKey,
      modelName: config.modelName,
      maxParallel: effectiveMaxParallel,
      timeoutSeconds: config.timeoutSeconds,
      showMessage: config.showMessage,
      providerSpecificConfig: config.providerSpecificConfig,
    );

    _analysisService = ScreenshotAnalysisService(adjustedConfig);
    _categorizationService = CollectionCategorizationService(adjustedConfig);
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

    // OCR provider does not support categorization
    if (_isOCRProvider()) {
      return AIResult.error(
        'Categorization is not supported with OCR provider. OCR only extracts text from images.',
        statusCode: 400,
      );
    }

    return await _categorizationService!.categorizeScreenshots(
      collection: collection,
      screenshots: screenshots,
      onBatchProcessed: onBatchProcessed,
    );
  }

  // Check if current model is OCR-based
  bool _isOCRProvider() {
    if (_analysisService == null) return false;
    final modelName = _analysisService!.config.modelName.toLowerCase();
    return modelName.contains('ocr') || modelName.contains('tesseract');
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
}
