import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shots_studio/services/snackbar_service.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';
import 'package:shots_studio/screens/ai_settings_screen.dart';
import 'package:shots_studio/utils/ai_provider_config.dart';

/// AI provider option for the onboarding flow
enum AIProviderOption { gemini, gemma, ocr }

class AISetupOnboardingScreen extends StatefulWidget {
  final String? currentApiKey;
  final Function(String) onApiKeyEntered;

  const AISetupOnboardingScreen({
    super.key,
    this.currentApiKey,
    required this.onApiKeyEntered,
  });

  @override
  State<AISetupOnboardingScreen> createState() =>
      _AISetupOnboardingScreenState();
}

class _AISetupOnboardingScreenState extends State<AISetupOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  AIProviderOption _selectedOption = AIProviderOption.gemini;
  final TextEditingController _apiKeyController = TextEditingController();
  bool _permissionGranted = false;
  bool _notificationPermissionGranted = false;
  bool _isRequestingPermission = false;
  bool _allPermissionsAlreadyGranted = false;

  // Total pages: Intro (0), Permissions (1), AI Selection (2), Configuration (3)
  static const int _totalPages = 4;

  @override
  void initState() {
    super.initState();
    AnalyticsService().logScreenView('ai_setup_onboarding');
    AnalyticsService().logFeatureUsed('ai_setup_onboarding_shown');
    _checkExistingPermissions();
    // Pre-populate API key if it exists
    if (widget.currentApiKey != null && widget.currentApiKey!.isNotEmpty) {
      _apiKeyController.text = widget.currentApiKey!;
    }
  }

  Future<void> _checkExistingPermissions() async {
    final photosStatus = await Permission.photos.status;
    final storageStatus = await Permission.storage.status;
    final notificationStatus = await Permission.notification.status;

    final hasStoragePermission =
        photosStatus.isGranted || storageStatus.isGranted;
    final hasNotificationPermission = notificationStatus.isGranted;

    if (mounted) {
      setState(() {
        _permissionGranted = hasStoragePermission;
        _notificationPermissionGranted = hasNotificationPermission;
        // If all permissions are already granted, we can skip the permissions page
        _allPermissionsAlreadyGranted =
            hasStoragePermission && hasNotificationPermission;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  /// Check if we should skip the configuration page (page 3)
  /// Skip if: Gemini selected AND API key already exists
  bool _shouldSkipConfigPage() {
    return _selectedOption == AIProviderOption.gemini &&
        widget.currentApiKey != null &&
        widget.currentApiKey!.isNotEmpty;
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      // If on intro page (page 0) and all permissions already granted, skip to AI selection
      if (_currentPage == 0 && _allPermissionsAlreadyGranted) {
        _pageController.jumpToPage(2); // Jump to AI selection
        return;
      }
      // If on AI selection page (page 2) and should skip config, complete onboarding
      if (_currentPage == 2 && _shouldSkipConfigPage()) {
        _completeOnboarding();
        return;
      }
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _launchURL(String urlString) async {
    AnalyticsService().logFeatureUsed('ai_setup_url_clicked');
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        SnackbarService().showError(context, 'Could not launch $urlString');
      }
    }
  }

  Future<void> _requestPermissions() async {
    if (_isRequestingPermission) return;

    setState(() {
      _isRequestingPermission = true;
    });

    try {
      // Request photos/storage permission
      var storageStatus = await Permission.photos.request();

      // For Android compatibility, also try storage permission
      if (!storageStatus.isGranted && Platform.isAndroid) {
        storageStatus = await Permission.storage.request();
      }

      // Request notification permission
      final notificationStatus = await Permission.notification.request();

      if (mounted) {
        setState(() {
          _permissionGranted = storageStatus.isGranted;
          _notificationPermissionGranted = notificationStatus.isGranted;
          _isRequestingPermission = false;
        });

        if (storageStatus.isGranted && notificationStatus.isGranted) {
          AnalyticsService().logFeatureUsed(
            'onboarding_all_permissions_granted',
          );
          SnackbarService().showSuccess(context, 'Permissions granted!');
        } else if (storageStatus.isGranted) {
          AnalyticsService().logFeatureUsed(
            'onboarding_storage_permission_granted',
          );
          SnackbarService().showSuccess(context, 'Storage permission granted!');
        } else if (storageStatus.isPermanentlyDenied) {
          SnackbarService().showWarning(
            context,
            'Permission denied. Please enable in Settings.',
          );
          await openAppSettings();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRequestingPermission = false;
        });
        SnackbarService().showError(context, 'Error requesting permission');
      }
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();

    // First, disable ALL providers
    await prefs.setBool(AIProviderConfig.providerPrefKeys['gemini']!, false);
    await prefs.setBool(AIProviderConfig.providerPrefKeys['gemma']!, false);
    await prefs.setBool(AIProviderConfig.providerPrefKeys['ocr']!, false);

    // Save onboarding completion
    await prefs.setBool('ai_setup_onboarding_completed', true);

    // Enable ONLY the selected provider
    switch (_selectedOption) {
      case AIProviderOption.gemini:
        await prefs.setBool(AIProviderConfig.providerPrefKeys['gemini']!, true);
        // Save API key if entered
        if (_apiKeyController.text.trim().isNotEmpty) {
          final apiKey = _apiKeyController.text.trim();
          await prefs.setString('apiKey', apiKey);
          widget.onApiKeyEntered(apiKey);
        }
        // Set model to default Gemini model
        await prefs.setString('modelName', 'gemini-2.5-flash-lite');
        AnalyticsService().logFeatureUsed('ai_setup_completed_gemini');
        break;

      case AIProviderOption.gemma:
        await prefs.setBool(AIProviderConfig.providerPrefKeys['gemma']!, true);
        // Set model to Gemma
        await prefs.setString('modelName', 'gemma');
        AnalyticsService().logFeatureUsed('ai_setup_completed_gemma');
        break;

      case AIProviderOption.ocr:
        await prefs.setBool(AIProviderConfig.providerPrefKeys['ocr']!, true);
        // Set model to OCR
        await prefs.setString('modelName', 'tesseract-ocr');
        AnalyticsService().logFeatureUsed('ai_setup_completed_ocr');
        break;
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _navigateToAISettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AISettingsScreen(
              currentModelName: 'gemma',
              onModelChanged: (String newModel) {},
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: List.generate(_totalPages, (index) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 4,
                      decoration: BoxDecoration(
                        color:
                            index <= _currentPage
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildIntroductionPage(theme),
                  _buildPermissionsPage(theme),
                  _buildAISelectionPage(theme),
                  _buildConfigurationPage(theme),
                ],
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousPage,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: theme.colorScheme.primary),
                        ),
                        child: Text(
                          'Back',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed:
                          _currentPage == _totalPages - 1
                              ? _completeOnboarding
                              : _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _currentPage == _totalPages - 1
                            ? 'Get Started'
                            : 'Continue',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroductionPage(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome header
          Center(
            child: Icon(
              Icons.auto_awesome,
              size: 80,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Welcome to Shots Studio',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Your AI-powered screenshot manager',
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),

          // Features list
          _buildFeatureItem(
            theme,
            Icons.image_search,
            'Smart Organization',
            'AI analyzes and categorizes your screenshots automatically',
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            theme,
            Icons.search,
            'Powerful Search',
            'Find any screenshot by describing what you\'re looking for',
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            theme,
            Icons.collections,
            'Auto Collections',
            'Screenshots are grouped into smart collections based on content',
          ),
          const SizedBox(height: 32),

          // How it works
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'How It Works',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Shots Studio uses AI to understand the content of your screenshots. '
                  'This makes them easier to find and organize without manual tagging.',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
    ThemeData theme,
    IconData icon,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionsPage(ThemeData theme) {
    final bool allGranted =
        _permissionGranted && _notificationPermissionGranted;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Icon(
              Icons.security,
              size: 64,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'App Permissions',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Shots Studio needs a couple of permissions to work properly',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),

          // Storage/Photos permission explanation
          _buildPermissionCard(
            theme,
            icon: Icons.folder_open,
            title: 'Photos & Storage',
            description: 'Access your screenshots to organize and search them',
            isGranted: _permissionGranted,
            reasons: [
              'Load your existing screenshots',
              'Detect new screenshots automatically',
            ],
          ),
          const SizedBox(height: 16),

          // Notification permission explanation
          _buildPermissionCard(
            theme,
            icon: Icons.notifications_active,
            title: 'Notifications',
            description: 'Send you reminders and alerts about your screenshots',
            isGranted: _notificationPermissionGranted,
            reasons: [
              'Remind you about screenshots you saved',
              'Notify when AI processing is complete',
            ],
          ),
          const SizedBox(height: 24),

          // Grant permissions button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  _isRequestingPermission || allGranted
                      ? null
                      : _requestPermissions,
              icon:
                  _isRequestingPermission
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
                      : Icon(allGranted ? Icons.check : Icons.lock_open),
              label: Text(
                _isRequestingPermission
                    ? 'Requesting...'
                    : allGranted
                    ? 'All Permissions Granted'
                    : 'Grant Permissions',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    allGranted ? Colors.green : theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor:
                    allGranted ? Colors.green.withOpacity(0.7) : null,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Note about skipping
          if (!allGranted)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can continue without some permissions, but some features may not work.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
    required List<String> reasons,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isGranted
                ? Colors.green.withOpacity(0.1)
                : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isGranted
                  ? Colors.green.withOpacity(0.3)
                  : theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:
                  isGranted
                      ? Colors.green.withOpacity(0.2)
                      : theme.colorScheme.secondaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isGranted ? Colors.green : theme.colorScheme.secondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (isGranted)
                      Icon(Icons.check_circle, color: Colors.green, size: 18),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                ...reasons.map(
                  (reason) => Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            reason,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
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
        ],
      ),
    );
  }

  Widget _buildPermissionReason(ThemeData theme, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurface),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAISelectionPage(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Your AI Provider',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select how you want Shots Studio to process your screenshots',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // AI Provider dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.5),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<AIProviderOption>(
                value: _selectedOption,
                isExpanded: true,
                dropdownColor: theme.colorScheme.surface,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: theme.colorScheme.primary,
                ),
                items: [
                  DropdownMenuItem(
                    value: AIProviderOption.gemini,
                    child: Row(
                      children: [
                        Icon(Icons.cloud, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        const Text('Gemini (Cloud AI)'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: AIProviderOption.gemma,
                    child: Row(
                      children: [
                        Icon(
                          Icons.phone_android,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 12),
                        const Text('On-Device AI (Gemma)'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: AIProviderOption.ocr,
                    child: Row(
                      children: [
                        Icon(
                          Icons.text_fields,
                          color: theme.colorScheme.tertiary,
                        ),
                        const SizedBox(width: 12),
                        const Text('OCR Only'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedOption = value;
                    });
                    AnalyticsService().logFeatureUsed(
                      'ai_setup_selected_${value.name}',
                    );
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Pros and Cons section
          _buildProsConsSection(theme),

          const SizedBox(height: 24),

          // Settings reminder
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.settings,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You can change this anytime in Settings → AI Settings',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProsConsSection(ThemeData theme) {
    String title;
    List<String> pros;
    List<String> cons;

    switch (_selectedOption) {
      case AIProviderOption.gemini:
        title = 'Gemini (Cloud AI)';
        pros = [
          'Best performance and accuracy',
          'Fast processing',
          'Free tier available for most users',
          'Always up-to-date with latest improvements',
        ];
        cons = [
          'Requires internet connection',
          'API key needed (free to obtain)',
          'Screenshots sent to Google servers for processing',
        ];
        break;
      case AIProviderOption.gemma:
        title = 'On-Device AI (Gemma)';
        pros = [
          'Fully private - all processing on device',
          'Works completely offline',
          'No API key required',
          'Your data never leaves your device',
        ];
        cons = [
          'Slower processing than cloud AI',
          'Requires ~3GB storage for model',
          'May be slow on older devices',
          'Need to download model first',
        ];
        break;
      case AIProviderOption.ocr:
        title = 'OCR Only';
        pros = [
          'Fastest option',
          'Minimal resource usage',
          'Works completely offline',
          'No downloads required',
        ];
        cons = [
          'No AI-powered categorization',
          'Text search only',
          'Cannot understand image content',
          'No smart collections',
        ];
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),

          // Pros
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                'Advantages',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...pros.map(
            (pro) => Padding(
              padding: const EdgeInsets.only(left: 28, bottom: 4),
              child: Text(
                '• $pro',
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Cons
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Considerations',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...cons.map(
            (con) => Padding(
              padding: const EdgeInsets.only(left: 28, bottom: 4),
              child: Text(
                '• $con',
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationPage(ThemeData theme) {
    switch (_selectedOption) {
      case AIProviderOption.gemini:
        return _buildGeminiConfigPage(theme);
      case AIProviderOption.gemma:
        return _buildGemmaConfigPage(theme);
      case AIProviderOption.ocr:
        return _buildOCRConfigPage(theme);
    }
  }

  Widget _buildGeminiConfigPage(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud, color: theme.colorScheme.primary, size: 32),
              const SizedBox(width: 12),
              Text(
                'Set Up Gemini',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your Google Gemini API key to enable cloud AI features',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),

          // API Key input
          TextField(
            controller: _apiKeyController,
            style: TextStyle(color: theme.colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: 'API Key',
              hintText: 'AIzaSy...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Icon(Icons.key, color: theme.colorScheme.primary),
              suffixIcon: IconButton(
                icon: Icon(Icons.open_in_new, color: theme.colorScheme.primary),
                onPressed:
                    () => _launchURL('https://aistudio.google.com/app/apikey'),
                tooltip: 'Get API key',
              ),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 24),

          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'How to get an API key:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildStep(theme, '1', 'Go to Google AI Studio'),
                _buildStep(theme, '2', 'Sign in with your Google account'),
                _buildStep(theme, '3', 'Click "Get API Key"'),
                _buildStep(theme, '4', 'Create a new API key'),
                _buildStep(theme, '5', 'Copy and paste it here'),
                const SizedBox(height: 12),
                InkWell(
                  onTap:
                      () =>
                          _launchURL('https://aistudio.google.com/app/apikey'),
                  child: Text(
                    '→ Open Google AI Studio',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Note about continuing without API key
          _buildSettingsReminder(theme),
        ],
      ),
    );
  }

  Widget _buildStep(ThemeData theme, String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGemmaConfigPage(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.phone_android,
                color: theme.colorScheme.secondary,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Set Up On-Device AI',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Download the Gemma model to process screenshots entirely on your device',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 32),

          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.secondary.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.download, color: theme.colorScheme.secondary),
                    const SizedBox(width: 8),
                    Text(
                      'Download Required',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'The Gemma AI model (~3GB) needs to be downloaded before you can use on-device processing.',
                  style: TextStyle(
                    color: theme.colorScheme.onSecondaryContainer,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _navigateToAISettings,
                    icon: const Icon(Icons.settings),
                    label: const Text('Open AI Settings'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: theme.colorScheme.onSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // What happens next
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'What happens next',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '1. Click "Get Started" to continue\n'
                  '2. Go to the app menu → AI Settings\n'
                  '3. Enable "On-Device AI (Gemma)"\n'
                  '4. Download the model',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSettingsReminder(theme),
        ],
      ),
    );
  }

  Widget _buildOCRConfigPage(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.text_fields,
                color: theme.colorScheme.tertiary,
                size: 32,
              ),
              const SizedBox(width: 12),
              Text(
                'OCR Only Mode',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Extract text from screenshots for basic search functionality',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 32),

          // Warning card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Limited Functionality',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'With OCR only mode:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                _buildWarningItem(
                  theme,
                  'AI-powered categorization will NOT work',
                ),
                _buildWarningItem(
                  theme,
                  'Smart collections will NOT be created',
                ),
                _buildWarningItem(
                  theme,
                  'You can only search by text found in screenshots',
                ),
                _buildWarningItem(
                  theme,
                  'Image content understanding is NOT available',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // What OCR can do
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'What OCR can do',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '• Extract visible text from screenshots\n'
                  '• Search by extracted text content\n'
                  '• Works completely offline\n'
                  '• No downloads or API keys required',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSettingsReminder(theme),
        ],
      ),
    );
  }

  Widget _buildSettingsReminder(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.settings, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You can change all these options anytime in Settings → AI Settings',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningItem(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.close, color: Colors.orange.shade700, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper function to show the AI setup onboarding if needed
Future<void> showAISetupOnboardingIfNeeded(
  BuildContext context,
  String? currentApiKey,
  Function(String) onApiKeyEntered,
) async {
  const String onboardingKey = 'ai_setup_onboarding_completed';

  final prefs = await SharedPreferences.getInstance();
  bool? onboardingCompleted = prefs.getBool(onboardingKey);

  // Show onboarding if not completed yet
  if (onboardingCompleted != true) {
    if (!context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => AISetupOnboardingScreen(
              currentApiKey: currentApiKey,
              onApiKeyEntered: onApiKeyEntered,
            ),
      ),
    );
  }
}
