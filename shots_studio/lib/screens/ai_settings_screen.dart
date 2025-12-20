import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';
import 'package:shots_studio/services/snackbar_service.dart';
import 'package:shots_studio/utils/ai_provider_config.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shots_studio/l10n/app_localizations.dart';
import 'package:shots_studio/services/gemma_download_service.dart';
import 'package:shots_studio/widgets/ai_settings/index.dart';
import 'dart:io';

class AISettingsScreen extends StatefulWidget {
  final String currentModelName;
  final Function(String) onModelChanged;

  const AISettingsScreen({
    super.key,
    required this.currentModelName,
    required this.onModelChanged,
  });

  @override
  State<AISettingsScreen> createState() => _AISettingsScreenState();
}

class _AISettingsScreenState extends State<AISettingsScreen> {
  final Map<String, bool> _providerStates = {};
  late String _selectedModelName;
  String? _gemmaModelPath;
  bool _isLoadingGemmaModel = false;
  bool _gemmaUseCPU = true; // CPU by default

  final GemmaDownloadService _downloadService = GemmaDownloadService();

  @override
  void initState() {
    super.initState();
    _selectedModelName = widget.currentModelName;
    _loadProviderSettings();

    // Listen to download service updates
    _downloadService.addListener(_onDownloadProgressUpdate);

    // Check for resumable downloads
    _downloadService.checkAndResumeDownload();

    // Track AI settings screen access
    AnalyticsService().logScreenView('ai_settings_screen');
    AnalyticsService().logFeatureUsed('ai_settings_accessed');
  }

  @override
  void dispose() {
    _downloadService.removeListener(_onDownloadProgressUpdate);
    super.dispose();
  }

  void _onDownloadProgressUpdate() {
    if (mounted) {
      setState(() {
        // Update UI when download progress changes
        if (_downloadService.isCompleted &&
            _downloadService.progress.filePath != null) {
          _gemmaModelPath = _downloadService.progress.filePath;
          _providerStates['gemma'] = true;
          // Save provider setting
          _saveProviderSetting('gemma', true);
        }
      });
    }
  }

