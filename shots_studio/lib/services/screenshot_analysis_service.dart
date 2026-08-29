// Screenshot Analysis Service
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/utils/ai_provider_config.dart';
import 'package:shots_studio/services/ai_service.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';
import 'package:shots_studio/utils/image_conversion_utils.dart';
import 'package:shots_studio/utils/collection_utils.dart';
import 'package:shots_studio/utils/ai_error_utils.dart';
import 'package:shots_studio/utils/json_utils.dart';
import 'package:shots_studio/utils/ai_language_config.dart';
import 'package:shots_studio/services/logger_service.dart';

class ScreenshotAnalysisService extends AIService {
  // Track network errors to prevent multiple notifications
  int _networkErrorCount = 0;
  bool _processingTerminated = false;
  bool _apiKeyErrorShown = false;

  // Track when the last successful request was made
  DateTime? _lastSuccessfulRequestTime;

  ScreenshotAnalysisService(super.config);

  @override
  void reset() {
    super.reset();
    _networkErrorCount = 0;
    _processingTerminated = false;
    _apiKeyErrorShown = false;
    _lastSuccessfulRequestTime = DateTime.now();
  }

  Future<AIResult<Map<String, dynamic>>> analyzeScreenshots({
    required List<Screenshot> screenshots,
    required BatchProcessedCallback onBatchProcessed,
    List<Map<String, String?>>? autoAddCollections,
  }) async {
    reset();

    if (screenshots.isEmpty) {
      return AIResult.error('No screenshots to analyze');
    }

    Map<String, dynamic> finalResults = {
      'batchResults': [],
      'statusCode': 200,
      'processedCount': 0,
      'totalCount': screenshots.length,
      'cancelled': false,
    };

    // Process in batches
    for (int i = 0; i < screenshots.length; i += config.maxParallel) {
      if (isCancelled) {
        finalResults['cancelled'] = true;
        break;
      }

      int end = min(i + config.maxParallel, screenshots.length);
      List<Screenshot> batch = screenshots.sublist(i, end);

      // Filter out already processed screenshots from this batch
      final unprocessedBatch = batch.where((s) => !s.aiProcessed).toList();

      // If no screenshots in this batch need processing, skip to next batch
      if (unprocessedBatch.isEmpty) {
        // Still call the callback to maintain progress tracking
        onBatchProcessed(batch, {
          'skipped': true,
          'reason': 'All screenshots already processed',
          'statusCode': 200,
        });
        continue;
      }

      try {
        if (isCancelled) {
          finalResults['cancelled'] = true;
          onBatchProcessed(batch, {
            'error': 'Processing cancelled by user',
            'cancelled': true,
          });
          break;
        }

        final requestData = await _prepareRequestData(
          unprocessedBatch, // Use filtered batch
          autoAddCollections: autoAddCollections,
        );
        final result = await _makeAPIRequest(requestData);

        if (isCancelled && result['statusCode'] == 499) {
          finalResults['cancelled'] = true;
          onBatchProcessed(batch, result);
          break;
        }

        (finalResults['batchResults'] as List).add({
          'batch': batch.map((s) => s.id).toList(),
          'result': result,
        });

        if (result.containsKey('error')) {
          onBatchProcessed(batch, result);
        } else {
          // Try to parse and update screenshots
          try {
            parseAndUpdateScreenshots(unprocessedBatch, result);
            finalResults['processedCount'] =
                (finalResults['processedCount'] as int) + batch.length;

            // Log analytics for Gemma processing if this is a Gemma model
            await _logGemmaAnalyticsIfApplicable(
              result,
              unprocessedBatch.length,
              config.maxParallel,
            );

            onBatchProcessed(batch, result);
          } catch (parseError) {
            // Handle parsing errors by stopping processing and showing error
            LoggerService.error("Parsing error occurred", parseError);
            final errorResult = {
              'error': parseError.toString(),
              'statusCode': 422, // Unprocessable Entity
              'parsing_error': true,
            };
            (finalResults['batchResults'] as List).add({
              'batch': batch.map((s) => s.id).toList(),
              'result': errorResult,
            });
            onBatchProcessed(batch, errorResult);
            // Stop processing further batches on parsing error
            break;
          }
        }

        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        (finalResults['batchResults'] as List).add({
          'batch': batch.map((s) => s.id).toList(),
          'error': e.toString(),
        });
        onBatchProcessed(batch, {'error': e.toString()});
      }
    }

    if (isCancelled) {
      return AIResult.cancelled();
    }

    final batchResults = finalResults['batchResults'] as List?;
    final firstError = batchResults
        ?.whereType<Map>()
        .map((b) => b['result']?['error'] ?? b['error'])
        .whereType<String>()
        .firstOrNull;

    if ((finalResults['processedCount'] as int? ?? 0) == 0 && firstError != null) {
      return AIResult.error(firstError);
    }

    return AIResult.success(finalResults);
  }

