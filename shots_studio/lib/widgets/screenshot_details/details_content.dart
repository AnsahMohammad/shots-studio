import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/models/collection_model.dart';
import 'package:shots_studio/widgets/screenshots/tags/tag_input_field.dart';
import 'package:shots_studio/widgets/screenshots/tags/tag_chip.dart';
import 'package:shots_studio/l10n/app_localizations.dart';
import 'description_field.dart';
import 'note_field.dart';
import 'collapsible_links_section.dart';
import 'package:shots_studio/widgets/screenshot_details/prefilter_status_section.dart';

/// The main details content section showing file info, description, links, AI metadata, tags, and collections.
class DetailsContent extends StatelessWidget {
  final Screenshot screenshot;
  final String imageName;
  final List<String> tags;
  final List<Collection> allCollections;
  final TextEditingController descriptionController;
  final FocusNode descriptionFocusNode;
  final TextEditingController notesController;
  final FocusNode notesFocusNode;
  final bool isDescriptionExpanded;
  final bool enhancedAnimationsEnabled;

  // Callbacks
  final VoidCallback onDescriptionExpand;
  final VoidCallback onDescriptionCollapse;
  final ValueChanged<String> onDescriptionChanged;
  final VoidCallback onDescriptionEditingComplete;
  final ValueChanged<String> onNotesChanged;
  final VoidCallback onNotesEditingComplete;
  final ValueChanged<String> onAddTag;
  final ValueChanged<String> onRemoveTag;
  final ValueChanged<String> onTagTapped;
  final VoidCallback onClearAiReprocessing;
  final VoidCallback onScreenshotUpdated;
  final VoidCallback? onAllowScreenshot;
  final VoidCallback? onMarkSensitive;

  const DetailsContent({
    super.key,
    required this.screenshot,
    required this.imageName,
    required this.tags,
    required this.allCollections,
    required this.descriptionController,
    required this.descriptionFocusNode,
    required this.notesController,
    required this.notesFocusNode,
    required this.isDescriptionExpanded,
    required this.enhancedAnimationsEnabled,
    required this.onDescriptionExpand,
    required this.onDescriptionCollapse,
    required this.onDescriptionChanged,
    required this.onDescriptionEditingComplete,
    required this.onNotesChanged,
    required this.onNotesEditingComplete,
    required this.onAddTag,
    required this.onRemoveTag,
    required this.onTagTapped,
    required this.onClearAiReprocessing,
    required this.onScreenshotUpdated,
    this.onAllowScreenshot,
    this.onMarkSensitive,
  });

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (math.log(bytes) / math.log(1024)).floor();
    if (i >= suffixes.length) {
      i = suffixes.length - 1;
    }
    return '${(bytes / math.pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
  }

  Widget _buildTag(BuildContext context, String label) {
    final String localizedAddTag =
        AppLocalizations.of(context)?.addTag ?? '+ Add Tag';
    final bool isAddButton = label == localizedAddTag || label == '+ Add Tag';

    if (isAddButton) {
      return TagInputField(onTagAdded: onAddTag);
    }

    return TagChip(
      label: label,
      onDelete: () => onRemoveTag(label),
      onTap: () => onTagTapped(label),
    );
  }

  void _showAiDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          title: Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)?.aiDetails ?? 'AI Details',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 280),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                  context,
                  Icons.check_circle_outline,
                  'Status',
                  screenshot.aiProcessed ? 'Processed' : 'Pending',
                  screenshot.aiProcessed
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                if (screenshot.aiProcessed &&
                    screenshot.aiMetadata != null) ...[
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    context,
                    Icons.psychology,
                    'Model',
                    screenshot.aiMetadata!.modelName,
                    null,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    context,
                    Icons.schedule,
                    'Processed on',
                    DateFormat(
                      'MMM d, yyyy, hh:mm a',
                    ).format(screenshot.aiMetadata!.processingTime),
                    null,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            if (screenshot.aiProcessed)
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  onClearAiReprocessing();
                },
                icon: Icon(
                  Icons.refresh,
                  size: 18,
                  color: Theme.of(context).colorScheme.error,
                ),
                label: Text(
                  'Reset AI Status',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color? valueColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            icon,
            size: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          imageName,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Flexible(
              child: Text(
                DateFormat('MMM d, yyyy, hh:mm a').format(screenshot.addedOn),
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (screenshot.fileSize != null && screenshot.fileSize! > 0) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '•',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                _formatFileSize(screenshot.fileSize!),
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            // AI Status indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '•',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _showAiDetailsDialog(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      screenshot.aiProcessed
                          ? Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withValues(alpha: 0.5)
                          : Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      screenshot.aiProcessed
                          ? Icons.auto_awesome
                          : Icons.hourglass_empty,
                      size: 14,
                      color:
                          screenshot.aiProcessed
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      screenshot.aiProcessed ? 'AI' : '',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            screenshot.aiProcessed
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (onAllowScreenshot != null && onMarkSensitive != null)
          PrefilterStatusSection(
            screenshot: screenshot,
            onAllow: onAllowScreenshot!,
            onMarkSensitive: onMarkSensitive!,
          ),
        DescriptionField(
          controller: descriptionController,
          focusNode: descriptionFocusNode,
          isExpanded: isDescriptionExpanded,
          enhancedAnimationsEnabled: enhancedAnimationsEnabled,
          readOnly: true,
          onExpand: onDescriptionExpand,
          onCollapse: onDescriptionCollapse,
          onChanged: onDescriptionChanged,
          onEditingComplete: onDescriptionEditingComplete,
        ),

        // Links section - show if there are any extracted links
        if (screenshot.links.isNotEmpty) ...[
          const SizedBox(height: 16),
          const SizedBox(height: 8),
          CollapsibleLinksSection(
            links: screenshot.links,
            parentContext: context,
          ),
        ],

        const SizedBox(height: 20),
        NoteField(
          controller: notesController,
          focusNode: notesFocusNode,
          enhancedAnimationsEnabled: enhancedAnimationsEnabled,
          onChanged: onNotesChanged,
          onEditingComplete: onNotesEditingComplete,
        ),

        const SizedBox(height: 24),
        Text(
          AppLocalizations.of(context)?.tags ?? 'Tags',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...tags.map((tag) => _buildTag(context, tag)),
            _buildTag(
              context,
              AppLocalizations.of(context)?.addTag ?? '+ Add Tag',
            ),
          ],
        ),

        const SizedBox(height: 24),
        Text(
          AppLocalizations.of(context)?.collections ?? 'Collections',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            if (screenshot.collectionIds.isEmpty)
              Text(
                "This isn't in any collection yet. Hit the + button to give it a cozy home 😺",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              ...screenshot.collectionIds.map((collectionId) {
                final collection = allCollections.firstWhere(
                  (c) => c.id == collectionId,
                  orElse:
                      () => Collection(
                        id: collectionId,
                        name: 'Unknown Collection',
                        description: '',
                        screenshotIds: [],
                        lastModified: DateTime.now(),
                        screenshotCount: 0,
                        isAutoAddEnabled: false,
                      ),
                );

                return Chip(
                  label: Text(collection.name ?? 'Unnamed'),
                  backgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                );
              }),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
