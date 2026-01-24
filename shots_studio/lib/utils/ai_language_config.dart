import 'package:shared_preferences/shared_preferences.dart';

/// Configuration for AI output languages
class AILanguageConfig {
  static const String defaultLanguageKey = 'default';
  static const String prefKey = 'ai_output_language';

  /// Map of language codes to their display names
  static const Map<String, String> supportedLanguages = {
    defaultLanguageKey: 'App Language (Default)',
    'en': 'English',
    'hi': 'हिंदी (Hindi)',
    'de': 'Deutsch (German)',
    'zh': '中文 (Chinese - Legacy)',
    'zh-CN': 'Chinese Simplified (简体中文)',
    'zh-TW': 'Chinese Traditional (繁體中文)',
    'pt': 'Português (Portuguese)',
    'ar': 'العربية (Arabic)',
    'es': 'Español (Spanish)',
    'fr': 'Français (French)',
    'it': 'Italiano (Italian)',
    'ja': '日本語 (Japanese)',
    'ru': 'Русский (Russian)',
    'ko': '한국어 (Korean)',
    'tr': 'Türkçe (Turkish)',
    'nl': 'Nederlands (Dutch)',
    'sv': 'Svenska (Swedish)',
    'no': 'Norsk (Norwegian)',
    'da': 'Dansk (Danish)',
    'fi': 'Suomi (Finnish)',
    'pl': 'Polski (Polish)',
    'cs': 'Čeština (Czech)',
    'sk': 'Slovenčina (Slovak)',
    'hu': 'Magyar (Hungarian)',
    'ro': 'Română (Romanian)',
    'bg': 'Български (Bulgarian)',
    'hr': 'Hrvatski (Croatian)',
    'sr': 'Српски (Serbian)',
    'sl': 'Slovenščina (Slovenian)',
    'et': 'Eesti (Estonian)',
    'lv': 'Latviešu (Latvian)',
    'lt': 'Lietuvių (Lithuanian)',
    'uk': 'Українська (Ukrainian)',
    'be': 'Беларуская (Belarusian)',
    'mk': 'Македонски (Macedonian)',
    'sq': 'Shqip (Albanian)',
    'mt': 'Malti (Maltese)',
    'ga': 'Gaeilge (Irish)',
    'cy': 'Cymraeg (Welsh)',
    'is': 'Íslenska (Icelandic)',
    'fo': 'Føroyskt (Faroese)',
    'eu': 'Euskera (Basque)',
    'ca': 'Català (Catalan)',
    'gl': 'Galego (Galician)',
    'th': 'ไทย (Thai)',
    'vi': 'Tiếng Việt (Vietnamese)',
    'id': 'Bahasa Indonesia (Indonesian)',
    'ms': 'Bahasa Melayu (Malay)',
    'tl': 'Filipino (Tagalog)',
    'sw': 'Kiswahili (Swahili)',
    'zu': 'isiZulu (Zulu)',
    'xh': 'isiXhosa (Xhosa)',
    'af': 'Afrikaans',
    'am': 'አማርኛ (Amharic)',
    'fa': 'فارسی (Persian)',
    'ur': 'اردو (Urdu)',
    'bn': 'বাংলা (Bengali)',
    'gu': 'ગુજરાતી (Gujarati)',
    'kn': 'ಕನ್ನಡ (Kannada)',
    'ml': 'മലയാളം (Malayalam)',
    'mr': 'मराठी (Marathi)',
    'ne': 'नेपाली (Nepali)',
    'or': 'ଓଡ଼ିଆ (Odia)',
    'pa': 'ਪੰਜਾਬੀ (Punjabi)',
    'si': 'සිංහල (Sinhala)',
    'ta': 'தமிழ் (Tamil)',
    'te': 'తెలుగు (Telugu)',
  };

  /// Get the language name for display
  static String getLanguageName(String languageCode) {
    return supportedLanguages[languageCode] ?? 'Unknown Language';
  }

  /// Get all language codes
  static List<String> getAllLanguageCodes() {
    return supportedLanguages.keys.toList();
  }

  /// Check if a language code is supported
  static bool isLanguageSupported(String languageCode) {
    return supportedLanguages.containsKey(languageCode);
  }

  /// Get the language instruction for AI prompt
  static Future<String> getLanguageInstruction(String languageCode) async {
    String actualLanguageCode = languageCode;

    // If using default (App Language), get the app's selected language
    if (languageCode == defaultLanguageKey || languageCode.isEmpty) {
      try {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        actualLanguageCode = prefs.getString('selected_language') ?? 'en';
      } catch (e) {
        // Fallback to English if there's an error
        actualLanguageCode = 'en';
      }
    }

    if (actualLanguageCode == 'en') {
      return '';
    }

    final languageName = getLanguageName(actualLanguageCode);
    return 'Please provide the title (title field) and description (desc field) in $languageName language. Keep the title, tags, collections, and other fields in English for consistency.';
  }
}
