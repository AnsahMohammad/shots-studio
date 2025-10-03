import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:math' as math;
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/models/collection_model.dart';
import 'package:shots_studio/screens/full_screen_image_viewer.dart';
import 'package:shots_studio/screens/search_screen.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';
import 'package:shots_studio/services/snackbar_service.dart';
import '../l10n/app_localizations.dart';
import 'package:shots_studio/services/hard_delete_service.dart';
import 'package:shots_studio/widgets/screenshots/tags/tag_input_field.dart';
import 'package:shots_studio/widgets/screenshots/tags/tag_chip.dart';
import 'package:shots_studio/widgets/screenshots/screenshot_collection_dialog.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shots_studio/utils/reminder_utils.dart';
import 'package:shots_studio/services/notification_service.dart';
import 'package:shots_studio/services/ai_service_manager.dart';
import 'package:shots_studio/services/ai_service.dart';
import 'package:shots_studio/services/ocr_service.dart';
import 'package:shots_studio/widgets/ocr_result_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ScreenshotDetailScreen extends StatefulWidget {
  final Screenshot screenshot;
  final List<Collection> allCollections;
  final List<Screenshot> allScreenshots;
  final List<Screenshot>?
  contextualScreenshots; // The filtered/contextual list for swiping
  final Function(Collection) onUpdateCollection;
  final Function(String) onDeleteScreenshot;
  final VoidCallback? onScreenshotUpdated;
  final int? currentIndex;
  final int? totalCount;
  final VoidCallback? onNavigateAfterDelete;
  final Function(int)?
  onNavigateToIndex; // Callback for navigating to a specific index

  const ScreenshotDetailScreen({
    super.key,
    required this.screenshot,
    required this.allCollections,
    required this.allScreenshots,
    required this.onUpdateCollection,
    required this.onDeleteScreenshot,
    this.contextualScreenshots,
    this.onScreenshotUpdated,
    this.currentIndex,
    this.totalCount,
    this.onNavigateAfterDelete,
    this.onNavigateToIndex,
  });

  @override
  State<ScreenshotDetailScreen> createState() => _ScreenshotDetailScreenState();
}

