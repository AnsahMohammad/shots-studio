import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/update_checker_service.dart';
import '../services/analytics_service.dart';

class UpdateDialog extends StatelessWidget {
  final UpdateInfo updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.system_update,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          const Text('Update Available'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A new version of Shots Studio is available!',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            _buildVersionInfo(context),
            if (updateInfo.releaseNotes.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildReleaseNotes(context),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Log analytics for update dismissal
            AnalyticsService().logFeatureUsed('update_dismissed');
            Navigator.of(context).pop();
          },
          child: const Text('Later'),
        ),
        FilledButton(
          onPressed: () {
            // Log analytics for update button clicks
            AnalyticsService().logFeatureUsed('update_initiated');
            _openUpdatePage(context);
          },
          child: const Text('Update'),
        ),
      ],
    );
  }

  Widget _buildVersionInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Version:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                updateInfo.currentVersion,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Latest Version:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  updateInfo.latestVersion,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReleaseNotes(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What\'s New:', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 150, // Fixed height to make it scrollable
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Scrollbar(
            child: SingleChildScrollView(
              child: Text(
                _formatReleaseNotes(updateInfo.releaseNotes),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatReleaseNotes(String notes) {
    // Try to extract content from "## What's New" section
    String extractedContent = _extractWhatsNewSection(notes);

    // If no "What's New" section found, use the full notes
    if (extractedContent.isEmpty) {
      extractedContent = notes;
    }

    // Clean up common markdown formatting for better display
    return extractedContent
        .replaceAll('**', '')
        .replaceAll('##', '')
        .replaceAll('- ', '• ')
        .trim();
  }

  String _extractWhatsNewSection(String notes) {
    // Look for "## What's New" section (case insensitive)
    final RegExp whatsNewRegex = RegExp(
      r'##\s*what.?s\s+new\s*(?:\n|$)(.*?)(?=##|\Z)',
      caseSensitive: false,
      multiLine: true,
      dotAll: true,
    );

    final match = whatsNewRegex.firstMatch(notes);
    if (match != null && match.group(1) != null) {
      return match.group(1)!.trim();
    }

    // Alternative: Look for content after the first heading that contains "new"
    final lines = notes.split('\n');
    int startIndex = -1;
    int endIndex = lines.length;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toLowerCase();
      if (line.startsWith('##') && line.contains('new')) {
        startIndex = i + 1;
        break;
      }
    }

    if (startIndex != -1) {
      // Find the next heading to stop at
      for (int i = startIndex; i < lines.length; i++) {
        if (lines[i].startsWith('##')) {
          endIndex = i;
          break;
        }
      }

      return lines.sublist(startIndex, endIndex).join('\n').trim();
    }

    return '';
  }

  void _openUpdatePage(BuildContext context) async {
    try {
      // Launch the GitHub releases page instead of specific release URL
      const releasesUrl =
          'https://github.com/AnsahMohammad/shots-studio/releases';
      await _launchURL(releasesUrl);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening update page: $e')),
        );
      }
    }

    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  /// Shows the update dialog if an update is available
  static Future<void> showUpdateDialogIfAvailable(BuildContext context) async {
    final updateInfo = await UpdateCheckerService.checkForUpdates();
    if (updateInfo != null && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => UpdateDialog(updateInfo: updateInfo),
      );
    }
  }
}
