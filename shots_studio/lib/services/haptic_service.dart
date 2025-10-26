import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing haptic feedback patterns throughout the app
/// Haptics are only triggered when Enhanced Animations setting is enabled
class HapticService {
  static const String _enhancedAnimationsEnabledPrefKey =
      'enhanced_animations_enabled';
  static bool _enhancedAnimationsEnabled = true;
  static bool _isInitialized = false;

  /// Initialize the haptic service by loading settings
  static Future<void> initialize() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    _enhancedAnimationsEnabled =
        prefs.getBool(_enhancedAnimationsEnabledPrefKey) ?? true;
    _isInitialized = true;
  }

  /// Update the enhanced animations setting
  static void updateEnhancedAnimationsSetting(bool enabled) {
    _enhancedAnimationsEnabled = enabled;
  }

  /// Check if haptics should be triggered
  static bool get _shouldTriggerHaptic => _enhancedAnimationsEnabled;

  // ==================== Haptic Patterns ====================

  /// Light impact - for subtle interactions (e.g., button taps, switches)
  static Future<void> lightImpact() async {
    if (!_shouldTriggerHaptic) return;
    await HapticFeedback.lightImpact();
  }

  /// Medium impact - for standard interactions (e.g., opening menus)
  static Future<void> mediumImpact() async {
    if (!_shouldTriggerHaptic) return;
    await HapticFeedback.mediumImpact();
  }

  /// Heavy impact - for significant actions (e.g., creating items, processing start/stop)
  static Future<void> heavyImpact() async {
    if (!_shouldTriggerHaptic) return;
    await HapticFeedback.heavyImpact();
  }

  /// Selection click - for navigating between items or selections
  static Future<void> selectionClick() async {
    if (!_shouldTriggerHaptic) return;
    await HapticFeedback.selectionClick();
  }

  /// Vibrate - for notifications and alerts
  static Future<void> vibrate() async {
    if (!_shouldTriggerHaptic) return;
    await HapticFeedback.vibrate();
  }

  // ==================== Custom Haptic Patterns ====================

  /// Double tap pattern - two light impacts
  static Future<void> doubleTap() async {
    if (!_shouldTriggerHaptic) return;
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.lightImpact();
  }

  /// Success pattern - light, medium, heavy crescendo
  static Future<void> success() async {
    if (!_shouldTriggerHaptic) return;
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.lightImpact();
  }

  /// Processing start pattern - medium, light
  static Future<void> processingStart() async {
    if (!_shouldTriggerHaptic) return;
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 60));
    await HapticFeedback.lightImpact();
  }

  /// Processing complete pattern - light, medium, heavy
  static Future<void> processingComplete() async {
    if (!_shouldTriggerHaptic) return;
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 40));
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 40));
    await HapticFeedback.heavyImpact();
  }

  /// Error pattern - heavy, light, heavy
  static Future<void> error() async {
    if (!_shouldTriggerHaptic) return;
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.heavyImpact();
  }

  /// Warning pattern - medium, light, medium
  static Future<void> warning() async {
    if (!_shouldTriggerHaptic) return;
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 60));
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 60));
    await HapticFeedback.mediumImpact();
  }

  /// FAB expand pattern - medium impact
  static Future<void> fabExpand() async {
    if (!_shouldTriggerHaptic) return;
    await HapticFeedback.mediumImpact();
  }

  /// FAB action selected pattern - light, medium
  static Future<void> fabActionSelected() async {
    if (!_shouldTriggerHaptic) return;
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 40));
    await HapticFeedback.mediumImpact();
  }

  /// Screenshot capture pattern - quick double impact
  static Future<void> screenshotCapture() async {
    if (!_shouldTriggerHaptic) return;
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 30));
    await HapticFeedback.lightImpact();
  }

  /// Collection created pattern - ascending impacts
  static Future<void> collectionCreated() async {
    if (!_shouldTriggerHaptic) return;
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.mediumImpact();
  }

  /// Delete pattern - descending impacts
  static Future<void> delete() async {
    if (!_shouldTriggerHaptic) return;
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.lightImpact();
  }
}
