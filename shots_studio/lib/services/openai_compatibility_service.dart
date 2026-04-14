import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shots_studio/services/logger_service.dart';

class OpenAICompatibilityService {
  static const String baseUrlPrefKey = 'openai_compatible_base_url';
  static const String apiKeyPrefKey = 'openai_compatible_api_key';
  static const String selectedModelPrefKey = 'openai_compatible_selected_model';
  static const String modelsCachePrefKey = 'openai_compatible_models_cache';

  static String normalizeBaseUrl(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return 'http://localhost:11434';
    }

    var normalized = trimmed;
    if (!normalized.startsWith('http://') &&
        !normalized.startsWith('https://')) {
      normalized = 'http://$normalized';
    }

    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }

    return normalized;
  }

  static Uri buildModelsUri(String baseUrl) {
    final normalized = normalizeBaseUrl(baseUrl);
    if (normalized.endsWith('/v1')) {
      return Uri.parse('$normalized/models');
    }

    return Uri.parse('$normalized/v1/models');
  }

  static Uri buildChatCompletionsUri(String baseUrl) {
    final normalized = normalizeBaseUrl(baseUrl);
    if (normalized.endsWith('/v1')) {
      return Uri.parse('$normalized/chat/completions');
    }

    return Uri.parse('$normalized/v1/chat/completions');
  }

  static Future<List<String>> fetchModels({
    required String baseUrl,
    String? apiKey,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final trimmedApiKey = (apiKey ?? '').trim();
    if (trimmedApiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer $trimmedApiKey';
    }

    try {
      final primaryModels = await _fetchFromOpenaiUrls(
        baseUrl: baseUrl,
        headers: headers,
        timeout: timeout,
      );
      if (primaryModels.isNotEmpty) {
        return primaryModels;
      }
    } catch (e) {
      LoggerService.error('Primary models endpoint fetch failed', e);
    }

    try {
      return await _fetchFromOllamaTags(
        baseUrl: baseUrl,
        headers: headers,
        timeout: timeout,
      );
    } catch (e) {
      LoggerService.error('Fallback tags endpoint model fetch failed', e);
      return [];
    }
  }

  static Future<List<String>> _fetchFromOpenaiUrls({
    required String baseUrl,
    required Map<String, String> headers,
    required Duration timeout,
  }) async {
    final modelsUri = buildModelsUri(baseUrl);
    final response = await http.get(modelsUri, headers: headers).timeout(timeout);
    if (response.statusCode != 200) {
      return [];
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['data'] is! List) {
      return [];
    }

    final models = (decoded['data'] as List)
        .whereType<Map>()
        .map((item) => item['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();

    return models;
  }

  static Future<List<String>> _fetchFromOllamaTags({
    required String baseUrl,
    required Map<String, String> headers,
    required Duration timeout,
  }) async {
    final normalized = normalizeBaseUrl(baseUrl);
    final tagsUri = Uri.parse('$normalized/api/tags');

    final response = await http.get(tagsUri, headers: headers).timeout(timeout);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch models (status: ${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['models'] is! List) {
      return [];
    }

    return (decoded['models'] as List)
        .whereType<Map>()
        .map((item) => item['name']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
  }

  static Future<void> saveModelsCache(List<String> models) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(modelsCachePrefKey, models);
  }

  static Future<List<String>> getModelsCache() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(modelsCachePrefKey) ?? [];
  }
}
