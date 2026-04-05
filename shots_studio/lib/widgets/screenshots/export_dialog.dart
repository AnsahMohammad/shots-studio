import 'package:flutter/material.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';

/// Export options returned from the dialog
class ExportOptions {
  final bool asZip;

  ExportOptions({required this.asZip});
}

/// Dialog for selecting export options (ZIP, Cut/Copy)
class ExportDialog extends StatefulWidget {
  final String collectionName;
  final int screenshotCount;

  const ExportDialog({
    super.key,
    required this.collectionName,
    required this.screenshotCount,
  });

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  bool _exportAsZip = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.share_outlined,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Export Collection',
              maxLines: 2,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Export ${widget.screenshotCount} screenshot${widget.screenshotCount != 1 ? 's' : ''} from "${widget.collectionName}"',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),

          // ZIP option
          InkWell(
            onTap: () {
              setState(() {
                _exportAsZip = !_exportAsZip;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Checkbox(
                    value: _exportAsZip,
                    onChanged: (value) {
                      setState(() {
                        _exportAsZip = value ?? true;
                      });
                    },
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Export as ZIP',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Create a single archive file to share',
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
          ),

          const SizedBox(height: 8),

          // Info about file export (only when not ZIP)
          AnimatedOpacity(
            opacity: _exportAsZip ? 0.4 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.folder_copy_outlined,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Files will be copied to the folder you select',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            AnalyticsService().logFeatureUsed('export_dialog_cancelled');
            Navigator.of(context).pop();
          },
          child: Text(
            'Cancel',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            AnalyticsService().logFeatureUsed('export_dialog_confirmed');
            Navigator.of(context).pop(ExportOptions(asZip: _exportAsZip));
          },
          icon: Icon(
            _exportAsZip ? Icons.archive_outlined : Icons.folder_open,
            size: 18,
          ),
          label: Text(_exportAsZip ? 'Export ZIP' : 'Export Files'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
        ),
      ],
    );
  }
}