  List<Screenshot> parseAndUpdateScreenshots(
    List<Screenshot> screenshots,
    Map<String, dynamic> response,
  ) {
    if (response.containsKey('error') || !response.containsKey('data')) {
      // Don't show error messages if processing has already been terminated
      if (!_processingTerminated) {
        _handleResponseError(response);
      }
      return screenshots;
    }

    try {
      final String responseText = response['data'];
      List<dynamic> parsedResponse = [];
      // Clean the response text by removing markdown code fences
      String cleanedResponseText = JsonUtils.cleanMarkdownCodeFences(
        responseText,
      );

      // Check if the JSON is complete (has matching brackets)
      if (!JsonUtils.isCompleteJson(cleanedResponseText)) {
        LoggerService.log(
          "WARNING: JSON appears to be truncated or incomplete",
        );
        // Try to fix incomplete JSON
        cleanedResponseText = JsonUtils.attemptJsonFix(cleanedResponseText);
      }

      // Try to parse the cleaned text directly first
      try {
        final dynamic decoded = jsonDecode(cleanedResponseText);
        if (decoded is List) {
          parsedResponse = decoded;
        } else if (decoded is Map<String, dynamic>) {
          parsedResponse = [decoded];
        } else if (decoded is Map) {
          parsedResponse = [Map<String, dynamic>.from(decoded)];
        }
      } catch (e) {
        LoggerService.error("Initial JSON parsing failed", e);

        // Try to extract JSON array [ ... ] with regex as fallback
        final RegExp arrayRegExp = RegExp(r'\[.*\]', dotAll: true);
        final arrayMatch = arrayRegExp.firstMatch(cleanedResponseText);

        if (arrayMatch != null) {
          try {
            final dynamic decoded = jsonDecode(arrayMatch.group(0)!);
            if (decoded is List &&
                decoded.isNotEmpty &&
                decoded.every((item) => item is Map)) {
              parsedResponse = decoded;
            } else if (decoded is Map) {
              parsedResponse = [Map<String, dynamic>.from(decoded)];
            }
          } catch (e2) {
            LoggerService.error("Failed to parse extracted JSON array", e2);
          }
        }

        // If array regex didn't yield results (or was not a list of objects), try single object { ... }
        if (parsedResponse.isEmpty) {
          final RegExp objRegExp = RegExp(r'\{.*\}', dotAll: true);
          final objMatch = objRegExp.firstMatch(cleanedResponseText);
          if (objMatch != null) {
            try {
              final dynamic decoded = jsonDecode(objMatch.group(0)!);
              if (decoded is Map) {
                parsedResponse = [Map<String, dynamic>.from(decoded)];
              } else if (decoded is List &&
                  decoded.isNotEmpty &&
                  decoded.every((item) => item is Map)) {
                parsedResponse = decoded;
              }
            } catch (e3) {
              LoggerService.error("Failed to parse extracted JSON object", e3);
            }
          }
        }

        if (parsedResponse.isEmpty) {
          LoggerService.log("No valid JSON pattern found in response");
          throw Exception(
            'JSON parsing failed: Unable to parse AI response. Please try again.',
          );
        }
      }

      if (parsedResponse.isEmpty) {
        throw Exception(
          'JSON parsing failed: AI response is empty or invalid. Please try again.',
        );
      }

      // Validate and sanitize the parsed response
      parsedResponse = _validateAndSanitizeResponse(parsedResponse);

      AiMetaData aiMetaData = AiMetaData(
        modelName: config.modelName,
        processingTime: DateTime.now(),
      );

      if (screenshots.length == 1 && parsedResponse.length == 1) {
        return _updateSingleScreenshot(
          screenshots[0],
          parsedResponse[0],
          aiMetaData,
          response,
        );
      }

      return _updateMultipleScreenshots(
        screenshots,
        parsedResponse,
        aiMetaData,
        response,
      );
    } catch (e) {
      LoggerService.error('Error parsing response and updating screenshots', e);
      return screenshots;
    }
  }

