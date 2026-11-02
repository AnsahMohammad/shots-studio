import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shots_studio/services/server_message_service.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const preferencesChannel = MethodChannel(
    'plugins.flutter.io/shared_preferences',
  );

  group('ServerMessageService preferences', () {
    late int requestCount;
    late MockClient client;
    late Map<String, Object> storedPreferences;

    http.Response messageResponse({bool isNotification = true}) {
      return http.Response(
        jsonEncode({
          'messages': [
            {
              'show': true,
              'id': 'test-message',
              'title': 'Server announcement',
              'message': 'An important update',
              'is_notification': isNotification,
            },
          ],
        }),
        200,
      );
    }

    setUp(() {
      SharedPreferences.resetStatic();
      storedPreferences = {};
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        preferencesChannel,
        (call) async {
          if (call.method == 'getAll' ||
              call.method == 'getAllWithParameters') {
            return Map<String, Object>.from(storedPreferences);
          }
          if (call.method == 'setBool') {
            final arguments = call.arguments as Map;
            storedPreferences[arguments['key'] as String] =
                arguments['value'] as bool;
            return true;
          }
          fail('Unexpected preferences method: ${call.method}');
        },
      );
      addTearDown(() {
        binding.defaultBinaryMessenger.setMockMethodCallHandler(
          preferencesChannel,
          null,
        );
        SharedPreferences.resetStatic();
      });
      PackageInfo.setMockInitialValues(
        appName: 'Shots Studio',
        packageName: 'com.ansah.shots_studio',
        version: '1.9.103',
        buildNumber: '10',
        buildSignature: '',
      );
      requestCount = 0;
      client = MockClient((request) async {
        requestCount++;
        return messageResponse();
      });
      addTearDown(client.close);
    });

    for (final forceFetch in [false, true]) {
      test(
        'disabled messages skip requests (forceFetch: $forceFetch)',
        () async {
          storedPreferences['flutter.server_messages_enabled'] = false;

          final message = await http.runWithClient(
            () => ServerMessageService.checkForMessages(forceFetch: forceFetch),
            () => client,
          );

          expect(message, isNull);
          expect(requestCount, 0);
        },
      );
    }

    test('messages are enabled by default', () async {
      final message = await http.runWithClient(
        () => ServerMessageService.checkForMessages(forceFetch: true),
        () => client,
      );

      expect(message?.id, 'test-message');
      expect(requestCount, 1);
    });

    for (final enabled in [false, true]) {
      test(
        'refreshes cached preferences when messages become $enabled',
        () async {
          storedPreferences['flutter.server_messages_enabled'] = !enabled;
          final prefs = await SharedPreferences.getInstance();
          expect(prefs.getBool('server_messages_enabled'), !enabled);

          // Simulate a setting change from another isolate without updating
          // this isolate's SharedPreferences cache.
          storedPreferences['flutter.server_messages_enabled'] = enabled;

          final message = await http.runWithClient(
            () => ServerMessageService.checkForMessages(forceFetch: true),
            () => client,
          );

          expect(message?.id, enabled ? 'test-message' : null);
          expect(requestCount, enabled ? 1 : 0);
        },
      );
    }

    for (final isNotification in [false, true]) {
      test('enabled messages allow isNotification: $isNotification', () async {
        storedPreferences['flutter.server_messages_enabled'] = true;
        final responseClient = MockClient((request) async {
          requestCount++;
          return messageResponse(isNotification: isNotification);
        });
        addTearDown(responseClient.close);

        final message = await http.runWithClient(
          () => ServerMessageService.checkForMessages(forceFetch: true),
          () => responseClient,
        );

        expect(message?.id, 'test-message');
        expect(message?.isNotification, isNotification);
        expect(requestCount, 1);
      });

      test('disabling messages during a request suppresses '
          'isNotification: $isNotification', () async {
        final responseClient = MockClient((request) async {
          requestCount++;
          storedPreferences['flutter.server_messages_enabled'] = false;
          return messageResponse(isNotification: isNotification);
        });
        addTearDown(responseClient.close);

        final message = await http.runWithClient(
          () => ServerMessageService.checkForMessages(forceFetch: true),
          () => responseClient,
        );

        expect(message, isNull);
        expect(requestCount, 1);
      });
    }

    test('messages can be re-enabled after a disabled check', () async {
      storedPreferences['flutter.server_messages_enabled'] = false;

      await http.runWithClient(() async {
        expect(
          await ServerMessageService.checkForMessages(forceFetch: true),
          isNull,
        );
        expect(requestCount, 0);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('server_messages_enabled', true);

        final message = await ServerMessageService.checkForMessages(
          forceFetch: true,
        );
        expect(message?.id, 'test-message');
        expect(requestCount, 1);
      }, () => client);
    });
  });
}
