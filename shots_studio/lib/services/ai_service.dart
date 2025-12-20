// AI Service Interface and Base Classes
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/services/gemma_service.dart';
import 'package:shots_studio/services/ocr_service.dart';

typedef ShowMessageCallback =
    void Function({
      required String message,
      Color? backgroundColor,
      Duration? duration,
    });

typedef BatchProcessedCallback =
    void Function(List<Screenshot> batch, Map<String, dynamic> result);

// AI metadata for tracking processing information
class AiMetaData {
  String modelName;
  DateTime processingTime;

  AiMetaData({required this.modelName, required this.processingTime});

  // Method to convert AiMetaData instance to a Map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'modelName': modelName,
      'processingTime': processingTime.toIso8601String(),
    };
  }

  // Factory constructor to create an AiMetaData instance from a Map (JSON)
  factory AiMetaData.fromJson(Map<String, dynamic> json) {
    return AiMetaData(
      modelName: json['modelName'] as String,
      processingTime: DateTime.parse(json['processingTime'] as String),
    );
  }
}

// Base configuration for AI operations
class AIConfig {
  final String apiKey;
  final String modelName;
  final int maxParallel;
  final int timeoutSeconds;
  final ShowMessageCallback? showMessage;
  final Map<String, dynamic> providerSpecificConfig;

  const AIConfig({
    required this.apiKey,
    required this.modelName,
    this.maxParallel = 4,
    this.timeoutSeconds = 120,
    this.showMessage,
    this.providerSpecificConfig = const {},
  });
}

// Progress tracking for AI operations
class AIProgress {
  final int processedCount;
  final int totalCount;
  final bool isProcessing;
  final bool isCancelled;
  final String? currentOperation;

  const AIProgress({
    required this.processedCount,
    required this.totalCount,
    required this.isProcessing,
    this.isCancelled = false,
    this.currentOperation,
  });

  double get progress => totalCount > 0 ? processedCount / totalCount : 0.0;

  AIProgress copyWith({
    int? processedCount,
    int? totalCount,
    bool? isProcessing,
    bool? isCancelled,
    String? currentOperation,
  }) {
    return AIProgress(
      processedCount: processedCount ?? this.processedCount,
      totalCount: totalCount ?? this.totalCount,
      isProcessing: isProcessing ?? this.isProcessing,
      isCancelled: isCancelled ?? this.isCancelled,
      currentOperation: currentOperation ?? this.currentOperation,
    );
  }
}

// Results for AI operations
class AIResult<T> {
  final bool success;
  final T? data;
  final String? error;
  final int statusCode;
  final bool cancelled;
  final Map<String, dynamic> metadata;

  const AIResult({
    required this.success,
    this.data,
    this.error,
    this.statusCode = 200,
    this.cancelled = false,
    this.metadata = const {},
  });

  factory AIResult.success(T data, {Map<String, dynamic>? metadata}) {
    return AIResult(success: true, data: data, metadata: metadata ?? {});
  }

  factory AIResult.error(String error, {int statusCode = 500}) {
    return AIResult(success: false, error: error, statusCode: statusCode);
  }

  factory AIResult.cancelled() {
    return const AIResult(success: false, cancelled: true, statusCode: 499);
  }
}

// Abstract API provider interface for different AI models
abstract class APIProvider {
  Future<Map<String, dynamic>> makeRequest(
    Map<String, dynamic> requestData,
    AIConfig config,
  );

  bool canHandleModel(String modelName);

  // Prepare request data in the format specific to this provider
  Map<String, dynamic> prepareScreenshotAnalysisRequest({
    required String prompt,
    required List<Map<String, dynamic>> imageData,
    Map<String, dynamic> additionalParams = const {},
  });

  Map<String, dynamic> prepareCategorizationRequest({
    required String prompt,
    required List<Map<String, String>> screenshotMetadata,
    Map<String, dynamic> additionalParams = const {},
  });
} // Gemini API provider implementation

class GeminiAPIProvider implements APIProvider {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  @override
  bool canHandleModel(String modelName) {
    return modelName.toLowerCase().contains('gemini');
  }

