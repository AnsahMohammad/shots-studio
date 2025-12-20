import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';
import 'package:shots_studio/services/snackbar_service.dart';
import 'package:shots_studio/services/gemma_download_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Section for managing local Gemma model files.
class GemmaModelSection extends StatelessWidget {
  final String? gemmaModelPath;
  final bool isLoadingGemmaModel;
  final bool gemmaUseCPU;
  final GemmaDownloadService downloadService;
  final VoidCallback onPickModelFile;
  final VoidCallback onClearModel;
  final VoidCallback onDownloadModel;
  final VoidCallback onPauseDownload;
  final VoidCallback onResumeDownload;
  final VoidCallback onCancelDownload;
  final Function(bool) onCpuGpuChanged;

  const GemmaModelSection({
    super.key,
    required this.gemmaModelPath,
    required this.isLoadingGemmaModel,
    required this.gemmaUseCPU,
    required this.downloadService,
    required this.onPickModelFile,
    required this.onClearModel,
    required this.onDownloadModel,
    required this.onPauseDownload,
    required this.onResumeDownload,
    required this.onCancelDownload,
    required this.onCpuGpuChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.android, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'LOCAL GEMMA MODEL',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Download or select a local Gemma model file (.bin or .task) to use for on-device AI processing. Downloaded models are saved to the app\'s private storage.',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),

            // Download Section
            _buildDownloadSection(context, theme),

            const SizedBox(height: 12),

            // Selected Model and Controls
            if (gemmaModelPath != null) ...[
              _buildSelectedModelInfo(theme),
              const SizedBox(height: 12),
              _buildCpuGpuToggle(context, theme),
              const SizedBox(height: 12),
              _buildModelControls(context, theme),
            ] else ...[
              _buildSelectModelButton(context, theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadSection(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.download,
                color: theme.colorScheme.secondary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Download Model',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Recommended: Gemma 3N E2B IT INT4 (~3.1GB)',
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),

          // Download progress section
          if (downloadService.progress.status != DownloadStatus.idle) ...[
            _buildDownloadProgress(context, theme),
            const SizedBox(height: 12),
          ],

          // Download button
          if (!downloadService.isDownloading &&
              gemmaModelPath == null &&
              !downloadService.isCompleted) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onDownloadModel,
                icon: const Icon(Icons.cloud_download),
                label: const Text('Download Gemma Model'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Manual download link
          _buildManualDownloadLink(context, theme),
        ],
      ),
    );
  }

  Widget _buildDownloadProgress(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                downloadService.isPaused
                    ? 'Download Paused'
                    : downloadService.isDownloading
                    ? 'Downloading...'
                    : downloadService.isCompleted
                    ? 'Download Complete'
                    : 'Download Error',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                '${(downloadService.progress.progress * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: downloadService.progress.progress,
            backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              downloadService.isPaused
                  ? Colors.orange
                  : theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          if (downloadService.progress.totalBytes > 0) ...[
            Text(
              '${(downloadService.progress.downloadedBytes / (1024 * 1024)).toStringAsFixed(1)} MB / ${(downloadService.progress.totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (downloadService.hasError &&
              downloadService.progress.error != null) ...[
            const SizedBox(height: 4),
            Text(
              'Error: ${downloadService.progress.error}',
              style: TextStyle(fontSize: 10, color: theme.colorScheme.error),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              if (downloadService.isDownloading &&
                  !downloadService.isPaused) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPauseDownload,
                    icon: const Icon(Icons.pause, size: 16),
                    label: const Text('Pause'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                    ),
                  ),
                ),
              ] else if (downloadService.isPaused) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onResumeDownload,
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('Resume'),
                  ),
                ),
              ],
              if (downloadService.isDownloading ||
                  downloadService.isPaused) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onCancelDownload,
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManualDownloadLink(BuildContext context, ThemeData theme) {
    return InkWell(
      onTap: () async {
        const url =
            'https://www.kaggle.com/models/google/gemma-3n/tfLite/gemma-3n-e2b-it-int4';
        try {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            await Clipboard.setData(const ClipboardData(text: url));
            if (context.mounted) {
              SnackbarService().showWarning(
                context,
                'Could not open browser. Link copied to clipboard!',
              );
            }
          }
        } catch (e) {
          await Clipboard.setData(const ClipboardData(text: url));
          if (context.mounted) {
            SnackbarService().showWarning(
              context,
              'Error opening link. URL copied to clipboard!',
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.outline.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.link,
              color: theme.colorScheme.onSurfaceVariant,
              size: 14,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Or download manually from Kaggle',
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onSurfaceVariant,
                  decoration: TextDecoration.underline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedModelInfo(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected Model:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            gemmaModelPath?.split('/').last ?? 'No model selected',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCpuGpuToggle(BuildContext context, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.tertiary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.settings_applications,
                color: theme.colorScheme.tertiary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Processing Mode',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the processing mode for the local model:',
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildProcessingModeButton(
                  context,
                  theme,
                  isCPU: true,
                  isSelected: gemmaUseCPU,
                  icon: Icons.battery_saver,
                  label: 'CPU',
                  description: 'Optimized for lower resource usage.',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildProcessingModeButton(
                  context,
                  theme,
                  isCPU: false,
                  isSelected: !gemmaUseCPU,
                  icon: Icons.memory,
                  label: 'GPU',
                  description: 'Designed for higher performance tasks.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingModeButton(
    BuildContext context,
    ThemeData theme, {
    required bool isCPU,
    required bool isSelected,
    required IconData icon,
    required String label,
    required String description,
  }) {
    return InkWell(
      onTap: () => onCpuGpuChanged(isCPU),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color:
                isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withOpacity(0.5),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color:
                  isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
              size: 16,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color:
                    isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
              ),
            ),
            Text(
              description,
              style: TextStyle(
                fontSize: 9,
                color:
                    isSelected
                        ? theme.colorScheme.onPrimary.withOpacity(0.8)
                        : theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelControls(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isLoadingGemmaModel ? null : onPickModelFile,
            icon:
                isLoadingGemmaModel
                    ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    )
                    : const Icon(Icons.folder_open),
            label: Text(isLoadingGemmaModel ? 'Loading...' : 'Change Model'),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: isLoadingGemmaModel ? null : onClearModel,
          icon: const Icon(Icons.delete_forever),
          label: const Text('Delete All'),
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectModelButton(BuildContext context, ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isLoadingGemmaModel ? null : onPickModelFile,
        icon:
            isLoadingGemmaModel
                ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.onSecondary,
                  ),
                )
                : const Icon(Icons.folder_open),
        label: Text(isLoadingGemmaModel ? 'Loading...' : 'Select Model File'),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.secondaryContainer,
        ),
      ),
    );
  }
}
