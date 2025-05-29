import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shots_studio/services/snackbar_service.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyAcknowledgementDialog extends StatelessWidget {
  final VoidCallback onAgreed;
  final VoidCallback? onDisagreed;

  const PrivacyAcknowledgementDialog({
    super.key,
    required this.onAgreed,
    this.onDisagreed,
  });

  Future<void> _launchURL(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      SnackbarService().showError(context, 'Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      title: Text(
        'Data Processing Acknowledgment',
        style: TextStyle(color: theme.colorScheme.primary),
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Text(
              "By clicking 'Agree & Continue', you acknowledge and consent to the following:\n\n"
              "Shots Studio utilizes Google Gemini, a third-party cloud-based AI service, to process and analyze your images for features such as generating searchable text, suggesting tags, and organizing collections. For these features to function, your images will be transmitted to and processed by Google's servers.\n",
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            InkWell(
              child: Text(
                "This image processing is subject to Google's Privacy Policy.",
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
              onTap:
                  () => _launchURL(
                    context,
                    'https://policies.google.com/privacy',
                  ),
            ),
            const SizedBox(height: 5),
            InkWell(
              child: Text(
                "And Google's Gemini API Terms of Service.",
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
              onTap: () => _launchURL(context, 'https://ai.google.dev/terms'),
            ),
            const SizedBox(height: 10),
            Text(
              "\nShots Studio itself does not permanently store your original images on its own servers after they have been processed by Google Gemini for the aforementioned AI features.\n\n"
              "Please ensure you review and are comfortable with Google's terms and privacy practices before proceeding. If you do not agree, you may not be able to use the AI-powered features of this application.\n"
              "P.S. Don't worry, your cat memes are safe with us. 😺",
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(
            'Disagree',
            style: TextStyle(color: theme.colorScheme.secondary),
          ),
          onPressed: () {
            Navigator.of(context).pop();
            if (onDisagreed != null) {
              onDisagreed!();
            } else {
              SystemNavigator.pop();
            }
          },
        ),
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
          ),
          child: Text(
            'Agree & Continue',
            style: TextStyle(color: theme.colorScheme.onPrimary),
          ),
          onPressed: () {
            Navigator.of(context).pop();
            onAgreed();
          },
        ),
      ],
    );
  }
}

Future<void> showPrivacyDialogIfNeeded(BuildContext context) async {
  const String privacyAcknowledgementKey = 'privacyAcknowledgementAccepted';
  final prefs = await SharedPreferences.getInstance();
  bool? acknowledged = prefs.getBool(privacyAcknowledgementKey);

  if (acknowledged != true) {
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return PrivacyAcknowledgementDialog(
          onAgreed: () async {
            await prefs.setBool(privacyAcknowledgementKey, true);
          },
          onDisagreed: () {
            SystemNavigator.pop();
          },
        );
      },
    );
  }
}