  @override
  Future<Map<String, dynamic>> makeRequest(
    Map<String, dynamic> requestData,
    AIConfig config,
  ) async {
    // Check if this is an empty request (all images already processed)
    if (requestData.containsKey('contents')) {
      final contents = requestData['contents'] as List;
      if (contents.length == 1 &&
          contents[0]['parts'] != null &&
          (contents[0]['parts'] as List).length == 1 &&
          (contents[0]['parts'][0]['text'] as String).contains(
            'No images to process',
          )) {
        return {
          'data': '[]', // Empty results
          'statusCode': 200,
          'skipped': true,
        };
      }
    }

    final url = Uri.parse(
      '$_baseUrl/${config.modelName}:generateContent?key=${config.apiKey}',
    );

    final requestBody = jsonEncode(requestData);
    final headers = {'Content-Type': 'application/json'};

    try {
      final response = await http
          .post(url, headers: headers, body: requestBody)
          .timeout(Duration(seconds: config.timeoutSeconds));

      final responseJson = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final candidates = responseJson['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'] as Map?;
          if (content != null) {
            final parts = content['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              final text = parts[0]['text'] as String?;
              if (text != null) {
                return {'data': text, 'statusCode': response.statusCode};
              }
            }
          }
        }
        return {
          'error': 'No response text from AI',
          'statusCode': response.statusCode,
          'rawResponse': response.body,
        };
      } else {
        return {
          'error': responseJson['error']?['message'] ?? 'API Error',
          'statusCode': response.statusCode,
          'rawResponse': response.body,
        };
      }
    } on SocketException catch (e) {
      return {'error': 'Network error: ${e.message}', 'statusCode': 503};
    } on TimeoutException catch (_) {
      return {'error': 'Request timed out', 'statusCode': 408};
    } catch (e) {
      return {'error': 'Unexpected error: ${e.toString()}', 'statusCode': 500};
    }
  }

  @override
  Map<String, dynamic> prepareScreenshotAnalysisRequest({
    required String prompt,
    required List<Map<String, dynamic>> imageData,
    Map<String, dynamic> additionalParams = const {},
  }) {
    // If no images need processing, return empty request
    if (imageData.isEmpty) {
      return {
        'contents': [
          {
            'parts': [
              {'text': 'No images to process - all are already processed.'},
            ],
          },
        ],
      };
    }

    List<Map<String, dynamic>> contentParts = [
      {'text': prompt},
    ];

    // Add all image data to content parts
    for (var imageItem in imageData) {
      if (imageItem['identifier'] != null) {
        contentParts.add({
          'text': '\nAnalyzing image: ${imageItem['identifier']}',
        });
      }
      if (imageItem['data'] != null) {
        contentParts.add({'inline_data': imageItem['data']});
      }
    }

    return {
      'contents': [
        {'parts': contentParts},
      ],
      ...additionalParams,
    };
  }

  @override
  Map<String, dynamic> prepareCategorizationRequest({
    required String prompt,
    required List<Map<String, String>> screenshotMetadata,
    Map<String, dynamic> additionalParams = const {},
  }) {
    List<Map<String, dynamic>> contentParts = [
      {'text': prompt},
    ];

    if (screenshotMetadata.isEmpty) {
      contentParts.add({'text': '\nNo eligible screenshots to analyze.'});
    } else {
      contentParts.add({
        'text':
            '\nScreenshots to analyze (${screenshotMetadata.length} total):',
      });

      for (var metadata in screenshotMetadata) {
        String screenshotInfo = '''
          ID: ${metadata['id'] ?? 'Unknown'}
          Title: ${metadata['title'] ?? 'No title'}
          Description: ${metadata['description'] ?? 'No description'}
          Tags: ${metadata['tags'] ?? 'No tags'}
          ''';
        contentParts.add({'text': screenshotInfo});
      }
    }

    return {
      'contents': [
        {'parts': contentParts},
      ],
      ...additionalParams,
    };
  }
}

// Gemma Local API provider implementation
class GemmaAPIProvider implements APIProvider {
  final GemmaService _gemmaService = GemmaService();

  @override
  bool canHandleModel(String modelName) {
    return modelName.toLowerCase().contains('gemma');
  }

