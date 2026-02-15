import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';
import 'package:shots_studio/services/api_validation_service.dart';
import 'package:shots_studio/services/snackbar_service.dart';
import 'package:shots_studio/l10n/app_localizations.dart';

class ApiKeySection extends StatefulWidget {
  final bool isGeminiEnabled;

  const ApiKeySection({super.key, required this.isGeminiEnabled});

  @override
  State<ApiKeySection> createState() => _ApiKeySectionState();
}

class _ApiKeySectionState extends State<ApiKeySection> {
  late TextEditingController _apiKeyController;
  final FocusNode _apiKeyFocusNode = FocusNode();
  bool _isValidatingApiKey = false;
  bool? _apiKeyValid;

  static const String _apiKeyPrefKey = 'apiKey';

  bool get _shouldShow => widget.isGeminiEnabled;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController();

    AnalyticsService().logFeatureUsed('view_api_key_settings');

    _loadApiKey();
  }

  @override
  void didUpdateWidget(covariant ApiKeySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isGeminiEnabled != oldWidget.isGeminiEnabled) {
      _apiKeyValid = null;
      ApiValidationService().clearCache();
      _loadApiKeyValidationState();
    }
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString(_apiKeyPrefKey) ?? '';
    _apiKeyController.text = apiKey;
    _loadApiKeyValidationState();
  }

  Future<void> _saveApiKey(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPrefKey, value);
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
        modelName: 'gemini-2.0-flash',
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

      AnalyticsService().logFeatureUsed('api_key_validation_ai_settings');
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
        modelName: 'gemini-2.0-flash',
      );
      if (mounted) {
        setState(() {
          _apiKeyValid = isValid;
        });
      }
    }
  }

  Widget _buildStatusChip(ThemeData theme) {
    if (_apiKeyController.text.isEmpty) {
      return _chip(
        theme,
        Icons.key_off,
        AppLocalizations.of(context)?.apiKeyRequired ?? 'Required',
        theme.colorScheme.error,
      );
    } else if (_apiKeyValid == true) {
      return _chip(
        theme,
        Icons.verified,
        AppLocalizations.of(context)?.apiKeyValid ?? 'Valid',
        theme.colorScheme.primary,
      );
    } else if (_apiKeyValid == false) {
      return _chip(
        theme,
        Icons.error_outline,
        AppLocalizations.of(context)?.apiKeyValidationFailed ?? 'Invalid',
        theme.colorScheme.error,
      );
    } else {
      return _chip(
        theme,
        Icons.help_outline,
        AppLocalizations.of(context)?.apiKeyNotValidated ?? 'Not validated',
        theme.colorScheme.onSurfaceVariant,
      );
    }
  }

  Widget _chip(ThemeData theme, IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      elevation: 0,
      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Icon(
                  Icons.vpn_key_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'API KEY',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                _buildStatusChip(theme),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Required for Gemini models. Get a free key from Google AI Studio.',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),

            // API Key Input
            TextFormField(
              controller: _apiKeyController,
              focusNode: _apiKeyFocusNode,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText:
                    AppLocalizations.of(context)?.enterApiKey ??
                    'Enter Gemini API Key',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.5),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color:
                        _apiKeyController.text.isEmpty
                            ? theme.colorScheme.error.withValues(alpha: 0.5)
                            : theme.colorScheme.outline.withValues(alpha: 0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2.0,
                  ),
                ),
                suffixIcon:
                    _apiKeyController.text.isNotEmpty
                        ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            _apiKeyController.clear();
                            _saveApiKey('');
                            setState(() {
                              _apiKeyValid = null;
                            });
                            ApiValidationService().clearCache();
                            AnalyticsService().logFeatureUsed(
                              'api_key_removed_ai_settings',
                            );
                          },
                        )
                        : null,
              ),
              obscureText: true,
              onChanged: (value) {
                _saveApiKey(value);

                if (value.isNotEmpty) {
                  AnalyticsService().logFeatureUsed(
                    'api_key_added_ai_settings',
                  );
                  AnalyticsService().logFeatureAdopted('gemini_api_configured');
                }

                setState(() {
                  _apiKeyValid = null;
                });

                ApiValidationService().clearCache();
              },
            ),
            const SizedBox(height: 12),

            // Action buttons row
            Row(
              children: [
                // Validate button
                if (_apiKeyController.text.isNotEmpty)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isValidatingApiKey ? null : _validateApiKey,
                      icon:
                          _isValidatingApiKey
                              ? SizedBox(
                                width: 14,
                                height: 14,
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
                                'Validate',
                        style: const TextStyle(fontSize: 13),
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
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                if (_apiKeyController.text.isNotEmpty) const SizedBox(width: 8),
                // Get API Key button
                OutlinedButton.icon(
                  onPressed: () async {
                    AnalyticsService().logFeatureUsed(
                      'api_key_help_clicked_ai_settings',
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
                  icon: Icon(
                    Icons.open_in_new,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                  label: Text(
                    AppLocalizations.of(context)?.getApiKey ?? 'Get API Key',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.colorScheme.primary),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),

            // Helper info for empty state
            if (_apiKeyController.text.isEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
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
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Quick Setup',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '1. Tap "Get API Key" above\n2. Sign in to Google AI Studio\n3. Create a key and paste it here',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
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
  void dispose() {
    _apiKeyController.dispose();
    _apiKeyFocusNode.dispose();
    super.dispose();
  }
}
