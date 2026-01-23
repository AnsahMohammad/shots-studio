import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shots_studio/services/notification_service.dart';
import 'package:shots_studio/utils/build_source.dart';
import 'package:shots_studio/services/logger_service.dart';

// TODO: Add don't show again functionality for messages

class ServerMessageService {
  static const List<String> baseUrls = [
    'https://ansahmohammad.github.io/shots-studio/messages',
    'https://gitlab.com/mohdansah10/shots-studio/-/raw/main/docs/messages',
  ];

  // Add cooldown for server requests to avoid spamming
  static DateTime? _lastRequestTime;
  static const Duration _requestCooldown = Duration(minutes: 30);

  /// Fetches server messages and filters relevant ones
  /// Returns null if no messages or error, MessageInfo if message is available
  static Future<MessageInfo?> checkForMessages({
    bool forceFetch = false,
  }) async {
    try {
      // Check cooldown unless force fetch is requested
      if (!forceFetch && _lastRequestTime != null) {
        final timeSinceLastRequest = DateTime.now().difference(
          _lastRequestTime!,
        );
        if (timeSinceLastRequest < _requestCooldown) {
          return null;
        }
      }

      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      // Fetch messages from a list of URLs with fallback
      final messages = await _getServerMessages(currentVersion);
      _lastRequestTime = DateTime.now();

      if (messages == null || messages.isEmpty) {
        return null;
      }

      // Process messages and find the most relevant one
      final relevantMessage = await _processMessages(messages, currentVersion);
      return relevantMessage;
    } catch (e) {
      _lastRequestTime = DateTime.now();
      return null;
    }
  }

  /// Fetches messages from a specific base URL
  static Future<List<dynamic>?> _getServerMessages(String version) async {
    for (final baseUrl in baseUrls) {
      try {
        // Construct version-specific messages URL
        final messagesUrl = '$baseUrl/$version/messages.json';
        final uri = Uri.parse(messagesUrl);
        final response = await http
            .get(
              uri,
              headers: {
                'Accept': 'application/json',
                'User-Agent': 'shots_studio_app',
                'Content-Type': 'application/json',
              },
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          // Expect an object with a "messages" array
          if (data is Map<String, dynamic> && data.containsKey('messages')) {
            return data['messages'] as List<dynamic>;
          } else if (data is List) {
            // Fallback: direct array format
            return data;
          }

          return null;
        } else if (response.statusCode == 404) {
          // If version-specific messages don't exist, try fallback to general messages.json
          final fallbackMessages = await _getFallbackMessages(baseUrl);
          if (fallbackMessages != null) {
            return fallbackMessages;
          }
        }
      } catch (e) {
        // Continue to the next URL in the list if an error occurs
        LoggerService.error("ServerMessageService: error fetching messages", e);
        continue;
      }
    }
    return null; // Return null if all fallbacks fail
  }