  /// Validates and sanitizes the parsed response to ensure it has the correct structure
  List<dynamic> _validateAndSanitizeResponse(List<dynamic> parsedResponse) {
    List<dynamic> sanitizedResponse = [];

    for (var item in parsedResponse) {
      if (item is Map) {
        Map<String, dynamic> sanitizedItem = Map<String, dynamic>.from(item);

        // Ensure required fields exist and have correct types
        sanitizedItem['filename'] =
            (sanitizedItem['filename'] ?? '').toString();
        sanitizedItem['title'] =
            (sanitizedItem['title'] ?? sanitizedItem['name'] ?? '').toString();
        sanitizedItem['desc'] =
            (sanitizedItem['desc'] ??
                    sanitizedItem['description'] ??
                    sanitizedItem['summary'] ??
                    '')
                .toString();

        // Ensure tags is always a list
        if (sanitizedItem['tags'] is! List) {
          if (sanitizedItem['tags'] is String) {
            // If tags is a string, split by comma or other delimiters
            String tagString = sanitizedItem['tags'].toString();
            sanitizedItem['tags'] =
                tagString
                    .split(RegExp(r'[,;|]'))
                    .map((tag) => tag.trim())
                    .where((tag) => tag.isNotEmpty)
                    .toList();
          } else {
            sanitizedItem['tags'] = [];
          }
        } else {
          // Ensure all items in tags list are strings
          sanitizedItem['tags'] =
              (sanitizedItem['tags'] as List)
                  .map((tag) => tag.toString())
                  .toList();
        }

        // Ensure collections is always a list
        if (sanitizedItem['collections'] is! List) {
          if (sanitizedItem['collections'] is String) {
            // If collections is a string, split by comma or other delimiters
            String collectionString = sanitizedItem['collections'].toString();
            sanitizedItem['collections'] =
                collectionString
                    .split(RegExp(r'[,;|]'))
                    .map((col) => col.trim())
                    .where((col) => col.isNotEmpty)
                    .toList();
          } else {
            sanitizedItem['collections'] = [];
          }
        } else {
          // Ensure all items in collections list are strings
          sanitizedItem['collections'] =
              (sanitizedItem['collections'] as List)
                  .map((col) => col.toString())
                  .toList();
        }

        // Ensure other is always a list
        if (sanitizedItem['other'] is! List) {
          if (sanitizedItem['other'] is String) {
            // If other is a string, convert to single-item list
            sanitizedItem['other'] = [sanitizedItem['other'].toString()];
          } else if (sanitizedItem['other'] != null) {
            sanitizedItem['other'] = [sanitizedItem['other'].toString()];
          } else {
            sanitizedItem['other'] = [];
          }
        } else {
          // Ensure all items in other list are strings
          sanitizedItem['other'] =
              (sanitizedItem['other'] as List)
                  .map((item) => item.toString())
                  .toList();
        }

        // Ensure links is always a list
        if (sanitizedItem['links'] is! List) {
          if (sanitizedItem['links'] is String) {
            // If links is a string, split by comma or other delimiters
            String linksString = sanitizedItem['links'].toString();
            sanitizedItem['links'] =
                linksString
                    .split(RegExp(r'[,;|]'))
                    .map((link) => link.trim())
                    .where((link) => link.isNotEmpty)
                    .map((link) => _normalizeLinkFormat(link))
                    .toList();
          } else if (sanitizedItem['links'] != null) {
            sanitizedItem['links'] = [
              _normalizeLinkFormat(sanitizedItem['links'].toString()),
            ];
          } else {
            sanitizedItem['links'] = [];
          }
        } else {
          // Ensure all items in links list are strings and normalized
          sanitizedItem['links'] =
              (sanitizedItem['links'] as List)
                  .map((link) => _normalizeLinkFormat(link.toString()))
                  .toList();
        }

        sanitizedResponse.add(sanitizedItem);
      } else {
        LoggerService.log(
          "Warning: Invalid item found in response, skipping: $item",
        );
      }
    }

    return sanitizedResponse;
  }

