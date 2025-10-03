import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shots_studio/services/snackbar_service.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';

class ApiKeyGuideDialog extends StatefulWidget {
  final VoidCallback onSetupLater;
  final Function(String) onApiKeyEntered;

  const ApiKeyGuideDialog({
    super.key,
    required this.onSetupLater,
    required this.onApiKeyEntered,
  });

  @override
  State<ApiKeyGuideDialog> createState() => _ApiKeyGuideDialogState();
}

class _ApiKeyGuideDialogState extends State<ApiKeyGuideDialog> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _isValidating = false;
  bool _showApiKeyField = false;

  @override
  void initState() {
    super.initState();
    // Track API key guide dialog shown
    AnalyticsService().logFeatureUsed('api_key_guide_dialog_shown');
  }

  Future<void> _launchURL(String urlString) async {
    // Track URL clicks from API key guide
    AnalyticsService().logFeatureUsed('api_key_guide_url_clicked');

    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        SnackbarService().showError(context, 'Could not launch $urlString');
      }
    }
  }

  void _handleSetupNow() {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      SnackbarService().showWarning(context, 'Please enter your API key');
      return;
    }

    // Track API key setup attempt
    AnalyticsService().logFeatureUsed('api_key_setup_attempted');

    setState(() {
      _isValidating = true;
    });

    // Simple validation - check if it looks like a valid API key
    if (apiKey.length < 10) {
      setState(() {
        _isValidating = false;
      });
      SnackbarService().showError(
        context,
        'API key seems too short. Please check and try again.',
      );
      return;
    }

    Navigator.of(context).pop();

    // Track successful API key setup
    AnalyticsService().logFeatureUsed('api_key_setup_completed');

    widget.onApiKeyEntered(apiKey);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.key, color: theme.colorScheme.primary, size: 24),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Welcome to Shots Studio!',
              style: TextStyle(color: theme.colorScheme.primary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Text(
              "Get the most out of your screenshots with AI-powered organization and smart categorization!",
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: theme.colorScheme.secondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "AI features include:",
                    style: TextStyle(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "• Auto-categorize screenshots by content",
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  Text(
                    "• Generate searchable descriptions",
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  Text(
                    "• Create smart collections",
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.cloud,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Recommended: Cloud AI (Best Performance)",
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Add your Google Gemini API key for the best AI performance and faster processing. The API is free for most users.",
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.secondary.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.offline_bolt,
                        color: theme.colorScheme.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Alternative: Offline AI (Uses Device Resources)",
                          style: TextStyle(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Download the Gemma model in AI Settings for offline processing. Requires device storage and may be slower on older devices.",
                    style: TextStyle(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (_showApiKeyField) ...[
              const SizedBox(height: 20),
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
                        Icon(
                          Icons.vpn_key,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Enter your Google Gemini API key:",
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _apiKeyController,
                      autofocus: true,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: "AIzaSy...",
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            Icons.help_outline,
                            color: theme.colorScheme.primary,
                          ),
                          onPressed:
                              () => _launchURL(
                                'https://aistudio.google.com/app/apikey',
                              ),
                          tooltip: "Get API key",
                        ),
                      ),
                      onSubmitted: (_) => _handleSetupNow(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "💡 Don't have one? Click the help icon above to get your free API key from Google AI Studio.",
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Remember: You can use offline AI instead by downloading the Gemma model in AI Settings.",
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(
            'Continue without API key',
            style: TextStyle(color: theme.colorScheme.secondary),
          ),
          onPressed: () {
            // Track skip action
            AnalyticsService().logFeatureUsed('api_key_guide_skipped');

            Navigator.of(context).pop();
            widget.onSetupLater();
          },
        ),
        if (!_showApiKeyField)
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add API key'),
            onPressed: () {
              // Track show API key field action
              AnalyticsService().logFeatureUsed(
                'api_key_guide_add_key_clicked',
              );

              setState(() {
                _showApiKeyField = true;
              });
            },
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
          )
        else
          FilledButton.icon(
            icon:
                _isValidating
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
                    : const Icon(Icons.check),
            label: Text(_isValidating ? 'Saving...' : 'Confirm'),
            onPressed: _isValidating ? null : _handleSetupNow,
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
          ),
      ],
    );
  }
}

Future<void> showApiKeyGuideIfNeeded(
  BuildContext context,
  String? currentApiKey,
  Function(String) onApiKeyEntered,
) async {
  const String apiKeyGuideShownKey = 'apiKeyGuideShown';

  // Get app version to check version-specific privacy acknowledgment
  final packageInfo = await PackageInfo.fromPlatform();
  final appVersion = packageInfo.version;
  final String privacyAcknowledgementKey =
      'privacyAcknowledgementAccepted_v$appVersion';

  final prefs = await SharedPreferences.getInstance();
  bool? guideShown = prefs.getBool(apiKeyGuideShownKey);
  bool? privacyAccepted = prefs.getBool(privacyAcknowledgementKey);

  // Show the guide if:
  // 1. Privacy has been accepted (to avoid cluttered dialogs)
  // 2. The guide hasn't been shown yet
  // 3. API key is not set
  if (privacyAccepted == true &&
      guideShown != true &&
      (currentApiKey == null || currentApiKey.isEmpty)) {
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return ApiKeyGuideDialog(
          onSetupLater: () async {
            await prefs.setBool(apiKeyGuideShownKey, true);
          },
          onApiKeyEntered: (String apiKey) async {
            await prefs.setBool(apiKeyGuideShownKey, true);
            onApiKeyEntered(apiKey);

            if (context.mounted) {
              SnackbarService().showSuccess(
                context,
                "API key saved! Cloud AI features are now available.",
              );
            }
          },
        );
      },
    );
  }
}
