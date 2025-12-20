import 'package:flutter/material.dart';
import 'package:shots_studio/l10n/app_localizations.dart';

/// A disabled tile for XMP metadata settings (feature currently broken).
class XmpSettingsTile extends StatelessWidget {
  const XmpSettingsTile({super.key});

  void _showHelpDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Text(
                  'XMP Metadata',
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                const SizedBox(width: 8),
              ],
            ),
            content: SingleChildScrollView(
              child: Text(
                '⚠️ TEMPORARILY DISABLED\n\n'
                'This feature is currently disabled due to permission issues with Android MediaStore.\n\n'
                'The feature was designed to embed AI-generated titles directly into your image files as searchable metadata, but is experiencing compatibility issues.\n\n'
                'We are working on a fix. This feature may be removed in a future update if the issues cannot be resolved.',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
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

    // TODO: Fix XMP metadata writing feature - currently failing with permission errors
    // RecoverableSecurityException when trying to modify files in MediaStore
    // Either fix the permission handling or remove this feature entirely
    return SwitchListTile(
      secondary: Icon(
        Icons.tag_outlined,
        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
      ),
      title: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    AppLocalizations.of(context)?.writeTagsToXMP ??
                        'Write Tags to XMP',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(
                        0.5,
                      ),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.help_outline,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            onPressed: () => _showHelpDialog(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
      subtitle: Text(
        'Temporarily disabled - Permission issues (see help for details)',
        style: TextStyle(
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
        ),
      ),
      value: false, // Always disabled
      activeThumbColor: theme.colorScheme.primary,
      onChanged: null, // Disabled - greyed out
    );
  }
}