  /// Fallback method to get general messages when version-specific messages don't exist
  static Future<List<dynamic>?> _getFallbackMessages(String baseUrl) async {
    try {
      final fallbackUrl = '$baseUrl.json';
      final uri = Uri.parse(fallbackUrl);

      final response = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'shots_studio_app',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Expect an object with a "messages" array
        if (data is Map<String, dynamic> && data.containsKey('messages')) {
          return data['messages'] as List<dynamic>;
        } else if (data is List) {
          // Fallback: direct array format
          return data;
        }

        return null;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Process messages and return the most relevant one that should be shown
  static Future<MessageInfo?> _processMessages(
    List<dynamic> messages,
    String currentVersion,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    // Check if user has beta testing enabled
    final betaTestingEnabled = prefs.getBool('beta_testing_enabled') ?? false;

    for (final messageData in messages) {
      try {
        final message = MessageInfo.fromJson(messageData);

        // Check if message should be shown
        if (!message.show) continue;

        // Check if message is beta-only and user is not opted into beta
        if (message.betaOnly && !betaTestingEnabled) {
          continue;
        }

        if (!_isPlatformTargeted(message.platform)) {
          continue;
        }

        if (!_isVersionTargeted(message.version, currentVersion)) {
          continue;
        }

        if (message.validUntil != null &&
            DateTime.now().isAfter(message.validUntil!)) {
          continue;
        }

        if (message.showOnce) {
          final hasBeenShown =
              prefs.getBool('message_shown_${message.id}') ?? false;
          if (hasBeenShown) continue;
        }

        return message;
      } catch (e) {
        continue;
      }
    }

    return null;
  }

  static bool _isVersionTargeted(String? targetVersion, String currentVersion) {
    if (targetVersion == null || targetVersion.isEmpty) {
      return true;
    }

    final target = targetVersion.toLowerCase().trim();
    final current = currentVersion.toLowerCase().trim();

    // Special case: "ALL" targets all versions
    if (target == 'all') {
      return true;
    }

    if (target == current) {
      return true;
    }

    // Wildcard matching (e.g., "1.8.*" matches "1.8.75")
    if (target.endsWith('*')) {
      final prefix = target.substring(0, target.length - 1);
      return current.startsWith(prefix);
    }

    // TODO: Version range matching could be added here in the future

    return false;
  }

  static bool _isPlatformTargeted(String? targetPlatform) {
    if (targetPlatform == null || targetPlatform.isEmpty) {
      return true;
    }

    final target = targetPlatform.toLowerCase().trim();
    final current = BuildSource.current.name.toLowerCase();

    // Special case: "ALL" targets all platforms
    if (target == 'all') {
      return true;
    }

    return target == current;
  }

  /// Marks a message as shown so it won't be displayed again (for show_once messages)
  static Future<void> markMessageAsShown(String messageId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('message_shown_$messageId', true);
  }

  /// Test method to simulate server response for development
  static Future<MessageInfo?> getTestMessage() async {
    const testMessageJson = {
      "show": true,
      "id": "msg_2025_06_21_01",
      "title": "New Tagging Feature!",
      "message":
          "You can now organize screenshots into smart collections. Try it out now.",
      "type": "info",
      "priority": "medium",
      "show_once": true,
      "valid_until": "2025-07-01T00:00:00Z",
      "is_notification": false,
      "version": "ALL",
      "beta_only": false,
      "action_text": "Try It Now",
      "dismiss_text": "Maybe Later",
      "action_url": "https://example.com/tagging-guide",
    };

    try {
      return MessageInfo.fromJson(testMessageJson);
    } catch (e) {
      return null;
    }
  }

  /// Test method to simulate an urgent notification message
  static Future<MessageInfo?> getTestNotificationMessage() async {
    const testMessageJson = {
      "show": true,
      "id": "msg_urgent_test_2025_08_03",
      "title": "🔥 Urgent: Test Notification",
      "message":
          "This is a test notification to verify background notifications are working correctly when the app is closed.",
      "type": "warning",
      "priority": "high",
      "show_once": false,
      "valid_until": "2025-12-31T23:59:59Z",
      "is_notification": true,
      "version": "ALL",
      "beta_only": false,
      "action_text": "View Details",
      "dismiss_text": "Not Now",
      "action_url": "https://example.com/notification-test",
      "platform": "github", // Targeting only GitHub build
    };

    try {
      return MessageInfo.fromJson(testMessageJson);
    } catch (e) {
      return null;
    }
  }

  /// Test method to force trigger a server notification immediately
  static Future<bool> triggerTestNotification() async {
    try {
      final message = await getTestNotificationMessage();
      if (message != null) {
        final notificationService = NotificationService();
        await notificationService.showServerMessageImmediate(
          messageId: message.id,
          title: message.title,
          body: message.message,
          isUrgent: message.priority == MessagePriority.high,
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

/// Contains information about a server message
///
/// For URLs, use actionUrl instead of updateRoute (legacy field kept for compatibility).
class MessageInfo {
  final bool show;
  final String id;
  final String title;
  final String message;
  final MessageType type;
  final MessagePriority priority;
  final bool showOnce;
  final DateTime? validUntil;
  final bool isNotification;
  final String? version;
  final String? actionText;
  final String? dismissText;
  final String? actionUrl; // Primary URL field for action button
  final MessageActionType? actionType;
  final String? updateRoute; // Legacy field, use actionUrl instead
  final bool betaOnly;
  final String?
  platform; // New field to specify target platform (github/fdroid/playstore)

  MessageInfo({
    required this.show,
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.showOnce,
    this.validUntil,
    required this.isNotification,
    this.version,
    this.actionText,
    this.dismissText,
    this.actionUrl,
    this.actionType,
    this.updateRoute,
    this.betaOnly = false,
    this.platform,
  });

  factory MessageInfo.fromJson(Map<String, dynamic> json) {
    return MessageInfo(
      show: json['show'] ?? false,
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: _parseMessageType(json['type']),
      priority: _parseMessagePriority(json['priority']),
      showOnce: json['show_once'] ?? true,
      validUntil:
          json['valid_until'] != null
              ? DateTime.tryParse(json['valid_until'])
              : null,
      isNotification: json['is_notification'] ?? false,
      version: json['version']?.toString(),
      actionText: json['action_text']?.toString(),
      dismissText: json['dismiss_text']?.toString(),
      actionUrl: json['action_url']?.toString(),
      actionType: _parseActionType(json['action_type']),
      updateRoute: json['update_route']?.toString(),
      betaOnly: json['beta_only'] ?? false,
      platform: json['platform']?.toString(),
    );
  }

  static MessageType _parseMessageType(dynamic type) {
    switch (type?.toString().toLowerCase()) {
      case 'info':
        return MessageType.info;
      case 'warning':
        return MessageType.warning;
      case 'update':
        return MessageType.update;
      default:
        return MessageType.info;
    }
  }

  static MessagePriority _parseMessagePriority(dynamic priority) {
    switch (priority?.toString().toLowerCase()) {
      case 'low':
        return MessagePriority.low;
      case 'medium':
        return MessagePriority.medium;
      case 'high':
        return MessagePriority.high;
      default:
        return MessagePriority.medium;
    }
  }

  static MessageActionType _parseActionType(dynamic actionType) {
    switch (actionType?.toString().toLowerCase()) {
      case 'url':
        return MessageActionType.url;
      case 'custom':
        return MessageActionType.custom;
      default:
        return MessageActionType.none;
    }
  }

  @override
  String toString() {
    return 'MessageInfo(id: $id, title: $title, type: $type, priority: $priority)';
  }
}

enum MessageType { info, warning, update }

enum MessagePriority { low, medium, high }

enum MessageActionType { url, custom, none }
