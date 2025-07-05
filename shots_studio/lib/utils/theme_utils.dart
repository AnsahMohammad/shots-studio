import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';

class ThemeUtils {
  static ColorScheme createAmoledColorScheme(ColorScheme baseDarkScheme) {
    return baseDarkScheme.copyWith(
      // Primary surfaces - pure black for AMOLED
      surface: Colors.black,
      onSurface: Colors.white,
      onSurfaceVariant: Colors.white70,

      // Surface containers with different levels of darkness
      surfaceContainer: const Color(0xFF0A0A0A),
      surfaceContainerHighest: const Color(0xFF1A1A1A),
      surfaceContainerHigh: const Color(0xFF151515),
      surfaceContainerLow: const Color(0xFF050505),
      surfaceContainerLowest: Colors.black,

      // Inverse colors
      inverseSurface: Colors.white,
      onInverseSurface: Colors.black,

      // Keep original accent colors but ensure they work well on black
      // The primary, secondary, and tertiary colors from Material You should
      // already have good contrast, but we can adjust if needed
    );
  }

  /// Creates the appropriate color schemes based on dynamic colors and AMOLED mode
  static (ColorScheme light, ColorScheme dark) createColorSchemes({
    required ColorScheme? lightDynamic,
    required ColorScheme? darkDynamic,
    required bool amoledModeEnabled,
  }) {
    ColorScheme lightScheme;
    ColorScheme darkScheme;

    if (lightDynamic != null && darkDynamic != null) {
      // Use dynamic colors if available (Material You)
      lightScheme = lightDynamic.harmonized();
      darkScheme = darkDynamic.harmonized();
    } else {
      // Fallback to custom color schemes if dynamic colors are not available
      lightScheme = ColorScheme.fromSeed(
        seedColor: Colors.amber,
        brightness: Brightness.light,
      );
      darkScheme = ColorScheme.fromSeed(
        seedColor: Colors.amber,
        brightness: Brightness.dark,
      );
    }

    // Apply AMOLED mode if enabled
    if (amoledModeEnabled) {
      darkScheme = createAmoledColorScheme(darkScheme);
    }

    return (lightScheme, darkScheme);
  }

  /// Creates a complete ThemeData for light mode
  static ThemeData createLightTheme(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  /// Creates a complete ThemeData for dark mode (including AMOLED if applied to colorScheme)
  static ThemeData createDarkTheme(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