  /// Normalize link format to ensure consistency
  String _normalizeLinkFormat(String link) {
    final cleanLink = link.trim();

    // Preserve calendar: prefixed links as-is
    if (cleanLink.startsWith('calendar:')) {
      return cleanLink;
    }

    // For phone numbers, ensure they have tel: prefix for consistency
    if (RegExp(
          r'^[\+]?[\d\s\-\(\)\.]{7,}$',
        ).hasMatch(cleanLink.replaceAll(' ', '')) &&
        !cleanLink.startsWith('tel:')) {
      return 'tel:$cleanLink';
    }

    // For emails, ensure they have mailto: prefix for consistency
    if (RegExp(
          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
        ).hasMatch(cleanLink) &&
        !cleanLink.startsWith('mailto:')) {
      return 'mailto:$cleanLink';
    }

    // For URLs, ensure they have proper protocol
    if ((RegExp(r'^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}').hasMatch(cleanLink) ||
            cleanLink.startsWith('www.')) &&
        !cleanLink.startsWith('http://') &&
        !cleanLink.startsWith('https://')) {
      return 'https://$cleanLink';
    }

    // Return as-is if already properly formatted or doesn't match known patterns
    return cleanLink;
  }

  Future<String> _getAnalysisPrompt({
    List<Map<String, String?>>? autoAddCollections,
  }) async {
    final bool advancedExtraction = AIProviderConfig.hasAdvancedExtraction(
      config.modelName,
    );
    final bool isGeminiModel =
        AIProviderConfig.getProviderForModel(config.modelName) == 'gemini';

    String basePrompt = """
      You are a screenshot analyzer. You will be given single or multiple images.
      For each image, generate a title and short description ${isGeminiModel ? 'and 3-5 relevant tags' : '1-3 relevant tags'} with which users can search and find later with ease.
    """;

    basePrompt += """

      Additionally, extract any copyable information from the screenshot that you can see on the image (if useful) such as:
      - Phone numbers (format them properly with country codes when possible)
      - Email addresses
      - Website URLs/links
      - Any other copyable text that users might want to copy or store for later
      Include these in a "links" field as a list of strings. eg : ["tel:+1234567890", "mailto:example@example.com"]
    """;

    // Advanced extraction: dates, events, flights, locations (only for capable models)
    if (advancedExtraction) {
      final todayDate = DateTime.now().toIso8601String().split('T')[0];
      basePrompt += """

      Also extract the following if visible in the screenshot:
      - Dates & times (events, appointments, reminders, deadlines)
      - Specific flight numbers only (e.g. AA1234, 6E 2145, BA 456) — these are airline codes followed by numbers.
        Do NOT extract airline brand names (e.g. "Air India", "Qantas") as flight numbers.
        Only extract if an actual flight code is visible. Format as: https://www.google.com/search?q=FLIGHT_NUMBER+flight+status
      - Locations or addresses (format as: https://www.google.com/maps/search/URL_ENCODED_ADDRESS)
      - For any future event with a clear date/time (after $todayDate), include a calendar link:
        calendar:EVENT TITLE|YYYYMMDDTHHMMSS|YYYYMMDDTHHMMSS|LOCATION
        (start time | end time | location — estimate 1 hour duration if end time is unknown, location can be empty)
        Only include calendar links for future dates.
      Include all of these in the same "links" field alongside phone numbers, emails, and URLs.
      """;
    }

    if (autoAddCollections != null && autoAddCollections.isNotEmpty) {
      basePrompt += """
      
      Here are list of collections and their descriptions that these images can potentially fit in.
      If the image belongs to any of these collections, include them in the response, if not, keep the collections list empty.
      
      Available collections:
      """;

      for (var collection in autoAddCollections) {
        basePrompt += """
        - Name: "${collection['name'] ?? 'Unnamed'}"
          Description: "${collection['description'] ?? 'No description'}"
        """;
      }
    }

    // Get language instruction from shared preferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedLanguage =
          prefs.getString(AILanguageConfig.prefKey) ??
          AILanguageConfig.defaultLanguageKey;
      final languageInstruction = await AILanguageConfig.getLanguageInstruction(
        selectedLanguage,
      );

      if (languageInstruction.isNotEmpty) {
        basePrompt += """
        Language Instruction: $languageInstruction
        """;
      }
    } catch (e) {
      LoggerService.error('Error loading language preference', e);
      // Continue without language instruction if there's an error
    }

