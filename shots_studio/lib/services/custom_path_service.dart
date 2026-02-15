import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shots_studio/services/logger_service.dart';

/// Service for managing custom screenshot directory paths
class CustomPathService {
  static const String _customPathsKey = 'custom_screenshot_paths';

  /// Get all custom screenshot paths
  static Future<List<String>> getCustomPaths() async {
    final prefs = await SharedPreferences.getInstance();
    final String? pathsJson = prefs.getString(_customPathsKey);

    if (pathsJson != null && pathsJson.isNotEmpty) {
      final List<dynamic> pathsList = jsonDecode(pathsJson);
      return List<String>.from(pathsList);
    }

    return [];
  }

  /// Add a new custom path
  static Future<bool> addCustomPath(String path) async {
    if (path.trim().isEmpty) return false;

    final currentPaths = await getCustomPaths();

    // Check if path already exists
    if (currentPaths.contains(path)) {
      return false;
    }

    currentPaths.add(path);
    return await _saveCustomPaths(currentPaths);
  }

  /// Remove a custom path
  static Future<bool> removeCustomPath(String path) async {
    final currentPaths = await getCustomPaths();

    if (currentPaths.remove(path)) {
      return await _saveCustomPaths(currentPaths);
    }

    return false;
  }

  /// Save custom paths to SharedPreferences
  static Future<bool> _saveCustomPaths(List<String> paths) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String pathsJson = jsonEncode(paths);
      return await prefs.setString(_customPathsKey, pathsJson);
    } catch (e) {
      LoggerService.error('Error saving custom paths', e);
      return false;
    }
  }

  /// Clear all custom paths
  static Future<bool> clearAllCustomPaths() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_customPathsKey);
    } catch (e) {
      LoggerService.error('Error clearing custom paths', e);
      return false;
    }
  }

  /// Validate if a directory path exists and is accessible
  static Future<bool> validatePath(String path) async {
    try {
      final directory = Directory(path);
      return await directory.exists();
    } catch (e) {
      LoggerService.error('Error validating path $path', e);
      return false;
    }
  }
}
