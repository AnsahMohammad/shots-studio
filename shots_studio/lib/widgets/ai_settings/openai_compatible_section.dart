import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';
import 'package:shots_studio/services/logger_service.dart';
import 'package:shots_studio/services/openai_compatibility_service.dart';
import 'package:shots_studio/services/snackbar_service.dart';
import 'package:shots_studio/utils/ai_provider_config.dart';

class OpenAICompatibleSection extends StatefulWidget {
  final bool isOpenAIEnabled;
  final String currentSelectedModel;
  final Function(String) onModelSelected;

  const OpenAICompatibleSection({
    super.key,
    required this.isOpenAIEnabled,
    required this.currentSelectedModel,
    required this.onModelSelected,
  });

  @override
  State<OpenAICompatibleSection> createState() =>
      _OpenAICompatibleSectionState();
}

class _OpenAICompatibleSectionState extends State<OpenAICompatibleSection> {
  late TextEditingController _baseUrlController;
  late TextEditingController _apiKeyController;
  late TextEditingController _customModelController;

  bool _obscureApiKey = true;
  bool _isFetchingModels = false;
  bool? _connectionSuccess;
  String? _errorMessage;
  List<String> _models = [];
  String? _selectedModel;

  @override
  void initState() {
    super.initState();
    _baseUrlController = TextEditingController(text: 'http://localhost:11434');
    _apiKeyController = TextEditingController();
    _customModelController = TextEditingController();
    _selectedModel = widget.currentSelectedModel;

    _loadSavedSettings();
  }

  @override
  void didUpdateWidget(covariant OpenAICompatibleSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentSelectedModel != oldWidget.currentSelectedModel) {
      setState(() {
        _selectedModel = widget.currentSelectedModel;
      });
    }
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _customModelController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedBaseUrl = prefs.getString(
        OpenAICompatibilityService.baseUrlPrefKey,
      );
      final savedApiKey = prefs.getString(
        OpenAICompatibilityService.apiKeyPrefKey,
      );
      final savedModel = prefs.getString(
        OpenAICompatibilityService.selectedModelPrefKey,
      );
      final cachedModels = await OpenAICompatibilityService.getModelsCache();

