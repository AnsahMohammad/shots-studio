import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';
import 'package:shots_studio/utils/theme_manager.dart';
import 'package:shots_studio/l10n/app_localizations.dart';

class SettingsSection extends StatefulWidget {
  final String? currentApiKey;
  final String currentModelName;
  final Function(String) onApiKeyChanged;
  final Function(String) onModelChanged;
  final Key? apiKeyFieldKey;
  final bool? currentAutoProcessEnabled;
  final Function(bool)? onAutoProcessEnabledChanged;
  final bool? currentAmoledModeEnabled;
  final Function(bool)? onAmoledModeChanged;
  final String? currentSelectedTheme;
  final Function(String)? onThemeChanged;
  final bool? currentDevMode;
  final Function(bool)? onDevModeChanged;
  final bool? currentHardDeleteEnabled;
  final Function(bool)? onHardDeleteChanged;
  final Function(Locale)? onLocaleChanged;

  const SettingsSection({
    super.key,
    this.currentApiKey,
    required this.currentModelName,
    required this.onApiKeyChanged,
    required this.onModelChanged,
    this.apiKeyFieldKey,
    this.currentAutoProcessEnabled,
    this.onAutoProcessEnabledChanged,
    this.currentAmoledModeEnabled,
    this.onAmoledModeChanged,
    this.currentSelectedTheme,
    this.onThemeChanged,
    this.currentDevMode,
    this.onDevModeChanged,
    this.currentHardDeleteEnabled,
    this.onHardDeleteChanged,
    this.onLocaleChanged,
  });

  @override
  State<SettingsSection> createState() => _SettingsSectionState();
}

class _SettingsSectionState extends State<SettingsSection> {
  final FocusNode _apiKeyFocusNode = FocusNode();
  bool _autoProcessEnabled = true;
  bool _amoledModeEnabled = false;
  String _selectedTheme = 'Adaptive Theme';
  bool _devMode = false;
  bool _hardDeleteEnabled = false;
  bool _safeDeleteEnabled = true;
  String _selectedLanguage = 'en'; // Default to English

  static const String _autoProcessEnabledPrefKey = 'auto_process_enabled';
  static const String _amoledModeEnabledPrefKey = 'amoled_mode_enabled';
  static const String _devModePrefKey = 'dev_mode';
  static const String _hardDeleteEnabledPrefKey = 'hard_delete_enabled';
  static const String _selectedLanguagePrefKey = 'selected_language';

  @override
  void initState() {
    super.initState();

    // Track when settings are viewed
    AnalyticsService().logScreenView('settings_section');
    AnalyticsService().logFeatureUsed('view_settings');

    // Initialize auto-processing state
    if (widget.currentAutoProcessEnabled != null) {
      _autoProcessEnabled = widget.currentAutoProcessEnabled!;
    } else {
      _loadAutoProcessEnabledPref();
    }

    // Initialize AMOLED mode state
    if (widget.currentAmoledModeEnabled != null) {
      _amoledModeEnabled = widget.currentAmoledModeEnabled!;
    } else {
      _loadAmoledModeEnabledPref();
    }

    // Initialize theme selection
    if (widget.currentSelectedTheme != null) {
      _selectedTheme = widget.currentSelectedTheme!;
    } else {
      _loadThemePref();
    }

    // Initialize dev mode state
    if (widget.currentDevMode != null) {
      _devMode = widget.currentDevMode!;
    } else {
      _loadDevModePref();
    }

    // Initialize hard delete state
    if (widget.currentHardDeleteEnabled != null) {
      _hardDeleteEnabled = widget.currentHardDeleteEnabled!;
      _safeDeleteEnabled =
          !_hardDeleteEnabled; // Safe delete is opposite of hard delete
    } else {
      _loadHardDeleteEnabledPref();
    }

    // Initialize language selection
    _loadLanguagePref();
  }

  void _loadAutoProcessEnabledPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _autoProcessEnabled = prefs.getBool(_autoProcessEnabledPrefKey) ?? true;
      });
    }
  }

  void _loadAmoledModeEnabledPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _amoledModeEnabled = prefs.getBool(_amoledModeEnabledPrefKey) ?? false;
      });
    }
  }

  void _loadThemePref() async {
    final selectedTheme = await ThemeManager.getSelectedTheme();
    if (mounted) {
      setState(() {
        _selectedTheme = selectedTheme;
      });
    }
  }

  void _loadDevModePref() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _devMode = prefs.getBool(_devModePrefKey) ?? false;
      });
    }
  }

  void _loadHardDeleteEnabledPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _hardDeleteEnabled = prefs.getBool(_hardDeleteEnabledPrefKey) ?? false;
        _safeDeleteEnabled =
            !_hardDeleteEnabled; // Safe delete is opposite of hard delete
      });
    }
  }

  void _loadLanguagePref() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _selectedLanguage = prefs.getString(_selectedLanguagePrefKey) ?? 'en';
      });
    }
  }

  @override
  void didUpdateWidget(covariant SettingsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentAutoProcessEnabled !=
            oldWidget.currentAutoProcessEnabled &&
        widget.currentAutoProcessEnabled != null) {
      _autoProcessEnabled = widget.currentAutoProcessEnabled!;
    }
    if (widget.currentAmoledModeEnabled != oldWidget.currentAmoledModeEnabled &&
        widget.currentAmoledModeEnabled != null) {
      _amoledModeEnabled = widget.currentAmoledModeEnabled!;
    }
    if (widget.currentSelectedTheme != oldWidget.currentSelectedTheme) {
      _selectedTheme = widget.currentSelectedTheme ?? 'Adaptive Theme';
    }
    if (widget.currentDevMode != oldWidget.currentDevMode &&
        widget.currentDevMode != null) {
      _devMode = widget.currentDevMode!;
    }
    if (widget.currentHardDeleteEnabled != oldWidget.currentHardDeleteEnabled &&
        widget.currentHardDeleteEnabled != null) {
      _hardDeleteEnabled = widget.currentHardDeleteEnabled!;
      _safeDeleteEnabled =
          !_hardDeleteEnabled; // Safe delete is opposite of hard delete
    }
  }

  Future<void> _saveAutoProcessEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoProcessEnabledPrefKey, value);
  }

  Future<void> _saveAmoledModeEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_amoledModeEnabledPrefKey, value);
  }

  Future<void> _saveSelectedTheme(String value) async {
    await ThemeManager.setSelectedTheme(value);
  }

  Future<void> _saveDevMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_devModePrefKey, value);
  }

  Future<void> _saveHardDeleteEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hardDeleteEnabledPrefKey, value);
  }

  Future<void> _saveSelectedLanguage(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedLanguagePrefKey, value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            AppLocalizations.of(context)?.settings ?? 'Settings',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        SwitchListTile(
          secondary: Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
          title: Text(
            AppLocalizations.of(context)?.autoProcessing ??
                'Auto-Process Screenshots',
            style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
          ),
          subtitle: Text(
            _autoProcessEnabled
                ? AppLocalizations.of(context)?.autoProcessingDescription ??
                    'Screenshots will be automatically processed when added'
                : AppLocalizations.of(context)?.manualProcessingOnly ??
                    'Manual processing only',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          value: _autoProcessEnabled,
          activeThumbColor: theme.colorScheme.primary,
          onChanged: (bool value) {
            setState(() {
              _autoProcessEnabled = value;
            });
            _saveAutoProcessEnabled(value);

            // Track settings change in analytics
            AnalyticsService().logFeatureUsed('setting_changed_auto_process');
            AnalyticsService().logFeatureAdopted(
              value ? 'auto_process_enabled' : 'auto_process_disabled',
            );

            if (widget.onAutoProcessEnabledChanged != null) {
              widget.onAutoProcessEnabledChanged!(value);
            }
          },
        ),
        SwitchListTile(
          secondary: Icon(
            Icons.nightlight_round,
            color: theme.colorScheme.primary,
          ),
          title: Text(
            AppLocalizations.of(context)?.amoledMode ?? 'AMOLED Mode',
            style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
          ),
          subtitle: Text(
            _amoledModeEnabled
                ? AppLocalizations.of(context)?.amoledModeDescription ??
                    'Dark theme optimized for AMOLED screens'
                : AppLocalizations.of(context)?.defaultDarkTheme ??
                    'Default dark theme',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          value: _amoledModeEnabled,
          activeThumbColor: theme.colorScheme.primary,
          onChanged: (bool value) {
            setState(() {
              _amoledModeEnabled = value;
            });
            _saveAmoledModeEnabled(value);

            // Track settings change in analytics
            AnalyticsService().logFeatureUsed('setting_changed_amoled_mode');
            AnalyticsService().logFeatureAdopted(
              value ? 'amoled_mode_enabled' : 'amoled_mode_disabled',
            );

            if (widget.onAmoledModeChanged != null) {
              widget.onAmoledModeChanged!(value);
            }
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Icon(Icons.palette, color: theme.colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme Color',
                      style: TextStyle(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButton<String>(
                      value: _selectedTheme,
                      dropdownColor: theme.colorScheme.secondaryContainer,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                      style: TextStyle(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                      underline: SizedBox.shrink(),
                      isExpanded: true,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedTheme = newValue;
                          });
                          widget.onThemeChanged?.call(newValue);
                          _saveSelectedTheme(newValue);

                          // Track theme change in analytics
                          AnalyticsService().logFeatureUsed(
                            'setting_changed_theme',
                          );
                          AnalyticsService().logFeatureAdopted(
                            'theme_${newValue.replaceAll(' ', '_').toLowerCase()}',
                          );
                        }
                      },
                      items:
                          ThemeManager.getAvailableThemes()
                              .map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: ThemeManager.getThemeColor(
                                            value,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        value,
                                        style: TextStyle(
                                          color:
                                              theme
                                                  .colorScheme
                                                  .onSecondaryContainer,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                );
                              })
                              .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Icon(Icons.language, color: theme.colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)?.language ?? 'Language',
                      style: TextStyle(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButton<String>(
                      value: _selectedLanguage,
                      dropdownColor: theme.colorScheme.secondaryContainer,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                      style: TextStyle(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                      underline: SizedBox.shrink(),
                      isExpanded: true,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedLanguage = newValue;
                          });
                          _saveSelectedLanguage(newValue);

                          // Track language change in analytics
                          AnalyticsService().logFeatureUsed(
                            'setting_changed_language',
                          );
                          AnalyticsService().logFeatureAdopted(
                            'language_$newValue',
                          );

                          // Trigger locale change callback if provided
                          if (widget.onLocaleChanged != null) {
                            widget.onLocaleChanged!(Locale(newValue));
                          }
                        }
                      },
                      items: [
                        DropdownMenuItem(
                          value: 'en',
                          child: Row(
                            children: [SizedBox(width: 8), Text('English')],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'hi',
                          child: Row(
                            children: [
                              SizedBox(width: 8),
                              Text('हिंदी (Hindi)'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'de',
                          child: Row(
                            children: [
                              SizedBox(width: 8),
                              Text('Deutsch (German)'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'zh',
                          child: Row(
                            children: [
                              SizedBox(width: 8),
                              Text('中文 (Chinese)'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'pt',
                          child: Row(
                            children: [
                              SizedBox(width: 8),
                              Text('Português (Portuguese)'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'ar',
                          child: Row(
                            children: [
                              SizedBox(width: 8),
                              Text('العربية (Arabic)'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'es',
                          child: Row(
                            children: [
                              SizedBox(width: 8),
                              Text('Español (Spanish)'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'fr',
                          child: Row(
                            children: [
                              SizedBox(width: 8),
                              Text('Français (French)'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'it',
                          child: Row(
                            children: [
                              SizedBox(width: 8),
                              Text('Italiano (Italian)'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'ja',
                          child: Row(
                            children: [
                              SizedBox(width: 8),
                              Text('日本語 (Japanese)'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'ru',
                          child: Row(
                            children: [
                              SizedBox(width: 8),
                              Text('Русский (Russian)'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'pl',
                          child: Row(
                            children: [
                              SizedBox(width: 8),
                              Text('Polski (Polish)'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'ro',
                          child: Row(
                            children: [
                              SizedBox(width: 8),
                              Text('Română (Romanian)'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SwitchListTile(
          secondary: Icon(
            Icons.delete_forever,
            color: theme.colorScheme.primary,
          ),
          title: Text(
            AppLocalizations.of(context)?.safeDelete ?? 'Safe Delete',
            style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
          ),
          subtitle: Text(
            'Screenshots will only be removed from the app',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          value: _safeDeleteEnabled,
          activeThumbColor: theme.colorScheme.primary,
          onChanged: (bool value) async {
            if (!value) {
              // Show warning dialog when disabling safe delete
              final bool? confirmDisable = await _showHardDeleteWarningDialog();
              if (confirmDisable != true) {
                return; // User cancelled, don't disable safe delete
              }
            }

            setState(() {
              _safeDeleteEnabled = value;
              _hardDeleteEnabled =
                  !value; // Hard delete is opposite of safe delete
            });
            _saveHardDeleteEnabled(!value); // Save the opposite value

            // Track analytics for safe delete setting
            AnalyticsService().logFeatureUsed(
              'settings_safe_delete_${value ? 'enabled' : 'disabled'}',
            );

            if (widget.onHardDeleteChanged != null) {
              widget.onHardDeleteChanged!(
                !value,
              ); // Pass the hard delete value (opposite of safe delete)
            }
          },
        ),
        SwitchListTile(
          secondary: Icon(
            Icons.developer_mode,
            color: theme.colorScheme.primary,
          ),
          title: Text(
            AppLocalizations.of(context)?.developerMode ?? 'Advanced Settings',
            style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
          ),
          subtitle: Text(
            'Show extra info and enable advanced settings',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          value: _devMode,
          activeThumbColor: theme.colorScheme.primary,
          onChanged: (bool value) {
            setState(() {
              _devMode = value;
            });
            _saveDevMode(value);

            // Track analytics for expert/dev mode setting
            AnalyticsService().logFeatureUsed(
              'settings_expert_mode_${value ? 'enabled' : 'disabled'}',
            );

            if (widget.onDevModeChanged != null) {
              widget.onDevModeChanged!(value);
            }
          },
        ),
      ],
    );
  }

  Future<bool?> _showHardDeleteWarningDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return AlertDialog(
          icon: Icon(
            Icons.warning_amber,
            color: theme.colorScheme.error,
            size: 32,
          ),
          title: Text(
            'Disable Safe Delete?',
            style: TextStyle(
              color: theme.colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This will change how deletions work in the app:',
                style: TextStyle(
                  color: theme.colorScheme.onTertiaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Screenshots will be removed from the app',
                      style: TextStyle(
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.delete_forever,
                    color: theme.colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Image files will be permanently deleted from your device storage',
                      style: TextStyle(
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '⚠️ Deleted files cannot be recovered.',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
              ),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text(
                'Disable',
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _apiKeyFocusNode.dispose();
    super.dispose();
  }
}