class _ScreenshotDetailScreenState extends State<ScreenshotDetailScreen>
    with SingleTickerProviderStateMixin {
  late List<String> _tags;
  late TextEditingController _descriptionController;
  bool _isProcessingAI = false;
  bool _isProcessingOCR = false;
  final AIServiceManager _aiServiceManager = AIServiceManager();
  final OCRService _ocrService = OCRService();
  bool _hardDeleteEnabled = false;

  // Animation controller for simple bounce
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _tags = List.from(widget.screenshot.tags);
    _descriptionController = TextEditingController(
      text: widget.screenshot.description,
    ); // Track screenshot details screen access
    AnalyticsService().logScreenView('screenshot_details_screen');

    // Initialize simple bounce animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    // Check for expired reminders after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkExpiredReminders();
      // Delay the bounce animation slightly to avoid conflicts with page transitions
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _animationController.forward();
        }
      });
    });

    // Load hard delete setting
    _loadHardDeleteSetting();
  }

  void _checkExpiredReminders() {
    final reminderTime = widget.screenshot.reminderTime;
    if (reminderTime != null && reminderTime.isBefore(DateTime.now())) {
      // Clear expired reminder silently (no snackbar needed for expired reminders)
      if (mounted) {
        setState(() {
          widget.screenshot.removeReminder();
        });
        // Cancel the notification without showing a snackbar
        NotificationService().cancelNotification(widget.screenshot.id.hashCode);
        _updateScreenshotDetails();
      }
    }
  }

  void _loadHardDeleteSetting() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _hardDeleteEnabled = prefs.getBool('hard_delete_enabled') ?? false;
      });
    }
  }

  @override
  void didUpdateWidget(ScreenshotDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if the screenshot has changed (after deletion navigation)
    if (oldWidget.screenshot.id != widget.screenshot.id) {
      _tags = List.from(widget.screenshot.tags);
      _descriptionController.text = widget.screenshot.description ?? '';

      _checkExpiredReminders();
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload settings when dependencies change (e.g., when coming back from settings)
  }

  /// Build a floating toolbar with all action buttons
  Widget _buildFloatingToolbar() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Main action buttons container
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 12),
                      _buildToolbarButton(
                        icon: Icons.share_outlined,
                        tooltip: 'Share',
                        onPressed: () async {
                          AnalyticsService().logFeatureUsed(
                            'screenshot_shared',
                          );
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
                      _buildToolbarButton(
                        icon:
                            widget.screenshot.reminderTime != null
                                ? Icons.alarm
                                : Icons.alarm_outlined,
                        tooltip: 'Set reminder',
                        isHighlighted: widget.screenshot.reminderTime != null,
                        onPressed: () async {
                          AnalyticsService().logFeatureUsed(
                            'reminder_dialog_opened',
                          );
                          final result =
                              await ReminderUtils.showReminderBottomSheet(
                                context,
                                widget.screenshot.reminderTime,
                                widget.screenshot.reminderText,
                              );

                          if (result != null) {
                            // If we received an 'expired' flag, it means the bottom sheet detected
                            // an expired reminder and already closed itself
                            if (result['expired'] == true) {
                              if (mounted) {
                                setState(() {
                                  widget.screenshot.removeReminder();
                                });
                              }
                              ReminderUtils.clearReminder(
                                context,
                                widget.screenshot,
                              );
                            } else {
                              if (mounted) {
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
                              }

                              if (result['reminderTime'] != null) {
                                AnalyticsService().logFeatureUsed(
                                  'reminder_set',
                                );
                                await ReminderUtils.setReminder(
                                  context,
                                  widget.screenshot,
                                  result['reminderTime'],
                                  customMessage: result['reminderText'],
                                );
                              } else {
                                AnalyticsService().logFeatureUsed(
                                  'reminder_cleared',
                                );
                                ReminderUtils.clearReminder(
                                  context,
                                  widget.screenshot,
                                );
                              }
                            }

                            _updateScreenshotDetails();
                          }
                        },
                      ),
                      _buildToolbarButton(
                        icon: Icons.text_fields_outlined,
                        tooltip: 'Extract text with OCR',
                        onPressed:
                            _isProcessingOCR ? null : _processScreenshotWithOCR,
                      ),
                      _buildToolbarButton(
                        icon: Icons.delete_outline,
                        tooltip: 'Delete',
                        onPressed: _confirmDeleteScreenshot,
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                ),
                const SizedBox(width: 12), // Brought closer
                // Add to collection button - separate rounded square
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(
                      24,
                    ), // More rounded (almost circular)
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: _showAddToCollectionDialog,
                      child: Icon(
                        Icons.add_rounded,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build individual toolbar button
  Widget _buildToolbarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    bool isHighlighted = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        height: 44,
        width: 44,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color:
              isHighlighted
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onPressed,
            child: Icon(
              icon,
              size: 22,
              color:
                  isHighlighted
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : (onPressed == null
                          ? Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
                          : Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _animationController.dispose();

    // Ensure wakelock is disabled when the screen is disposed
    WakelockPlus.disable().catchError((e) {
      print('Failed to disable wakelock on dispose: $e');
    });

    super.dispose();
  }

  void _updateScreenshotDetails() {
    widget.onScreenshotUpdated?.call();
  }

  void _addTag(String tag) {
    if (mounted) {
      setState(() {
        if (!_tags.contains(tag)) {
          _tags.add(tag);
          widget.screenshot.tags = _tags;
          AnalyticsService().logFeatureUsed('tag_added');
        }
      });
    }
  }

  void _removeTag(String tag) {
    if (mounted) {
      setState(() {
        _tags.remove(tag);
        widget.screenshot.tags = _tags;
        AnalyticsService().logFeatureUsed('tag_removed');
      });
    }
  }

  Widget _buildTag(String label) {
    // Check for both localized and fallback versions of the add tag button
    final String localizedAddTag =
        AppLocalizations.of(context)?.addTag ?? '+ Add Tag';
    final bool isAddButton = label == localizedAddTag || label == '+ Add Tag';

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
              onCollectionToggle:
                  (collection, dialogSetState) =>
                      _toggleScreenshotInCollection(collection, dialogSetState),
            );
          },
        );
      },
    ).then((_) {
      // Force refresh the main screen state when dialog closes
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _toggleScreenshotInCollection(
    Collection collection,
    StateSetter dialogSetState,
  ) {
    // Use the same logic as the dialog to determine current state
    // Check both sides of the bidirectional relationship to ensure consistency
    // This fixes the issue where toggle could only tick but not untick when
    // opened from collection detail screen
    final bool isCurrentlyIn =
        widget.screenshot.collectionIds.contains(collection.id) ||
        collection.screenshotIds.contains(widget.screenshot.id);

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
      // Remove from both sides of the relationship
      updatedScreenshotIds.remove(widget.screenshot.id);
      updatedCollectionIdsInScreenshot.remove(collection.id);
    } else {
      // Add to both sides of the relationship if not already present
      if (!updatedScreenshotIds.contains(widget.screenshot.id)) {
        updatedScreenshotIds.add(widget.screenshot.id);
      }
      if (!updatedCollectionIdsInScreenshot.contains(collection.id)) {
        updatedCollectionIdsInScreenshot.add(collection.id);
      }
    }

    // Update the screenshot's collection IDs immediately
    widget.screenshot.collectionIds = updatedCollectionIdsInScreenshot;

    // Create updated collection
    Collection updatedCollection = collection.copyWith(
      screenshotIds: updatedScreenshotIds,
      screenshotCount: updatedScreenshotIds.length,
      lastModified: DateTime.now(),
    );

    // Update the collection in the allCollections list immediately so dialog sees the change
    final collectionIndex = widget.allCollections.indexWhere(
      (c) => c.id == collection.id,
    );
    if (collectionIndex != -1) {
      widget.allCollections[collectionIndex] = updatedCollection;
    } else {
      print(
        'DEBUG: WARNING - Could not find collection in allCollections list',
      );
    }

    // Call the update callback to persist changes
    widget.onUpdateCollection(updatedCollection);
    dialogSetState(() {});
    if (mounted) {
      setState(() {});
    }
    widget.onScreenshotUpdated?.call();
    _updateScreenshotDetails();
  }

  void _clearAndRequestAiReprocessing() {
    AnalyticsService().logFeatureUsed('ai_analysis_cleared');
    if (mounted) {
      setState(() {
        widget.screenshot.aiProcessed = false;
      });
    }
    _updateScreenshotDetails();

    SnackbarService().showInfo(
      context,
      'AI details cleared. Ready for re-processing.',
    );
  }

  Future<void> _processSingleScreenshotWithAI() async {
    // Track AI reprocessing requests
    AnalyticsService().logFeatureUsed('ai_reprocessing_requested');

    // Enable wakelock to prevent screen from sleeping during processing
    try {
      await WakelockPlus.enable();
    } catch (e) {
      print('Failed to enable wakelock: $e');
    }

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

      if (shouldReprocess != true) {
        try {
          await WakelockPlus.disable();
        } catch (e) {
          print('Failed to disable wakelock: $e');
        }
        return;
      }

      // Clear previous AI processed state and metadata before reprocessing
      widget.screenshot.aiProcessed = false;
      widget.screenshot.aiMetadata = null;
    }

    // Get settings from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    String? apiKey = prefs.getString('apiKey');

    if (prefs.getString('modelName') == 'gemma') {
      apiKey = 'gemma-v1'; // explicitly set APIKey to gemma-v1
    } else if (apiKey == null || apiKey.isEmpty) {
      try {
        await WakelockPlus.disable();
      } catch (e) {
        print('Failed to disable wakelock: $e');
      }
      SnackbarService().showError(
        context,
        'AI API key not configured. Please check app settings.',
      );
      return;
    }

    final String modelName =
        prefs.getString('modelName') ?? 'gemini-2.5-flash-lite';

    if (mounted) {
      setState(() {
        _isProcessingAI = true;
      });
    }

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
      timeoutSeconds: 120,
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

      // Process the single screenshot with timeout wrapper
      final result = await _aiServiceManager
          .analyzeScreenshots(
            screenshots: [widget.screenshot],
            onBatchProcessed: (batch, response) {
              // Update the screenshot with processed data
              final updatedScreenshots = _aiServiceManager
                  .parseAndUpdateScreenshots(batch, response);

              if (updatedScreenshots.isNotEmpty) {
                final updatedScreenshot = updatedScreenshots.first;

                if (mounted) {
                  setState(() {
                    // Update the screenshot properties
                    widget.screenshot.title = updatedScreenshot.title;
                    widget.screenshot.description =
                        updatedScreenshot.description;
                    widget.screenshot.tags = updatedScreenshot.tags;
                    widget.screenshot.links = updatedScreenshot.links;
                    widget.screenshot.aiProcessed =
                        updatedScreenshot.aiProcessed;
                    widget.screenshot.aiMetadata = updatedScreenshot.aiMetadata;

                    // Update local state
                    _tags = List.from(updatedScreenshot.tags);
                    _descriptionController.text =
                        updatedScreenshot.description ?? '';
                  });
                }

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
                          response['suggestedCollections']
                              as Map<dynamic, dynamic>;
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
          )
          .timeout(
            Duration(seconds: 120),
            onTimeout: () {
              throw TimeoutException(
                'AI processing timed out after 120 seconds',
                Duration(seconds: 120),
              );
            },
          );

      if (result.success) {
        // SnackbarService().showSuccess(
        //   context,
        //   'Screenshot processed successfully!',
        // );
        print("Screenshot processed success");
        widget.onScreenshotUpdated?.call();
      } else if (result.cancelled) {
        SnackbarService().showInfo(context, 'AI processing was cancelled.');
      } else {
        SnackbarService().showError(
          context,
          result.error ?? 'Failed to process screenshot',
        );
      }
    } on TimeoutException catch (_) {
      SnackbarService().showError(
        context,
        'AI processing timed out after 120 seconds. Please try again.',
      );
    } catch (e) {
      SnackbarService().showError(context, 'Error processing screenshot: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingAI = false;
        });
      }

      try {
        await WakelockPlus.disable();
      } catch (e) {
        print('Failed to disable wakelock: $e');
      }
    }
  }

  Future<void> _confirmDeleteScreenshot() async {
    AnalyticsService().logFeatureUsed('screenshot_deletion_initiated');

    // Build dialog content based on hard delete setting
    String dialogTitle = 'Delete Screenshot?';
    String dialogContent =
        'Are you sure you want to delete this screenshot? This action cannot be undone.';

    if (_hardDeleteEnabled && HardDeleteService.isHardDeleteAvailable()) {
      dialogTitle = 'Delete Screenshot?';
      dialogContent =
          'This will:\n'
          '1. Remove the screenshot from the app\n'
          '2. Delete the image file from your device\n\n'
          'This action cannot be undone. Continue?'
          '\n if you do not want to delete the files from your device, disable hard delete in settings.';
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            dialogTitle,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
          content: Text(
            dialogContent,
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
      await _performDelete();
    }
  }

  /// Perform the actual deletion (soft delete + optional hard delete)
  Future<void> _performDelete() async {
    try {
      // Step 1: Perform soft delete first
      widget.screenshot.isDeleted = true;
      widget.onDeleteScreenshot(widget.screenshot.id);
      AnalyticsService().logFeatureUsed('screenshot_deleted');

      // Step 2: Attempt hard delete if enabled and available
      String deleteMessage = 'Screenshot deleted successfully';

      if (_hardDeleteEnabled && HardDeleteService.isHardDeleteAvailable()) {
        print(
          'HardDeleteService: Attempting hard delete for ${widget.screenshot.path}',
        );

        final hardDeleteResult = await HardDeleteService.hardDeleteScreenshot(
          widget.screenshot,
        );

        if (hardDeleteResult.success) {
          if (hardDeleteResult.fileExisted) {
            deleteMessage = 'Screenshot deleted from app and device';
            print('HardDeleteService: Successfully hard deleted file');
          } else {
            deleteMessage =
                'Screenshot deleted from app (file was already removed)';
            print('HardDeleteService: File was already deleted or moved');
          }
        } else {
          // Hard delete failed, but soft delete succeeded
          deleteMessage =
              'Screenshot deleted from app, but file deletion failed: ${hardDeleteResult.error}';
          print(
            'HardDeleteService: Hard delete failed: ${hardDeleteResult.error}',
          );

          // Show a more detailed error if hard delete failed
          if (mounted) {
            SnackbarService().showWarning(
              context,
              'Screenshot removed from app, but couldn\'t delete file: ${hardDeleteResult.error}',
            );
          }
        }

        print('HardDeleteService: Hard delete result: $hardDeleteResult');
      } else {
        print('HardDeleteService: Hard delete not available or disabled');
      }

      // Navigation and success message
      if (widget.onNavigateAfterDelete != null) {
        widget.onNavigateAfterDelete!();
      } else if (mounted) {
        Navigator.of(context).pop();
      }

      // Show appropriate success message
      if (mounted &&
          !(_hardDeleteEnabled &&
              HardDeleteService.isHardDeleteAvailable() &&
              !deleteMessage.contains('successfully'))) {
        SnackbarService().showSuccess(context, deleteMessage);
      }
    } catch (e) {
      print('Error during delete operation: $e');
      if (mounted) {
        SnackbarService().showError(context, 'Error deleting screenshot: $e');
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (math.log(bytes) / math.log(1024)).floor();
    if (i >= suffixes.length) {
      i = suffixes.length - 1;
    }
    return '${(bytes / math.pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
  }

  /// Detect the type of link and return appropriate icon and action
  Map<String, dynamic> _getLinkInfo(String link) {
    final cleanLink = link.trim();

    // Handle links that already have prefixes
    if (cleanLink.startsWith('mailto:')) {
      return {
        'type': 'email',
        'icon': Icons.email,
        'color': Colors.red,
        'action': () => _launchLink(cleanLink),
      };
    }

    if (cleanLink.startsWith('tel:')) {
      return {
        'type': 'phone',
        'icon': Icons.phone,
        'color': Colors.green,
        'action': () => _launchLink(cleanLink),
      };
    }

    // Email detection (raw email format)
    if (RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(cleanLink)) {
      return {
        'type': 'email',
        'icon': Icons.email,
        'color': Colors.red,
        'action': () => _launchLink('mailto:$cleanLink'),
      };
    }

    // Phone number detection (various formats)
    if (RegExp(
      r'^[\+]?[\d\s\-\(\)\.]{7,}$',
    ).hasMatch(cleanLink.replaceAll(' ', ''))) {
      return {
        'type': 'phone',
        'icon': Icons.phone,
        'color': Colors.green,
        'action': () => _launchLink('tel:$cleanLink'),
      };
    }

    // URL detection
    if (cleanLink.startsWith('http://') ||
        cleanLink.startsWith('https://') ||
        cleanLink.startsWith('www.') ||
        RegExp(r'^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}').hasMatch(cleanLink)) {
      String url = cleanLink;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }
      return {
        'type': 'url',
        'icon': Icons.link,
        'color': Colors.blue,
        'action': () => _launchLink(url),
      };
    }

    // Default fallback
    return {
      'type': 'text',
      'icon': Icons.content_copy,
      'color': Colors.grey,
      'action': () => _copyToClipboard(cleanLink),
    };
  }

  /// Launch a link (URL, phone, email) or copy to clipboard if it fails
  Future<void> _launchLink(String link) async {
    try {
      final uri = Uri.parse(link);

      bool launched = false;
      try {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        print('Direct launch failed: $e');
        launched = false;
      }

      if (launched) {
        AnalyticsService().logFeatureUsed('link_launched');
      } else {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
          if (launched) {
            AnalyticsService().logFeatureUsed('link_launched');
            return;
          }
        } catch (e) {
          print('Platform default launch failed: $e');
        }

        await _copyToClipboard(link);
      }
    } catch (e) {
      print('URL parsing failed: $e');
      await _copyToClipboard(link);
    }
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));

    String displayText = text;

    if (text.startsWith('mailto:')) {
      displayText = text.substring(7); // Remove 'mailto:' prefix
    } else if (text.startsWith('tel:')) {
      displayText = text.substring(4); // Remove 'tel:' prefix
    }

    SnackbarService().showWarning(context, 'Copied to clipboard: $displayText');
    AnalyticsService().logFeatureUsed('link_copied_to_clipboard');
  }

  /// Build a clickable link chip
  Widget _buildLinkChip(String link) {
    final linkInfo = _getLinkInfo(link);
    final displayText = _getDisplayText(link);

    return GestureDetector(
      onTap: linkInfo['action'],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: linkInfo['color'].withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(linkInfo['icon'], size: 16, color: linkInfo['color']),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                displayText,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get clean display text for links by removing prefixes
  String _getDisplayText(String link) {
    final cleanLink = link.trim();

    if (cleanLink.startsWith('mailto:')) {
      return cleanLink.substring(7); // Remove 'mailto:' prefix
    } else if (cleanLink.startsWith('tel:')) {
      return cleanLink.substring(4); // Remove 'tel:' prefix
    } else if (cleanLink.startsWith('http://')) {
      return cleanLink.substring(7); // Remove 'http://' prefix for display
    } else if (cleanLink.startsWith('https://')) {
      return cleanLink.substring(8); // Remove 'https://' prefix for display
    }

    return cleanLink;
  }

  /// Build the image widget for the screenshot
  Widget _buildImageWidget(String imageName) {
    Widget imageWidget;

    final screenshotPath = widget.screenshot.path;
    if (screenshotPath != null) {
      final file = File(screenshotPath);
      if (file.existsSync()) {
        imageWidget = Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Mark as AI processed and persist the change when image fails to load
            if (!widget.screenshot.aiProcessed) {
              widget.screenshot.aiProcessed = true;
              _updateScreenshotDetails();
            }
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
                    'Image could not be loaded',
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
        // File not found - mark as AI processed to prevent sending to AI and persist the change
        if (!widget.screenshot.aiProcessed) {
          widget.screenshot.aiProcessed = true;
          _updateScreenshotDetails();
        }
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
      }
    } else if (widget.screenshot.bytes != null) {
      imageWidget = Image.memory(
        widget.screenshot.bytes!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Mark as AI processed and persist the change when image fails to load
          if (!widget.screenshot.aiProcessed) {
            widget.screenshot.aiProcessed = true;
            _updateScreenshotDetails();
          }
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
                  'Image could not be loaded',
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
      // No image data available - mark as AI processed to prevent sending to AI and persist the change
      if (!widget.screenshot.aiProcessed) {
        widget.screenshot.aiProcessed = true;
        _updateScreenshotDetails();
      }
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
    }

    return imageWidget;
  }

  /// Build the details content section
  Widget _buildDetailsContent(String imageName) {
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
        Text(
          // Format DateTime using intl package
          DateFormat('MMM d, yyyy, hh:mm a').format(widget.screenshot.addedOn),
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (widget.screenshot.fileSize != null &&
            widget.screenshot.fileSize! > 0) ...[
          const SizedBox(height: 4),
          Text(
            '${AppLocalizations.of(context)?.size ?? 'Size'}: ${_formatFileSize(widget.screenshot.fileSize!)}',
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
            hintText:
                AppLocalizations.of(context)?.addDescription ??
                'Add a description...',
            filled: true,
            fillColor: Theme.of(context).colorScheme.secondaryContainer,
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
            widget.screenshot.description = _descriptionController.text;
            _updateScreenshotDetails();
            FocusScope.of(context).unfocus();
          },
        ),

        // Links section - show if there are any extracted links
        if (widget.screenshot.links.isNotEmpty) ...[
          const SizedBox(height: 16),
          // Text(
          //   'Extracted Links',
          //   style: TextStyle(
          //     fontSize: 16,
          //     fontWeight: FontWeight.w600,
          //     color: Theme.of(context).colorScheme.onSecondaryContainer,
          //   ),
          // ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                widget.screenshot.links
                    .map((link) => _buildLinkChip(link))
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
                        color:
                            Theme.of(context).colorScheme.onSecondaryContainer,
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
            ..._tags.map((tag) => _buildTag(tag)),
            _buildTag(AppLocalizations.of(context)?.addTag ?? '+ Add Tag'),
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
            if (widget.screenshot.collectionIds.isEmpty)
              Text(
                "This isn't in any collection yet. Hit the + button to give it a cozy home 😺",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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

  @override
  Widget build(BuildContext context) {
    String imageName = widget.screenshot.title ?? 'Screenshot';
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 768; // Tablet and above

    // Update imageName if file is not found
    if (widget.screenshot.path != null) {
      final file = File(widget.screenshot.path!);
      if (!file.existsSync()) {
        imageName = 'File Not Found';
      }
    } else if (widget.screenshot.bytes == null) {
      imageName = 'Invalid Image';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Screenshot Detail',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        elevation: 0,
        actions: [
          if (_isProcessingAI || _isProcessingOCR)
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
      body:
          isLargeScreen
              ? _buildLargeScreenLayout(imageName)
              : _buildMobileLayout(imageName),
      floatingActionButton: _buildFloatingToolbar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  /// Build layout for large screens (tablet/desktop) with side-by-side image and details
  Widget _buildLargeScreenLayout(String imageName) {
    return Row(
      children: [
        // Left side - Image (40% of screen width)
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: InkWell(
              onTap: () async {
                AnalyticsService().logFeatureUsed('full_screen_image_viewer');
                final result = await Navigator.push<int>(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => FullScreenImageViewer(
                          screenshots:
                              widget.contextualScreenshots ??
                              [widget.screenshot],
                          initialIndex:
                              widget.contextualScreenshots?.indexWhere(
                                (s) => s.id == widget.screenshot.id,
                              ) ??
                              0,
                          onScreenshotChanged: widget.onNavigateToIndex,
                        ),
                  ),
                );

                // If user navigated to a different screenshot, use the callback to sync
                if (result != null &&
                    mounted &&
                    widget.onNavigateToIndex != null) {
                  widget.onNavigateToIndex!(result);
                }
              },
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildImageWidget(imageName),
              ),
            ),
          ),
        ),
        // Right side - Details (60% of screen width)
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 100, // Extra padding for floating toolbar
            ),
            child: _buildDetailsContent(imageName),
          ),
        ),
      ],
    );
  }

  /// Build layout for mobile devices with stacked image and details
  Widget _buildMobileLayout(String imageName) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () async {
              AnalyticsService().logFeatureUsed('full_screen_image_viewer');
              final result = await Navigator.push<int>(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => FullScreenImageViewer(
                        screenshots:
                            widget.contextualScreenshots ?? [widget.screenshot],
                        initialIndex:
                            widget.contextualScreenshots?.indexWhere(
                              (s) => s.id == widget.screenshot.id,
                            ) ??
                            0,
                        onScreenshotChanged: widget.onNavigateToIndex,
                      ),
                ),
              );

              // If user navigated to a different screenshot, use the callback to sync
              if (result != null &&
                  mounted &&
                  widget.onNavigateToIndex != null) {
                widget.onNavigateToIndex!(result);
              }
            },
            child: Container(
              height: MediaQuery.of(context).size.height * 0.5,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.all(16),
              clipBehavior: Clip.antiAlias,
              child: _buildImageWidget(imageName),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 100, // Extra padding for floating toolbar
            ),
            child: _buildDetailsContent(imageName),
          ),
        ],
      ),
    );
  }

  Future<void> _processScreenshotWithOCR() async {
    // Track OCR usage
    AnalyticsService().logFeatureUsed('ocr_processing_requested');

    // Check if OCR is available on this platform
    if (!_ocrService.isOCRAvailable()) {
      SnackbarService().showError(
        context,
        'OCR is not available on this platform',
      );
      return;
    }

    // Enable wakelock to prevent screen from sleeping during processing
    try {
      await WakelockPlus.enable();
    } catch (e) {
      print('Failed to enable wakelock: $e');
    }

    if (mounted) {
      setState(() {
        _isProcessingOCR = true;
      });
    }

    try {
      // Show processing message
      SnackbarService().showInfo(context, 'Processing image with OCR...');

      // Extract text and copy to clipboard
      final extractedText = await _ocrService.extractTextAndCopyToClipboard(
        widget.screenshot,
      );

      if (extractedText != null && extractedText.isNotEmpty) {
        SnackbarService().showSuccess(
          context,
          'Text extracted and copied to clipboard!',
        );
        AnalyticsService().logFeatureUsed('ocr_text_extracted');

        // Show the extracted text in a dialog
        OCRResultDialog.show(context, extractedText);
      } else {
        SnackbarService().showWarning(context, 'No text found in the image');
      }
    } catch (e) {
      SnackbarService().showError(
        context,
        'Error processing image: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingOCR = false;
        });
      }

      // Disable wakelock when processing is complete
      try {
        await WakelockPlus.disable();
      } catch (e) {
        print('Failed to disable wakelock: $e');
      }
    }
  }
}
