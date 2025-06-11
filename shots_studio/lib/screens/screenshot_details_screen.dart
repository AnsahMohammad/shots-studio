import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/models/collection_model.dart';
import 'package:shots_studio/screens/full_screen_image_viewer.dart';
import 'package:shots_studio/screens/search_screen.dart';
import 'package:shots_studio/services/analytics_service.dart';
import 'package:shots_studio/services/snackbar_service.dart';
import 'package:shots_studio/widgets/screenshots/tags/tag_input_field.dart';
import 'package:shots_studio/widgets/screenshots/tags/tag_chip.dart';
import 'package:shots_studio/widgets/screenshots/screenshot_collection_dialog.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shots_studio/utils/reminder_utils.dart';
import 'package:shots_studio/services/ai_service_manager.dart';
import 'package:shots_studio/services/ai_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScreenshotDetailScreen extends StatefulWidget {
  final Screenshot screenshot;
  final List<Collection> allCollections;
  final List<Screenshot> allScreenshots;
  final Function(Collection) onUpdateCollection;
  final Function(String) onDeleteScreenshot;
  final VoidCallback? onScreenshotUpdated;
  final int? currentIndex;
  final int? totalCount;
  final VoidCallback? onNavigateAfterDelete;

  const ScreenshotDetailScreen({
    super.key,
    required this.screenshot,
    required this.allCollections,
    required this.allScreenshots,
    required this.onUpdateCollection,
    required this.onDeleteScreenshot,
    this.onScreenshotUpdated,
    this.currentIndex,
    this.totalCount,
    this.onNavigateAfterDelete,
  });

  @override
  State<ScreenshotDetailScreen> createState() => _ScreenshotDetailScreenState();
}

class _ScreenshotDetailScreenState extends State<ScreenshotDetailScreen> {
  late List<String> _tags;
  late TextEditingController _descriptionController;
  bool _isProcessingAI = false;
  final AIServiceManager _aiServiceManager = AIServiceManager();

  @override
  void initState() {
    super.initState();
    _tags = List.from(widget.screenshot.tags);
    _descriptionController = TextEditingController(
      text: widget.screenshot.description,
    );

    // Track screenshot details screen access
    AnalyticsService().logScreenView('screenshot_details_screen');

    // Check for expired reminders
    _checkExpiredReminders();
  }

