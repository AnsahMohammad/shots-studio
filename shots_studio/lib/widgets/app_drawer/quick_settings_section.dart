import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';
import 'package:shots_studio/services/api_validation_service.dart';
import 'package:shots_studio/services/snackbar_service.dart';
import 'package:shots_studio/screens/ai_settings_screen.dart';
import 'package:shots_studio/utils/ai_provider_config.dart';
import 'package:shots_studio/l10n/app_localizations.dart';

class QuickSettingsSection extends StatefulWidget {
  final String? currentApiKey;
  final String currentModelName;
  final Function(String) onApiKeyChanged;
  final Function(String) onModelChanged;
  final Key? apiKeyFieldKey;

  const QuickSettingsSection({
    super.key,
    this.currentApiKey,
    required this.currentModelName,
    required this.onApiKeyChanged,
    required this.onModelChanged,
    this.apiKeyFieldKey,
  });

  @override
  State<QuickSettingsSection> createState() => _QuickSettingsSectionState();
}

class _QuickSettingsSectionState extends State<QuickSettingsSection> {
  late TextEditingController _apiKeyController;
  late String _selectedModelName;
  final FocusNode _apiKeyFocusNode = FocusNode();
  bool _isValidatingApiKey = false;
  bool? _apiKeyValid;

  static const String _apiKeyPrefKey = 'apiKey';
  static const String _modelNamePrefKey = 'modelName';

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(text: widget.currentApiKey ?? '');
    _selectedModelName = widget.currentModelName;

    // Track when quick settings are viewed
    AnalyticsService().logScreenView('quick_settings_section');
    AnalyticsService().logFeatureUsed('view_quick_settings');

