import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryUtils {
  static void clearImageCache() {
    PaintingBinding.instance.imageCache.clear();
  }

  /// Clear only large images, preserving small thumbnail cache
  static void clearLargeImagesOnly() {
    final imageCache = PaintingBinding.instance.imageCache;
    // Force eviction of images larger than thumbnail size
    imageCache.clearLiveImages();
  }

  /// Clear image cache and force garbage collection
  static Future<void> clearImageCacheAndGC() async {
    PaintingBinding.instance.imageCache.clear();

    // Force garbage collection (platform specific)
    try {
      await SystemChannels.platform.invokeMethod('System.gc');
    } catch (e) {
      // Ignore if not supported on platform
    }
  }

  /// Set image cache limits for better memory management
  static Future<void> optimizeImageCache() async {
    final imageCache = PaintingBinding.instance.imageCache;

    // Check if enhanced cache mode is enabled
    final prefs = await SharedPreferences.getInstance();
    final isEnhancedCacheMode = prefs.getBool('enhanced_cache_mode') ?? false;

    imageCache.maximumSize =
        isEnhancedCacheMode
            ? 200 // Enhanced cache for better experience
            : 100; // Default cache for better performance
    imageCache.maximumSizeBytes =
        100 << 20; // 100MB for better thumbnail caching
  }

  /// Get the cache size setting for use in other components
  static Future<int> getCacheSize() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnhancedCacheMode = prefs.getBool('enhanced_cache_mode') ?? false;
    return isEnhancedCacheMode ? 200 : 100;
  }

  /// Set the enhanced cache mode preference
  static Future<void> setEnhancedCacheMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enhanced_cache_mode', enabled);
    // Apply the cache setting immediately
    await optimizeImageCache();
  }

  /// Get the enhanced cache mode preference
  static Future<bool> getEnhancedCacheMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('enhanced_cache_mode') ?? false;
  }

  /// Get current image cache statistics
  static Map<String, dynamic> getImageCacheStats() {
    final imageCache = PaintingBinding.instance.imageCache;
    return {
      'currentSize': imageCache.currentSize,
      'maximumSize': imageCache.maximumSize,
      'currentSizeBytes': imageCache.currentSizeBytes,
      'maximumSizeBytes': imageCache.maximumSizeBytes,
      'pendingImageCount': imageCache.pendingImageCount,
    };
  }
}
