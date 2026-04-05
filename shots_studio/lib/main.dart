import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shots_studio/l10n/app_localizations.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shots_studio/services/notification_service.dart';
import 'package:shots_studio/utils/memory_utils.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';
import 'package:shots_studio/utils/theme_utils.dart';
import 'package:shots_studio/utils/theme_manager.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shots_studio/utils/display_utils.dart';
import 'package:shots_studio/services/haptic_service.dart';
import 'package:shots_studio/screens/home_screen.dart';

void main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://6f96d22977b283fc325e038ac45e6e5e@o4509484018958336.ingest.us.sentry.io/4509484020072448';

      options.tracesSampleRate =
          kDebugMode ? 0 : 0.1; // 30% in debug, 10% in production
    },
    appRunner: () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize haptic feedback service
      await HapticService.initialize();

      // Initialize display refresh rate detection and optimization
      await DisplayUtils.initializeHighRefreshRate();

      // Initialize Analytics
      await AnalyticsService().initialize();

      // Optimize image cache for better memory management
      await MemoryUtils.optimizeImageCache();

      // Initialize Notification Service and channels
      await NotificationService().init();

      // Background service notification channel is now set up in NotificationService.init()

      runApp(SentryWidget(child: const MyApp()));
    },
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _amoledModeEnabled = false;
  String _selectedTheme = 'Adaptive Theme';
  Locale _selectedLocale = const Locale('en'); // Default to English

  @override
  void initState() {
    super.initState();
    _loadThemeSettings();
    _loadLocaleSettings();
  }

  Future<void> _loadThemeSettings() async {
    final amoledMode = await ThemeManager.getAmoledMode();
    final selectedTheme = await ThemeManager.getSelectedTheme();
    setState(() {
      _amoledModeEnabled = amoledMode;
      _selectedTheme = selectedTheme;
    });
  }

  Future<void> _loadLocaleSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('selected_language') ?? 'en';

    // Parse the stored locale string (handles cases like 'zh_CN' or 'en')
    final parts = languageCode.split('_');
    Locale locale;
    if (parts.length == 2) {
      locale = Locale(parts[0], parts[1]);
    } else {
      locale = Locale(languageCode);
    }

    setState(() {
      _selectedLocale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final (lightScheme, darkScheme) = ThemeManager.createColorSchemes(
          lightDynamic: lightDynamic,
          darkDynamic: darkDynamic,
          selectedTheme: _selectedTheme,
          amoledModeEnabled: _amoledModeEnabled,
        );

        return MaterialApp(
          title: 'Shots Studio',
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'), // English
            Locale('hi'), // Hindi
            Locale('de'), // German
            Locale('zh'), // Chinese (Generic)
            Locale('zh', 'CN'), // Chinese (Simplified)
            Locale('zh', 'TW'), // Chinese (Traditional)
            Locale('pt'), // Portuguese
            Locale('ar'), // Arabic
            Locale('es'), // Spanish
            Locale('fr'), // French
            Locale('it'), // Italian
            Locale('ja'), // Japanese
            Locale('pl'), // Polish
            Locale('ro'), // Romanian
            Locale('ru'), // Russian
          ],
          locale: _selectedLocale, // Use the selected locale
          theme: ThemeUtils.createLightTheme(lightScheme),
          darkTheme: ThemeUtils.createDarkTheme(darkScheme),
          themeMode:
              ThemeMode.system, // Automatically switch between light and dark
          home: HomeScreen(
            onAmoledModeChanged: (enabled) async {
              await ThemeManager.setAmoledMode(enabled);
              setState(() {
                _amoledModeEnabled = enabled;
              });
            },
            onThemeChanged: (themeName) async {
              await ThemeManager.setSelectedTheme(themeName);
              setState(() {
                _selectedTheme = themeName;
              });
            },
            onLocaleChanged: (locale) async {
              final prefs = await SharedPreferences.getInstance();
              // Save the full locale string including country code (e.g., 'zh_CN')
              await prefs.setString('selected_language', locale.toString());
              setState(() {
                _selectedLocale = locale;
              });
            },
          ),
        );
      },
    );
  }
}
