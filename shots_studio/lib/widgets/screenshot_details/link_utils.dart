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

    // Calendar event links (calendar:TITLE|START|END|LOCATION)
    if (cleanLink.startsWith('calendar:')) {
      return {
        'type': 'calendar',
        'icon': Icons.calendar_month,
        'color': Colors.teal,
        'action': () {
          final calendarUrl = _buildGoogleCalendarUrl(cleanLink);
          if (calendarUrl != null) {
            launchLinkFn(calendarUrl);
          }
        },
      };
    }

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

    // Google Maps URL detection
    if (cleanLink.contains('google.com/maps') ||
        cleanLink.contains('maps.google.com') ||
        cleanLink.contains('goo.gl/maps')) {
      String url = cleanLink;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }
      return {
        'type': 'maps',
        'icon': Icons.location_on,
        'color': Colors.orange,
        'action': () => launchLinkFn(url),
      };
    }

    // Flight tracking URL detection
    if (cleanLink.contains('flight+status') ||
        cleanLink.contains('flight%20status')) {
      String url = cleanLink;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }
      return {
        'type': 'flight',
        'icon': Icons.flight,
        'color': Colors.indigo,
        'action': () => launchLinkFn(url),
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

    // Calendar links: show event title
    if (cleanLink.startsWith('calendar:')) {
      final data = cleanLink.substring(9); // Remove 'calendar:'
      final parts = data.split('|');
      final title = parts.isNotEmpty ? parts[0].trim() : 'Event';
      return 'Add to Calendar: $title';
    }

    if (cleanLink.startsWith('mailto:')) {
      return cleanLink.substring(7); // Remove 'mailto:' prefix
    } else if (cleanLink.startsWith('tel:')) {
      return cleanLink.substring(4); // Remove 'tel:' prefix
    } else if (cleanLink.startsWith('http://') ||
        cleanLink.startsWith('https://')) {
      final url =
          cleanLink.startsWith('http://')
              ? cleanLink.substring(7)
              : cleanLink.substring(8);

      // Google Maps links: show friendly text
      if (url.contains('google.com/maps/search/')) {
        final searchTerm = Uri.decodeFull(
          url.split('google.com/maps/search/').last.split('?').first,
        );
        return searchTerm;
      }

      // Flight tracking links: show flight number
      if (url.contains('google.com/search?q=') &&
          (url.contains('flight+status') || url.contains('flight%20status'))) {
        final query = Uri.decodeFull(
          url.split('q=').last.split('&').first,
        ).replaceAll('+', ' ').replaceAll(' flight status', '');
        return query;
      }

      return url; // Remove protocol prefix for display
    }

    return cleanLink;
  }

  /// Build a Google Calendar URL from a calendar: link.
  /// Format: calendar:TITLE|YYYYMMDDTHHMMSS|YYYYMMDDTHHMMSS|LOCATION
  static String? _buildGoogleCalendarUrl(String calendarLink) {
    try {
      final data = calendarLink.substring(9); // Remove 'calendar:'
      final parts = data.split('|');

      if (parts.length < 2) return null;

      final title = parts[0].trim();
      final startDate = parts[1].trim();
      final endDate = parts.length > 2 ? parts[2].trim() : startDate;
      final location = parts.length > 3 ? parts[3].trim() : '';

      final params = {
        'action': 'TEMPLATE',
        'text': title,
        'dates': '$startDate/$endDate',
        if (location.isNotEmpty) 'location': location,
      };

      final uri = Uri.https('calendar.google.com', '/calendar/render', params);

      return uri.toString();
    } catch (e) {
      LoggerService.error('Error building calendar URL', e);
      return null;
    }
  }
}