    basePrompt += """
      
      Respond strictly in this JSON format:
      [{"filename": '', "title": '', "desc": '', "tags": [], "links": [], "collections": []}, ...]
      The "collections" field should contain names of collections that match the image content. The "tags" field should contain relevant search tags. The "links" field should contain any clickable information like phone numbers, emails, URLs${advancedExtraction ? ', calendar events, map locations, flight tracking links' : ''}, etc.
    """;

    return basePrompt;
  }

  Future<Map<String, dynamic>> _prepareRequestData(
    List<Screenshot> images, {
    List<Map<String, String?>>? autoAddCollections,
  }) async {
    // Filter out screenshots that are already AI processed (including corrupted ones)
    final unprocessedImages =
        images.where((image) => !image.aiProcessed).toList();

    // Prepare image data in a generic format
    List<Map<String, dynamic>> imageData = [];

    for (var image in unprocessedImages) {
      String imageIdentifier = image.id;
      Map<String, String>? imageBase64Data;

      try {
        if (image.path != null && image.path!.isNotEmpty) {
          imageBase64Data = await ImageConversionUtils.convertImageToBase64(
            image.path!,
          );
        } else if (image.bytes != null) {
          imageBase64Data = ImageConversionUtils.bytesToBase64(
            image.bytes!,
            fileName: image.path,
          );
        } else {
          LoggerService.log(
            "Warning: Screenshot with id ${image.id} has no path or bytes.",
          );
          continue;
        }

        imageData.add({'identifier': imageIdentifier, 'data': imageBase64Data});
      } catch (e) {
        LoggerService.error("Error adding image data for ${image.id}", e);
      }
    }

    // Use the provider-specific request preparation
    final prompt = await _getAnalysisPrompt(
      autoAddCollections: autoAddCollections,
    );
    final requestData = prepareScreenshotAnalysisRequest(
      prompt: prompt,
      imageData: imageData,
    );

    // Fallback to old format if provider doesn't support new format
    return requestData ??
        {
          'contents': [
            {
              'parts': [
                {'text': 'No images to process - provider not supported.'},
              ],
            },
          ],
        };
  }

  // Wrapper method that adds screenshot-specific logic before calling base API method
  Future<Map<String, dynamic>> _makeAPIRequest(
    Map<String, dynamic> requestData,
  ) async {
    if (isCancelled || _processingTerminated) {
      return {'error': 'Request cancelled by user', 'statusCode': 499};
    }

    // Check if it has been a long time since the last successful request
    if (_lastSuccessfulRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(
        _lastSuccessfulRequestTime!,
      );
      // If more than 2 minutes have passed since the last successful request, assume app was reopened
      if (timeSinceLastRequest.inMinutes > 2) {
        _processingTerminated = true;
        return {
          'error':
              'App was likely closed and reopened. AI processing terminated.',
          'statusCode': 499,
        };
      }
    }

    // Call the base class method to make the actual API request
    final result = await makeAPIRequest(requestData);

    // Update last successful request time if the request was successful
    if (result['statusCode'] == 200) {
      _lastSuccessfulRequestTime = DateTime.now();
    }

    return result;
  }

  List<Screenshot> _updateSingleScreenshot(
    Screenshot screenshot,
    Map<String, dynamic> item,
    AiMetaData aiMetaData,
    Map<String, dynamic> response,
  ) {
    final List<String> collectionNames = List<String>.from(
      item['collections'] ?? [],
    );

    // Only update fields if AI response has non-empty values
    // This preserves existing data when AI models (like OCR) only provide partial data
    final titleValue = item['title'] ?? item['name'];
    final String? newTitle =
        (titleValue != null && titleValue.toString().trim().isNotEmpty)
            ? titleValue.toString().trim()
            : null;
    final descValue = item['desc'] ?? item['description'] ?? item['summary'];
    final String? newDescription =
        (descValue != null && descValue.toString().trim().isNotEmpty)
            ? descValue.toString().trim()
            : null;
    final List<String> newTags = List<String>.from(item['tags'] ?? []);
    final List<String> newLinks = List<String>.from(item['links'] ?? []);

    final updatedScreenshot = screenshot.copyWith(
      title: newTitle ?? screenshot.title,
      description: newDescription ?? screenshot.description,
      tags: newTags.isNotEmpty ? newTags : screenshot.tags,
      links: newLinks.isNotEmpty ? newLinks : screenshot.links,
      aiProcessed: true,
      aiMetadata: aiMetaData,
    );

    if (collectionNames.isNotEmpty) {
      CollectionUtils.storeSuggestedCollections(
        response,
        updatedScreenshot.id,
        collectionNames,
      );
    }

    return [updatedScreenshot];
  }

  List<Screenshot> _updateMultipleScreenshots(
    List<Screenshot> screenshots,
    List<dynamic> parsedResponse,
    AiMetaData aiMetaData,
    Map<String, dynamic> response,
  ) {
    List<Screenshot> updatedScreenshots = [];
    List<dynamic> availableResponses = List.from(parsedResponse);

    for (var screenshot in screenshots) {
      String identifier = screenshot.id;
      Map<String, dynamic>? matchedAiItem;
      int? matchedAiItemIndex;

      // Find matching AI response by filename
      for (int i = 0; i < availableResponses.length; i++) {
        var currentAiItem = availableResponses[i];
        if (currentAiItem is Map<String, dynamic>) {
          String responseFileId = currentAiItem['filename'] ?? '';
          if (responseFileId.isNotEmpty &&
              (identifier == responseFileId ||
                  identifier.contains(responseFileId) ||
                  responseFileId.contains(identifier))) {
            matchedAiItem = currentAiItem;
            matchedAiItemIndex = i;
            break;
          }
        }
      }

      // Fallback: If no filename match was found, match positionally with first available response
      if (matchedAiItem == null && availableResponses.isNotEmpty) {
        final firstAvailable = availableResponses.first;
        if (firstAvailable is Map<String, dynamic>) {
          matchedAiItem = firstAvailable;
          matchedAiItemIndex = 0;
        }
      }

      if (matchedAiItem != null) {
        final List<String> collectionNames = List<String>.from(
          matchedAiItem['collections'] ?? [],
        );

        // Only update fields if AI response has non-empty values
        // This preserves existing data when AI models (like OCR) only provide partial data
        final itemTitle = matchedAiItem['title'] ?? matchedAiItem['name'];
        final String? newTitle =
            (itemTitle != null && itemTitle.toString().trim().isNotEmpty)
                ? itemTitle.toString().trim()
                : null;
        final itemDesc = matchedAiItem['desc'] ?? matchedAiItem['description'] ?? matchedAiItem['summary'];
        final String? newDescription =
            (itemDesc != null && itemDesc.toString().trim().isNotEmpty)
                ? itemDesc.toString().trim()
                : null;
        final List<String> newTags = List<String>.from(
          matchedAiItem['tags'] ?? [],
        );
        final List<String> newLinks = List<String>.from(
          matchedAiItem['links'] ?? [],
        );

        final updatedScreenshot = screenshot.copyWith(
          title: newTitle ?? screenshot.title,
          description: newDescription ?? screenshot.description,
          tags: newTags.isNotEmpty ? newTags : screenshot.tags,
          links: newLinks.isNotEmpty ? newLinks : screenshot.links,
          aiProcessed: true,
          aiMetadata: aiMetaData,
        );

        if (collectionNames.isNotEmpty) {
          CollectionUtils.storeSuggestedCollections(
            response,
            updatedScreenshot.id,
            collectionNames,
          );
        }

        updatedScreenshots.add(updatedScreenshot);
        if (matchedAiItemIndex != null) {
          availableResponses.removeAt(matchedAiItemIndex);
        }
      } else {
        updatedScreenshots.add(screenshot);
      }
    }

    return updatedScreenshots;
  }

  void _handleResponseError(Map<String, dynamic> response) {
    // Check if this is a parsing error
    if (response.containsKey('parsing_error') &&
        response['parsing_error'] == true) {
      // For parsing errors, always show the message and terminate processing
      if (config.showMessage != null) {
        config.showMessage!(
          message:
              'AI Processing Error: ${response['error'] ?? 'Failed to parse AI response'}',
        );
      }
      _processingTerminated = true;
      return;
    }

    final result = AIErrorHandler.handleResponseError(
      response,
      showMessage: config.showMessage,
      isCancelled: () => isCancelled,
      cancelProcessing: cancel,
      apiKeyErrorShown: _apiKeyErrorShown,
      processingTerminated: _processingTerminated,
      networkErrorCount: _networkErrorCount,
      setApiKeyErrorShown: (value) => _apiKeyErrorShown = value,
      setProcessingTerminated: (value) => _processingTerminated = value,
      setNetworkErrorCount: (value) => _networkErrorCount = value,
    );

    // Update state based on error handling result
    if (result.shouldTerminate) {
      _processingTerminated = true;
    }
  }

  /// Log analytics for Gemma processing if applicable
  Future<void> _logGemmaAnalyticsIfApplicable(
    Map<String, dynamic> result,
    int batchSize,
    int maxParallelAI,
  ) async {
    try {
      // Check if this is a Gemma response by looking for Gemma-specific fields
      final bool isGemmaResponse =
          result.containsKey('gemma_processing_time_ms') &&
          result.containsKey('gemma_model_name') &&
          result.containsKey('gemma_use_cpu');

      if (!isGemmaResponse) {
        // Not a Gemma response, skip analytics
        return;
      }

      final processingTimeMs = result['gemma_processing_time_ms'] as int?;
      final modelName = result['gemma_model_name'] as String?;
      final useCPU = result['gemma_use_cpu'] as bool?;

      if (processingTimeMs == null || modelName == null || useCPU == null) {
        // Missing required data, skip analytics
        return;
      }

      // Get device info from the analytics service
      final analyticsService = AnalyticsService();
      final deviceInfo = await analyticsService.getDeviceInfo();
      final devicePlatform = deviceInfo['platform'] ?? 'unknown';
      final deviceModel = deviceInfo['model'];

      // Log Gemma processing time analytics
      await analyticsService.logGemmaProcessingTime(
        processingTimeMs: processingTimeMs,
        screenshotCount: batchSize,
        maxParallelAI: maxParallelAI,
        modelName: modelName,
        devicePlatform: devicePlatform,
        deviceModel: deviceModel,
        useCPU: useCPU,
      );
    } catch (e) {
      // Silently fail analytics to not disrupt the main processing flow
      LoggerService.error('Error logging Gemma analytics', e);
    }
  }
}
