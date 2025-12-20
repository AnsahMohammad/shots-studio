import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/models/collection_model.dart';
import 'package:shots_studio/widgets/screenshots/tags/tag_input_field.dart';
import 'package:shots_studio/widgets/screenshots/tags/tag_chip.dart';
import 'package:shots_studio/l10n/app_localizations.dart';
import 'description_field.dart';
import 'link_chip.dart';

/// The main details content section showing file info, description, links, AI metadata, tags, and collections.
class DetailsContent extends StatelessWidget {
  final Screenshot screenshot;
  final String imageName;
  final List<String> tags;
  final List<Collection> allCollections;
  final TextEditingController descriptionController;
  final FocusNode descriptionFocusNode;
  final bool isDescriptionExpanded;
  final bool enhancedAnimationsEnabled;
  
  // Callbacks
  final VoidCallback onDescriptionExpand;
  final VoidCallback onDescriptionCollapse;
  final ValueChanged<String> onDescriptionChanged;
  final VoidCallback onDescriptionEditingComplete;
  final ValueChanged<String> onAddTag;
  final ValueChanged<String> onRemoveTag;
  final ValueChanged<String> onTagTapped;
  final VoidCallback onClearAiReprocessing;
  final VoidCallback onScreenshotUpdated;

  const DetailsContent({
    super.key,
    required this.screenshot,
    required this.imageName,
    required this.tags,
    required this.allCollections,
    required this.descriptionController,
    required this.descriptionFocusNode,
    required this.isDescriptionExpanded,
    required this.enhancedAnimationsEnabled,
    required this.onDescriptionExpand,
    required this.onDescriptionCollapse,
    required this.onDescriptionChanged,
    required this.onDescriptionEditingComplete,
    required this.onAddTag,
    required this.onRemoveTag,
    required this.onTagTapped,
    required this.onClearAiReprocessing,
    required this.onScreenshotUpdated,
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
          ],
        ),
        const SizedBox(height: 16),
        DescriptionField(
          controller: descriptionController,
          focusNode: descriptionFocusNode,
          isExpanded: isDescriptionExpanded,
          enhancedAnimationsEnabled: enhancedAnimationsEnabled,
          onExpand: onDescriptionExpand,
          onCollapse: onDescriptionCollapse,
          onChanged: onDescriptionChanged,
          onEditingComplete: onDescriptionEditingComplete,
        ),

        // Links section - show if there are any extracted links
        if (screenshot.links.isNotEmpty) ...[
          const SizedBox(height: 16),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: screenshot.links
                .map((link) => LinkChip(link: link, parentContext: context))
                .toList(),
          ),
        ],

        const SizedBox(height: 24),
        Text(
          AppLocalizations.of(context)?.aiDetails ?? 'AI Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Analysis Status:',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                    if (screenshot.aiProcessed &&
                        screenshot.aiMetadata != null) ...[
                      Text(
                        'Model: ${screenshot.aiMetadata!.modelName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                      ),
                      Text(
                        'Analyzed on: ${DateFormat('MMM d, yyyy, HH:mm').format(screenshot.aiMetadata!.processingTime)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                screenshot.aiProcessed
                    ? Icons.check_circle
                    : Icons.hourglass_empty,
                color: Theme.of(context).colorScheme.primary,
              ),
              if (screenshot.aiProcessed)
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  tooltip: 'Clear AI analysis to re-process',
                  onPressed: onClearAiReprocessing,
                ),
            ],
          ),
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
            _buildTag(context, AppLocalizations.of(context)?.addTag ?? '+ Add Tag'),
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
                  orElse: () => Collection(
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
