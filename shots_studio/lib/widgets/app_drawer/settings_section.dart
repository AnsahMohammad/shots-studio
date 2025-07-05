import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shots_studio/services/analytics_service.dart';
import 'package:shots_studio/utils/theme_manager.dart';
import 'package:shots_studio/services/gemma_service.dart';
import 'package:file_picker/file_picker.dart';

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
  });

  @override
  State<SettingsSection> createState() => _SettingsSectionState();
}

class _SettingsSectionState extends State<SettingsSection> {
  late TextEditingController _apiKeyController;
  late String _selectedModelName;
  final FocusNode _apiKeyFocusNode = FocusNode();
  bool _autoProcessEnabled = true;
  bool _amoledModeEnabled = false;
  String _selectedTheme = 'Dynamic Theme';

  // Gemma service state
  final GemmaService _gemmaService = GemmaService();
  String _localModelName = 'No Model Loaded';
  bool _isLoadingLocalModel = false;
  bool _isTestingLocalModel = false;

  static const String _apiKeyPrefKey = 'apiKey';
  static const String _modelNamePrefKey = 'modelName';
  static const String _autoProcessEnabledPrefKey = 'auto_process_enabled';
  static const String _amoledModeEnabledPrefKey = 'amoled_mode_enabled';

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(text: widget.currentApiKey ?? '');
    _selectedModelName = widget.currentModelName;

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

    // Load local model preference
    _loadLocalModelPref();

