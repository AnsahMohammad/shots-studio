import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/models/collection_model.dart';
import 'package:shots_studio/screens/full_screen_image_viewer.dart';
import 'package:shots_studio/services/snackbar_service.dart';
import 'package:shots_studio/widgets/screenshots/tags/tag_input_field.dart';
import 'package:shots_studio/widgets/screenshots/tags/tag_chip.dart';
import 'package:shots_studio/widgets/screenshots/screenshot_collection_dialog.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shots_studio/utils/reminder_utils.dart';

class ScreenshotDetailScreen extends StatefulWidget {
  final Screenshot screenshot;
  final List<Collection> allCollections;
  final Function(Collection) onUpdateCollection;
  final Function(String) onDeleteScreenshot;
  final VoidCallback? onScreenshotUpdated;

  const ScreenshotDetailScreen({
    super.key,
    required this.screenshot,
    required this.allCollections,
    required this.onUpdateCollection,
    required this.onDeleteScreenshot,
    this.onScreenshotUpdated,
  });

  @override
  State<ScreenshotDetailScreen> createState() => _ScreenshotDetailScreenState();
}

class _ScreenshotDetailScreenState extends State<ScreenshotDetailScreen> {
  late List<String> _tags;
  late TextEditingController _descriptionController;
  DateTime? _selectedReminderTime;

  @override
  void initState() {
    super.initState();
    _tags = List.from(widget.screenshot.tags);
    _descriptionController = TextEditingController(
      text: widget.screenshot.description,
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _updateScreenshotDetails() {
    widget.onScreenshotUpdated?.call();
  }

  void _addTag(String tag) {
    setState(() {
      if (!_tags.contains(tag)) {
        _tags.add(tag);
        widget.screenshot.tags = _tags;
      }
    });
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
      widget.screenshot.tags = _tags;
    });
  }

  Widget _buildTag(String label) {
    final bool isAddButton = label == '+ Add Tag';

    if (isAddButton) {
      return TagInputField(onTagAdded: _addTag);
    }

    return TagChip(label: label, onDelete: () => _removeTag(label));
  }

