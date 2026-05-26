import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';
import 'package:shots_studio/services/snackbar_service.dart';
import 'package:shots_studio/services/prefilter_service.dart';
import 'package:shots_studio/services/prefilter_model_download_service.dart';

class PrefilterSettingsScreen extends StatefulWidget {
  const PrefilterSettingsScreen({super.key});

  @override
  State<PrefilterSettingsScreen> createState() =>
      _PrefilterSettingsScreenState();
}

class _PrefilterSettingsScreenState extends State<PrefilterSettingsScreen> {
  String _selectedMode = 'none';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMode();
    AnalyticsService().logScreenView('prefilter_settings_screen');
  }

  Future<void> _loadMode() async {
    final mode = await PrefilterService.getMode();
    final isDownloaded = await PrefilterModelDownloadService().isModelDownloaded();
    
    if (mounted) {
      setState(() {
        _selectedMode = mode;
        _isLoading = false;
        // If deep mode is selected but model is gone, fallback or show warning
        if (mode == 'deep' && !isDownloaded) {
          _selectedMode = 'light';
          PrefilterService.setMode('light');
        }
      });
    }
  }

  Future<void> _selectMode(String mode) async {
    if (mode == 'deep') {
      final isDownloaded = await PrefilterModelDownloadService().isModelDownloaded();
      if (!isDownloaded) {
        _showDownloadDialog();
        return;
      }
    }

    await PrefilterService.setMode(mode);
    if (mounted) {
      setState(() => _selectedMode = mode);
      AnalyticsService().logFeatureUsed('prefilter_mode_set_$mode');
      SnackbarService().showSuccess(
        context,
        'Privacy prefilter set to ${_modeLabel(mode)}',
      );
    }
  }

  void _showDownloadDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _PrefilterDownloadDialog(),
    ).then((success) {
      if (success == true) {
        _selectMode('deep');
      }
    });
  }

  String _modeLabel(String mode) {
    switch (mode) {
      case 'light':
        return 'Light';
      case 'deep':
        return 'Deep';
      default:
        return 'None';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Prefilter'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── What is the prefilter ─────────────────────────────────
                  _buildSectionLabel(theme, 'About'),
                  Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 4.0),
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.shield_outlined,
                                  color: theme.colorScheme.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Protect sensitive screenshots',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'The prefilter scans each screenshot\'s text locally '
                            'on your device before sending it to Gemini or Gemma. '
                            'Screenshots containing sensitive data are blocked '
                            'from AI processing. Nothing is sent to any server.',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer
                                  .withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: theme.colorScheme.primary
                                    .withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline,
                                    size: 14,
                                    color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'You can always allow individual blocked '
                                    'screenshots from their detail screen.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.primary,
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

                  // ── Mode selection ────────────────────────────────────────
                  const SizedBox(height: 12),
                  _buildSectionLabel(theme, 'Prefilter Mode'),
                  Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 4.0),
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainer,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Column(
                        children: [
                          _buildModeOption(
                            theme: theme,
                            mode: 'none',
                            icon: Icons.block,
                            iconColor: theme.colorScheme.onSurfaceVariant,
                            title: 'None',
                            subtitle:
                                'No filtering — all screenshots are sent to AI directly.',
                            badge: null,
                          ),
                          _buildDivider(theme),
                          _buildModeOption(
                            theme: theme,
                            mode: 'light',
                            icon: Icons.bolt,
                            iconColor: Colors.amber,
                            title: 'Light',
                            subtitle:
                                'Fast pattern scan using regex. Catches obvious '
                                'card numbers, API keys (Google, OpenAI, AWS, '
                                'GitHub, Stripe) and PEM private keys. '
                                'Runs in under 1ms per screenshot.',
                            badge: null,
                          ),
                          _buildDivider(theme),
                          _buildModeOption(
                            theme: theme,
                            mode: 'deep',
                            icon: Icons.psychology_outlined,
                            iconColor: theme.colorScheme.primary,
                            title: 'Deep',
                            subtitle:
                                'Runs all Light checks first, then uses an '
                                'on-device AI model (GLiNER) to detect passwords, '
                                'bank accounts, government IDs (Aadhaar, PAN, SSN), '
                                'UPI IDs and more. ~300ms per screenshot.',
                            badge: 'Recommended',
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── What gets detected ────────────────────────────────────
                  const SizedBox(height: 12),
                  _buildSectionLabel(theme, 'What Gets Detected'),
                  Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 4.0),
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          _buildDetectionRow(theme, Icons.credit_card,
                              'Credit / Debit Card Numbers',
                              'Light + Deep', Colors.red),
                          _buildDetectionRow(theme, Icons.vpn_key_outlined,
                              'API Keys & Secrets',
                              'Light + Deep', Colors.red),
                          _buildDetectionRow(theme, Icons.lock_outline,
                              'Passwords & OTPs',
                              'Deep only', theme.colorScheme.primary),
                          _buildDetectionRow(theme, Icons.account_balance_outlined,
                              'Bank Accounts, IBAN, UPI, NEFT',
                              'Deep only', theme.colorScheme.primary),
                          _buildDetectionRow(theme, Icons.badge_outlined,
                              'Aadhaar, PAN, SSN, Passport',
                              'Deep only', theme.colorScheme.primary),
                          _buildDetectionRow(theme, Icons.terminal,
                              'PEM / SSH Private Keys',
                              'Deep only', theme.colorScheme.primary),
                        ],
                      ),
                    ),
                  ),

                  // ── Deep mode model note ──────────────────────────────────
                  if (_selectedMode == 'deep') ...[
                    const SizedBox(height: 12),
                    _buildSectionLabel(theme, 'Deep Mode Model'),
                    Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 4.0),
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.memory,
                                    color: theme.colorScheme.primary,
                                    size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'GLiNER PII Small v1.0',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'knowledgator/gliner-pii-small-v1.0 — a span-based '
                              'NER model built on DeBERTa-v3-small. Runs fully '
                              'on-device via ONNX Runtime. ~85 MB. Requires ≥ 2 GB RAM.',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            FutureBuilder<bool>(
                              future: PrefilterModelDownloadService().isModelDownloaded(),
                              builder: (context, snapshot) {
                                final isDownloaded = snapshot.data ?? false;
                                return Text(
                                  isDownloaded 
                                    ? 'Model is downloaded and ready.' 
                                    : 'Model not found. Download required for Deep mode.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDownloaded ? theme.colorScheme.primary : theme.colorScheme.error,
                                    fontStyle: FontStyle.italic,
                                  ),
                                );
                              }
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  // ── Reusable widgets matching AISettingsScreen style ──────────────────────

  Widget _buildSectionLabel(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 28.0, top: 8.0, bottom: 4.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: theme.colorScheme.outline.withOpacity(0.2),
    );
  }

  Widget _buildModeOption({
    required ThemeData theme,
    required String mode,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String? badge,
  }) {
    final isSelected = _selectedMode == mode;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _selectMode(mode),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Radio indicator
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // Icon
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 12),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
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

  Widget _buildDetectionRow(
    ThemeData theme,
    IconData icon,
    String label,
    String modeTag,
    Color tagColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 7.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: tagColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              modeTag,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: tagColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrefilterDownloadDialog extends StatefulWidget {
  const _PrefilterDownloadDialog();

  @override
  State<_PrefilterDownloadDialog> createState() => _PrefilterDownloadDialogState();
}

class _PrefilterDownloadDialogState extends State<_PrefilterDownloadDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PrefilterModelDownloadService().startDownload();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ListenableBuilder(
      listenable: PrefilterModelDownloadService(),
      builder: (context, _) {
        final progress = PrefilterModelDownloadService().progress;
        final isError = progress.status == PrefilterDownloadStatus.error;
        final isCompleted = progress.status == PrefilterDownloadStatus.completed;

        return AlertDialog(
          title: Text(isCompleted ? 'Download Complete' : isError ? 'Download Failed' : 'Downloading Deep Model'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isCompleted && !isError) ...[
                const Text('Setting up deep scan engine (~80MB)...'),
                const SizedBox(height: 20),
                LinearProgressIndicator(value: progress.progress),
                const SizedBox(height: 10),
                Text('${(progress.progress * 100).toStringAsFixed(1)}%', 
                  style: theme.textTheme.bodySmall),
              ] else if (isError) ...[
                Text('Error: ${progress.error}', style: TextStyle(color: theme.colorScheme.error)),
              ] else ...[
                const Text('The Deep prefilter engine is now ready to use.'),
              ],
            ],
          ),
          actions: [
            if (isError)
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
            if (isError)
              ElevatedButton(
                onPressed: () => PrefilterModelDownloadService().startDownload(),
                child: const Text('Retry'),
              ),
            if (isCompleted)
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Get Started'),
              ),
          ],
        );
      },
    );
  }
}
