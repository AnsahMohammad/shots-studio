import 'dart:io';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/core/model.dart';
import 'package:flutter_gemma/pigeon.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GemmaService {
  static GemmaService? _instance;
  GemmaService._internal();

  factory GemmaService() {
    return _instance ??= GemmaService._internal();
  }

  static const String _modelPathPrefKey = 'local_model_path';

  FlutterGemmaPlugin? _gemma;
  ModelFileManager? _modelManager;
  InferenceModel? _inferenceModel;
  InferenceModelSession? _session;

  bool _isModelLoaded = false;
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _currentModelPath;

  // Initialize Gemma
  void initialize() {
    _gemma = FlutterGemmaPlugin.instance;
    _modelManager = _gemma!.modelManager;
  }

  // Load model from file path
  Future<bool> loadModel(String modelFilePath) async {
    if (_gemma == null) {
      initialize();
    }

    _isLoading = true;

    try {
      // Close existing model if any
      if (_inferenceModel != null) {
        await _inferenceModel!.close();
        _inferenceModel = null;
      }

      // Delete any existing model
      await _modelManager!.deleteModel();

      // Set the model path
      await _modelManager!.setModelPath(modelFilePath);

      // Verify installation
      final isInstalled = await _modelManager!.isModelInstalled;
      if (!isInstalled) {
        throw Exception('Model not properly installed');
      }

      // Create inference model with multimodal support
      _inferenceModel = await _gemma!.createModel(
        modelType: ModelType.gemmaIt,
        // preferredBackend: PreferredBackend.gpu,
        maxTokens: 4096,
        supportImage: true,
        maxNumImages: 1,
      );

      _isModelLoaded = true;
      _currentModelPath = modelFilePath;

      // Save the model path to preferences
      await _saveModelPath(modelFilePath);

      return true;
    } catch (e) {
      _isModelLoaded = false;
      _currentModelPath = null;
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  // Load model from saved preferences
  Future<bool> loadModelFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedModelPath = prefs.getString(_modelPathPrefKey);

      if (savedModelPath != null && savedModelPath.isNotEmpty) {
        final file = File(savedModelPath);
        if (await file.exists()) {
          return await loadModel(savedModelPath);
        } else {
          // Clean up invalid path
          await _removeModelPath();
        }
      }
    } catch (e) {
      print('Error loading model from preferences: $e');
    }
    return false;
  }

  // Ensure model is ready (load from preferences if needed)
  Future<bool> ensureModelReady() async {
    if (_isModelLoaded) {
      return true;
    }

    return await loadModelFromPreferences();
  }

  // Save model path to preferences
  Future<void> _saveModelPath(String modelPath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_modelPathPrefKey, modelPath);
    } catch (e) {
      print('Error saving model path: $e');
    }
  }

  // Remove model path from preferences
  Future<void> _removeModelPath() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_modelPathPrefKey);
    } catch (e) {
      print('Error removing model path: $e');
    }
  }

  // Get saved model path
  Future<String?> getSavedModelPath() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_modelPathPrefKey);
    } catch (e) {
      print('Error getting saved model path: $e');
      return null;
    }
  }

  // Get model name from path
  String? get modelName {
    if (_currentModelPath != null) {
      return _currentModelPath!.split('/').last;
    }
    return null;
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

    try {
      // Create a new session
      _session = await _inferenceModel!.createSession(
        temperature: temperature,
        randomSeed: randomSeed,
        topK: topK,
      );

      Message message;
      if (imageFile != null) {
        // Read image bytes
        final imageBytes = await imageFile.readAsBytes();

        // Create multimodal message with image and text
        message = Message.withImage(
          text: prompt,
          imageBytes: imageBytes,
          isUser: true,
        );
      } else {
        // Create text-only message
        message = Message.text(text: prompt, isUser: true);
      }

      await _session!.addQueryChunk(message);

      // Get direct response (non-streaming)
      final response = await _session!.getResponse();

      await _session!.close();
      _session = null;

      return response;
    } catch (e) {
      rethrow;
    } finally {
      _isGenerating = false;
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

    try {
      // Create a new session
      _session = await _inferenceModel!.createSession(
        temperature: temperature,
        randomSeed: randomSeed,
        topK: topK,
      );

      Message message;
      if (imageFile != null) {
        // Read image bytes
        final imageBytes = await imageFile.readAsBytes();

        // Create multimodal message with image and text
        message = Message.withImage(
          text: prompt,
          imageBytes: imageBytes,
          isUser: true,
        );
      } else {
        // Create text-only message
        message = Message.text(text: prompt, isUser: true);
      }

      await _session!.addQueryChunk(message);

      // Return the streaming response
      return _session!.getResponseAsync();
    } catch (e) {
      _isGenerating = false;
      rethrow;
    }
  }

  // Dispose all resources
  void dispose() {
    _inferenceModel?.close();
    _session?.close();
    _inferenceModel = null;
    _session = null;
    _gemma = null;
    _modelManager = null;
    _isModelLoaded = false;
    _isLoading = false;
    _isGenerating = false;
    _currentModelPath = null;
  }

  // Clear the loaded model and remove from preferences
  Future<void> clearModel() async {
    await _removeModelPath();
    dispose();
  }

  // Status getters
  bool get isModelLoaded => _isModelLoaded;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
}
