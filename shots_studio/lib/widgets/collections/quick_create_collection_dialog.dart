import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';
import 'package:shots_studio/l10n/app_localizations.dart';

class QuickCreateCollectionDialog extends StatefulWidget {
  final VoidCallback onConfirm;
  final String collectionName;
  final int screenshotCount;

  const QuickCreateCollectionDialog({
    super.key,
    required this.onConfirm,
    required this.collectionName,
    required this.screenshotCount,
  });

  @override
  State<QuickCreateCollectionDialog> createState() =>
      _QuickCreateCollectionDialogState();
}

class _QuickCreateCollectionDialogState
    extends State<QuickCreateCollectionDialog> {
  bool _dontShowAgain = false;

  Future<void> _saveDontShowAgain() async {
    if (_dontShowAgain) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('quick_create_dialog_dont_show_again', true);
      AnalyticsService().logFeatureUsed('quick_create_dialog_dont_show_again');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.flash_on, color: theme.colorScheme.primary, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n?.quickCreateCollection ?? 'Quick Create Collection',
              maxLines: 2,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n != null
                  ? l10n.quickCreateCollectionMessage(
                      widget.collectionName,
                      widget.screenshotCount,
                    )
                  : 'Create a new collection "${widget.collectionName}" with ${widget.screenshotCount} screenshot${widget.screenshotCount == 1 ? '' : 's'} from your search results?',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n?.quickCreateWhatHappens ?? 'What happens:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n?.quickCreateExplanation ??
                        'All screenshots from your search results will be added to this new collection. You can customize the collection name and settings later.',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _dontShowAgain,
                  onChanged: (value) {
                    setState(() {
                      _dontShowAgain = value ?? false;
                    });
                  },
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _dontShowAgain = !_dontShowAgain;
                      });
                    },
                    child: Text(
                      l10n?.dontShowAgain ?? 'Don\'t show this again',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            AnalyticsService().logFeatureUsed('quick_create_dialog_cancelled');
            Navigator.of(context).pop();
          },
          child: Text(
            l10n?.cancel ?? 'Cancel',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            await _saveDontShowAgain();
            AnalyticsService().logFeatureUsed('quick_create_dialog_confirmed');
            Navigator.of(context).pop();
            widget.onConfirm();
          },
          icon: const Icon(Icons.create_new_folder, size: 18),
          label: Text(l10n?.create ?? 'Create'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
        ),
      ],
    );
  }
}
