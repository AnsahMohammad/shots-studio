import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_gemma/flutter_gemma.dart';

import 'package:flutter_gemma/core/api/flutter_gemma.dart' as gemma_api;
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
  String? _currentModelPath;
  int _generationCount = 0;
  int? _lastProcessingTimeMs; // Track last processing time for analytics
  static const int _maxGenerationsBeforeCleanup = 2;

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

  // Load model from file path
  Future<bool> loadModel(String modelFilePath) async {
    if (_gemma == null) {
      await initialize();
    }

    _isLoading = true;

    try {
      // Verify file exists
      final file = File(modelFilePath);
      if (!await file.exists()) {
        throw Exception('Model file does not exist: $modelFilePath');
      }

      // Clean up existing resources before loading new model
      await _cleanupExistingModel();

      // Install the model using the new FileSource API (references file without copying)
      final modelFileName = modelFilePath.split('/').last;
      await gemma_api.FlutterGemma.installModel(
        modelType: ModelType.gemmaIt,
      ).fromFile(modelFilePath).install();

      // Verify the model is properly installed
      final isInstalled = await gemma_api.FlutterGemma.isModelInstalled(
        modelFileName,
      );
      if (!isInstalled) {
        throw Exception('Model not properly installed at path: $modelFilePath');
      }

      // Get CPU/GPU preference from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final useCPU = prefs.getBool('gemma_use_cpu') ?? true; // CPU by default

      // Create inference model with conservative settings to reduce memory usage
      _inferenceModel = await _gemma!.createModel(
        modelType: ModelType.gemmaIt,
        preferredBackend: useCPU ? PreferredBackend.cpu : PreferredBackend.gpu,
        maxTokens: 2048, // Reduced from 4096 to save memory
        supportImage: true, // Enable multimodal support
        maxNumImages: 1,
      );

      _isModelLoaded = true;
      _currentModelPath = modelFilePath;

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
      rethrow;
    } finally {
      _isLoading = false;
    }
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

    // Note: FileSource models don't need deletion as they reference the original file
    // The model can be uninstalled if needed using the new API

    _forceGarbageCollection();
  }

  // Check if model is ready and load from preferences if needed
  Future<bool> ensureModelReady() async {
    if (_isModelLoaded && _inferenceModel != null) {
      return true;
    }

    // Try to load from saved preferences
    return await loadModelFromPreferences();
  }

  // Load model from saved preferences
  Future<bool> loadModelFromPreferences() async {
    try {
      LoggerService.log("\n\n Loading model from preferences...");
      final prefs = await SharedPreferences.getInstance();
      final savedModelPath = prefs.getString(_modelPathPrefKey);
      LoggerService.log("Saved model path: $savedModelPath");

      if (savedModelPath != null && savedModelPath.isNotEmpty) {
        LoggerService.log('Checking if file exists: $savedModelPath');
        final file = File(savedModelPath);
        if (await file.exists()) {
          LoggerService.log('Loading model from saved path: $savedModelPath');
          return await loadModel(savedModelPath);
        } else {
          LoggerService.log('Saved model path does not exist: $savedModelPath');
          // Clean up invalid path
          await _removeModelPath();
          await _saveModelLoadedState(false);
        }
      } else {
        LoggerService.log('No model path found in preferences');
      }
    } catch (e) {
      LoggerService.error('Error loading model from preferences', e);
      await _saveModelLoadedState(false);
    }
    LoggerService.log('No valid model found in preferences.');
    return false;
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
      if (imageFile != null) {
        // Read image bytes for multimodal input - limit image size to prevent memory issues
        final imageBytes = await _readImageWithSizeLimit(imageFile);
        message = Message.withImage(
          text: prompt,
          imageBytes: imageBytes,
          isUser: true,
        );
      } else {
        // Text-only message
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
      if (imageFile != null) {
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
      return _currentModelPath?.split('/').last;
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
  String? get currentModelPath => _currentModelPath;
  int? get lastProcessingTimeMs => _lastProcessingTimeMs;
}