  @override
  Future<Map<String, dynamic>> makeRequest(
    Map<String, dynamic> requestData,
    AIConfig config,
  ) async {
    File? tempFile;

    try {
      // Ensure Gemma model is ready
      final isReady = await _gemmaService.ensureModelReady();
      if (!isReady) {
        return {
          'error':
              'Gemma model not loaded. Please select a model file in AI Settings.',
          'statusCode': 400,
        };
      }

      // Extract prompt and image data from request
      final String prompt = _extractPromptFromRequest(requestData);
      tempFile = await _extractImageFromRequest(requestData);

      // print("requestData: $requestData");
      // print("Extracted prompt: $prompt");

      // Generate response using Gemma service
      final response = await _gemmaService.generateResponse(
        prompt: prompt,
        imageFile: tempFile,
        temperature: 0.8,
        randomSeed: 1,
        topK: 1,
      );

      if (_gemmaService.shouldPerformMemoryCleanup()) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _gemmaService.performMemoryCleanup();
        });
      }

      // print("Gemma response: $response");

      // Add processing time and model info to response for analytics
      final result = {
        'data': response,
        'statusCode': 200,
        'gemma_processing_time_ms': _gemmaService.lastProcessingTimeMs,
        'gemma_model_name': _gemmaService.modelName,
        'gemma_use_cpu': await _gemmaService.getUseCPUPreference(),
      };

      return result;
    } catch (e) {
      return {
        'error': 'Gemma processing error: ${e.toString()}',
        'statusCode': 500,
      };
    } finally {
      // Clean up temporary file if created
      if (tempFile != null) {
        try {
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        } catch (e) {
          print('Warning: Could not delete temporary file: $e');
        }
      }
    }
  }

  @override
  Map<String, dynamic> prepareScreenshotAnalysisRequest({
    required String prompt,
    required List<Map<String, dynamic>> imageData,
    Map<String, dynamic> additionalParams = const {},
  }) {
    // For Gemma, we only process one image at a time
    // Take the first image if multiple are provided
    Map<String, dynamic>? firstImageData;
    if (imageData.isNotEmpty) {
      firstImageData = imageData.first;
    }

    return {
      'prompt': prompt,
      'imageData': firstImageData,
      'type': 'screenshot_analysis',
      ...additionalParams,
    };
  }

  @override
  Map<String, dynamic> prepareCategorizationRequest({
    required String prompt,
    required List<Map<String, String>> screenshotMetadata,
    Map<String, dynamic> additionalParams = const {},
  }) {
    // For categorization, we don't need images, just text
    String metadataText = '';

    if (screenshotMetadata.isEmpty) {
      metadataText = 'No eligible screenshots to analyze.';
    } else {
      metadataText =
          'Screenshots to analyze (${screenshotMetadata.length} total):\n';

      for (var metadata in screenshotMetadata) {
        metadataText += '''
        ID: ${metadata['id'] ?? 'Unknown'}
        Title: ${metadata['title'] ?? 'No title'}
        Description: ${metadata['description'] ?? 'No description'}
        Tags: ${metadata['tags'] ?? 'No tags'}
        
        ''';
      }
    }

    return {
      'prompt': '$prompt\n\n$metadataText',
      'imageData': null, // No image for categorization
      'type': 'categorization',
      ...additionalParams,
    };
  }

  // Extract prompt text from the request data
  String _extractPromptFromRequest(Map<String, dynamic> requestData) {
    if (requestData.containsKey('prompt')) {
      // we need to add imageData.identifier to make sure the model knows the image identifier to reference in the output
      // to do that, append the identifier to the prompt
      if (requestData.containsKey('imageData') &&
          requestData['imageData'] != null &&
          requestData['imageData'] is Map<String, dynamic> &&
          requestData['imageData'].containsKey('identifier')) {
        final identifier =
            requestData['imageData']['identifier'] as String? ?? '';
        return '${requestData['prompt']} (Image ID: $identifier)';
      }

      return requestData['prompt'] as String;
    }

    // Fallback: extract from contents structure (Gemini format)
    if (requestData.containsKey('contents')) {
      final contents = requestData['contents'] as List;
      for (var content in contents) {
        if (content is Map && content.containsKey('parts')) {
          final parts = content['parts'] as List;
          for (var part in parts) {
            if (part is Map && part.containsKey('text')) {
              return part['text'] as String;
            }
          }
        }
      }
    }

    return 'Analyze this image and provide title, description, and tags.';
  }

  // Extract image file from request data
  Future<File?> _extractImageFromRequest(
    Map<String, dynamic> requestData,
  ) async {
    try {
      // Check if imageData is provided directly
      if (requestData.containsKey('imageData') &&
          requestData['imageData'] != null) {
        final imageData = requestData['imageData'] as Map<String, dynamic>;
        return await _convertImageDataToFile(imageData);
      }

      // TODO: Remove this if not needed
      // Check if inline_data is provided in parts (Gemini format)
      // Fallback: extract from contents structure (Gemini format)
      if (requestData.containsKey('contents')) {
        final contents = requestData['contents'] as List;
        for (var content in contents) {
          if (content is Map && content.containsKey('parts')) {
            final parts = content['parts'] as List;
            for (var part in parts) {
              if (part is Map && part.containsKey('inline_data')) {
                return await _convertInlineDataToFile(part['inline_data']);
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error extracting image from request: $e');
    }

    return null;
  }

  // Convert image data to temporary file
  Future<File?> _convertImageDataToFile(Map<String, dynamic> imageData) async {
    try {
      if (imageData.containsKey('data') && imageData['data'] is Map) {
        final data = imageData['data'] as Map<String, String>;
        if (data.containsKey('mime_type') && data.containsKey('data')) {
          return await _createTempFileFromBase64(
            data['data']!,
            data['mime_type']!,
          );
        }
      }
    } catch (e) {
      print('Error converting image data to file: $e');
    }
    return null;
  }

  // Convert inline data to temporary file
  Future<File?> _convertInlineDataToFile(
    Map<String, dynamic> inlineData,
  ) async {
    try {
      if (inlineData.containsKey('mime_type') &&
          inlineData.containsKey('data')) {
        return await _createTempFileFromBase64(
          inlineData['data'] as String,
          inlineData['mime_type'] as String,
        );
      }
    } catch (e) {
      print('Error converting inline data to file: $e');
    }
    return null;
  }

  // Create temporary file from base64 data
  Future<File> _createTempFileFromBase64(
    String base64Data,
    String mimeType,
  ) async {
    final bytes = base64Decode(base64Data);
    final tempDir = Directory.systemTemp;
    final extension = _getExtensionFromMimeType(mimeType);
    final tempFile = File(
      '${tempDir.path}/gemma_temp_${DateTime.now().millisecondsSinceEpoch}.$extension',
    );

    await tempFile.writeAsBytes(bytes);
    return tempFile;
  }

  // Get file extension from MIME type
  String _getExtensionFromMimeType(String mimeType) {
    switch (mimeType.toLowerCase()) {
      case 'image/jpeg':
        return 'jpg';
      case 'image/png':
        return 'png';
      case 'image/gif':
        return 'gif';
      case 'image/webp':
        return 'webp';
      default:
        return 'jpg';
    }
  }
}

// OCR API provider implementation - uses Tesseract OCR for text extraction only
class OcrAPIProvider implements APIProvider {
  @override
  bool canHandleModel(String modelName) {
    final lowerName = modelName.toLowerCase();
    return lowerName.contains('ocr') || lowerName.contains('tesseract');
  }

  @override
  Future<Map<String, dynamic>> makeRequest(
    Map<String, dynamic> requestData,
    AIConfig config,
  ) async {
    try {
      // Import OCR service dynamically to avoid circular dependencies
      final ocrService = _getOCRService();

      // Extract image data from request
      if (!requestData.containsKey('imageData') ||
          requestData['imageData'] == null) {
        return {
          'error': 'No image data provided for OCR processing',
          'statusCode': 400,
        };
      }

      final imageData = requestData['imageData'] as Map<String, dynamic>;
      final identifier = imageData['identifier'] as String? ?? 'unknown';

      // Convert image data to file for OCR processing
      File? tempFile;
      try {
        tempFile = await _convertImageDataToFile(imageData);
        if (tempFile == null) {
          return {
            'error': 'Failed to process image data for OCR',
            'statusCode': 400,
          };
        }

        // Create a minimal Screenshot object for OCR service
        final screenshot = _createMinimalScreenshot(identifier, tempFile.path);

        // Extract text using OCR
        final extractedText = await ocrService.extractTextFromScreenshot(
          screenshot,
        );

        // Format response as JSON matching expected structure
        final responseData = [
          {
            'filename': identifier,
            'title': '',
            'desc': extractedText ?? '',
            'tags': <String>[],
            'links': <String>[],
            'collections': <String>[],
          },
        ];

        return {'data': jsonEncode(responseData), 'statusCode': 200};
      } finally {
        // Clean up temporary file
        if (tempFile != null) {
          try {
            if (await tempFile.exists()) {
              await tempFile.delete();
            }
          } catch (e) {
            print('Warning: Could not delete temporary OCR file: $e');
          }
        }
      }
    } catch (e) {
      return {
        'error': 'OCR processing error: ${e.toString()}',
        'statusCode': 500,
      };
    }
  }

  @override
  Map<String, dynamic> prepareScreenshotAnalysisRequest({
    required String prompt,
    required List<Map<String, dynamic>> imageData,
    Map<String, dynamic> additionalParams = const {},
  }) {
    // OCR processes one image at a time
    Map<String, dynamic>? firstImageData;
    if (imageData.isNotEmpty) {
      firstImageData = imageData.first;
    }

    return {
      'prompt': prompt, // Prompt is ignored for OCR
      'imageData': firstImageData,
      'type': 'ocr_extraction',
      ...additionalParams,
    };
  }

  @override
  Map<String, dynamic> prepareCategorizationRequest({
    required String prompt,
    required List<Map<String, String>> screenshotMetadata,
    Map<String, dynamic> additionalParams = const {},
  }) {
    // OCR does not support categorization - return error structure
    return {
      'error': 'OCR provider does not support categorization',
      'type': 'unsupported',
    };
  }

  dynamic _getOCRService() {
    return OCRService();
  }

  // Create minimal Screenshot object for OCR processing
  Screenshot _createMinimalScreenshot(String id, String path) {
    return Screenshot(
      id: id,
      path: path,
      tags: [],
      aiProcessed: false,
      addedOn: DateTime.now(),
    );
  }

  Future<File?> _convertImageDataToFile(Map<String, dynamic> imageData) async {
    try {
      if (imageData.containsKey('data') && imageData['data'] is Map) {
        final data = imageData['data'] as Map<String, dynamic>;
        if (data.containsKey('mime_type') && data.containsKey('data')) {
          return await _createTempFileFromBase64(
            data['data'] as String,
            data['mime_type'] as String,
          );
        }
      }
    } catch (e) {
      print('Error converting image data to file for OCR: $e');
    }
    return null;
  }

  Future<File> _createTempFileFromBase64(
    String base64Data,
    String mimeType,
  ) async {
    final bytes = base64Decode(base64Data);
    final tempDir = Directory.systemTemp;
    final extension = _getExtensionFromMimeType(mimeType);
    final tempFile = File(
      '${tempDir.path}/ocr_temp_${DateTime.now().millisecondsSinceEpoch}.$extension',
    );

    await tempFile.writeAsBytes(bytes);
    return tempFile;
  }

  String _getExtensionFromMimeType(String mimeType) {
    switch (mimeType.toLowerCase()) {
      case 'image/jpeg':
        return 'jpg';
      case 'image/png':
        return 'png';
      case 'image/gif':
        return 'gif';
      case 'image/webp':
        return 'webp';
      default:
        return 'jpg';
    }
  }
}

// Factory for API providers
class APIProviderFactory {
  static final List<APIProvider> _providers = [
    GeminiAPIProvider(),
    GemmaAPIProvider(),
    OcrAPIProvider(),
    // Future providers can be added here:
    // LocalLlamaAPIProvider(),
  ];

  static APIProvider? getProvider(String modelName) {
    for (final provider in _providers) {
      if (provider.canHandleModel(modelName)) {
        return provider;
      }
    }
    return null;
  }
}

// Abstract base class for AI services
abstract class AIService {
  final AIConfig config;
  bool _isCancelled = false;

  AIService(this.config);

  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
    config.showMessage?.call(
      message: "AI processing cancelled.",
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 2),
    );
  }

  void reset() {
    _isCancelled = false;
  }

  // Protected method for making API requests that delegates to appropriate provider
  Future<Map<String, dynamic>> makeAPIRequest(
    Map<String, dynamic> requestData,
  ) async {
    if (isCancelled) {
      return {'error': 'Request cancelled by user', 'statusCode': 499};
    }

    final provider = APIProviderFactory.getProvider(config.modelName);
    if (provider == null) {
      return {
        'error': 'No API provider found for model: ${config.modelName}',
        'statusCode': 400,
      };
    }

    try {
      return await provider.makeRequest(requestData, config);
    } catch (e) {
      return {'error': 'Provider error: ${e.toString()}', 'statusCode': 500};
    }
  }

  // Protected method for preparing screenshot analysis requests
  Map<String, dynamic>? prepareScreenshotAnalysisRequest({
    required String prompt,
    required List<Map<String, dynamic>> imageData,
    Map<String, dynamic> additionalParams = const {},
  }) {
    final provider = APIProviderFactory.getProvider(config.modelName);
    if (provider == null) {
      return null;
    }

    return provider.prepareScreenshotAnalysisRequest(
      prompt: prompt,
      imageData: imageData,
      additionalParams: additionalParams,
    );
  }

  // Protected method for preparing categorization requests
  Map<String, dynamic>? prepareCategorizationRequest({
    required String prompt,
    required List<Map<String, String>> screenshotMetadata,
    Map<String, dynamic> additionalParams = const {},
  }) {
    final provider = APIProviderFactory.getProvider(config.modelName);
    if (provider == null) {
      return null;
    }

    return provider.prepareCategorizationRequest(
      prompt: prompt,
      screenshotMetadata: screenshotMetadata,
      additionalParams: additionalParams,
    );
  }
}
