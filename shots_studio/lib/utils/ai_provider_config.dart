class AIProviderConfig {
  // Dynamic cache for models discovered from OpenAI-compatible / Ollama servers
  static List<String> _dynamicOpenAIModels = [];

  static void setDynamicOpenAIModels(List<String> models) {
    _dynamicOpenAIModels = List<String>.from(models);
  }

  static List<String> getDynamicOpenAIModels() {
    return _dynamicOpenAIModels;
  }

  // Available models for each provider
  static const Map<String, List<String>> providerModels = {
    'gemini': [
      'gemini-2.0-flash',
      'gemini-2.5-flash-lite',
      'gemini-2.5-flash',
      'gemini-2.5-pro',
    ],
    'gemma': ['gemma'],
    'openai_compatible': [
      'openai-compatible',
    ],
    'ocr': ['tesseract-ocr'],
    'none': ['No AI Model'],
  };

  // Model-specific maxParallel limits
  static const Map<String, int> modelMaxParallelLimits = {
    'gemini-2.0-flash': 16,
    'gemini-2.5-flash': 16,
    'gemini-2.5-flash-lite': 16,
    'gemini-2.5-pro': 32,
    'gemma': 1,
    'openai-compatible': 1,
    'tesseract-ocr': 1,
  };

  // Model-specific max categorization limits (for batch processing text analysis)
  static const Map<String, int> modelMaxCategorizationLimits = {
    'gemini-2.0-flash': 50,
    'gemini-2.5-flash': 50,
    'gemini-2.5-flash-lite': 50,
    'gemini-2.5-pro': 50,
    'gemma': 10,
    'openai-compatible': 30,
    'tesseract-ocr': 0,
  };

  // Model-specific API key requirements
  static const Map<String, bool> modelRequiresApiKey = {
    'gemini-2.0-flash': true,
    'gemini-2.5-flash': true,
    'gemini-2.5-flash-lite': true,
    'gemini-2.5-pro': true,
    'gemma': false,
    'openai-compatible': false,
    'tesseract-ocr': false,
  };

  static bool requiresApiKey(String model) {
    if (modelRequiresApiKey.containsKey(model)) {
      return modelRequiresApiKey[model]!;
    }
    final provider = getProviderForModel(model);
    return provider == 'gemini';
  }

  // Models capable of advanced extraction (dates, events, locations, flights)
  static const Map<String, bool> modelSupportsAdvancedExtraction = {
    'gemini-2.0-flash': false,
    'gemini-2.5-flash': true,
    'gemini-2.5-flash-lite': false,
    'gemini-2.5-pro': true,
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
    'openai_compatible': 'ai_provider_openai_compatible_enabled',
    'ocr': 'ai_provider_ocr_enabled',
  };

  // Get all available providers (excluding 'none')
  static List<String> getProviders() {
    return providerModels.keys.where((key) => key != 'none').toList();
  }

  // Get models for a specific provider
  static List<String> getModelsForProvider(String provider) {
    if (provider == 'openai_compatible') {
      final base = List<String>.from(providerModels['openai_compatible'] ?? []);
      for (final m in _dynamicOpenAIModels) {
        if (!base.contains(m)) base.add(m);
      }
      return base;
    }
    return providerModels[provider] ?? [];
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
    final lower = model.toLowerCase();
    if (_dynamicOpenAIModels.contains(model) ||
        model.contains(':') ||
        lower.contains('openai-compatible') ||
        lower.contains('ollama') ||
        (providerModels['openai_compatible']?.contains(model) ?? false)) {
      return 'openai_compatible';
    }
    if (lower.contains('gemini')) {
      return 'gemini';
    }
    if (lower.contains('ocr') || lower.contains('tesseract')) {
      return 'ocr';
    }
    if (lower == 'no ai model' || lower == 'none') {
      return 'none';
    }
    // All other models (dynamic on-device models, Qwen, Phi, Llama, Falcon, SmolLM, .task, .bin, .gguf, .litertlm, .tflite)
    // belong to the local on-device provider ('gemma')
    return 'gemma';
  }

  // Get the model-specific maxParallel limit
  static int getMaxParallelLimitForModel(String model) {
    if (modelMaxParallelLimits.containsKey(model)) {
      return modelMaxParallelLimits[model]!;
    }
    final provider = getProviderForModel(model);
    if (provider == 'gemma' || provider == 'openai_compatible' || provider == 'ocr') {
      return 1;
    }
    return 4;
  }

  // Get the model-specific max categorization limit
  static int getMaxCategorizationLimitForModel(String model) {
    return modelMaxCategorizationLimits[model] ?? (getProviderForModel(model) == 'gemma' ? 10 : 20);
  }

  // Get the effective maxParallel value (minimum of model limit and global preference)
  static int getEffectiveMaxParallel(String model, int globalMaxParallel) {
    final modelLimit = getMaxParallelLimitForModel(model);
    return modelLimit < globalMaxParallel ? modelLimit : globalMaxParallel;
  }
}