  Future<void> _loadProviderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        for (final provider in AIProviderConfig.getProviders()) {
          final prefKey = AIProviderConfig.getPrefKeyForProvider(provider);
          if (prefKey != null) {
            if (provider == 'gemma') {
              // For Gemma, only enable if model file exists
              final modelPath = prefs.getString('gemma_model_path');
              _providerStates[provider] =
                  (modelPath != null && modelPath.isNotEmpty)
                      ? (prefs.getBool(prefKey) ?? false)
                      : false;
            } else {
              _providerStates[provider] =
                  prefs.getBool(prefKey) ?? (provider == 'gemini');
            }
          }
        }
        // Load saved Gemma model path
        _gemmaModelPath = prefs.getString('gemma_model_path');
        // Load saved Gemma CPU/GPU preference (CPU by default)
        _gemmaUseCPU = prefs.getBool('gemma_use_cpu') ?? true;
      });
    }
  }

  Future<void> _pickGemmaModelFile() async {
    try {
      setState(() {
        _isLoadingGemmaModel = true;
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['bin', 'gguf', 'task'],
        dialogTitle: 'Select Gemma Model File',
      );

      if (result != null && result.files.single.path != null) {
        final sourcePath = result.files.single.path;
        if (sourcePath == null) {
          throw Exception('Selected file path is null');
        }

        final sourceFile = File(sourcePath);

        if (await sourceFile.exists()) {
          // Copy the file to app's documents directory to ensure persistence
          final appDocDir = await getApplicationDocumentsDirectory();
          final modelsDir = Directory('${appDocDir.path}/gemma_models');

          // Create models directory if it doesn't exist
          if (!await modelsDir.exists()) {
            await modelsDir.create(recursive: true);
          }

          // Create destination file with original name
          final originalFileName = result.files.single.name;
          final destinationFile = File('${modelsDir.path}/$originalFileName');

          // Copy the file
          await sourceFile.copy(destinationFile.path);

          // Verify the copied file exists
          if (await destinationFile.exists()) {
            // Save the permanent model path
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('gemma_model_path', destinationFile.path);

            setState(() {
              _gemmaModelPath = destinationFile.path;
            });

            // Track analytics
            AnalyticsService().logFeatureUsed('gemma_model_file_selected');

            if (mounted) {
              SnackbarService().showSuccess(
                context,
                'Gemma model file copied: $originalFileName',
              );
            }
          } else {
            throw Exception('Failed to copy model file to permanent location');
          }
        } else {
          throw Exception('Selected file does not exist');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarService().showError(context, 'Error selecting model file: $e');
      }
    } finally {
      setState(() {
        _isLoadingGemmaModel = false;
      });
    }
  }

  Future<void> _confirmAndClearGemmaModel() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Gemma Models'),
          content: const Text(
            'This will permanently delete all downloaded Gemma model files from your device and disable the Gemma provider. Are you sure you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _clearGemmaModel();
    }
  }

  Future<void> _clearGemmaModel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentModelPath = prefs.getString('gemma_model_path');

      // Delete the specific model file if it exists
      if (currentModelPath != null) {
        final modelFile = File(currentModelPath);
        if (await modelFile.exists()) {
          await modelFile.delete();
        }
      }

      // Also clean up the entire gemma_models directory to remove any downloaded models
      try {
        final appDocDir = await getApplicationDocumentsDirectory();
        final modelsDir = Directory('${appDocDir.path}/gemma_models');
        if (await modelsDir.exists()) {
          await modelsDir.delete(recursive: true);
        }
      } catch (e) {
        // If cleaning up the directory fails, it's not critical
        print('Warning: Could not clean up gemma_models directory: $e');
      }

      // Cancel any ongoing download
      if (_downloadService.isDownloading || _downloadService.isPaused) {
        _downloadService.cancelDownload();
      }

      await prefs.remove('gemma_model_path');

      setState(() {
        _gemmaModelPath = null;
        // Automatically disable Gemma provider when model is cleared
        _providerStates['gemma'] = false;
      });

      // Save the disabled state
      await _saveProviderSetting('gemma', false);

      // If current model is Gemma, switch to first available model
      if (_selectedModelName.toLowerCase().contains('gemma')) {
        final availableModels = _getAvailableModels();
        if (availableModels.isNotEmpty) {
          final newModel = availableModels.first;
          setState(() {
            _selectedModelName = newModel;
          });
          widget.onModelChanged(newModel);
        }
      }

      AnalyticsService().logFeatureUsed('gemma_model_cleared');

      if (mounted) {
        SnackbarService().showWarning(
          context,
          'Gemma models cleared and provider disabled',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarService().showError(context, 'Error clearing model: $e');
      }
    }
  }

  Future<void> _saveProviderSetting(String provider, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    final prefKey = AIProviderConfig.getPrefKeyForProvider(provider);
    if (prefKey != null) {
      await prefs.setBool(prefKey, enabled);
    }
  }

  Future<void> _saveGemmaCpuGpuSetting(bool useCPU) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('gemma_use_cpu', useCPU);

    // Track CPU/GPU preference change in analytics
    AnalyticsService().logFeatureUsed(
      'gemma_backend_changed_to_${useCPU ? 'cpu' : 'gpu'}',
    );
  }

  Future<bool> _showTermsAndConditionsDialog() async {
    final bool? accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Gemma Terms and Conditions'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Before downloading the Gemma model, you must accept the terms and conditions of use.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Text(
                  'By downloading and using this model, you agree to:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('• Use the model responsibly and ethically'),
                const Text('• Comply with applicable laws and regulations'),
                const Text('• Not use the model for harmful purposes'),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    const url = 'https://ai.google.dev/gemma/terms';
                    try {
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    } catch (e) {
                      await Clipboard.setData(const ClipboardData(text: url));
                      if (context.mounted) {
                        SnackbarService().showInfo(
                          context,
                          'Link copied to clipboard!',
                        );
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.open_in_new,
                          color: Theme.of(context).colorScheme.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Read Full Terms and Conditions',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              decoration: TextDecoration.underline,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Theme.of(context).colorScheme.secondaryContainer,
              ),
              child: const Text('Decline'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: const Text('Accept & Download'),
            ),
          ],
        );
      },
    );
    return accepted ?? false;
  }

  Future<String> _getDownloadLocation() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final modelsDir = Directory('${appDocDir.path}/gemma_models');

      if (!await modelsDir.exists()) {
        await modelsDir.create(recursive: true);
      }

      return modelsDir.path;
    } catch (e) {
      final appDocDir = await getApplicationDocumentsDirectory();
      return appDocDir.path;
    }
  }

  Future<void> _downloadGemmaModel() async {
    final termsAccepted = await _showTermsAndConditionsDialog();
    if (!termsAccepted) {
      return;
    }

    final downloadLocation = await _getDownloadLocation();

    final success = await _downloadService.startDownload(downloadLocation);

    if (!success && mounted) {
      SnackbarService().showError(
        context,
        'Download failed: ${_downloadService.progress.error?.substring(0, 50) ?? "Unknown error"}...',
      );
    }
  }

  void _pauseDownload() {
    _downloadService.pauseDownload();
  }

  void _resumeDownload() {
    _downloadService.resumeDownload();
  }

  void _cancelDownload() {
    _downloadService.cancelDownload();
  }

  List<String> _getAvailableModels() {
    List<String> availableModels = [];

    for (final provider in AIProviderConfig.getProviders()) {
      if (_providerStates[provider] == true) {
        availableModels.addAll(AIProviderConfig.getModelsForProvider(provider));
      }
    }

    if (availableModels.isEmpty) {
      availableModels.addAll(AIProviderConfig.getModelsForProvider('none'));
    }

    return availableModels;
  }

  Future<void> _showGemmaWarningDialog(String provider) async {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      if (mounted) {
        SnackbarService().showError(
          context,
          'Cannot show dialog - localization not available',
        );
      }
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizations.enableLocalAI),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.localAIBenefits,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(localizations.localAIOffline),
              Text(localizations.localAIPrivacy),
              const SizedBox(height: 12),
              Text(
                localizations.localAINote,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(localizations.localAIBattery),
              Text(localizations.localAIRAM),
              const SizedBox(height: 12),
              Text(
                localizations.localAIPrivacyNote,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Text(localizations.enableLocalAIButton),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        _providerStates[provider] = true;
      });

      await _saveProviderSetting(provider, true);

      AnalyticsService().logFeatureUsed(
        'ai_provider_${provider}_enabled_with_warning',
      );
    }
  }

  void _onProviderToggle(String provider, bool enabled) async {
    // For Gemma provider, check if model file is available before enabling
    if (provider == 'gemma' &&
        enabled &&
        (_gemmaModelPath == null || _gemmaModelPath?.isEmpty == true)) {
      if (mounted) {
        SnackbarService().showWarning(
          context,
          'Please select a Gemma model file first',
        );
      }
      return;
    }

    // Show warning dialog when enabling Gemma
    if (provider == 'gemma' && enabled) {
      await _showGemmaWarningDialog(provider);
      return;
    }

    setState(() {
      _providerStates[provider] = enabled;
    });

    await _saveProviderSetting(provider, enabled);

    AnalyticsService().logFeatureUsed(
      'ai_provider_${provider}_${enabled ? 'enabled' : 'disabled'}',
    );

    // If the current model belongs to the disabled provider, switch to first available model
    final availableModels = _getAvailableModels();
    if (availableModels.isNotEmpty &&
        !availableModels.contains(_selectedModelName)) {
      final newModel = availableModels.first;
      setState(() {
        _selectedModelName = newModel;
      });
      widget.onModelChanged(newModel);

      AnalyticsService().logFeatureUsed(
        'ai_model_auto_switched_due_to_provider_disable',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Settings'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current model info
            CurrentModelInfo(modelName: _selectedModelName),

            // AI Providers Header section
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Providers',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toggle AI providers on or off. Enabled providers will show their models in the main settings dropdown.',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => ModelSelectionGuideDialog.show(context),
                    icon: Icon(
                      Icons.help_outline,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    label: Text(
                      'How to choose the right model',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.colorScheme.primary),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Provider toggles
            ...AIProviderConfig.getProviders().map((provider) {
              final isEnabled = _providerStates[provider] ?? false;
              bool canToggle = true;
              bool forceDisabled = false;
              String? disabledReason;

              if (provider == 'gemma') {
                canToggle =
                    _gemmaModelPath != null &&
                    _gemmaModelPath?.isNotEmpty == true;
                if (!canToggle) {
                  forceDisabled = true;
                  disabledReason = 'load the model file first';
                }
              }

              return ProviderToggleCard(
                provider: provider,
                isEnabled: isEnabled,
                canToggle: canToggle,
                forceDisabled: forceDisabled,
                disabledReason: disabledReason,
                onToggle: _onProviderToggle,
              );
            }),

            // Local Models Section
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Local Models',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 8),
            GemmaModelSection(
              gemmaModelPath: _gemmaModelPath,
              isLoadingGemmaModel: _isLoadingGemmaModel,
              gemmaUseCPU: _gemmaUseCPU,
              downloadService: _downloadService,
              onPickModelFile: _pickGemmaModelFile,
              onClearModel: _confirmAndClearGemmaModel,
              onDownloadModel: _downloadGemmaModel,
              onPauseDownload: _pauseDownload,
              onResumeDownload: _resumeDownload,
              onCancelDownload: _cancelDownload,
              onCpuGpuChanged: (useCPU) {
                setState(() {
                  _gemmaUseCPU = useCPU;
                });
                _saveGemmaCpuGpuSetting(useCPU);
              },
            ),

            const SizedBox(height: 16),
            // AI Output Settings Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'AI Output Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const LanguageSection(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