  void _checkExpiredReminders() {
    if (widget.screenshot.reminderTime != null &&
        widget.screenshot.reminderTime!.isBefore(DateTime.now())) {
      // Clear expired reminder
      setState(() {
        widget.screenshot.removeReminder();
      });
      ReminderUtils.clearReminder(context, widget.screenshot);
      _updateScreenshotDetails();
    }
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
        AnalyticsService().logFeatureUsed('tag_added');
      }
    });
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
      widget.screenshot.tags = _tags;
      AnalyticsService().logFeatureUsed('tag_removed');
    });
  }

  Widget _buildTag(String label) {
    final bool isAddButton = label == '+ Add Tag';

    if (isAddButton) {
      return TagInputField(onTagAdded: _addTag);
    }

    return TagChip(
      label: label,
      onDelete: () => _removeTag(label),
      onTap: () => _navigateToTagSearch(label),
    );
  }

  void _navigateToTagSearch(String tag) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => SearchScreen(
              allScreenshots: widget.allScreenshots,
              allCollections: widget.allCollections,
              onUpdateCollection: widget.onUpdateCollection,
              onDeleteScreenshot: widget.onDeleteScreenshot,
              initialSearchQuery: tag,
            ),
      ),
    );
  }

  void _showAddToCollectionDialog() {
    AnalyticsService().logFeatureUsed('collection_dialog_opened');
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

    // Track collection additions/removals
    if (isCurrentlyIn) {
      AnalyticsService().logFeatureUsed('screenshot_removed_from_collection');
    } else {
      AnalyticsService().logFeatureUsed('screenshot_added_to_collection');
    }

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
    AnalyticsService().logFeatureUsed('ai_analysis_cleared');
    setState(() {
      widget.screenshot.aiProcessed = false;
    });
    _updateScreenshotDetails();

    SnackbarService().showInfo(
      context,
      'AI details cleared. Ready for re-processing.',
    );
  }

  Future<void> _processSingleScreenshotWithAI() async {
    // Track AI reprocessing requests
    AnalyticsService().logFeatureUsed('ai_reprocessing_requested');
    // Check if already processed and confirmed by user
    if (widget.screenshot.aiProcessed) {
      final bool? shouldReprocess = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              'Screenshot Already Processed',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            content: Text(
              'This screenshot has already been processed by AI. Do you want to process it again?',
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
                  'Process Again',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );

      if (shouldReprocess != true) return;
    }

    // Get settings from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final String? apiKey = prefs.getString('apiKey');

    if (apiKey == null || apiKey.isEmpty) {
      SnackbarService().showError(
        context,
        'Gemini API key not configured. Please check app settings.',
      );
      return;
    }

    final String modelName =
        prefs.getString('selected_model') ?? 'gemini-2.0-flash';

    setState(() {
      _isProcessingAI = true;
    });

    // Get list of collections that have auto-add enabled for auto-categorization
    final autoAddCollections =
        widget.allCollections
            .where((collection) => collection.isAutoAddEnabled)
            .map(
              (collection) => {
                'name': collection.name,
                'description': collection.description,
                'id': collection.id,
              },
            )
            .toList();

    final config = AIConfig(
      apiKey: apiKey,
      modelName: modelName,
      maxParallel: 1, // Single screenshot processing
      showMessage: ({
        required String message,
        Color? backgroundColor,
        Duration? duration,
      }) {
        SnackbarService().showSnackbar(
          context,
          message: message,
          backgroundColor: backgroundColor,
          duration: duration,
        );
      },
    );

    try {
      // Initialize the AI service manager
      _aiServiceManager.initialize(config);

      // Process the single screenshot (pass as single-item list)
      final result = await _aiServiceManager.analyzeScreenshots(
        screenshots: [widget.screenshot],
        onBatchProcessed: (batch, response) {
          // Update the screenshot with processed data
          final updatedScreenshots = _aiServiceManager
              .parseAndUpdateScreenshots(batch, response);

          if (updatedScreenshots.isNotEmpty) {
            final updatedScreenshot = updatedScreenshots.first;

            setState(() {
              // Update the screenshot properties
              widget.screenshot.title = updatedScreenshot.title;
              widget.screenshot.description = updatedScreenshot.description;
              widget.screenshot.tags = updatedScreenshot.tags;
              widget.screenshot.aiProcessed = updatedScreenshot.aiProcessed;
              widget.screenshot.aiMetadata = updatedScreenshot.aiMetadata;

              // Update local state
              _tags = List.from(updatedScreenshot.tags);
              _descriptionController.text = updatedScreenshot.description ?? '';
            });

            // Handle auto-categorization
            if (response['suggestedCollections'] != null) {
              try {
                Map<dynamic, dynamic>? suggestionsMap;
                if (response['suggestedCollections']
                    is Map<String, List<String>>) {
                  suggestionsMap =
                      response['suggestedCollections']
                          as Map<String, List<String>>;
                } else if (response['suggestedCollections']
                    is Map<dynamic, dynamic>) {
                  suggestionsMap =
                      response['suggestedCollections'] as Map<dynamic, dynamic>;
                }

                List<String> suggestedCollections = [];
                if (suggestionsMap != null &&
                    suggestionsMap.containsKey(updatedScreenshot.id)) {
                  final suggestions = suggestionsMap[updatedScreenshot.id];
                  if (suggestions is List) {
                    suggestedCollections = List<String>.from(
                      suggestions.whereType<String>(),
                    );
                  } else if (suggestions is String) {
                    suggestedCollections = [suggestions];
                  }
                }

                if (suggestedCollections.isNotEmpty) {
                  int autoAddedCount = 0;
                  for (var collection in widget.allCollections) {
                    if (collection.isAutoAddEnabled &&
                        suggestedCollections.contains(collection.name) &&
                        !updatedScreenshot.collectionIds.contains(
                          collection.id,
                        ) &&
                        !collection.screenshotIds.contains(
                          updatedScreenshot.id,
                        )) {
                      // Auto-add screenshot to this collection
                      final updatedCollection = collection.addScreenshot(
                        updatedScreenshot.id,
                        isAutoCategorized: true,
                      );
                      widget.onUpdateCollection(updatedCollection);
                      updatedScreenshot.collectionIds.add(collection.id);
                      autoAddedCount++;
                    }
                  }

                  if (autoAddedCount > 0) {
                    SnackbarService().showSuccess(
                      context,
                      'Screenshot processed and auto-categorized into $autoAddedCount collection${autoAddedCount > 1 ? 's' : ''}',
                    );
                  }
                }
              } catch (e) {
                print('Error handling auto-categorization: $e');
              }
            }
          }
        },
        autoAddCollections: autoAddCollections,
      );

      if (result.success) {
        SnackbarService().showSuccess(
          context,
          'Screenshot processed successfully!',
        );
        widget.onScreenshotUpdated?.call();
      } else if (result.cancelled) {
        SnackbarService().showInfo(context, 'AI processing was cancelled.');
      } else {
        SnackbarService().showError(
          context,
          result.error ?? 'Failed to process screenshot',
        );
      }
    } catch (e) {
      SnackbarService().showError(context, 'Error processing screenshot: $e');
    } finally {
      setState(() {
        _isProcessingAI = false;
      });
    }
  }

  Future<void> _confirmDeleteScreenshot() async {
    AnalyticsService().logFeatureUsed('screenshot_deletion_initiated');
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
      AnalyticsService().logFeatureUsed('screenshot_deleted');

      // Use navigation callback if provided, otherwise pop
      if (widget.onNavigateAfterDelete != null) {
        widget.onNavigateAfterDelete!();
      } else {
        Navigator.of(context).pop();
      }

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
      final file = File(widget.screenshot.path!);
      if (file.existsSync()) {
        imageWidget = Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Automatically delete corrupt images
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.screenshot.isDeleted = true;
              widget.onDeleteScreenshot(widget.screenshot.id);
              SnackbarService().showInfo(
                context,
                'Corrupt image deleted automatically',
              );
              AnalyticsService().logFeatureUsed(
                'corrupt_screenshot_auto_deleted',
              );
              Navigator.of(context).pop();
            });

            return Container(
              color: Theme.of(context).colorScheme.surface,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Deleting corrupt image...',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      } else {
        // Mark as AI processed to prevent AI analysis of invalid images
        widget.screenshot.aiProcessed = true;
        _updateScreenshotDetails();

        imageWidget = Container(
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                'Image file not found',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'The original file may have been moved or deleted',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
        imageName = 'File Not Found';
      }
    } else if (widget.screenshot.bytes != null) {
      imageWidget = Image.memory(
        widget.screenshot.bytes!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Automatically delete corrupt images
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.screenshot.isDeleted = true;
            widget.onDeleteScreenshot(widget.screenshot.id);
            SnackbarService().showInfo(
              context,
              'Corrupt image deleted automatically',
            );
            AnalyticsService().logFeatureUsed(
              'corrupt_screenshot_auto_deleted',
            );
            Navigator.of(context).pop();
          });

          return Container(
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  'Deleting corrupt image...',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      // Mark as AI processed to prevent AI analysis of invalid images
      widget.screenshot.aiProcessed = true;
      _updateScreenshotDetails();

      imageWidget = Container(
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              'No image available',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
      imageName = 'Invalid Image';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Screenshot Detail',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
        ),
        elevation: 0,
        actions: [
          if (_isProcessingAI)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(
                Icons.auto_awesome_outlined,
                color:
                    widget.screenshot.aiProcessed
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              tooltip:
                  widget.screenshot.aiProcessed
                      ? 'Reprocess with AI'
                      : 'Process with AI',
              onPressed: _processSingleScreenshotWithAI,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                AnalyticsService().logFeatureUsed('full_screen_image_viewer');
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
                  const SizedBox(height: 24),
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
                AnalyticsService().logFeatureUsed('screenshot_shared');
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
                color:
                    widget.screenshot.reminderTime != null
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.secondary,
              ),
              onPressed: () async {
                AnalyticsService().logFeatureUsed('reminder_dialog_opened');
                final result = await ReminderUtils.showReminderBottomSheet(
                  context,
                  widget.screenshot.reminderTime,
                  widget.screenshot.reminderText,
                );

                if (result != null) {
                  // If we received an 'expired' flag, it means the bottom sheet detected
                  // an expired reminder and already closed itself
                  if (result['expired'] == true) {
                    setState(() {
                      widget.screenshot.removeReminder();
                    });
                    ReminderUtils.clearReminder(context, widget.screenshot);
                    SnackbarService().showInfo(
                      context,
                      'Expired reminder has been cleared',
                    );
                  } else {
                    setState(() {
                      if (result['reminderTime'] != null) {
                        widget.screenshot.setReminder(
                          result['reminderTime'],
                          text: result['reminderText'],
                        );
                      } else {
                        widget.screenshot.removeReminder();
                      }
                    });

                    if (result['reminderTime'] != null) {
                      AnalyticsService().logFeatureUsed('reminder_set');
                      ReminderUtils.setReminder(
                        context,
                        widget.screenshot,
                        result['reminderTime'],
                        customMessage: result['reminderText'],
                      );
                    } else {
                      AnalyticsService().logFeatureUsed('reminder_cleared');
                      ReminderUtils.clearReminder(context, widget.screenshot);
                    }
                  }

                  _updateScreenshotDetails();
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
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}
