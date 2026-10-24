class AIProviderConfig {
  static const String defaultGeminiModel = 'gemini-3.5-flash-lite';

  // Available models for each provider
  static const Map<String, List<String>> providerModels = {
    'gemini': [
      'gemini-3.8-flash',
      'gemini-3.6-flash',
      'gemini-3.5-flash-lite',
      'gemini-3.1-flash-lite',
      'gemini-4-argon',
    ],
    'gemma': ['gemma'],
    'ocr': ['tesseract-ocr'],
    'none': ['No AI Model'],
  };

  // Model-specific maxParallel limits
  static const Map<String, int> modelMaxParallelLimits = {
    'gemini-3.5-flash-lite': 16,
    'gemini-3.1-flash-lite': 16,
    'gemini-3.6-flash': 16,
    'gemini-3.8-flash': 16,
    'gemini-4-argon': 32,
    'gemma': 1,
    'tesseract-ocr': 1,
  };

  // Model-specific max categorization limits (for batch processing text analysis)
  static const Map<String, int> modelMaxCategorizationLimits = {
    'gemini-3.5-flash-lite': 50,
    'gemini-3.1-flash-lite': 50,
    'gemini-3.6-flash': 50,
    'gemini-3.8-flash': 50,
    'gemini-4-argon': 50,
    'gemma': 10,
    'tesseract-ocr': 0,
  };

  // Model-specific API key requirements
  static const Map<String, bool> modelRequiresApiKey = {
    'gemini-3.5-flash-lite': true,
    'gemini-3.1-flash-lite': true,
    'gemini-3.6-flash': true,
    'gemini-3.8-flash': true,
    'gemini-4-argon': true,
    'gemma': false,
    'tesseract-ocr': false,
  };

  static bool requiresApiKey(String model) {
    return modelRequiresApiKey[model] ?? false; // Default to false
  }

  // Models capable of advanced extraction (dates, events, locations, flights)
  static const Map<String, bool> modelSupportsAdvancedExtraction = {
    'gemini-3.5-flash-lite': true,
    'gemini-3.1-flash-lite': true,
    'gemini-3.6-flash': true,
    'gemini-3.8-flash': true,
    'gemini-4-argon': true,
    'gemma': false,
    'tesseract-ocr': false,
  };

  static bool hasAdvancedExtraction(String model) {
    return modelSupportsAdvancedExtraction[model] ?? false;
  }

  // Preference keys for provider settings
  static const Map<String, String> providerPrefKeys = {
    'gemini': 'ai_provider_gemini_enabled',
    'gemma': 'ai_provider_gemma_enabled',
    'ocr': 'ai_provider_ocr_enabled',
  };

  // Get all available providers (excluding 'none')
  static List<String> getProviders() {
    return providerModels.keys.where((key) => key != 'none').toList();
  }

  // Get models for a specific provider
  static List<String> getModelsForProvider(String provider) {
    return providerModels[provider] ?? [];
  }

  static bool isSupportedModel(String model) {
    return providerModels.values.any((models) => models.contains(model));
  }

  // Get preference key for a provider
  static String? getPrefKeyForProvider(String provider) {
    return providerPrefKeys[provider];
  }

  // Check if a model belongs to a specific provider
  static String getProviderForModel(String model) {
    for (final entry in providerModels.entries) {
      if (entry.value.contains(model)) {
        return entry.key;
      }
    }
    return 'unknown';
  }

  // Get the model-specific maxParallel limit
  static int getMaxParallelLimitForModel(String model) {
    return modelMaxParallelLimits[model] ?? 4; // Default to 4 if not found
  }

  // Get the model-specific max categorization limit
  static int getMaxCategorizationLimitForModel(String model) {
    return modelMaxCategorizationLimits[model] ??
        20; // Default to 20 if not found
  }

  // Get the effective maxParallel value (minimum of model limit and global preference)
  static int getEffectiveMaxParallel(String model, int globalMaxParallel) {
    final modelLimit = getMaxParallelLimitForModel(model);
    return modelLimit < globalMaxParallel ? modelLimit : globalMaxParallel;
  }
}
