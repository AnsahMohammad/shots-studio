import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'update_checker_service.dart';
import 'package:shots_studio/utils/build_source.dart';

/// Progress callback type for download progress
typedef ProgressCallback = void Function(double progress, String status);

/// Service for downloading and installing app updates
class UpdateInstallerService {
  static const MethodChannel _channel = MethodChannel('update_installer');

  /// Downloads and installs an update
  static Future<bool> downloadAndInstall({
    required UpdateInfo updateInfo,
    ProgressCallback? onProgress,
  }) async {
    try {
      onProgress?.call(0.0, 'Checking permissions...');

      // Check and request install permission
      if (!await _checkInstallPermission()) {
        onProgress?.call(0.0, 'Requesting install permission...');
        if (!await _requestInstallPermission()) {
          throw Exception('Install permission denied');
        }
      }

      onProgress?.call(0.1, 'Finding APK download URL...');

      // Get the APK download URL from the release
      final apkUrl = await _getApkDownloadUrl(updateInfo);
      if (apkUrl == null) {
        throw Exception('No APK file found in release');
      }

      onProgress?.call(0.2, 'Starting download...');

      // Download the APK file
      final apkFile = await _downloadApk(
        apkUrl,
        updateInfo.latestVersion,
        (progress) =>
            onProgress?.call(0.2 + (progress * 0.7), 'Downloading update...'),
      );

      onProgress?.call(0.9, 'Installing update...');

      // Install the APK
      await _installApk(apkFile.path);

      onProgress?.call(1.0, 'Installation complete!');

      return true;
    } catch (e) {
      onProgress?.call(0.0, 'Error: $e');
      rethrow;
    }
  }

  /// Checks if the app has permission to install unknown apps
  static Future<bool> _checkInstallPermission() async {
    if (Platform.isAndroid) {
      try {
        final buildSource = BuildSource.current;
        if (!buildSource.allowsInAppUpdates) {
          print(
            'MainApp: In-App update disabled for ${buildSource.displayName} builds',
          );
          return false;
        }

        final bool? result = await _channel.invokeMethod(
          'canRequestPackageInstalls',
        );
        return result ?? false;
      } catch (e) {
        // Fallback to permission_handler for older Android versions
        try {
          final status = await Permission.requestInstallPackages.status;
          return status.isGranted;
        } catch (permissionError) {
          // Permission might not be declared in manifest
          return false;
        }
      }
    }
    return false;
  }

  /// Requests permission to install unknown apps
  static Future<bool> _requestInstallPermission() async {
    if (Platform.isAndroid) {
      try {
        final buildSource = BuildSource.current;
        if (!buildSource.allowsInAppUpdates) {
          print(
            'MainApp: In-App update disabled for ${buildSource.displayName} builds',
          );
          return false;
        }

        final bool? result = await _channel.invokeMethod(
          'requestInstallPermission',
        );
        return result ?? false;
      } catch (e) {
        // Fallback to permission_handler
        try {
          final status = await Permission.requestInstallPackages.request();
          return status.isGranted;
        } catch (permissionError) {
          // Permission might not be declared in manifest
          return false;
        }
      }
    }
    return false;
  }

  /// Gets the APK download URL from the GitHub release
  static Future<String?> _getApkDownloadUrl(UpdateInfo updateInfo) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              'https://api.github.com/repos/AnsahMohammad/shots-studio/releases/tags/${updateInfo.tagName}',
            ),
            headers: {
              'Accept': 'application/vnd.github.v3+json',
              'User-Agent': 'shots_studio_app',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> release = json.decode(response.body);
        final List<dynamic> assets = release['assets'] ?? [];

        // Look for APK file in assets
        for (final asset in assets) {
          final String name = asset['name'] ?? '';
          final String downloadUrl = asset['browser_download_url'] ?? '';

          if (name.toLowerCase().endsWith('.apk') && downloadUrl.isNotEmpty) {
            return downloadUrl;
          }
        }
      }

      return null;
    } catch (e) {
      print('Error getting APK download URL: $e');
      return null;
    }
  }

  /// Downloads the APK file with progress tracking
  static Future<File> _downloadApk(
    String url,
    String version,
    void Function(double progress)? onProgress,
  ) async {
    final client = http.Client();

    try {
      // Get app directory for storing the APK
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName = 'shots_studio_v$version.apk';
      final File apkFile = File('${tempDir.path}/$fileName');

      // Delete existing file if it exists
      if (await apkFile.exists()) {
        await apkFile.delete();
      }

      // Start streaming download
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Failed to download APK: ${response.statusCode}');
      }

      final int totalBytes = response.contentLength ?? 0;
      int downloadedBytes = 0;

      final sink = apkFile.openWrite();

      await response.stream.listen((List<int> chunk) {
        downloadedBytes += chunk.length;
        sink.add(chunk);

        if (totalBytes > 0) {
          final progress = downloadedBytes / totalBytes;
          onProgress?.call(progress);
        }
      }).asFuture();

      await sink.close();

      // Verify file was downloaded completely
      if (totalBytes > 0) {
        final actualSize = await apkFile.length();
        if (actualSize != totalBytes) {
          throw Exception(
            'Download incomplete: expected $totalBytes bytes, got $actualSize bytes',
          );
        }
      }

      return apkFile;
    } finally {
      client.close();
    }
  }

  /// Installs the APK file
  static Future<void> _installApk(String apkPath) async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('installApk', {'apkPath': apkPath});
      } catch (e) {
        throw Exception('Failed to install APK: $e');
      }
    } else {
      throw Exception('APK installation is only supported on Android');
    }
  }

  /// Checks if the device supports automatic updates
  static Future<bool> isUpdateSupportedOnPlatform() async {
    if (!Platform.isAndroid) return false;

    final buildSource = BuildSource.current;
    if (!buildSource.allowsInAppUpdates) {
      print(
        'MainApp: In-App update disabled for ${buildSource.displayName} builds',
      );
      return false;
    }
    return true;
  }

  /// Gets estimated download size for the update
  static Future<int?> getUpdateSize(UpdateInfo updateInfo) async {
    try {
      final apkUrl = await _getApkDownloadUrl(updateInfo);
      if (apkUrl == null) return null;

      final response = await http.head(Uri.parse(apkUrl));
      if (response.statusCode == 200) {
        final contentLength = response.headers['content-length'];
        return contentLength != null ? int.tryParse(contentLength) : null;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Formats file size in human readable format
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Deletes all downloaded APK files from temporary directory
  /// This should be called when no update is available to clean up old downloads
  static Future<void> deleteDownloadedApks() async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final List<FileSystemEntity> files = tempDir.listSync();

      int deletedCount = 0;
      for (final file in files) {
        if (file is File && file.path.toLowerCase().endsWith('.apk')) {
          try {
            await file.delete();
            deletedCount++;
            print('Deleted APK: ${file.path}');
          } catch (e) {
            print('Failed to delete APK ${file.path}: $e');
          }
        }
      }

      if (deletedCount > 0) {
        print('Cleaned up $deletedCount downloaded APK file(s)');
      } else {
        print('No downloaded APK files found to clean up');
      }
    } catch (e) {
      print('Error cleaning up downloaded APKs: $e');
    }
  }
}