    // Load API key validation state
    _loadApiKeyValidationState();
  }

  @override
  void didUpdateWidget(covariant QuickSettingsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentApiKey != oldWidget.currentApiKey) {
      if (_apiKeyController.text != (widget.currentApiKey ?? '')) {
        _apiKeyController.text = widget.currentApiKey ?? '';
        _apiKeyController.selection = TextSelection.fromPosition(
          TextPosition(offset: _apiKeyController.text.length),
        );
        // Reset validation state when API key changes
        _apiKeyValid = null;
        // Clear cached validation result in the service
        ApiValidationService().clearCache();
        _loadApiKeyValidationState();
      }
    }
    if (widget.currentModelName != oldWidget.currentModelName) {
      if (_selectedModelName != widget.currentModelName) {
        _selectedModelName = widget.currentModelName;
      }
    }
  }

  Future<List<String>> _getAvailableModels() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> availableModels = [];

    // Check which providers are enabled
    for (final provider in AIProviderConfig.getProviders()) {
      final prefKey = AIProviderConfig.getPrefKeyForProvider(provider);
      if (prefKey != null) {
        final isEnabled = prefs.getBool(prefKey) ?? (provider == 'gemini');
        if (isEnabled) {
          availableModels.addAll(
            AIProviderConfig.getModelsForProvider(provider),
          );
        }
      }
    }

    // If no providers are enabled, default to none models
    if (availableModels.isEmpty) {
      availableModels.addAll(AIProviderConfig.getModelsForProvider('none'));
    }

    return availableModels;
  }

  void _navigateToAISettings() async {
    // Track AI settings navigation from quick settings
    AnalyticsService().logFeatureUsed('ai_settings_navigation_from_quick');
    AnalyticsService().logScreenView('ai_settings_screen');

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AISettingsScreen(
              currentModelName: _selectedModelName,
              onModelChanged: (String newModel) {
                _saveModelName(newModel);
              },
            ),
      ),
    );

    // Refresh the UI when returning from AI settings to reflect any provider changes
    if (mounted) {
      setState(() {
        // This will trigger a rebuild and refresh the FutureBuilder for available models
      });
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

  Future<void> _validateApiKey() async {
    if (_isValidatingApiKey) return;

    if (mounted) {
      setState(() {
        _isValidatingApiKey = true;
        _apiKeyValid = null;
      });
    }

    try {
      final result = await ApiValidationService().validateApiKey(
        apiKey: _apiKeyController.text,
        modelName: _selectedModelName,
        context: context,
        showMessages: true,
        forceValidation: true,
      );

      if (mounted) {
        setState(() {
          _apiKeyValid = result.isValid;
          _isValidatingApiKey = false;
        });
      }

      // Track validation in analytics
      AnalyticsService().logFeatureUsed('api_key_validation_quick_settings');
      if (result.isValid) {
        AnalyticsService().logFeatureUsed('api_key_validation_success');
      } else {
        AnalyticsService().logFeatureUsed('api_key_validation_failed');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isValidatingApiKey = false;
          _apiKeyValid = false;
        });
        SnackbarService().showError(
          context,
          'Validation failed: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _loadApiKeyValidationState() async {
    if (_apiKeyController.text.isNotEmpty) {
      final isValid = await ApiValidationService().isApiKeyValid(
        apiKey: _apiKeyController.text,
        modelName: _selectedModelName,
      );
      if (mounted) {
        setState(() {
          _apiKeyValid = isValid;
        });
      }
    }
  }

  String _getApiKeyHelperText() {
    if (_apiKeyController.text.isEmpty) {
      return AppLocalizations.of(context)?.apiKeyRequired ??
          'Required for AI features';
    } else if (_apiKeyValid == true) {
      return AppLocalizations.of(context)?.apiKeyValid ?? 'API key is valid';
    } else if (_apiKeyValid == false) {
      return AppLocalizations.of(context)?.apiKeyValidationFailed ??
          'API key validation failed';
    } else {
      return AppLocalizations.of(context)?.apiKeyNotValidated ??
          'API key is set (not validated)';
    }
  }

  Color _getApiKeyHelperColor(ThemeData theme) {
    if (_apiKeyController.text.isEmpty) {
      return theme.colorScheme.error.withOpacity(0.7);
    } else if (_apiKeyValid == true) {
      return theme.colorScheme.primary;
    } else if (_apiKeyValid == false) {
      return theme.colorScheme.error;
    } else {
      return theme.colorScheme.onSecondaryContainer;
    }
  }

  Color _getApiKeyBorderColor(ThemeData theme) {
    if (_apiKeyController.text.isEmpty) {
      return theme.colorScheme.error.withOpacity(0.5);
    } else if (_apiKeyValid == false) {
      return theme.colorScheme.error.withOpacity(0.5);
    } else {
      return theme.colorScheme.outline;
    }
  }

  Widget _getApiKeySuffixIcon(ThemeData theme) {
    if (_apiKeyController.text.isEmpty) {
      return Icon(Icons.key_off, color: theme.colorScheme.error, size: 20);
    } else if (_apiKeyValid == true) {
      return Icon(Icons.verified, color: theme.colorScheme.primary, size: 20);
    } else if (_apiKeyValid == false) {
      return Icon(Icons.error, color: theme.colorScheme.error, size: 20);
    } else {
      return Icon(
        Icons.help_outline,
        color: theme.colorScheme.onSecondaryContainer,
        size: 20,
      );
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
            'Quick Settings',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),

        // AI Model Selection
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)?.modelName ??
                                'AI Model',
                            style: TextStyle(
                              color: theme.colorScheme.onSecondaryContainer,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Flexible(
                          child: TextButton.icon(
                            onPressed: _navigateToAISettings,
                            icon: Icon(
                              Icons.settings_outlined,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            label: Text(
                              AppLocalizations.of(context)?.aiSettings ??
                                  'AI Settings',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    FutureBuilder<List<String>>(
                      future: _getAvailableModels(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return DropdownButton<String>(
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
                            items: [
                              DropdownMenuItem<String>(
                                value: _selectedModelName,
                                child: Text(
                                  _selectedModelName,
                                  style: TextStyle(
                                    color:
                                        theme.colorScheme.onSecondaryContainer,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                            onChanged: null,
                          );
                        }

                        final availableModels = snapshot.data!;

                        // Ensure current model is in available models
                        if (!availableModels.contains(_selectedModelName) &&
                            availableModels.isNotEmpty) {
                          // Auto-switch to first available model
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            setState(() {
                              _selectedModelName = availableModels.first;
                            });
                            widget.onModelChanged(availableModels.first);
                            _saveModelName(availableModels.first);
                          });
                        }

                        return DropdownButton<String>(
                          value:
                              availableModels.contains(_selectedModelName)
                                  ? _selectedModelName
                                  : (availableModels.isNotEmpty
                                      ? availableModels.first
                                      : _selectedModelName),
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
                                'setting_changed_ai_model_quick',
                              );
                              AnalyticsService().logFeatureAdopted(
                                'model_$newValue',
                              );
                            }
                          },
                          items:
                              availableModels.map<DropdownMenuItem<String>>((
                                String value,
                              ) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: TextStyle(
                                      color:
                                          theme
                                              .colorScheme
                                              .onSecondaryContainer,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // API Key Input - Only shown for Gemini models
        if (_selectedModelName.toLowerCase().startsWith('gemini'))
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.vpn_key_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)?.apiKey ?? 'API Key',
                        style: TextStyle(
                          color: theme.colorScheme.onSecondaryContainer,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip:
                          AppLocalizations.of(context)?.getApiKey ??
                          "Get an API key",
                      icon: Icon(
                        Icons.help_outline,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      onPressed: () async {
                        // Track when users seek API key help
                        AnalyticsService().logFeatureUsed(
                          'api_key_help_clicked_quick',
                        );

                        final Uri url = Uri.parse(
                          'https://aistudio.google.com/app/apikey',
                        );
                        if (await canLaunchUrl(url)) {
                          await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: widget.apiKeyFieldKey,
                  controller: _apiKeyController,
                  focusNode: _apiKeyFocusNode,
                  style: TextStyle(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        AppLocalizations.of(context)?.enterApiKey ??
                        'Enter Gemini API Key',
                    helperText: _getApiKeyHelperText(),
                    helperStyle: TextStyle(
                      color: _getApiKeyHelperColor(theme),
                      fontSize: 12,
                    ),
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: _getApiKeyBorderColor(theme),
                        width: _apiKeyController.text.isEmpty ? 2.0 : 1.0,
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2.0,
                      ),
                    ),
                    suffixIcon: _getApiKeySuffixIcon(theme),
                  ),
                  obscureText: true,
                  onChanged: (value) {
                    widget.onApiKeyChanged(value);
                    _saveApiKey(value);

                    // Track API key changes in analytics (only track if key was added or removed, not the actual key)
                    if (_apiKeyController.text.isEmpty && value.isNotEmpty) {
                      // API key was added
                      AnalyticsService().logFeatureUsed('api_key_added_quick');
                      AnalyticsService().logFeatureAdopted(
                        'gemini_api_configured',
                      );
                    } else if (_apiKeyController.text.isNotEmpty &&
                        value.isEmpty) {
                      // API key was removed
                      AnalyticsService().logFeatureUsed(
                        'api_key_removed_quick',
                      );
                    }

                    // Reset validation state when API key changes
                    setState(() {
                      _apiKeyValid = null;
                    });

                    // Clear cached validation result in the service
                    ApiValidationService().clearCache();
                  },
                ),
                // Validation button
                if (_apiKeyController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isValidatingApiKey ? null : _validateApiKey,
                        icon:
                            _isValidatingApiKey
                                ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      theme.colorScheme.onPrimary,
                                    ),
                                  ),
                                )
                                : Icon(
                                  _apiKeyValid == true
                                      ? Icons.check_circle
                                      : Icons.security,
                                  size: 16,
                                ),
                        label: Text(
                          _isValidatingApiKey
                              ? 'Validating...'
                              : _apiKeyValid == true
                              ? AppLocalizations.of(context)?.valid ?? 'Valid'
                              : AppLocalizations.of(context)?.validateApiKey ??
                                  'Validate API Key',
                          style: const TextStyle(fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _apiKeyValid == true
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.secondaryContainer,
                          foregroundColor:
                              _apiKeyValid == true
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSecondaryContainer,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

        // Add a helper note about getting an API key - Only shown for Gemini models
        if (_apiKeyController.text.isEmpty &&
            _selectedModelName.toLowerCase().startsWith('gemini'))
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
                      Expanded(
                        child: Text(
                          'How to get an API key:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
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
      ],
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _apiKeyFocusNode.dispose();
    super.dispose();
  }
}
