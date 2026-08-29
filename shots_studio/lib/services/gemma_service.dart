import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_gemma/flutter_gemma.dart';

import 'package:flutter_gemma/core/api/flutter_gemma.dart' as gemma_api;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shots_studio/services/logger_service.dart';

class GemmaService {
  static GemmaService? _instance;
  GemmaService._internal();

  factory GemmaService() {
    return _instance ??= GemmaService._internal();
  }

  static const String _modelPathPrefKey = 'gemma_model_path';
  static const String _isModelLoadedPrefKey = 'gemma_model_loaded';

  FlutterGemmaPlugin? _gemma;

  InferenceModel? _inferenceModel;
  InferenceModelSession? _session;

  bool _isModelLoaded = false;
  bool _isLoading = false;
  bool _isGenerating = false;
  bool _supportsImage = true;
  String? _currentModelPath;
  int _generationCount = 0;
  int? _lastProcessingTimeMs; // Track last processing time for analytics
  static const int _maxGenerationsBeforeCleanup = 2;

  String? _lastLoadError;
  String? get lastLoadError => _lastLoadError;

  // Initialize Gemma plugin (lazy - only when needed)
  static bool _isFlutterGemmaInitialized = false;

  Future<void> initialize() async {
    // Initialize FlutterGemma once (required since version 0.11.10)
    if (!_isFlutterGemmaInitialized) {
      await FlutterGemma.initialize();
      _isFlutterGemmaInitialized = true;
    }
    _gemma = FlutterGemmaPlugin.instance;
  }

  ModelType _getModelType(String path) {
    final lower = path.toLowerCase();
    if (lower.contains('qwen')) {
      return ModelType.qwen;
    } else if (lower.contains('llama')) {
      return ModelType.llama;
    } else if (lower.contains('deepseek')) {
      return ModelType.deepSeek;
    } else if (lower.contains('hammer')) {
      return ModelType.hammer;
    } else if (lower.contains('gemma')) {
      return ModelType.gemmaIt;
    } else {
      return ModelType.general;
    }
  }

