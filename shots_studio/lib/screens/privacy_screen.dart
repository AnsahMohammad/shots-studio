import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shots_studio/services/snackbar_service.dart';
import 'package:shots_studio/utils/privacy_content_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';

class PrivacyScreen extends StatefulWidget {
  final bool isAcknowledgementRequired;
  final VoidCallback? onAgreed;
  final VoidCallback? onDisagreed;

  const PrivacyScreen({
    super.key,
    this.isAcknowledgementRequired = false,
    this.onAgreed,
    this.onDisagreed,
  });

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _analyticsEnabled = false; // Default to false for privacy - opt-in only

  @override
  void initState() {
    super.initState();
    _loadAnalyticsEnabledPref();
  }

  void _loadAnalyticsEnabledPref() async {
    final analyticsService = AnalyticsService();
    setState(() {
      _analyticsEnabled = analyticsService.analyticsEnabled;
    });
  }

  Future<void> _saveAnalyticsEnabled(bool value) async {
    final analyticsService = AnalyticsService();
    if (value) {
      await analyticsService.enableAnalytics();
    } else {
      await analyticsService.disableAnalytics();
    }
  }

  Future<void> _launchURL(BuildContext context, String urlString) async {
    // Track URL launches from privacy screen
    AnalyticsService().logFeatureUsed('privacy_screen_url_clicked');

    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      SnackbarService().showError(context, 'Could not launch $urlString');
    }
  }

  Future<void> _handleAgree(BuildContext context) async {
    if (widget.isAcknowledgementRequired) {
      // Track privacy agreement
      AnalyticsService().logFeatureUsed('privacy_screen_agreed');

      // Get app version to make privacy acknowledgment version-specific
      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = packageInfo.version;

      // Version-specific privacy acknowledgment key
      final String privacyAcknowledgementKey =
          'privacyAcknowledgementAccepted_v$appVersion';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(privacyAcknowledgementKey, true);

      if (widget.onAgreed != null) {
        widget.onAgreed!();
      }
    }

    Navigator.of(context).pop(true); // Return true to indicate agreement
  }

  void _handleDisagree(BuildContext context) {
    if (widget.isAcknowledgementRequired) {
      // Track privacy disagreement
      AnalyticsService().logFeatureUsed('privacy_screen_disagreed');

      if (widget.onDisagreed != null) {
        widget.onDisagreed!();
      } else {
        SystemNavigator.pop();
      }
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        title: Text(
          widget.isAcknowledgementRequired
              ? 'Data Processing Acknowledgment'
              : 'Privacy Notice',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        automaticallyImplyLeading: !widget.isAcknowledgementRequired,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.isAcknowledgementRequired) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: theme.colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "By clicking 'Agree & Continue', you acknowledge and consent to the following:",
                                style: TextStyle(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Privacy content from provider
                    ...PrivacyContentProvider.getPrivacyContent(
                      context,
                      launchUrlCallback: _launchURL,
                    ),

                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchListTile(
                            secondary: Icon(
                              Icons.analytics_outlined,
                              color: theme.colorScheme.primary,
                            ),
                            title: Text(
                              'Analytics & Telemetry',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              _analyticsEnabled
                                  ? 'Help improve the app by sharing usage data'
                                  : 'Analytics and crash reporting disabled',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            value: _analyticsEnabled,
                            activeThumbColor: theme.colorScheme.primary,
                            onChanged: (bool value) {
                              setState(() {
                                _analyticsEnabled = value;
                              });
                              _saveAnalyticsEnabled(value);

                              // Track analytics for analytics setting (meta-analytics!)
                              AnalyticsService().logFeatureUsed(
                                'settings_analytics_${value ? 'enabled' : 'disabled'}',
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 16.0,
                              right: 16.0,
                            ),
                            child: Text(
                              "Anonymous usage analytics help us improve the app experience. This feature is completely optional and can be disabled at any time. For more details, you can inspect the source code of our analytics implementation here: ",
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 16.0,
                              right: 16.0,
                              top: 4.0,
                            ),
                            child: GestureDetector(
                              onTap: () async {
                                const url =
                                    'https://github.com/AnsahMohammad/shots-studio/blob/main/shots_studio/lib/services/analytics/posthog_analytics_service.dart';
                                final Uri uri = Uri.parse(url);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                } else {
                                  SnackbarService().showError(
                                    context,
                                    'Could not launch $url',
                                  );
                                }
                              },
                              child: Text(
                                'Analytics Source Code',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Additional spacing and information
                    if (!widget.isAcknowledgementRequired) ...[
                      const SizedBox(height: 16),
                    ],

                    // Legacy container for non-acknowledgment screens (keeping for any additional content)
                    if (!widget.isAcknowledgementRequired) ...[
                      // This section can be used for any additional settings that are specific
                      // to the privacy screen accessed from app drawer (not first-time setup)
                    ],

                    const SizedBox(
                      height: 100,
                    ), // Extra space for bottom buttons
                  ],
                ),
              ),
            ),

            // Bottom action buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child:
                  widget.isAcknowledgementRequired
                      ? Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _handleDisagree(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                side: BorderSide(
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                              child: Text(
                                'Disagree',
                                style: TextStyle(
                                  color: theme.colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () => _handleAgree(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: Text(
                                'Agree & Continue',
                                style: TextStyle(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                      : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Close',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper function to show privacy screen when acknowledgment is needed
Future<bool> showPrivacyScreenIfNeeded(BuildContext context) async {
  // Get app version to make privacy acknowledgment version-specific
  final packageInfo = await PackageInfo.fromPlatform();
  final appVersion = packageInfo.version;

  // Version-specific privacy acknowledgment key
  final String privacyAcknowledgementKey =
      'privacyAcknowledgementAccepted_v$appVersion';
  final prefs = await SharedPreferences.getInstance();
  bool? acknowledged = prefs.getBool(privacyAcknowledgementKey);

  if (acknowledged == true) {
    // Privacy already accepted for this version, no need to show screen
    return true;
  }

  if (!context.mounted) return false;

  // Track privacy screen shown
  AnalyticsService().logFeatureUsed('privacy_screen_shown');
  AnalyticsService().logScreenView('privacy_acknowledgment_screen');

  // Navigate to privacy screen and wait for result
  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder:
          (context) => PrivacyScreen(
            isAcknowledgementRequired: true,
            onAgreed: () {
              // Agreement is handled in the screen itself
            },
            onDisagreed: () {
              SystemNavigator.pop();
            },
          ),
    ),
  );

  return result ?? false;
}
