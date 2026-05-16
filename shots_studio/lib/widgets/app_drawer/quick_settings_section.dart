import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';
import 'package:shots_studio/services/openai_compatibility_service.dart';
import 'package:shots_studio/screens/ai_settings_screen.dart';
import 'package:shots_studio/utils/ai_provider_config.dart';
import 'package:shots_studio/l10n/app_localizations.dart';

class _ModelAvailability {
  final List<String> models;
  final Map<String, String> providerByModel;

  const _ModelAvailability(this.models, this.providerByModel);
}

class QuickSettingsSection extends StatefulWidget {
  final String currentModelName;
  final Function(String) onModelChanged;

  const QuickSettingsSection({
    super.key,
    required this.currentModelName,
    required this.onModelChanged,
  });

  @override
  State<QuickSettingsSection> createState() => _QuickSettingsSectionState();
}

class _QuickSettingsSectionState extends State<QuickSettingsSection> {
  late String _selectedModelName;

  static const String _modelNamePrefKey = 'modelName';
  static const String _modelProviderPrefKey = 'modelProvider';

  @override
  void initState() {
    super.initState();
    _selectedModelName = widget.currentModelName;

    // Track when quick settings are viewed
    AnalyticsService().logScreenView('quick_settings_section');
    AnalyticsService().logFeatureUsed('view_quick_settings');
  }

  @override
  void didUpdateWidget(covariant QuickSettingsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentModelName != oldWidget.currentModelName) {
      if (_selectedModelName != widget.currentModelName) {
        _selectedModelName = widget.currentModelName;
      }
    }
  }

  Future<_ModelAvailability> _getAvailableModels() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> availableModels = [];
    final providerByModel = <String, String>{};
    final openAIModels = await OpenAICompatibilityService.getModelsCache();

    // Check which providers are enabled
    for (final provider in AIProviderConfig.getProviders()) {
      final prefKey = AIProviderConfig.getPrefKeyForProvider(provider);
      if (prefKey != null) {
        final isEnabled = prefs.getBool(prefKey) ?? (provider == 'gemini');
        if (isEnabled) {
          if (provider == 'openai_compatible') {
            availableModels.addAll(openAIModels);
            for (final model in openAIModels) {
              providerByModel[model] = 'openai_compatible';
            }
          } else {
            final models = AIProviderConfig.getModelsForProvider(provider);
            availableModels.addAll(models);
            for (final model in models) {
              providerByModel[model] = provider;
            }
          }
        }
      }
    }

    // If no providers are enabled, default to none models
    if (availableModels.isEmpty) {
      availableModels.addAll(AIProviderConfig.getModelsForProvider('none'));
      providerByModel['No AI Model'] = 'none';
    }

    return _ModelAvailability(availableModels, providerByModel);
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
                setState(() {
                  _selectedModelName = newModel;
                });
                widget.onModelChanged(newModel);
                _saveModelName(newModel, null);
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

  Future<void> _saveModelName(String value, String? provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modelNamePrefKey, value);
    if (provider != null && provider.isNotEmpty) {
      await prefs.setString(_modelProviderPrefKey, provider);
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
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 280;

                        final settingsButton = TextButton.icon(
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
                        );

                        if (compact) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)?.modelName ??
                                    'AI Model',
                                style: TextStyle(
                                  color: theme.colorScheme.onSecondaryContainer,
                                  fontSize: 16,
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: settingsButton,
                              ),
                            ],
                          );
                        }

                        return Row(
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
                            settingsButton,
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    FutureBuilder<_ModelAvailability>(
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

                        final availableModels = snapshot.data!.models;
                        final providerByModel = snapshot.data!.providerByModel;

                        // Ensure current model is in available models
                        if (!availableModels.contains(_selectedModelName) &&
                            availableModels.isNotEmpty) {
                          // Auto-switch to first available model
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            setState(() {
                              _selectedModelName = availableModels.first;
                            });
                            widget.onModelChanged(availableModels.first);
                            _saveModelName(
                              availableModels.first,
                              providerByModel[availableModels.first],
                            );
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
                              _saveModelName(newValue, providerByModel[newValue]);

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
      ],
    );
  }
}