    // Request focus on the API key field when it's empty
    if (widget.currentApiKey?.isEmpty ?? true) {
      // Request focus on the next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _apiKeyFocusNode.requestFocus();
      });
    }
  }

  void _loadAutoProcessEnabledPref() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoProcessEnabled = prefs.getBool(_autoProcessEnabledPrefKey) ?? true;
    });
  }

  void _loadAmoledModeEnabledPref() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _amoledModeEnabled = prefs.getBool(_amoledModeEnabledPrefKey) ?? false;
    });
  }

  void _loadThemePref() async {
    final selectedTheme = await ThemeManager.getSelectedTheme();
    setState(() {
      _selectedTheme = selectedTheme;
    });
  }

  void _loadLocalModelPref() async {
    try {
      // Use centralized method to load from preferences
      await _gemmaService.ensureModelReady();

      // Update UI state based on loaded model
      final modelPath = await _gemmaService.getSavedModelPath();
      if (modelPath != null && _gemmaService.isModelLoaded) {
        setState(() {
          _localModelName = _gemmaService.modelName ?? 'Unknown Model';
        });
      } else {
        setState(() {
          _localModelName = 'No Model Loaded';
        });
      }
    } catch (e) {
      print('Error loading local model preference: $e');
      setState(() {
        _localModelName = 'No Model Loaded';
      });
    }
  }

  @override
  void didUpdateWidget(covariant SettingsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentApiKey != oldWidget.currentApiKey) {
      if (_apiKeyController.text != (widget.currentApiKey ?? '')) {
        _apiKeyController.text = widget.currentApiKey ?? '';
        _apiKeyController.selection = TextSelection.fromPosition(
          TextPosition(offset: _apiKeyController.text.length),
        );
      }
    }
    if (widget.currentModelName != oldWidget.currentModelName) {
      if (_selectedModelName != widget.currentModelName) {
        _selectedModelName = widget.currentModelName;
      }
    }
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
      _selectedTheme = widget.currentSelectedTheme ?? 'Dynamic Theme';
    }
  }

  Future<void> _saveApiKey(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPrefKey, value);
  }

  Future<void> _saveModelName(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modelNamePrefKey, value);
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

  Future<void> _pickAndLoadLocalModel() async {
    setState(() {
      _isLoadingLocalModel = true;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['task', 'bin'],
        dialogTitle: 'Select Gemma Model File',
      );

      if (result != null && result.files.single.path != null) {
        final modelPath = result.files.single.path!;
        final modelName = modelPath.split('/').last;

        // Load the model (this will automatically save to preferences)
        final success = await _gemmaService.loadModel(modelPath);

        if (success) {
          setState(() {
            _localModelName = _gemmaService.modelName ?? modelName;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Model loaded successfully: $_localModelName'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading model: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingLocalModel = false;
      });
    }
  }

  Future<void> _testLocalModel() async {
    if (!_gemmaService.isModelLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please load a model first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isTestingLocalModel = true;
    });

    try {
      final testPrompts = [
        'Tell me a short joke.',
        'What is the capital of France?',
        'Explain what AI is in one sentence.',
        'Write a haiku about technology.',
        'What is 2+2?',
      ];

      final randomPrompt =
          testPrompts[DateTime.now().millisecondsSinceEpoch %
              testPrompts.length];

      final response = await _gemmaService.generateResponse(
        prompt: randomPrompt,
        temperature: 0.8,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Local Model Test'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prompt:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(randomPrompt),
                    const SizedBox(height: 16),
                    Text(
                      'Response:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(response),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isTestingLocalModel = false;
      });
    }
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
            'Settings',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SwitchListTile(
          secondary: Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
          title: Text(
            'Auto-Process Screenshots',
            style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
          ),
          subtitle: Text(
            _autoProcessEnabled
                ? 'Screenshots will be automatically processed when added'
                : 'Manual processing only',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          value: _autoProcessEnabled,
          activeColor: theme.colorScheme.primary,
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Model',
                      style: TextStyle(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButton<String>(
                      value: _selectedModelName,
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
                            _selectedModelName = newValue;
                          });
                          widget.onModelChanged(newValue);
                          _saveModelName(newValue);

                          // Track model change in analytics
                          AnalyticsService().logFeatureUsed(
                            'setting_changed_ai_model',
                          );
                          AnalyticsService().logFeatureAdopted(
                            'model_$newValue',
                          );
                        }
                      },
                      items:
                          <String>[
                            'gemini-2.0-flash',
                            'gemini-2.5-flash-pro',
                          ].map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: TextStyle(
                                  color: theme.colorScheme.onSecondaryContainer,
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ListTile(
          leading: Icon(
            Icons.vpn_key_outlined,
            color: theme.colorScheme.primary,
          ),
          trailing: IconButton(
            tooltip: "Get an API key",
            icon: Icon(
              Icons.help_outline,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            onPressed: () async {
              // Track when users seek API key help
              AnalyticsService().logFeatureUsed('api_key_help_clicked');

              final Uri url = Uri.parse(
                'https://aistudio.google.com/app/apikey',
              );
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
          title: TextFormField(
            key: widget.apiKeyFieldKey,
            controller: _apiKeyController,
            focusNode: _apiKeyFocusNode,
            autofocus: widget.currentApiKey?.isEmpty ?? true,
            style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
            decoration: InputDecoration(
              hintText: 'Enter Gemini API Key',
              helperText:
                  _apiKeyController.text.isEmpty
                      ? 'Required for AI features'
                      : 'API key is set',
              helperStyle: TextStyle(
                color:
                    _apiKeyController.text.isEmpty
                        ? theme.colorScheme.error.withOpacity(0.7)
                        : Theme.of(context).colorScheme.onSecondaryContainer,
                fontSize: 12,
              ),
              hintStyle: TextStyle(
                color: theme.colorScheme.onSecondaryContainer,
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color:
                      _apiKeyController.text.isEmpty
                          ? theme.colorScheme.error.withOpacity(0.5)
                          : theme.colorScheme.outline,
                  width: _apiKeyController.text.isEmpty ? 2.0 : 1.0,
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2.0,
                ),
              ),
              suffixIcon:
                  _apiKeyController.text.isEmpty
                      ? Icon(
                        Icons.key_off,
                        color: theme.colorScheme.error,
                        size: 20,
                      )
                      : Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        size: 20,
                      ),
            ),
            obscureText: true,
            onChanged: (value) {
              widget.onApiKeyChanged(value);
              _saveApiKey(value);

              // Track API key changes in analytics (only track if key was added or removed, not the actual key)
              if (_apiKeyController.text.isEmpty && value.isNotEmpty) {
                // API key was added
                AnalyticsService().logFeatureUsed('api_key_added');
                AnalyticsService().logFeatureAdopted('gemini_api_configured');
              } else if (_apiKeyController.text.isNotEmpty && value.isEmpty) {
                // API key was removed
                AnalyticsService().logFeatureUsed('api_key_removed');
              }

              setState(() {}); // Refresh to update the suffix icon
            },
          ),
        ),

        // Add a helper note about getting an API key
        if (_apiKeyController.text.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: theme.colorScheme.primary,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'How to get an API key:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    '1. Go to Google AI Studio website',
                    style: TextStyle(fontSize: 13),
                  ),
                  Text(
                    '2. Create or log in to your account',
                    style: TextStyle(fontSize: 13),
                  ),
                  Text(
                    '3. Navigate to API Keys section',
                    style: TextStyle(fontSize: 13),
                  ),
                  Text(
                    '4. Create a new key and paste it here',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        SwitchListTile(
          secondary: Icon(
            Icons.nightlight_round,
            color: theme.colorScheme.primary,
          ),
          title: Text(
            'AMOLED Mode',
            style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
          ),
          subtitle: Text(
            _amoledModeEnabled
                ? 'Dark theme optimized for AMOLED screens'
                : 'Default dark theme',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          value: _amoledModeEnabled,
          activeColor: theme.colorScheme.primary,
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

        // Local Gemma Model Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Local AI Model',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Local Model Status Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _gemmaService.isModelLoaded
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color:
                            _gemmaService.isModelLoaded
                                ? Colors.green
                                : theme.colorScheme.outline,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Local Model Status',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                            Text(
                              _localModelName,
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              _isLoadingLocalModel
                                  ? null
                                  : _pickAndLoadLocalModel,
                          icon:
                              _isLoadingLocalModel
                                  ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.file_open),
                          label: Text(
                            _isLoadingLocalModel ? 'Loading...' : 'Load Model',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            foregroundColor:
                                theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              (_isTestingLocalModel ||
                                      !_gemmaService.isModelLoaded)
                                  ? null
                                  : _testLocalModel,
                          icon:
                              _isTestingLocalModel
                                  ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.play_arrow),
                          label: Text(
                            _isTestingLocalModel ? 'Testing...' : 'Test',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                theme.colorScheme.secondaryContainer,
                            foregroundColor:
                                theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_gemmaService.isModelLoaded) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.green[700],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Model loaded and ready for local inference',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[700],
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
          ),
        ),
        const SizedBox(height: 16),

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
      ],
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _apiKeyFocusNode.dispose();
    _gemmaService.dispose();
    super.dispose();
  }
}
