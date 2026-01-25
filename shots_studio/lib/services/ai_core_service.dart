import 'package:flutter/services.dart';
import 'package:shots_studio/services/logger_service.dart';

class AICoreService {
  static const MethodChannel _channel = MethodChannel(
    'com.ansah.shots_studio/ai_core',
  );

  // Singleton instance
  static final AICoreService _instance = AICoreService._internal();

  factory AICoreService() {
    return _instance;
  }

  AICoreService._internal();

  /// Checks if the device supports AICore
  /// Returns false if not supported or if running on F-Droid build where dependency is missing
  Future<bool> isAiCoreSupported() async {
    try {
      final bool isSupported = await _channel.invokeMethod('isAiCoreSupported');
      return isSupported;
    } on MissingPluginException {
      // Channel not implemented (e.g. running on platform where not registered, or very old version)
      return false;
    } catch (e) {
      LoggerService.error('AiCore support check failed', e);
      return false;
    }
  }

  /// Generates a description for the image at [imagePath] using AICore
  /// Throws exception if generation fails
  Future<String> generateDescriptionWithAiCore(String imagePath) async {
    try {
      final String description = await _channel.invokeMethod(
        'generateDescriptionWithAiCore',
        {'imagePath': imagePath},
      );
      return description;
    } catch (e) {
      LoggerService.error('AiCore generation failed', e);
      rethrow;
    }
  }
}