  // Load model from file path
  Future<bool> loadModel(String modelFilePath) async {
    if (_gemma == null) {
      await initialize();
    }

    _isLoading = true;
    _lastLoadError = null;

    try {
      // Verify file exists
      final file = File(modelFilePath);
      if (!await file.exists()) {
        throw Exception('Model file does not exist: $modelFilePath');
      }

      // Clean up existing resources before loading new model
      await _cleanupExistingModel();

      final modelType = _getModelType(modelFilePath);

      // Install the model using the FileSource API (references file without copying)
      await gemma_api.FlutterGemma.installModel(
        modelType: modelType,
      ).fromFile(modelFilePath).install();

      // Get CPU/GPU preference from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final useCPU = prefs.getBool('gemma_use_cpu') ?? true;

      _supportsImage = _checkIsMultimodal(modelFilePath);

      LoggerService.log('Creating inference model with ModelType: $modelType, useCPU: $useCPU, supportsImage: $_supportsImage');

      // Load model with multiple fallback tiers for memory safety
      _inferenceModel = await _createInferenceModelWithFallback(
        modelType: modelType,
        useCPU: useCPU,
        supportsImage: _supportsImage,
      );

      _isModelLoaded = true;
      _currentModelPath = modelFilePath;
      _lastLoadError = null;

      // Save the model path and loaded state to preferences
      await _saveModelPath(modelFilePath);
      await _saveModelLoadedState(true);

      // Force garbage collection after model loading
      _forceGarbageCollection();

      return true;
    } catch (e) {
      _isModelLoaded = false;
      _currentModelPath = null;
      await _saveModelLoadedState(false);
      LoggerService.error('Error loading model: $modelFilePath', e);
      if (e.toString().contains('RET_CHECK') || e.toString().contains('building tflite model')) {
        _lastLoadError = 'Incompatible model format: This model file was not compiled for Google MediaPipe/LiteRT. Please use a .task or .bin model compiled for LiteRT, or run via Ollama.';
      } else {
        _lastLoadError = 'Failed to load model: ${e.toString()}';
      }
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<InferenceModel> _createInferenceModelWithFallback({
    required ModelType modelType,
    required bool useCPU,
    required bool supportsImage,
  }) async {
    _forceGarbageCollection();

    // Attempt 1: Requested configuration with 512 tokens for optimal RAM footprint
    try {
      return await _gemma!.createModel(
        modelType: modelType,
        preferredBackend: useCPU ? PreferredBackend.cpu : PreferredBackend.gpu,
        maxTokens: 512,
        supportImage: supportsImage,
        maxNumImages: supportsImage ? 1 : 0,
      );
    } catch (e) {
      LoggerService.log('Tier 1 model creation failed ($e), trying CPU...');
    }

    // Attempt 2: If deepSeek, try Qwen architecture (DeepSeek-R1-Distill-Qwen is based on Qwen)
    if (modelType == ModelType.deepSeek) {
      try {
        return await _gemma!.createModel(
          modelType: ModelType.qwen,
          preferredBackend: PreferredBackend.cpu,
          maxTokens: 512,
          supportImage: false,
          maxNumImages: 0,
        );
      } catch (e) {
        LoggerService.log('Tier 2 Qwen architecture fallback failed ($e)...');
      }
    }

    // Attempt 3: CPU text-only with 512 context tokens
    try {
      return await _gemma!.createModel(
        modelType: modelType,
        preferredBackend: PreferredBackend.cpu,
        maxTokens: 512,
        supportImage: false,
        maxNumImages: 0,
      );
    } catch (e) {
      LoggerService.log('Tier 3 model creation failed ($e), falling back to ModelType.general...');
    }

    // Attempt 4: ModelType.general with 256 tokens (minimal RAM footprint)
    try {
      return await _gemma!.createModel(
        modelType: ModelType.general,
        preferredBackend: PreferredBackend.cpu,
        maxTokens: 256,
        supportImage: false,
        maxNumImages: 0,
      );
    } catch (e) {
      LoggerService.log('Tier 4 model creation failed ($e), falling back to ModelType.gemmaIt...');
    }

    // Attempt 5: ModelType.gemmaIt fallback with 256 tokens
    return await _gemma!.createModel(
      modelType: ModelType.gemmaIt,
      preferredBackend: PreferredBackend.cpu,
      maxTokens: 256,
      supportImage: false,
      maxNumImages: 0,
    );
  }

  Future<void> _cleanupExistingModel() async {
    if (_session != null) {
      try {
        await _session!.close();
      } catch (e) {
        LoggerService.error('Error closing existing session', e);
      }
      _session = null;
    }

    if (_inferenceModel != null) {
      try {
        await _inferenceModel!.close();
      } catch (e) {
        LoggerService.error('Error closing existing model', e);
      }
      _inferenceModel = null;
    }

    _forceGarbageCollection();
  }

  // Check if model is ready and load from preferences if needed
  Future<bool> ensureModelReady({String? preferredModelName}) async {
    if (_isModelLoaded && _inferenceModel != null) {
      return true;
    }

    // Try to load from saved preferences or search installed directory
    return await loadModelFromPreferences(preferredModelName: preferredModelName);
  }

  // Load model from saved preferences
  Future<bool> loadModelFromPreferences({String? preferredModelName}) async {
    try {
      LoggerService.log("\n\n Loading model from preferences...");
      final prefs = await SharedPreferences.getInstance();
      String? savedModelPath = prefs.getString(_modelPathPrefKey);
      LoggerService.log("Saved model path: $savedModelPath");

      String? targetPath;

      // 1. If preferredModelName is provided, search installed directory for a matching file
      if (preferredModelName != null && preferredModelName.isNotEmpty) {
        targetPath = await _findInstalledModelFile(preferredModelName: preferredModelName);
      }

      // 2. If no target path yet, check savedModelPath
      if (targetPath == null || targetPath.isEmpty || !await File(targetPath).exists()) {
        if (savedModelPath != null && savedModelPath.isNotEmpty && await File(savedModelPath).exists()) {
          targetPath = savedModelPath;
        }
      }

      // 3. If still no target path, pick any available installed model file
      if (targetPath == null || targetPath.isEmpty || !await File(targetPath).exists()) {
        targetPath = await _findInstalledModelFile();
      }

      if (targetPath != null && targetPath.isNotEmpty) {
        final file = File(targetPath);
        if (await file.exists()) {
          LoggerService.log('Loading model from path: $targetPath');
          await _saveModelPath(targetPath);
          return await loadModel(targetPath);
        } else {
          LoggerService.log('Model path does not exist: $targetPath');
          await _removeModelPath();
          await _saveModelLoadedState(false);
        }
      } else {
        LoggerService.log('No model path found in preferences or storage');
      }
    } catch (e) {
      LoggerService.error('Error loading model from preferences', e);
      await _saveModelLoadedState(false);
    }
    LoggerService.log('No valid model found in storage.');
    return false;
  }

  Future<String?> _findInstalledModelFile({String? preferredModelName}) async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final modelsDir = Directory('${appDocDir.path}/gemma_models');
      if (!await modelsDir.exists()) return null;

      final entities = await modelsDir.list().toList();
      final files = entities
          .where((entity) =>
              entity is File &&
              (entity.path.endsWith('.task') ||
                  entity.path.endsWith('.bin') ||
                  entity.path.endsWith('.gguf') ||
                  entity.path.endsWith('.litertlm') ||
                  entity.path.endsWith('.tflite')))
          .cast<File>()
          .toList();

      if (files.isEmpty) return null;

      if (preferredModelName != null && preferredModelName.isNotEmpty) {
        final cleanPref = preferredModelName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        for (final f in files) {
          final cleanFileName = f.path.split(RegExp(r'[\\/]')).last.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
          if (cleanFileName.contains(cleanPref) || cleanPref.contains(cleanFileName)) {
            return f.path;
          }
        }
      }

      return files.first.path;
    } catch (e) {
      LoggerService.error('Error finding installed model files', e);
      return null;
    }
  }

