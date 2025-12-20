import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/sponsorship_service.dart';
import '../../services/analytics/analytics_service.dart';
import '../../services/update_checker_service.dart';
import '../../services/snackbar_service.dart';
import '../sponsorship/sponsorship_dialog.dart';
import '../update_dialog.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/build_source.dart';

class AboutSection extends StatelessWidget {
  final String appVersion;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const AboutSection({
    super.key,
    required this.appVersion,
    this.onTap,
    this.onLongPress,
  });

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $urlString');
    }
  }

  Future<void> _openDonationPage(BuildContext context) async {
    const List<String> donationUrls = [
      'https://ansahmohammad.github.io/shots-studio/donation.html',
      'https://shots-studio-854420.gitlab.io/donation.html',
    ];

    bool launched = false;
    String? lastError;

    for (int i = 0; i < donationUrls.length; i++) {
      final url = donationUrls[i];

      try {
        final Uri uri = Uri.parse(url);
        final success = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (success) {
          launched = true;
          // Log which platform was successfully used
          AnalyticsService().logFeatureUsed(
            'donation_opened_${i == 0 ? 'github' : 'gitlab'}',
          );
          break;
        }
      } catch (e) {
        lastError = e.toString();
        // Log failed attempt but continue to next URL
        AnalyticsService().logFeatureUsed(
          'donation_failed_${i == 0 ? 'github' : 'gitlab'}',
        );
        continue;
      }
    }

    if (!launched && context.mounted) {
      // Show error if all sources fail
      SnackbarService().showError(
        context,
        'Failed to open donation page: ${lastError ?? "Unknown error"}',
      );
    }
  }

  Future<void> _openSourceCode(BuildContext context) async {
    const List<String> sourceCodeUrls = [
      'https://github.com/AnsahMohammad/shots-studio',
      'https://gitlab.com/mohdansah10/shots-studio',
    ];

    bool launched = false;
    String? lastError;

    for (int i = 0; i < sourceCodeUrls.length; i++) {
      final url = sourceCodeUrls[i];
      final platform = i == 0 ? 'GitHub' : 'GitLab';

      try {
        final Uri uri = Uri.parse(url);
        final success = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (success) {
          launched = true;
          // Log which platform was successfully used
          AnalyticsService().logFeatureUsed(
            'source_code_opened_${platform.toLowerCase()}',
          );
          break;
        }
      } catch (e) {
        lastError = e.toString();
        // Log failed attempt but continue to next URL
        AnalyticsService().logFeatureUsed(
          'source_code_failed_${platform.toLowerCase()}',
        );
        continue;
      }
    }

    if (!launched && context.mounted) {
      // Show error if all sources fail
      SnackbarService().showError(
        context,
        'Failed to open source code: ${lastError ?? "Unknown error"}',
      );
    }
  }

  Future<void> _openFeedbackForm(BuildContext context) async {
    // // Show loading indicator
    // ScaffoldMessenger.of(
    //   context,
    // ).showSnackBar(const SnackBar(content: Text('Opening feedback form...')));

    try {
      // Fetch feedback URL from remote sources
      final feedbackUrl = await _getFeedbackUrl();

      if (feedbackUrl != null) {
        // Log analytics for feedback access
        AnalyticsService().logFeatureUsed('feedback_form_opened');

        await _launchURL(feedbackUrl);
      } else {
        if (context.mounted) {
          print('Failed to load feedback form');
        }
      }
    } catch (e) {
      // Show error if feedback form can't be loaded
      if (context.mounted) {
        SnackbarService().showError(
          context,
          'Failed to open feedback form: $e',
        );
      }
    }
  }

  /// Fetches feedback URL from remote sources with fallback
  Future<String?> _getFeedbackUrl() async {
    const List<String> feedbackUrls = [
      'https://ansahmohammad.github.io/shots-studio/feedback.json',
      'https://gitlab.com/mohdansah10/shots-studio/-/raw/main/docs/feedback.json',
    ];

    for (final url in feedbackUrls) {
      try {
        final response = await http
            .get(
              Uri.parse(url),
              headers: {
                'Accept': 'application/json',
                'User-Agent': 'shots_studio_app',
                'Content-Type': 'application/json',
              },
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data is Map<String, dynamic> && data.containsKey('form_link')) {
            return data['form_link'] as String;
          }
        }
      } catch (e) {
        // Continue to next URL if current one fails
        continue;
      }
    }
    return null; // Return null if all sources fail
  }

  Future<void> _checkForUpdatesManually(BuildContext context) async {
    // Show loading indicator
    SnackbarService().showInfo(context, 'Checking for updates...');

    try {
      final updateInfo = await UpdateCheckerService.checkForUpdates();

      if (updateInfo != null) {
        // Update is available, show dialog
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => UpdateDialog(updateInfo: updateInfo),
          );
        }
      } else {
        // No update available
        if (context.mounted) {
          SnackbarService().showSuccess(
            context,
            'You are running the latest version!',
          );
        }
      }
    } catch (e) {
      // Error occurred
      if (context.mounted) {
        SnackbarService().showError(context, 'Failed to check for updates: $e');
      }
    }
  }

  void _showSponsorshipDialog(BuildContext context) {
    final sponsorshipOptions = SponsorshipService.getAllOptions();

    // Route to fullscreen dialog
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (context) =>
                SponsorshipDialog(sponsorshipOptions: sponsorshipOptions),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _copyVersionToClipboard(BuildContext context) async {
    try {
      final versionText =
          'Version $appVersion (${BuildSource.current.displayName})';
      await Clipboard.setData(ClipboardData(text: versionText));
      if (context.mounted) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text('Copied to clipboard: $versionText'),
        //     duration: const Duration(seconds: 2),
        //   ),
        // );
        print('Copied to clipboard: $versionText');
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarService().showError(
          context,
          'Failed to copy version to clipboard',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Divider(color: theme.colorScheme.outline),
        ListTile(
          leading: Icon(Icons.code, color: theme.colorScheme.primary),
          title: Text(
            AppLocalizations.of(context)?.sourceCode ?? 'Source Code',
            style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
          ),
          subtitle: Text(
            'Contribute on GitHub or GitLab',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          onTap: () {
            // Log analytics for source code access
            AnalyticsService().logFeatureUsed('source_code_accessed');

            Navigator.pop(context);
            _openSourceCode(context);
          },
        ),
        ListTile(
          leading: Icon(Icons.favorite, color: Colors.redAccent),
          title: Text(
            AppLocalizations.of(context)?.support ?? 'Support',
            style: TextStyle(color: Colors.greenAccent),
          ),
          subtitle: Text(
            'Sponsor the project',
            style: TextStyle(color: Colors.greenAccent),
          ),
          onTap: () {
            // Log analytics for sponsorship access
            AnalyticsService().logFeatureUsed('sponsorship_dialog_opened');
            AnalyticsService().logFeatureUsed('support_clicked');

            Navigator.pop(context);
            _showSponsorshipDialog(context);
          },
        ),
        ListTile(
          leading: Icon(Icons.feedback, color: theme.colorScheme.primary),
          title: Text(
            'Feedback',
            style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
          ),
          subtitle: Text(
            'Share your suggestions',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          onTap: () {
            Navigator.pop(context);
            _openFeedbackForm(context);
          },
        ),
        Divider(color: theme.colorScheme.outline),
        ListTile(
          leading: Icon(Icons.info_outline, color: theme.colorScheme.primary),
          title: Text(
            AppLocalizations.of(context)?.about ?? 'About',
            style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
          ),
          subtitle: Text(
            'Version $appVersion (${BuildSource.current.displayName})',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          onTap: () {
            // Log analytics for about section interactions
            AnalyticsService().logFeatureUsed('about_section_clicked');

            // Copy version to clipboard
            _copyVersionToClipboard(context);

            if (onTap != null) {
              onTap!();
            }
            // Don't close drawer when tapping About to allow for multiple taps
          },
          onLongPress: () {
            if (onLongPress != null) {
              onLongPress!();
            }
          },
        ),
        // Only show update checker for builds that support it
        if (BuildSource.current.allowsUpdateCheck)
          ListTile(
            leading: Icon(
              Icons.system_update,
              color: theme.colorScheme.primary,
            ),
            title: Text(
              AppLocalizations.of(context)?.checkForUpdates ??
                  'Check for Updates',
              style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
            ),
            subtitle: Text(
              'Check for app updates',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            onTap: () {
              // Log analytics for update check access
              AnalyticsService().logFeatureUsed('manual_update_check');

              // Close drawer first, then check for updates with a fresh context
              Navigator.pop(context);

              // Use a post-frame callback to ensure the drawer is closed before checking updates
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final navigatorContext = Navigator.of(context).context;
                _checkForUpdatesManually(navigatorContext);
              });
            },
          ),
      ],
    );
  }
}
