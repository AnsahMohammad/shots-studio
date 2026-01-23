import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';
import 'package:shots_studio/services/snackbar_service.dart';
import 'package:shots_studio/services/logger_service.dart';

/// Utility class for handling link detection, display, and launching.
/// Supports URLs, emails, and phone numbers.
class LinkUtils {
  /// Detect the type of link and return appropriate icon, color, and action.
  static Map<String, dynamic> getLinkInfo(
    BuildContext context,
    String link,
    void Function(String) launchLinkFn,
    void Function(String) copyToClipboardFn,
  ) {
    final cleanLink = link.trim();

    // Handle links that already have prefixes
    if (cleanLink.startsWith('mailto:')) {
      return {
        'type': 'email',
        'icon': Icons.email,
        'color': Colors.red,
        'action': () => launchLinkFn(cleanLink),
      };
    }

    if (cleanLink.startsWith('tel:')) {
      return {
        'type': 'phone',
        'icon': Icons.phone,
        'color': Colors.green,
        'action': () => launchLinkFn(cleanLink),
      };
    }

    // Email detection (raw email format)
    if (RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(cleanLink)) {
      return {
        'type': 'email',
        'icon': Icons.email,
        'color': Colors.red,
        'action': () => launchLinkFn('mailto:$cleanLink'),
      };
    }

    // Phone number detection (various formats)
    if (RegExp(
      r'^[\+]?[\d\s\-\(\)\.]{7,}$',
    ).hasMatch(cleanLink.replaceAll(' ', ''))) {
      return {
        'type': 'phone',
        'icon': Icons.phone,
        'color': Colors.green,
        'action': () => launchLinkFn('tel:$cleanLink'),
      };
    }

    // URL detection
    if (cleanLink.startsWith('http://') ||
        cleanLink.startsWith('https://') ||
        cleanLink.startsWith('www.') ||
        RegExp(r'^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}').hasMatch(cleanLink)) {
      String url = cleanLink;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }
      return {
        'type': 'url',
        'icon': Icons.link,
        'color': Colors.blue,
        'action': () => launchLinkFn(url),
      };
    }

    // Default fallback
    return {
      'type': 'text',
      'icon': Icons.content_copy,
      'color': Colors.grey,
      'action': () => copyToClipboardFn(cleanLink),
    };
  }

  /// Launch a link (URL, phone, email) or copy to clipboard if it fails.
  static Future<void> launchLink(BuildContext context, String link) async {
    try {
      final uri = Uri.parse(link);

      bool launched = false;
      try {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        LoggerService.error('Direct launch failed', e);
        launched = false;
      }

      if (launched) {
        AnalyticsService().logFeatureUsed('link_launched');
      } else {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
          if (launched) {
            AnalyticsService().logFeatureUsed('link_launched');
            return;
          }
        } catch (e) {
          LoggerService.error('Platform default launch failed', e);
        }

        await copyToClipboard(context, link);
      }
    } catch (e) {
      LoggerService.error('URL parsing failed', e);
      await copyToClipboard(context, link);
    }
  }

  /// Copy text to clipboard with feedback.
  static Future<void> copyToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));

    String displayText = text;

    if (text.startsWith('mailto:')) {
      displayText = text.substring(7); // Remove 'mailto:' prefix
    } else if (text.startsWith('tel:')) {
      displayText = text.substring(4); // Remove 'tel:' prefix
    }

    SnackbarService().showWarning(context, 'Copied to clipboard: $displayText');
    AnalyticsService().logFeatureUsed('link_copied_to_clipboard');
  }

  /// Get clean display text for links by removing prefixes.
  static String getDisplayText(String link) {
    final cleanLink = link.trim();

    if (cleanLink.startsWith('mailto:')) {
      return cleanLink.substring(7); // Remove 'mailto:' prefix
    } else if (cleanLink.startsWith('tel:')) {
      return cleanLink.substring(4); // Remove 'tel:' prefix
    } else if (cleanLink.startsWith('http://')) {
      return cleanLink.substring(7); // Remove 'http://' prefix for display
    } else if (cleanLink.startsWith('https://')) {
      return cleanLink.substring(8); // Remove 'https://' prefix for display
    }

    return cleanLink;
  }
}