  // Generate response with optional image
  Future<String> generateResponse({
    required String prompt,
    File? imageFile,
    double temperature = 0.8,
    int randomSeed = 1,
    int topK = 1,
  }) async {
    if (!_isModelLoaded || _inferenceModel == null) {
      throw StateError('Model not loaded. Call loadModel() first.');
    }

    _isGenerating = true;
    InferenceModelSession? localSession;
    final stopwatch = Stopwatch()..start();

    try {
      // Create a new session for this inference
      localSession = await _inferenceModel!.createSession(
        temperature: temperature,
        randomSeed: randomSeed,
        topK: topK,
      );

      Message message;
      if (imageFile != null && _supportsImage) {
        // Read image bytes for multimodal input - limit image size to prevent memory issues
        final imageBytes = await _readImageWithSizeLimit(imageFile);
        message = Message.withImage(
          text: prompt,
          imageBytes: imageBytes,
          isUser: true,
        );
      } else {
        // Text-only message for text-only models (Qwen, Phi, Llama, Falcon, SmolLM, Gemma 2) or text prompts
        message = Message.text(text: prompt, isUser: true);
      }

      await localSession.addQueryChunk(message);

      // Get response (blocking call)
      final response = await localSession.getResponse();

      // Increment generation counter and check if cleanup is needed
      _generationCount++;

      return response;
    } catch (e) {
      LoggerService.error('Error during generation', e);
      rethrow;
    } finally {
      stopwatch.stop();
      final processingTimeMs = stopwatch.elapsedMilliseconds;

      // Always clean up session in finally block
      if (localSession != null) {
        try {
          await localSession.close();
        } catch (e) {
          LoggerService.error('Error closing session', e);
        }
      }
      _session = null;
      _isGenerating = false;

      // Store the last processing time for analytics
      _lastProcessingTimeMs = processingTimeMs;

      // Perform memory cleanup if we've hit the generation limit
      if (_generationCount >= _maxGenerationsBeforeCleanup) {
        LoggerService.log(
          'Performing automatic memory cleanup after $_generationCount generations',
        );
        await performMemoryCleanup();
        _generationCount = 0;
      } else {
        // Force garbage collection after each generation to free memory
        _forceGarbageCollection();
      }
    }
  }

