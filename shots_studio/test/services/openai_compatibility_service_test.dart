import 'package:flutter_test/flutter_test.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/services/ai_service.dart';
import 'package:shots_studio/services/openai_compatibility_service.dart';
import 'package:shots_studio/services/screenshot_analysis_service.dart';
import 'package:shots_studio/utils/ai_provider_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OpenAICompatibilityService Tests', () {
    test('normalizeBaseUrl should handle empty, localhost, and custom IPs', () {
      expect(
        OpenAICompatibilityService.normalizeBaseUrl(''),
        'http://localhost:11434',
      );
      expect(
        OpenAICompatibilityService.normalizeBaseUrl('   '),
        'http://localhost:11434',
      );
      expect(
        OpenAICompatibilityService.normalizeBaseUrl('192.168.1.50:11434'),
        'http://192.168.1.50:11434',
      );
      expect(
        OpenAICompatibilityService.normalizeBaseUrl('http://192.168.1.50:11434/v1/'),
        'http://192.168.1.50:11434/v1',
      );
      expect(
        OpenAICompatibilityService.normalizeBaseUrl('https://api.openai.com/v1/'),
        'https://api.openai.com/v1',
      );
    });

    test('buildModelsUri should construct correct endpoints', () {
      expect(
        OpenAICompatibilityService.buildModelsUri('http://192.168.1.50:11434')
            .toString(),
        'http://192.168.1.50:11434/v1/models',
      );
      expect(
        OpenAICompatibilityService.buildModelsUri('http://192.168.1.50:11434/v1')
            .toString(),
        'http://192.168.1.50:11434/v1/models',
      );
    });

    test('buildChatCompletionsUri should construct correct endpoints', () {
      expect(
        OpenAICompatibilityService.buildChatCompletionsUri(
          'http://192.168.1.50:11434',
        ).toString(),
        'http://192.168.1.50:11434/v1/chat/completions',
      );
      expect(
        OpenAICompatibilityService.buildChatCompletionsUri(
          'http://192.168.1.50:11434/v1',
        ).toString(),
        'http://192.168.1.50:11434/v1/chat/completions',
      );
    });
  });

  group('AIProviderConfig OpenAI Integration Tests', () {
    test('should include openai_compatible in providers list and pref keys', () {
      final providers = AIProviderConfig.getProviders();
      expect(providers.contains('openai_compatible'), true);
      expect(
        AIProviderConfig.getPrefKeyForProvider('openai_compatible'),
        'ai_provider_openai_compatible_enabled',
      );
    });

    test('should support dynamic OpenAI model caching', () {
      AIProviderConfig.setDynamicOpenAIModels([
        'llama3.2-vision:latest',
        'qwen2.5-vl:7b',
      ]);

      final models = AIProviderConfig.getModelsForProvider('openai_compatible');
      expect(models.contains('llama3.2-vision:latest'), true);
      expect(models.contains('qwen2.5-vl:7b'), true);
      expect(
        AIProviderConfig.getProviderForModel('llama3.2-vision:latest'),
        'openai_compatible',
      );
    });
  });

  group('OpenAICompatibleAPIProvider Tests', () {
    final provider = OpenAICompatibleAPIProvider();

    test('canHandleModel should detect OpenAI and dynamic models', () {
      expect(provider.canHandleModel('openai-compatible'), true);
      expect(provider.canHandleModel('llama3.2-vision:latest'), true);
      expect(provider.canHandleModel('gemini-2.0-flash'), false);
    });

    test('prepareScreenshotAnalysisRequest formats multimodal payload', () {
      final request = provider.prepareScreenshotAnalysisRequest(
        prompt: 'Analyze screenshot',
        imageData: [
          {
            'identifier': 'img-1',
            'data': {
              'mime_type': 'image/jpeg',
              'data': 'base64sampledata',
            },
          },
        ],
        additionalParams: {'modelName': 'llama3.2-vision:latest'},
      );

      expect(request['model'], 'llama3.2-vision:latest');
      expect(request['messages'] is List, true);

      final messages = request['messages'] as List;
      expect(messages.isNotEmpty, true);
      final content = messages[0]['content'] as List;
      expect(content.any((item) => item['type'] == 'image_url'), true);
    });

    test('prepareCategorizationRequest formats text analysis payload', () {
      final request = provider.prepareCategorizationRequest(
        prompt: 'Categorize screenshots',
        screenshotMetadata: [
          {
            'id': '1',
            'title': 'Receipt',
            'description': 'Store receipt',
            'tags': 'shopping, receipt',
          },
        ],
        additionalParams: {'modelName': 'llama3.2-vision:latest'},
      );

      expect(request['model'], 'llama3.2-vision:latest');
      expect(request['messages'] is List, true);
    });
  });

  group('ScreenshotAnalysisService Response Parsing Tests', () {
    final service = ScreenshotAnalysisService(
      AIConfig(apiKey: '', modelName: 'openai-compatible'),
    );
    final dummyScreenshot = Screenshot(
      id: 'screenshot_123',
      path: '/path/to/screenshot_123.png',
      tags: [],
      links: [],
      collectionIds: [],
      addedOn: DateTime.now(),
      aiProcessed: false,
    );

    test('parses single JSON object correctly', () {
      final response = {
        'data': '{"title": "Invoice Details", "description": "Payment receipt for coffee", "tags": ["coffee", "receipt"], "links": ["tel:+123456789"]}',
      };

      final result = service.parseAndUpdateScreenshots(
        [dummyScreenshot],
        response,
      );

      expect(result.length, 1);
      expect(result[0].title, 'Invoice Details');
      expect(result[0].description, 'Payment receipt for coffee');
      expect(result[0].tags, ['coffee', 'receipt']);
      expect(result[0].links, ['tel:+123456789']);
      expect(result[0].aiProcessed, true);
    });

    test('parses markdown-wrapped JSON array correctly', () {
      final response = {
        'data': '```json\n[{"filename": "screenshot_123", "title": "Flight Ticket", "desc": "Boarding pass", "tags": ["travel"]}]\n```',
      };

      final result = service.parseAndUpdateScreenshots(
        [dummyScreenshot],
        response,
      );

      expect(result.length, 1);
      expect(result[0].title, 'Flight Ticket');
      expect(result[0].description, 'Boarding pass');
      expect(result[0].tags, ['travel']);
      expect(result[0].aiProcessed, true);
    });

    test('parses conversational text with embedded JSON object', () {
      final response = {
        'data': 'Here is the analysis of your screenshot:\n\n{"title": "Bank Alert", "summary": "Account transaction alert", "tags": ["banking"]}\n\nHope this helps!',
      };

      final result = service.parseAndUpdateScreenshots(
        [dummyScreenshot],
        response,
      );

      expect(result.length, 1);
      expect(result[0].title, 'Bank Alert');
      expect(result[0].description, 'Account transaction alert');
      expect(result[0].tags, ['banking']);
      expect(result[0].aiProcessed, true);
    });

    test('parses thinking / reasoning model output with <think> tags', () {
      final response = {
        'data': '<think>\nFirst, let me observe the screenshot.\nI see a train schedule with ticket numbers.\nNow formatting to requested JSON.\n</think>\n```json\n[{"title": "Train Ticket", "desc": "Express train booking", "tags": ["train", "booking"]}]\n```',
      };

      final result = service.parseAndUpdateScreenshots(
        [dummyScreenshot],
        response,
      );

      expect(result.length, 1);
      expect(result[0].title, 'Train Ticket');
      expect(result[0].description, 'Express train booking');
      expect(result[0].tags, ['train', 'booking']);
      expect(result[0].aiProcessed, true);
    });
  });
}

