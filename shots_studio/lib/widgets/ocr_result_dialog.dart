import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shots_studio/services/snackbar_service.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';

/// A dialog widget to display OCR results with copy functionality
class OCRResultDialog extends StatelessWidget {
  final String extractedText;
  final VoidCallback? onClose;

  const OCRResultDialog({super.key, required this.extractedText, this.onClose});

  @override
  Widget build(BuildContext context) {
    // Track OCR result dialog shown
    AnalyticsService().logFeatureUsed('ocr_result_dialog_shown');

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.text_fields, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            'Extracted Text',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 300),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  extractedText,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            // Track OCR text copy action
            AnalyticsService().logFeatureUsed('ocr_text_copied');

            await Clipboard.setData(ClipboardData(text: extractedText));
            if (context.mounted) {
              SnackbarService().showSuccess(
                context,
                'Text copied to clipboard!',
              );
            }
          },
          child: Text(
            'Copy',
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        ),
        TextButton(
          onPressed: () {
            // Track OCR dialog close action
            AnalyticsService().logFeatureUsed('ocr_result_dialog_closed');

            Navigator.of(context).pop();
            onClose?.call();
          },
          child: Text(
            'Close',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      ],
    );
  }

  /// Shows the OCR result dialog
  static void show(
    BuildContext context,
    String extractedText, {
    VoidCallback? onClose,
  }) {
    showDialog(
      context: context,
      builder:
          (context) =>
              OCRResultDialog(extractedText: extractedText, onClose: onClose),
    );
  }
}