  // Generate streaming response
  Future<Stream<String>> generateResponseStream({
    required String prompt,
    File? imageFile,
    double temperature = 0.8,
    int randomSeed = 1,
    int topK = 1,
  }) async {
    if (!_isModelLoaded || _inferenceModel == null) {
      throw StateError('Model not loaded. Call loadModel() first.');
    }

    _isGenerating = true;
    InferenceModelSession? localSession;

    try {
      // Create a new session for streaming
      localSession = await _inferenceModel!.createSession(
        temperature: temperature,
        randomSeed: randomSeed,
        topK: topK,
      );

      Message message;
      if (imageFile != null && _supportsImage) {
        final imageBytes = await _readImageWithSizeLimit(imageFile);
        message = Message.withImage(
          text: prompt,
          imageBytes: imageBytes,
          isUser: true,
        );
      } else {
        message = Message.text(text: prompt, isUser: true);
      }

      await localSession.addQueryChunk(message);

      // Store session reference for cleanup
      _session = localSession;

      // Return the streaming response with cleanup handling
      return localSession.getResponseAsync().transform(
        StreamTransformer<String, String>.fromHandlers(
          handleDone: (sink) {
            // Clean up when stream is done
            _cleanupAfterStreaming();
            sink.close();
          },
          handleError: (error, stackTrace, sink) {
            // Clean up on error
            _cleanupAfterStreaming();
            sink.addError(error, stackTrace);
          },
          handleData: (data, sink) {
            sink.add(data);
          },
        ),
      );
    } catch (e) {
      _isGenerating = false;
      if (localSession != null) {
        try {
          await localSession.close();
        } catch (e) {
          LoggerService.error('Error closing session', e);
        }
      }
      rethrow;
    }
  }

