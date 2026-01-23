import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shots_studio/services/logger_service.dart';

// TODO: Add don't show again functionality for messages

class UpdateCheckerService {
  static const String githubApiUrl = 'https://api.github.com/repos';
  static const String repoOwner = 'AnsahMohammad';
  static const String repoName = 'shots-studio';

  /// Checks for app updates by comparing current version with latest GitHub release
  /// Returns null if no update available, or UpdateInfo if update is available
  static Future<UpdateInfo?> checkForUpdates() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final prefs = await SharedPreferences.getInstance();
      final bool betaTestingEnabled =
          prefs.getBool('beta_testing_enabled') ?? false;

      // Fetch recent releases from GitHub (up to 3)
      final releases = await _getRecentReleases();
      if (releases.isEmpty) {
        LoggerService.error('No releases found or error fetching them.');
        return null;
      }

      // Find the appropriate release based on beta testing preference
      Map<String, dynamic>? selectedRelease;

      for (final release in releases) {
        final String tagName = release['tag_name'] ?? '';

        final bool isPreRelease =
            tagName.startsWith('a') || tagName.startsWith('b');
        final bool isStableRelease = tagName.startsWith('v');

        // Skip pre-releases if user is not in beta testing
        if (!betaTestingEnabled && isPreRelease) {
          continue;
        }

        // For non-beta users, only consider stable releases
        if (!betaTestingEnabled && !isStableRelease) {
          continue;
        }

        final latestVersion = _extractVersionFromTag(tagName);

        if (latestVersion != null &&
            _isNewerVersion(currentVersion, latestVersion)) {
          selectedRelease = release;
          break;
        }
      }

      // If no suitable release found, return null
      if (selectedRelease == null) {
        return null;
      }

      // Build UpdateInfo from the selected release
      final String tagName = selectedRelease['tag_name'] ?? '';
      final String latestVersion = _extractVersionFromTag(tagName) ?? '';
      final bool isPreRelease =
          tagName.startsWith('a') || tagName.startsWith('b');

      return UpdateInfo(
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        releaseUrl: selectedRelease['html_url'],
        releaseNotes: selectedRelease['body'] ?? '',
        tagName: tagName,
        publishedAt: selectedRelease['published_at'],
        isPreRelease: isPreRelease,
      );
    } catch (e) {
      return null;
    }
  }

  /// Fetches the latest releases from GitHub API (up to 3)
  static Future<List<Map<String, dynamic>>> _getRecentReleases() async {
    try {
      final response = await http
          .get(
            Uri.parse('$githubApiUrl/$repoOwner/$repoName/releases?per_page=3'),
            headers: {
              'Accept': 'application/vnd.github.v3+json',
              'User-Agent': 'shots_studio_app',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> releases =
            json.decode(response.body) as List<dynamic>;
        return releases.cast<Map<String, dynamic>>();
      } else {
        LoggerService.error('GitHub API error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      LoggerService.error('Network error fetching releases', e);
      return [];
    }
  }

  /// Extracts version number from GitHub tag (e.g., "v1.8.52" -> "1.8.52", "a1.8.52" -> "1.8.52")
  static String? _extractVersionFromTag(String tagName) {
    if (tagName.startsWith('v') ||
        tagName.startsWith('a') ||
        tagName.startsWith('b')) {
      return tagName.substring(1);
    }
    return tagName;
  }

  /// Compares two version strings to determine if the new version is newer
  /// Supports semantic versioning format (major.minor.patch)
  static bool isNewerVersion(String current, String latest) {
    return _isNewerVersion(current, latest);
  }

  /// Extracts version number from GitHub tag (e.g., "v1.8.52" -> "1.8.52", "a1.8.52" -> "1.8.52")
  static String? extractVersionFromTag(String tagName) {
    return _extractVersionFromTag(tagName);
  }

  /// Compares two version strings to determine if the new version is newer
  /// Supports semantic versioning format (major.minor.patch)
  static bool _isNewerVersion(String current, String latest) {
    try {
      final currentParts = current.split('.').map(int.parse).toList();
      final latestParts = latest.split('.').map(int.parse).toList();

      // Ensure both versions have the same number of parts by padding with zeros
      while (currentParts.length < latestParts.length) {
        currentParts.add(0);
      }
      while (latestParts.length < currentParts.length) {
        latestParts.add(0);
      }

      // Compare version parts
      for (int i = 0; i < currentParts.length; i++) {
        if (latestParts[i] > currentParts[i]) {
          return true;
        } else if (latestParts[i] < currentParts[i]) {
          return false;
        }
      }

      return false; // Versions are equal
    } catch (e) {
      LoggerService.error('Error comparing versions', e);
      return false;
    }
  }
}

/// Contains information about an available app update
class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String releaseUrl;
  final String releaseNotes;
  final String tagName;
  final String publishedAt;
  final bool isPreRelease;

  UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseUrl,
    required this.releaseNotes,
    required this.tagName,
    required this.publishedAt,
    required this.isPreRelease,
  });

  @override
  String toString() {
    return 'UpdateInfo(current: $currentVersion, latest: $latestVersion, preRelease: $isPreRelease)';
  }
}
