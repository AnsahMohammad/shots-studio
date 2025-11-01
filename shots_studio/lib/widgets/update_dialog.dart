import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/update_checker_service.dart';
import '../services/update_installer_service.dart';
import '../services/analytics/analytics_service.dart';
import '../services/snackbar_service.dart';

class UpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isInstalling = false;
  double _progress = 0.0;
  String _status = '';
  int? _downloadSize;
  bool _showInstallOption = false;

  @override
  void initState() {
    super.initState();
    _checkInstallSupport();
    _getDownloadSize();
  }

  Future<void> _checkInstallSupport() async {
    final isSupported =
        await UpdateInstallerService.isUpdateSupportedOnPlatform();
    if (mounted) {
      setState(() {
        _showInstallOption = isSupported;
      });
    }
  }

  Future<void> _getDownloadSize() async {
    final size = await UpdateInstallerService.getUpdateSize(widget.updateInfo);
    if (mounted) {
      setState(() {
        _downloadSize = size;
      });
    }
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $urlString');
    }
  }

  Future<void> _downloadAndInstall() async {
    if (_isInstalling) return;

    setState(() {
      _isInstalling = true;
      _progress = 0.0;
      _status = 'Starting update...';
    });

    try {
      // Log analytics for direct install attempt
      AnalyticsService().logFeatureUsed(
        'update_dialog_install_clicked_${widget.updateInfo.currentVersion}',
      );

      await UpdateInstallerService.downloadAndInstall(
        updateInfo: widget.updateInfo,
        onProgress: (progress, status) {
          if (mounted) {
            setState(() {
              _progress = progress;
              _status = status;
            });
          }
        },
      );

      // If we reach here, the update was successful
      if (mounted) {
        Navigator.of(context).pop();
        SnackbarService().showSuccess(
          context,
          'Update installed successfully! Please restart the app.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInstalling = false;
          _status = 'Error: $e';
        });

        // Show error dialog and offer fallback to browser
        _showErrorDialog(e.toString());
      }
    }
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Installation Failed'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Failed to install update: $error'),
                const SizedBox(height: 16),
                const Text('Would you like to download manually from GitHub?'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _openBrowserUpdate();
                },
                child: const Text('Open GitHub'),
              ),
            ],
          ),
    );
  }

  void _openBrowserUpdate() {
    // Log analytics for fallback to browser
    AnalyticsService().logFeatureUsed(
      'update_dialog_fallback_browser_${widget.updateInfo.currentVersion}',
    );
    _openUpdatePage(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _isInstalling ? Icons.downloading : Icons.system_update,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(_isInstalling ? 'Installing Update' : 'Update Available'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isInstalling) ...[
              Text(
                'A new version of Shots Studio is available!',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              _buildVersionInfo(context),
              if (_downloadSize != null) ...[
                const SizedBox(height: 12),
                _buildDownloadSizeInfo(context),
              ],
              if (widget.updateInfo.releaseNotes.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildReleaseNotes(context),
              ],
            ] else ...[
              _buildInstallProgress(context),
            ],
          ],
        ),
      ),
      actions:
          _isInstalling ? _buildInstallingActions() : _buildNormalActions(),
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
                widget.updateInfo.currentVersion,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          widget.updateInfo.isPreRelease
                              ? Theme.of(context).colorScheme.secondary
                              : Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.updateInfo.latestVersion,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            widget.updateInfo.isPreRelease
                                ? Theme.of(context).colorScheme.onSecondary
                                : Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (widget.updateInfo.isPreRelease) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Pre-release',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadSizeInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Download Size:', style: Theme.of(context).textTheme.bodySmall),
          Text(
            UpdateInstallerService.formatFileSize(_downloadSize!),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallProgress(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_status, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: _progress,
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(_progress * 100).toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (_downloadSize != null) ...[
              Text(
                _buildProgressSizeText(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  String _buildProgressSizeText() {
    if (_downloadSize == null) return '';

    final downloadedBytes = (_downloadSize! * _progress).round();
    final downloadedFormatted = UpdateInstallerService.formatFileSize(
      downloadedBytes,
    );
    final totalFormatted = UpdateInstallerService.formatFileSize(
      _downloadSize!,
    );

    return '$downloadedFormatted / $totalFormatted';
  }

  List<Widget> _buildNormalActions() {
    return [
      TextButton(
        onPressed: () {
          // Log analytics for update dismissal
          AnalyticsService().logFeatureUsed(
            'update_dialog_later_clicked_${widget.updateInfo.currentVersion}',
          );
          Navigator.of(context).pop();
        },
        child: const Text('Later'),
      ),
      if (_showInstallOption) ...[
        FilledButton.icon(
          onPressed: _downloadAndInstall,
          icon: const Icon(Icons.download),
          label: const Text('Install'),
        ),
      ] else ...[
        FilledButton(
          onPressed: () {
            AnalyticsService().logFeatureUsed(
              'update_dialog_update_clicked_${widget.updateInfo.currentVersion}',
            );
            _openUpdatePage(context);
          },
          child: const Text('Download'),
        ),
      ],
    ];
  }

  List<Widget> _buildInstallingActions() {
    return [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
    ];
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
                _formatReleaseNotes(widget.updateInfo.releaseNotes),
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
        SnackbarService().showError(context, 'Error opening update page: $e');
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
