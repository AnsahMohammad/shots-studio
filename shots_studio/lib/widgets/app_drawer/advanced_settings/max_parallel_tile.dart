import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';
import 'package:shots_studio/l10n/app_localizations.dart';

/// A tile for configuring the maximum number of parallel AI processes.
class MaxParallelTile extends StatelessWidget {
  final int currentMaxParallel;
  final Function(int) onMaxParallelChanged;

  static const String _maxParallelPrefKey = 'maxParallel';

  const MaxParallelTile({
    super.key,
    required this.currentMaxParallel,
    required this.onMaxParallelChanged,
  });

  Future<void> _saveMaxParallel(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_maxParallelPrefKey, value);
  }

  void _showHelpDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Max Parallel AI Processes',
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            content: Text(
              'Controls the maximum number of images sent in one AI request.\n\n'
              '• Default: 4 (recommended for most users)\n'
              '• Maximum: 8 (recommended for faster processing)\n'
              '• Higher values require more internet bandwidth\n'
              '• Gemma AI only supports 1 image regardless of this setting\n'
              '• Adjust based on your internet connection speed',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Got it',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(Icons.sync_alt, color: theme.colorScheme.primary),
      title: Row(
        children: [
          Expanded(
            child: Text(
              AppLocalizations.of(context)?.maxParallelAI ??
                  'Max Parallel AI Processes',
              style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.help_outline,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            onPressed: () => _showHelpDialog(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$currentMaxParallel',
              style: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Controls parallel image processing. Higher values need more bandwidth. '
            'Default: 4. \nNote: Gemma only supports 1 image.',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '1',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              Expanded(
                child: Slider(
                  value: currentMaxParallel.toDouble(),
                  min: 1,
                  max: 8,
                  divisions: 7,
                  label: currentMaxParallel.toString(),
                  activeColor: theme.colorScheme.primary,
                  onChanged: (value) {
                    final intValue = value.round();
                    onMaxParallelChanged(intValue);
                    _saveMaxParallel(intValue);

                    // Track analytics for max parallel processes change
                    AnalyticsService().logFeatureUsed(
                      'settings_max_parallel_changed',
                    );
                  },
                ),
              ),
              Text(
                '8',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