      if (mounted) {
        setState(() {
          if (savedBaseUrl != null && savedBaseUrl.isNotEmpty) {
            _baseUrlController.text = savedBaseUrl;
          }
          if (savedApiKey != null && savedApiKey.isNotEmpty) {
            _apiKeyController.text = savedApiKey;
          }
          if (cachedModels.isNotEmpty) {
            _models = cachedModels;
            AIProviderConfig.setDynamicOpenAIModels(cachedModels);
          }
          if (savedModel != null && savedModel.isNotEmpty) {
            _selectedModel = savedModel;
          }
        });
      }
    } catch (e) {
      LoggerService.error('Error loading OpenAI settings', e);
    }
  }

  Future<void> _saveBaseUrl(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = OpenAICompatibilityService.normalizeBaseUrl(value);
    await prefs.setString(OpenAICompatibilityService.baseUrlPrefKey, normalized);
  }

  Future<void> _saveApiKey(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(OpenAICompatibilityService.apiKeyPrefKey, value.trim());
  }

  Future<void> _saveSelectedModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      OpenAICompatibilityService.selectedModelPrefKey,
      model,
    );
    setState(() {
      _selectedModel = model;
    });
    widget.onModelSelected(model);
  }

  Future<void> _fetchModels() async {
    if (_isFetchingModels) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isFetchingModels = true;
      _connectionSuccess = null;
      _errorMessage = null;
    });

    final baseUrl = _baseUrlController.text.trim();
    final apiKey = _apiKeyController.text.trim();

    await _saveBaseUrl(baseUrl);
    await _saveApiKey(apiKey);

    try {
      final fetchedModels = await OpenAICompatibilityService.fetchModels(
        baseUrl: baseUrl,
        apiKey: apiKey.isNotEmpty ? apiKey : null,
      );

      if (mounted) {
        if (fetchedModels.isNotEmpty) {
          setState(() {
            _models = fetchedModels;
            _connectionSuccess = true;
            _isFetchingModels = false;
          });

          AIProviderConfig.setDynamicOpenAIModels(fetchedModels);
          await OpenAICompatibilityService.saveModelsCache(fetchedModels);

          // If current selected model is not in list, pick the first one
          if (_selectedModel == null || !fetchedModels.contains(_selectedModel)) {
            await _saveSelectedModel(fetchedModels.first);
          }

          AnalyticsService().logFeatureUsed('openai_models_fetch_success');
          if (mounted) {
            SnackbarService().showSuccess(
              context,
              'Connected! Found ${fetchedModels.length} models.',
            );
          }
        } else {
          setState(() {
            _connectionSuccess = false;
            _errorMessage =
                'Connected to server, but no models were returned.';
            _isFetchingModels = false;
          });
          AnalyticsService().logFeatureUsed('openai_models_fetch_empty');
          if (mounted) {
            SnackbarService().showWarning(
              context,
              'Server reached, but 0 models found. Ensure models are pulled.',
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _connectionSuccess = false;
          _errorMessage = e.toString();
          _isFetchingModels = false;
        });
        AnalyticsService().logFeatureUsed('openai_models_fetch_failed');
        SnackbarService().showError(
          context,
          'Connection failed: ${e.toString().replaceAll('Exception: ', '')}',
        );
      }
    }
  }

  void _addCustomModel() {
    final customName = _customModelController.text.trim();
    if (customName.isEmpty) return;

    if (!_models.contains(customName)) {
      setState(() {
        _models.insert(0, customName);
      });
      AIProviderConfig.setDynamicOpenAIModels(_models);
      OpenAICompatibilityService.saveModelsCache(_models);
    }

    _saveSelectedModel(customName);
    _customModelController.clear();
    Navigator.of(context).pop();
  }

  void _showAddCustomModelDialog() {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Add Custom Model Name'),
            content: TextField(
              controller: _customModelController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Model Name',
                hintText: 'e.g. llama3.2-vision:latest',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _addCustomModel(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _addCustomModel,
                child: const Text('Add & Select'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpenAIEnabled) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.dns_outlined,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OpenAI-Compatible / Ollama',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Connect to local LLMs hosted on PC or LAN',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_connectionSuccess != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          _connectionSuccess == true
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _connectionSuccess == true
                              ? Icons.check_circle
                              : Icons.error_outline,
                          size: 14,
                          color:
                              _connectionSuccess == true
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _connectionSuccess == true ? 'Online' : 'Failed',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color:
                                _connectionSuccess == true
                                    ? theme.colorScheme.onPrimaryContainer
                                    : theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Info box for LAN setup
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Running Ollama on PC? Set OLLAMA_HOST=0.0.0.0:11434 on your computer and use your PC\'s Wi-Fi IP (e.g. http://192.168.1.100:11434).',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Base URL Field
            TextField(
              controller: _baseUrlController,
              decoration: InputDecoration(
                labelText: 'Server Base URL',
                hintText: 'http://192.168.1.x:11434 or http://localhost:11434',
                prefixIcon: const Icon(Icons.link),
                border: const OutlineInputBorder(),
                isDense: true,
                helperText: 'Ollama or OpenAI-compatible endpoint',
              ),
              onChanged: _saveBaseUrl,
            ),
            const SizedBox(height: 12),

            // API Key Field (Optional)
            TextField(
              controller: _apiKeyController,
              obscureText: _obscureApiKey,
              decoration: InputDecoration(
                labelText: 'API Key (Optional)',
                hintText: 'Leave blank for local Ollama / LM Studio',
                prefixIcon: const Icon(Icons.key),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureApiKey ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureApiKey = !_obscureApiKey;
                    });
                  },
                ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: _saveApiKey,
            ),
            const SizedBox(height: 14),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isFetchingModels ? null : _fetchModels,
                    icon:
                        _isFetchingModels
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(Icons.refresh, size: 18),
                    label: Text(
                      _isFetchingModels
                          ? 'Connecting...'
                          : 'Test & Fetch Models',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _showAddCustomModelDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Custom'),
                ),
              ],
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.error,
                ),
              ),
            ],

            // Model Selection
            if (_models.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Available Models (${_models.length})',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Select Vision Model',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                constraints: const BoxConstraints(maxHeight: 180),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _models.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final model = _models[index];
                    final isSelected =
                        _selectedModel == model ||
                        widget.currentSelectedModel == model;

                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                      leading: Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color:
                            isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      title: Text(
                        model,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color:
                              isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                        ),
                      ),
                      trailing:
                          model.contains('vision') ||
                                  model.contains('vl') ||
                                  model.contains('llava')
                              ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Vision',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color:
                                        theme.colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                              : null,
                      onTap: () => _saveSelectedModel(model),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