  void _showAddToCollectionDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return ScreenshotCollectionDialog(
              collections: widget.allCollections,
              screenshot: widget.screenshot,
              onCollectionToggle: _toggleScreenshotInCollection,
            );
          },
        );
      },
    );
  }

  void _toggleScreenshotInCollection(
    Collection collection,
    StateSetter setModalState,
  ) {
    final bool isCurrentlyIn = collection.screenshotIds.contains(
      widget.screenshot.id,
    );
    List<String> updatedScreenshotIds = List.from(collection.screenshotIds);
    List<String> updatedCollectionIdsInScreenshot = List.from(
      widget.screenshot.collectionIds,
    );

    if (isCurrentlyIn) {
      updatedScreenshotIds.remove(widget.screenshot.id);
      updatedCollectionIdsInScreenshot.remove(collection.id);
    } else {
      updatedScreenshotIds.add(widget.screenshot.id);
      updatedCollectionIdsInScreenshot.add(collection.id);
    }

    widget.screenshot.collectionIds = updatedCollectionIdsInScreenshot;

    Collection updatedCollection = collection.copyWith(
      screenshotIds: updatedScreenshotIds,
      screenshotCount: updatedScreenshotIds.length,
      lastModified: DateTime.now(),
    );
    widget.onUpdateCollection(updatedCollection);
    setModalState(() {});
    setState(() {});
  }

  void _clearAndRequestAiReprocessing() {
    setState(() {
      widget.screenshot.aiProcessed = false;
    });
    _updateScreenshotDetails();
    SnackbarService().showInfo(
      context,
      'AI details cleared. Ready for re-processing.',
    );
  }

  Future<void> _confirmDeleteScreenshot() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Delete Screenshot?',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this screenshot? This action cannot be undone.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onTertiaryContainer,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text(
                'Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      // Call the delete callback
      widget.screenshot.isDeleted = true;
      widget.onDeleteScreenshot(widget.screenshot.id);

      Navigator.of(context).pop();

      // Show confirmation message
      SnackbarService().showSuccess(context, 'Screenshot deleted successfully');
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (log(bytes) / log(1024)).floor();
    if (i >= suffixes.length) {
      i = suffixes.length - 1;
    }
    return '${(bytes / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    String imageName = widget.screenshot.title ?? 'Screenshot';

    if (widget.screenshot.path != null) {
      imageWidget = Image.file(
        File(widget.screenshot.path!),
        fit: BoxFit.cover,
      );
    } else if (widget.screenshot.bytes != null) {
      imageWidget = Image.memory(widget.screenshot.bytes!, fit: BoxFit.cover);
    } else {
      imageWidget = const Center(child: Icon(Icons.broken_image));
      imageName = 'Invalid Image';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Screenshot Detail',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => FullScreenImageViewer(
                          screenshot: widget.screenshot,
                        ),
                  ),
                );
              },
              child: Container(
                height: MediaQuery.of(context).size.height * 0.5,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.all(16),
                clipBehavior: Clip.antiAlias,
                child: imageWidget,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    imageName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    // Format DateTime using intl package
                    DateFormat(
                      'MMM d, yyyy, hh:mm a',
                    ).format(widget.screenshot.addedOn),
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (widget.screenshot.fileSize != null &&
                      widget.screenshot.fileSize! > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Size: ${_formatFileSize(widget.screenshot.fileSize!)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      hintText: 'Add a description...',
                      filled: true,
                      fillColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                    maxLines: 3,
                    onChanged: (value) {
                      widget.screenshot.description = value;
                    },
                    onEditingComplete: () {
                      widget.screenshot.description =
                          _descriptionController.text;
                      _updateScreenshotDetails();
                      FocusScope.of(context).unfocus();
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Tags',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._tags.map((tag) => _buildTag(tag)),
                      _buildTag('+ Add Tag'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'AI Details',
                    style: TextStyle(
                      fontSize: 18,
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
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSecondaryContainer,
                                ),
                              ),
                              if (widget.screenshot.aiProcessed &&
                                  widget.screenshot.aiMetadata != null) ...[
                                Text(
                                  'Model: ${widget.screenshot.aiMetadata!.modelName}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSecondaryContainer,
                                  ),
                                ),
                                Text(
                                  'Analyzed on: ${DateFormat('MMM d, yyyy HH:mm a').format(widget.screenshot.aiMetadata!.processingTime)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(
                          widget.screenshot.aiProcessed
                              ? Icons.check_circle
                              : Icons.hourglass_empty,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        if (widget.screenshot.aiProcessed)
                          IconButton(
                            icon: Icon(
                              Icons.refresh,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            tooltip: 'Clear AI analysis to re-process',
                            onPressed: _clearAndRequestAiReprocessing,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Collections',
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
                      if (widget.screenshot.collectionIds.isEmpty)
                        Text(
                          "This isn’t in any collection yet. Hit the + button to give it a cozy home 😺",
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      else
                        ...widget.screenshot.collectionIds.map((collectionId) {
                          final collection = widget.allCollections.firstWhere(
                            (c) => c.id == collectionId,
                          );

                          return Chip(
                            label: Text(collection.name ?? 'Unnamed'),
                            backgroundColor:
                                Theme.of(
                                  context,
                                ).colorScheme.secondaryContainer,
                            labelStyle: TextStyle(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSecondaryContainer,
                            ),
                          );
                        }),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddToCollectionDialog,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(
          Icons.add,
          color: Theme.of(context).colorScheme.primaryContainer,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Theme.of(context).colorScheme.secondaryContainer.withAlpha(100),
        child: Row(
          children: <Widget>[
            IconButton(
              icon: Icon(
                Icons.share,
                color: Theme.of(context).colorScheme.secondary,
              ),
              onPressed: () async {
                final file = File(widget.screenshot.path!);
                if (await file.exists()) {
                  await SharePlus.instance.share(
                    ShareParams(
                      text: 'Check out this screenshot!',
                      files: [XFile(file.path)],
                    ),
                  );
                } else {
                  SnackbarService().showError(
                    context,
                    'Screenshot file not found',
                  );
                }
              },
            ),

            IconButton(
              icon: Icon(
                Icons.alarm,
                color: Theme.of(context).colorScheme.secondary,
              ),
              onPressed: () async {
                final newReminderTime =
                    await ReminderUtils.selectReminderDateTime(
                      context,
                      _selectedReminderTime,
                    );
                if (newReminderTime != null) {
                  setState(() {
                    _selectedReminderTime = newReminderTime;
                  });
                  ReminderUtils.setReminder(
                    context,
                    widget.screenshot,
                    _selectedReminderTime,
                  );
                }
              },
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.secondary,
              ),
              onPressed: _confirmDeleteScreenshot,
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}
