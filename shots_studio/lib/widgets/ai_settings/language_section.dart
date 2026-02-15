import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';
import 'package:shots_studio/utils/ai_language_config.dart';

/// AI output language selection section.
class LanguageSection extends StatefulWidget {
  final String? initialLanguage;
  final Function(String)? onLanguageChanged;

  const LanguageSection({
    super.key,
    this.initialLanguage,
    this.onLanguageChanged,
  });

  @override
  State<LanguageSection> createState() => _LanguageSectionState();
}

class _LanguageSectionState extends State<LanguageSection> {
  late String _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _selectedLanguage =
        widget.initialLanguage ?? AILanguageConfig.defaultLanguageKey;
    if (widget.initialLanguage == null) {
      _loadLanguagePref();
    }
  }

  Future<void> _loadLanguagePref() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _selectedLanguage =
            prefs.getString(AILanguageConfig.prefKey) ??
            AILanguageConfig.defaultLanguageKey;
      });
    }
  }

  Future<void> _saveLanguageSetting(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AILanguageConfig.prefKey, languageCode);

    // Track language change in analytics
    AnalyticsService().logFeatureUsed(
      'ai_output_language_changed_to_$languageCode',
    );

    widget.onLanguageChanged?.call(languageCode);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 0,
      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.language,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI OUTPUT LANGUAGE (BETA)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Choose the language for AI-generated descriptions. Other fields (title, tags) will remain in English for consistency.',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.5),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedLanguage,
                  isExpanded: true,
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onChanged: (String? newValue) async {
                    if (newValue != null && newValue != _selectedLanguage) {
                      setState(() {
                        _selectedLanguage = newValue;
                      });
                      await _saveLanguageSetting(newValue);
                    }
                  },
                  items:
                      AILanguageConfig.getAllLanguageCodes()
                          .map<DropdownMenuItem<String>>((String code) {
                            return DropdownMenuItem<String>(
                              value: code,
                              child: Row(
                                children: [
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      AILanguageConfig.getLanguageName(code),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          })
                          .toList(),
                ),
              ),
            ),
            if (_selectedLanguage != AILanguageConfig.defaultLanguageKey) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Selected: ${AILanguageConfig.getLanguageName(_selectedLanguage)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