  // Save model path to preferences
  Future<void> _saveModelPath(String modelPath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_modelPathPrefKey, modelPath);
    } catch (e) {
      LoggerService.error('Error saving model path', e);
    }
  }

  // Save model loaded state
  Future<void> _saveModelLoadedState(bool isLoaded) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isModelLoadedPrefKey, isLoaded);
    } catch (e) {
      LoggerService.error('Error saving model loaded state', e);
    }
  }

  // Remove model path from preferences
  Future<void> _removeModelPath() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_modelPathPrefKey);
      await prefs.remove(_isModelLoadedPrefKey);
    } catch (e) {
      LoggerService.error('Error removing model path', e);
    }
  }

  // Check if a model file is available (without loading)
  Future<bool> isModelFileAvailable() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedModelPath = prefs.getString(_modelPathPrefKey);

      if (savedModelPath != null && savedModelPath.isNotEmpty) {
        final file = File(savedModelPath);
        return await file.exists();
      }
    } catch (e) {
      LoggerService.error('Error checking model file availability', e);
    }
    return false;
  }

  // Get saved model path
  Future<String?> getSavedModelPath() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_modelPathPrefKey);
    } catch (e) {
      LoggerService.error('Error getting saved model path', e);
      return null;
    }
  }

  // Get CPU/GPU preference
  Future<bool> getUseCPUPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('gemma_use_cpu') ?? true; // CPU by default
    } catch (e) {
      LoggerService.error('Error getting CPU/GPU preference', e);
      return true; // Default to CPU on error
    }
  }

  // Note: If CPU/GPU preference changes, the model needs to be reloaded
  // to apply the new backend setting. Call loadModel() again after changing
  // the preference in SharedPreferences.

  // Get model name from current path
  String? get modelName {
    if (_currentModelPath != null) {
      final fileName = _currentModelPath!.split(Platform.isWindows ? '\\' : '/').last;
      return fileName
          .replaceAll('.task', '')
          .replaceAll('.bin', '')
          .replaceAll('.gguf', '')
          .replaceAll('_', ' ')
          .replaceAll('-', ' ');
    }
    return null;
  }

  // Check if model is available for use
  bool get isAvailable => _isModelLoaded && _inferenceModel != null;

  // Clear the loaded model and remove from preferences
  Future<void> clearModel() async {
    await _removeModelPath();
    dispose();
  }

  // Helper method to read image with size limit to prevent memory issues
  Future<Uint8List> _readImageWithSizeLimit(File imageFile) async {
    const int maxImageSize = 10 * 1024 * 1024; // 10MB limit

    final fileSize = await imageFile.length();
    if (fileSize > maxImageSize) {
      throw Exception(
        'Image file too large ($fileSize bytes). Maximum allowed: $maxImageSize bytes',
      );
    }

    return await imageFile.readAsBytes();
  }

  // Helper method to force garbage collection
  void _forceGarbageCollection() {
    // Force garbage collection to free up memory
    // This is a hint to the Dart VM, not a guarantee
    try {
      // Trigger garbage collection by creating and discarding objects
      for (int i = 0; i < 100; i++) {
        List.generate(1000, (index) => index);
      }
    } catch (e) {
      // Ignore any errors from forcing GC
    }
  }

  // Helper method to clean up after streaming
  void _cleanupAfterStreaming() {
    if (_session != null) {
      try {
        _session!.close();
      } catch (e) {
        LoggerService.error('Error closing session during cleanup', e);
      }
      _session = null;
    }
    _isGenerating = false;

    // Increment generation counter for streaming too
    _generationCount++;

    // Perform memory cleanup if needed
    if (_generationCount >= _maxGenerationsBeforeCleanup) {
      LoggerService.log(
        'Performing automatic memory cleanup after $_generationCount generations (streaming)',
      );
      performMemoryCleanup(); // Don't await here as this is called from transform
      _generationCount = 0;
    } else {
      _forceGarbageCollection();
    }
  }

  // Method to preemptively clean up memory when needed
  Future<void> performMemoryCleanup() async {
    LoggerService.log('Performing memory cleanup...');

    // Close any active sessions
    if (_session != null) {
      try {
        await _session!.close();
        _session = null;
      } catch (e) {
        LoggerService.error('Error closing session during memory cleanup', e);
      }
    }

    // Force multiple garbage collection cycles
    for (int i = 0; i < 3; i++) {
      _forceGarbageCollection();
      await Future.delayed(const Duration(milliseconds: 100));
    }

    LoggerService.log('Memory cleanup completed');
  }

  // Method to check if memory cleanup is needed (call this between generations)
  bool shouldPerformMemoryCleanup() {
    // You can implement more sophisticated memory pressure detection here
    // For now, just check if we have any active sessions that should be cleaned
    return _session != null && !_isGenerating;
  }

  // Dispose all resources
  void dispose() {
    // Clean up session first
    if (_session != null) {
      try {
        _session!.close();
      } catch (e) {
        LoggerService.error('Error closing session during dispose', e);
      }
      _session = null;
    }

    // Clean up inference model
    if (_inferenceModel != null) {
      try {
        _inferenceModel!.close();
      } catch (e) {
        LoggerService.error('Error closing inference model during dispose', e);
      }
      _inferenceModel = null;
    }

    // Reset other properties
    _gemma = null;

    _isModelLoaded = false;
    _isLoading = false;
    _isGenerating = false;
    _currentModelPath = null;
    _generationCount = 0;
    _lastProcessingTimeMs = null; // Reset processing time

    // Force garbage collection after disposal
    _forceGarbageCollection();
  }

  // Status getters
  bool get isModelLoaded => _isModelLoaded;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  bool get supportsImage => _supportsImage;
  String? get currentModelPath => _currentModelPath;
  int? get lastProcessingTimeMs => _lastProcessingTimeMs;

  bool _checkIsMultimodal(String path) {
    final lower = path.toLowerCase();
    // Gemma 3N and explicit vision models support images
    return (lower.contains('gemma') && (lower.contains('3n') || lower.contains('vision'))) ||
        lower.contains('minicpm-v') ||
        lower.contains('llava') ||
        lower.contains('qwen2.5-vl') ||
        lower.contains('vl');
  }
}


