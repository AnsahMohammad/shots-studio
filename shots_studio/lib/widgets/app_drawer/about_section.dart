import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutSection extends StatelessWidget {
  final String appVersion;

  const AboutSection({super.key, required this.appVersion});

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $urlString');
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
            'Source Code',
            style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
          ),
          subtitle: Text(
            'View on GitHub',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          onTap: () {
            Navigator.pop(context);
            _launchURL('https://github.com/AnsahMohammad/shots-studio');
          },
        ),
        ListTile(
          leading: Icon(Icons.favorite, color: Colors.redAccent),
          title: Text(
            'Contribute',
            style: TextStyle(color: Colors.greenAccent),
          ),
          subtitle: Text(
            'Support the project',
            style: TextStyle(color: Colors.greenAccent),
          ),
          onTap: () {
            Navigator.pop(context); // Close drawer
            _launchURL('http://github.com/AnsahMohammad');
          },
        ),
        Divider(color: theme.colorScheme.outline),
        ListTile(
          leading: Icon(Icons.info_outline, color: theme.colorScheme.primary),
          title: Text(
            'About',
            style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
          ),
          subtitle: Text(
            'Version $appVersion',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          onTap: () {
            Navigator.pop(context);
            showAboutDialog(
              context: context,
              applicationName: 'Shots Studio',
              applicationVersion: appVersion,
              applicationIcon: Icon(
                Icons.photo_library,
                size: 50,
                color: theme.colorScheme.primary,
              ),
              children: [
                Text(
                  'A screenshot management app built with Flutter.',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap:
                      () => _launchURL(
                        'https://github.com/AnsahMohammad/shots-studio',
                      ),
                  child: Text(
                    'Contribute to the project ❤️',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
