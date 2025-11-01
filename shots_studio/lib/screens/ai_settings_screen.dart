import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';
import 'package:shots_studio/services/snackbar_service.dart';
import 'package:shots_studio/utils/ai_provider_config.dart';
import 'package:shots_studio/utils/ai_language_config.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shots_studio/l10n/app_localizations.dart';
import 'package:shots_studio/services/gemma_download_service.dart';
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
  String _selectedLanguage = AILanguageConfig.defaultLanguageKey;
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
        // Load saved AI output language
        _selectedLanguage =
            prefs.getString(AILanguageConfig.prefKey) ??
            AILanguageConfig.defaultLanguageKey;
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

  Future<void> _saveLanguageSetting(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AILanguageConfig.prefKey, languageCode);

    // Track language change in analytics
    AnalyticsService().logFeatureUsed(
      'ai_output_language_changed_to_$languageCode',
    );
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
      // Always use app's documents directory for downloads
      // This doesn't require any special permissions
      final appDocDir = await getApplicationDocumentsDirectory();
      final modelsDir = Directory('${appDocDir.path}/gemma_models');

      // Create models directory if it doesn't exist
      if (!await modelsDir.exists()) {
        await modelsDir.create(recursive: true);
      }

      return modelsDir.path;
    } catch (e) {
      // Fallback to app documents directory if creating subdirectory fails
      final appDocDir = await getApplicationDocumentsDirectory();
      return appDocDir.path;
    }
  }

  Future<void> _downloadGemmaModel() async {
    // Show terms and conditions
    final termsAccepted = await _showTermsAndConditionsDialog();
    if (!termsAccepted) {
      return;
    }

    // Get download location (app documents directory - no permissions needed)
    final downloadLocation = await _getDownloadLocation();

    // Start download using service
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

    // If no providers are enabled, show 'none' models
    if (availableModels.isEmpty) {
      availableModels.addAll(AIProviderConfig.getModelsForProvider('none'));
    }

    return availableModels;
  }

  Future<void> _showGemmaWarningDialog(String provider) async {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      // Fallback if localizations are not available
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

      // Track provider toggle in analytics
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
      // Show a message that model file is required
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

    // Track provider toggle in analytics
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

  Future<void> _showModelSelectionGuide() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'How to choose the right model ?',
                  softWrap: true,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose the right AI model based on your needs:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Gemini 2.0 Flash
                  _buildModelCard(
                    theme: theme,
                    modelName: 'Gemini 2.0 Flash',
                    description: '2.0 model, least expensive',
                    icon: Icons.flash_on,
                    iconColor: Colors.yellow,
                    useCases: [
                      'Basic screenshot analysis',
                      'Limited daily processing',
                      'Cost-conscious users',
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Gemini 2.5 Flash Lite
                  _buildModelCard(
                    theme: theme,
                    modelName: 'Gemini 2.5 Flash Lite',
                    description: 'Better than 2.0 and cost effective',
                    icon: Icons.flash_auto,
                    iconColor: Colors.orange,
                    useCases: [
                      'Lots of images without hitting free quota',
                      'Good balance of quality and cost',
                      'Regular daily usage',
                    ],
                    recommended: true,
                  ),
                  const SizedBox(height: 12),

                  // Gemini 2.5 Flash
                  _buildModelCard(
                    theme: theme,
                    modelName: 'Gemini 2.5 Flash',
                    description: 'High quality analysis with fast processing',
                    icon: Icons.flash_on,
                    iconColor: Colors.blue,
                    useCases: [
                      'High volume processing',
                      'Better accuracy for complex screenshots',
                      'Professional use cases',
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Gemini 2.5 Pro
                  _buildModelCard(
                    theme: theme,
                    modelName: 'Gemini 2.5 Pro',
                    description: 'Premium model with highest accuracy',
                    icon: Icons.star,
                    iconColor: Colors.purple,
                    useCases: [
                      'Maximum accuracy needed',
                      'Complex screenshot analysis',
                      'Professional/enterprise use',
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Gemma (Local)
                  _buildModelCard(
                    theme: theme,
                    modelName: 'Gemma (Local)',
                    description: 'Offline processing, completely private',
                    icon: Icons.security,
                    iconColor: Colors.green,
                    useCases: [
                      'Complete privacy (no data sent online)',
                      'Works without internet connection',
                      'Takes more time to process',
                      'No API costs',
                    ],
                    isLocal: true,
                  ),

                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(
                        0.3,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You can change models anytime in the main settings.',
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
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );

    // Track analytics for model guide usage
    AnalyticsService().logFeatureUsed('model_selection_guide_viewed');
  }

  Widget _buildModelCard({
    required ThemeData theme,
    required String modelName,
    required String description,
    required IconData icon,
    required Color iconColor,
    required List<String> useCases,
    bool recommended = false,
    bool isLocal = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              recommended
                  ? theme.colorScheme.primary.withOpacity(0.5)
                  : theme.colorScheme.outline.withOpacity(0.3),
          width: recommended ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  modelName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  softWrap: true,
                  maxLines: 2,
                ),
              ),
              if (recommended) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'RECOMMENDED',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
              if (isLocal) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'OFFLINE',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
            softWrap: true,
          ),
          const SizedBox(height: 8),
          Text(
            'Best for:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          ...useCases.map(
            (useCase) => Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      useCase,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderToggle(String provider, ThemeData theme) {
    final isEnabled = _providerStates[provider] ?? false;
    final models = AIProviderConfig.getModelsForProvider(provider);

    // For Gemma provider, check if model file is available
    bool canToggle = true;
    bool forceDisabled = false;
    String? disabledReason;

    if (provider == 'gemma') {
      canToggle =
          _gemmaModelPath != null && _gemmaModelPath?.isNotEmpty == true;
      if (!canToggle) {
        forceDisabled = true;
        disabledReason = 'load the model file first';
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.toUpperCase(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color:
                          forceDisabled
                              ? theme.colorScheme.onSurfaceVariant.withOpacity(
                                0.6,
                              )
                              : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    disabledReason ?? models.join(', '),
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          forceDisabled
                              ? theme.colorScheme.error.withOpacity(0.7)
                              : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: forceDisabled ? false : isEnabled,
              onChanged:
                  canToggle
                      ? (value) => _onProviderToggle(provider, value)
                      : null,
              activeThumbColor: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGemmaModelSection(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.android, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'LOCAL GEMMA MODEL',
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
              'Download or select a local Gemma model file (.bin or .task) to use for on-device AI processing. Downloaded models are saved to the app\'s private storage.',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.secondary.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.download,
                        color: theme.colorScheme.secondary,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Download Model',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Recommended: Gemma 3N E2B IT INT4 (~3.1GB)',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Download progress section
                  if (_downloadService.progress.status !=
                      DownloadStatus.idle) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _downloadService.isPaused
                                    ? 'Download Paused'
                                    : _downloadService.isDownloading
                                    ? 'Downloading...'
                                    : _downloadService.isCompleted
                                    ? 'Download Complete'
                                    : 'Download Error',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${(_downloadService.progress.progress * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: _downloadService.progress.progress,
                            backgroundColor: theme.colorScheme.outline
                                .withValues(alpha: 0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _downloadService.isPaused
                                  ? Colors.orange
                                  : theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_downloadService.progress.totalBytes > 0) ...[
                            Text(
                              '${(_downloadService.progress.downloadedBytes / (1024 * 1024)).toStringAsFixed(1)} MB / ${(_downloadService.progress.totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          if (_downloadService.hasError &&
                              _downloadService.progress.error != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Error: ${_downloadService.progress.error}',
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (_downloadService.isDownloading &&
                                  !_downloadService.isPaused) ...[
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _pauseDownload,
                                    icon: const Icon(Icons.pause, size: 16),
                                    label: const Text('Pause'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.orange,
                                    ),
                                  ),
                                ),
                              ] else if (_downloadService.isPaused) ...[
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _resumeDownload,
                                    icon: const Icon(
                                      Icons.play_arrow,
                                      size: 16,
                                    ),
                                    label: const Text('Resume'),
                                  ),
                                ),
                              ],
                              if (_downloadService.isDownloading ||
                                  _downloadService.isPaused) ...[
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: _cancelDownload,
                                  icon: const Icon(Icons.close, size: 16),
                                  label: const Text('Cancel'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: theme.colorScheme.error,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Download button (show only if not currently downloading and no model loaded)
                  if (!_downloadService.isDownloading &&
                      _gemmaModelPath == null &&
                      !_downloadService.isCompleted) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _downloadGemmaModel,
                        icon: const Icon(Icons.cloud_download),
                        label: const Text('Download Gemma Model'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Alternative manual download link
                  InkWell(
                    onTap: () async {
                      const url =
                          'https://www.kaggle.com/models/google/gemma-3n/tfLite/gemma-3n-e2b-it-int4';
                      try {
                        final uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        } else {
                          // Fallback to copying to clipboard if URL can't be launched
                          await Clipboard.setData(
                            const ClipboardData(text: url),
                          );
                          if (mounted) {
                            SnackbarService().showWarning(
                              context,
                              'Could not open browser. Link copied to clipboard!',
                            );
                          }
                        }
                      } catch (e) {
                        // Fallback to copying to clipboard on error
                        await Clipboard.setData(const ClipboardData(text: url));
                        if (mounted) {
                          SnackbarService().showWarning(
                            context,
                            'Error opening link. URL copied to clipboard!',
                          );
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outline.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.link,
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Or download manually from Kaggle',
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.onSurfaceVariant,
                                decoration: TextDecoration.underline,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            if (_gemmaModelPath != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Model:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _gemmaModelPath?.split('/').last ?? 'No model selected',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // CPU/GPU Performance Toggle
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.tertiary.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.settings_applications,
                          color: theme.colorScheme.tertiary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Processing Mode',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose the processing mode for the local model:',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _gemmaUseCPU = true;
                              });
                              _saveGemmaCpuGpuSetting(true);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    _gemmaUseCPU
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color:
                                      _gemmaUseCPU
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.outline
                                              .withOpacity(0.5),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.battery_saver,
                                    color:
                                        _gemmaUseCPU
                                            ? theme.colorScheme.onPrimary
                                            : theme.colorScheme.onSurface,
                                    size: 16,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'CPU',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          _gemmaUseCPU
                                              ? theme.colorScheme.onPrimary
                                              : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    'Optimized for lower resource usage.',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color:
                                          _gemmaUseCPU
                                              ? theme.colorScheme.onPrimary
                                                  .withOpacity(0.8)
                                              : theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _gemmaUseCPU = false;
                              });
                              _saveGemmaCpuGpuSetting(false);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    !_gemmaUseCPU
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color:
                                      !_gemmaUseCPU
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.outline
                                              .withOpacity(0.5),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.memory,
                                    color:
                                        !_gemmaUseCPU
                                            ? theme.colorScheme.onPrimary
                                            : theme.colorScheme.onSurface,
                                    size: 16,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'GPU',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          !_gemmaUseCPU
                                              ? theme.colorScheme.onPrimary
                                              : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    'Designed for higher performance tasks.',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color:
                                          !_gemmaUseCPU
                                              ? theme.colorScheme.onPrimary
                                                  .withOpacity(0.8)
                                              : theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          _isLoadingGemmaModel ? null : _pickGemmaModelFile,
                      icon:
                          _isLoadingGemmaModel
                              ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.primary,
                                ),
                              )
                              : const Icon(Icons.folder_open),
                      label: Text(
                        _isLoadingGemmaModel ? 'Loading...' : 'Change Model',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed:
                        _isLoadingGemmaModel
                            ? null
                            : _confirmAndClearGemmaModel,
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Delete All'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoadingGemmaModel ? null : _pickGemmaModelFile,
                  icon:
                      _isLoadingGemmaModel
                          ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.onSecondary,
                            ),
                          )
                          : const Icon(Icons.folder_open),
                  label: Text(
                    _isLoadingGemmaModel ? 'Loading...' : 'Select Model File',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondaryContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSection(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
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
            Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Current Model: $_selectedModelName',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // AI Output Settings Section (moved to top)
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
            const SizedBox(height: 8),
            _buildLanguageSection(theme),

            // AI Providers Header section
            const SizedBox(height: 16),
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
                    onPressed: _showModelSelectionGuide,
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
            ...AIProviderConfig.getProviders().map(
              (provider) => _buildProviderToggle(provider, theme),
            ),

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
            _buildGemmaModelSection(theme),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
