import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/models/collection_model.dart';
import 'package:shots_studio/screens/full_screen_image_viewer.dart';
import 'package:shots_studio/screens/search_screen.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';
import 'package:shots_studio/services/snackbar_service.dart';
import '../l10n/app_localizations.dart';
import 'package:shots_studio/services/hard_delete_service.dart';
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

// Import extracted widgets
import 'package:shots_studio/widgets/screenshot_details/index.dart';

class ScreenshotDetailScreen extends StatefulWidget {
  final Screenshot screenshot;
  final List<Collection> allCollections;
  final List<Screenshot> allScreenshots;
  final List<Screenshot>?
      contextualScreenshots;
  final Function(Collection) onUpdateCollection;
  final Function(Collection)? onCollectionAdded;
  final Function(String) onDeleteScreenshot;
  final VoidCallback? onScreenshotUpdated;
  final int? currentIndex;
  final int? totalCount;
  final VoidCallback? onNavigateAfterDelete;
  final Function(int)?
      onNavigateToIndex;
  final bool
      disableAnimations;

  const ScreenshotDetailScreen({
    super.key,
    required this.screenshot,
    required this.allCollections,
    required this.allScreenshots,
    required this.onUpdateCollection,
    required this.onDeleteScreenshot,
    this.contextualScreenshots,
    this.onCollectionAdded,
    this.onScreenshotUpdated,
    this.currentIndex,
    this.totalCount,
    this.onNavigateAfterDelete,
    this.onNavigateToIndex,
    this.disableAnimations = false,
  });

  @override
  State<ScreenshotDetailScreen> createState() => _ScreenshotDetailScreenState();
}

class _ScreenshotDetailScreenState extends State<ScreenshotDetailScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late List<String> _tags;
  late TextEditingController _descriptionController;
  late FocusNode _descriptionFocusNode;
  late TextEditingController _notesController;
  late FocusNode _notesFocusNode;
  bool _isProcessingAI = false;
  bool _isProcessingOCR = false;
  final AIServiceManager _aiServiceManager = AIServiceManager();
  final OCRService _ocrService = OCRService();
  bool _hardDeleteEnabled = false;
  bool _isDescriptionExpanded = false;
  bool _enhancedAnimationsEnabled = true;
  double _lastKeyboardHeight = 0;
  bool _isKeyboardVisible = false;

  // Animation controller for simple bounce
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tags = List.from(widget.screenshot.tags);
    _descriptionController = TextEditingController(
      text: widget.screenshot.description,
    );

    // Initialize focus node and add listener to expand when focused
    _descriptionFocusNode = FocusNode();
    _descriptionFocusNode.addListener(() {
      if (_descriptionFocusNode.hasFocus && !_isDescriptionExpanded) {
        setState(() {
          _isDescriptionExpanded = true;
        });
      }
    });

    // Initialize notes controller and focus node
    _notesController = TextEditingController(
      text: widget.screenshot.notes,
    );
    _notesFocusNode = FocusNode();

    // Track screenshot details screen access
    AnalyticsService().logScreenView('screenshot_details_screen');

    // Initialize animation controller - always enable for floating toolbar bounce
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    // Check for expired reminders after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkExpiredReminders();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _animationController.forward();
        }
      });
    });

    // Load settings
    _loadHardDeleteSetting();
    _loadEnhancedAnimationsSetting();
  }

  void _checkExpiredReminders() {
    final reminderTime = widget.screenshot.reminderTime;
    if (reminderTime != null && reminderTime.isBefore(DateTime.now())) {
      if (mounted) {
        setState(() {
          widget.screenshot.removeReminder();
        });
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

  void _loadEnhancedAnimationsSetting() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _enhancedAnimationsEnabled =
            prefs.getBool('enhanced_animations_enabled') ?? true;
      });
    }
  }

  @override
  void didUpdateWidget(ScreenshotDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.screenshot.id != widget.screenshot.id) {
      _tags = List.from(widget.screenshot.tags);
      _descriptionController.text = widget.screenshot.description ?? '';
      _notesController.text = widget.screenshot.notes ?? '';

      _checkExpiredReminders();
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _descriptionController.dispose();
    _descriptionFocusNode.dispose();
    _notesController.dispose();
    _notesFocusNode.dispose();
    _animationController.dispose();

    WakelockPlus.disable().catchError((e) {
      print('Failed to disable wakelock on dispose: $e');
    });

    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // Get current keyboard height using the recommended approach
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final keyboardHeight = view.viewInsets.bottom / view.devicePixelRatio;
    
    // Check if keyboard visibility changed and update state
    final isVisible = keyboardHeight > 0;
    if (_isKeyboardVisible != isVisible) {
      setState(() {
        _isKeyboardVisible = isVisible;
      });
      // If keyboard is hiding, play the bounce animation for the toolbar
      if (!isVisible) {
        _animationController.reset();
        _animationController.forward();
      }
    }
    
    // If keyboard was visible and is now hidden, unfocus text fields
    if (_lastKeyboardHeight > 0 && keyboardHeight == 0) {
      if (_descriptionFocusNode.hasFocus) {
        _descriptionFocusNode.unfocus();
      }
      if (_notesFocusNode.hasFocus) {
        _notesFocusNode.unfocus();
      }
    }
    _lastKeyboardHeight = keyboardHeight;
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

  void _navigateToTagSearch(String tag) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SearchScreen(
          allScreenshots: widget.allScreenshots,
          allCollections: widget.allCollections,
          onUpdateCollection: widget.onUpdateCollection,
          onCollectionAdded: widget.onCollectionAdded ??
              (_) {
                print(
                  'WARNING: onCollectionAdded is null in tag search, collection will not be saved!',
                );
              },
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
              onCollectionToggle: (collection, dialogSetState) =>
                  _toggleScreenshotInCollection(collection, dialogSetState),
            );
          },
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _toggleScreenshotInCollection(
    Collection collection,
    StateSetter dialogSetState,
  ) {
    final bool isCurrentlyIn =
        widget.screenshot.collectionIds.contains(collection.id) ||
            collection.screenshotIds.contains(widget.screenshot.id);

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
      if (!updatedScreenshotIds.contains(widget.screenshot.id)) {
        updatedScreenshotIds.add(widget.screenshot.id);
      }
      if (!updatedCollectionIdsInScreenshot.contains(collection.id)) {
        updatedCollectionIdsInScreenshot.add(collection.id);
      }
    }

    widget.screenshot.collectionIds = updatedCollectionIdsInScreenshot;

    Collection updatedCollection = collection.copyWith(
      screenshotIds: updatedScreenshotIds,
      screenshotCount: updatedScreenshotIds.length,
      lastModified: DateTime.now(),
    );

    final collectionIndex = widget.allCollections.indexWhere(
      (c) => c.id == collection.id,
    );
    if (collectionIndex != -1) {
      widget.allCollections[collectionIndex] = updatedCollection;
    }

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

  Future<void> _handleShare() async {
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
      SnackbarService().showError(context, 'Screenshot file not found');
    }
  }

  Future<void> _handleReminder() async {
    AnalyticsService().logFeatureUsed('reminder_dialog_opened');
    final result = await ReminderUtils.showReminderBottomSheet(
      context,
      widget.screenshot.reminderTime,
      widget.screenshot.reminderText,
    );

    if (result != null) {
      if (result['expired'] == true) {
        if (mounted) {
          setState(() {
            widget.screenshot.removeReminder();
          });
        }
        ReminderUtils.clearReminder(context, widget.screenshot);
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
          AnalyticsService().logFeatureUsed('reminder_set');
          await ReminderUtils.setReminder(
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
  }

  Future<void> _processSingleScreenshotWithAI() async {
    AnalyticsService().logFeatureUsed('ai_reprocessing_requested');

    try {
      await WakelockPlus.enable();
    } catch (e) {
      print('Failed to enable wakelock: $e');
    }

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

      widget.screenshot.aiProcessed = false;
      widget.screenshot.aiMetadata = null;
    }

    final prefs = await SharedPreferences.getInstance();
    String? apiKey = prefs.getString('apiKey');

    if (prefs.getString('modelName') == 'gemma') {
      apiKey = 'gemma-v1';
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

    final autoAddCollections = widget.allCollections
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
      maxParallel: 1,
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
      _aiServiceManager.initialize(config);

      final result = await _aiServiceManager
          .analyzeScreenshots(
            screenshots: [widget.screenshot],
            onBatchProcessed: (batch, response) {
              final updatedScreenshots =
                  _aiServiceManager.parseAndUpdateScreenshots(batch, response);

              if (updatedScreenshots.isNotEmpty) {
                final updatedScreenshot = updatedScreenshots.first;

                if (mounted) {
                  setState(() {
                    widget.screenshot.title = updatedScreenshot.title;
                    widget.screenshot.description =
                        updatedScreenshot.description;
                    widget.screenshot.tags = updatedScreenshot.tags;
                    widget.screenshot.links = updatedScreenshot.links;
                    widget.screenshot.aiProcessed =
                        updatedScreenshot.aiProcessed;
                    widget.screenshot.aiMetadata = updatedScreenshot.aiMetadata;

                    _tags = List.from(updatedScreenshot.tags);
                    _descriptionController.text =
                        updatedScreenshot.description ?? '';
                  });
                }

                // Handle auto-categorization
                if (response['suggestedCollections'] != null) {
                  _handleAutoCategorization(response, updatedScreenshot);
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

  void _handleAutoCategorization(
      Map<String, dynamic> response, Screenshot updatedScreenshot) {
    try {
      Map<dynamic, dynamic>? suggestionsMap;
      if (response['suggestedCollections'] is Map<String, List<String>>) {
        suggestionsMap =
            response['suggestedCollections'] as Map<String, List<String>>;
      } else if (response['suggestedCollections'] is Map<dynamic, dynamic>) {
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
              !updatedScreenshot.collectionIds.contains(collection.id) &&
              !collection.screenshotIds.contains(updatedScreenshot.id)) {
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

  Future<void> _confirmDeleteScreenshot() async {
    AnalyticsService().logFeatureUsed('screenshot_deletion_initiated');

    String dialogTitle = 'Delete Screenshot?';
    String dialogContent =
        'Are you sure you want to delete this screenshot? This action cannot be undone.';

    if (_hardDeleteEnabled && HardDeleteService.isHardDeleteAvailable()) {
      dialogTitle = 'Delete Screenshot?';
      dialogContent = 'This will:\n'
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

  Future<void> _performDelete() async {
    try {
      widget.screenshot.isDeleted = true;
      widget.onDeleteScreenshot(widget.screenshot.id);
      AnalyticsService().logFeatureUsed('screenshot_deleted');

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
          } else {
            deleteMessage =
                'Screenshot deleted from app (file was already removed)';
          }
        } else {
          deleteMessage =
              'Screenshot deleted from app, but file deletion failed: ${hardDeleteResult.error}';

          if (mounted) {
            SnackbarService().showWarning(
              context,
              'Screenshot removed from app, but couldn\'t delete file: ${hardDeleteResult.error}',
            );
          }
        }
      }

      if (widget.onNavigateAfterDelete != null) {
        widget.onNavigateAfterDelete!();
      } else if (mounted) {
        Navigator.of(context).pop();
      }

      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted &&
            !(_hardDeleteEnabled &&
                HardDeleteService.isHardDeleteAvailable() &&
                !deleteMessage.contains('successfully'))) {
          SnackbarService().showSuccess(context, deleteMessage);
        }
      });
    } catch (e) {
      print('Error during delete operation: $e');
      if (mounted) {
        SnackbarService().showError(context, 'Error deleting screenshot: $e');
      }
    }
  }

  Future<void> _processScreenshotWithOCR() async {
    AnalyticsService().logFeatureUsed('ocr_processing_requested');

    if (!_ocrService.isOCRAvailable()) {
      SnackbarService().showError(
        context,
        'OCR is not available on this platform',
      );
      return;
    }

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
      SnackbarService().showInfo(context, 'Processing image with OCR...');

      final extractedText = await _ocrService.extractTextFromScreenshot(
        widget.screenshot,
      );

      if (extractedText != null && extractedText.isNotEmpty) {
        SnackbarService().showSuccess(context, 'Text extracted successfully!');
        AnalyticsService().logFeatureUsed('ocr_text_extracted');

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

      try {
        await WakelockPlus.disable();
      } catch (e) {
        print('Failed to disable wakelock: $e');
      }
    }
  }

  void _handleImageError() {
    if (!widget.screenshot.aiProcessed) {
      widget.screenshot.aiProcessed = true;
      _updateScreenshotDetails();
    }
  }

  Widget? _buildFloatingToolbar() {
    // Hide floating toolbar when keyboard is visible to prevent obstruction
    // Using Visibility instead of returning null prevents Scaffold from running its own exit/enter animations
    return Visibility(
      visible: !_isKeyboardVisible,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FloatingToolbar(
            scaleAnimation: _scaleAnimation,
            screenshot: widget.screenshot,
            isProcessingOCR: _isProcessingOCR,
            onShare: _handleShare,
            onReminderPressed: _handleReminder,
            onOCRPressed: _processScreenshotWithOCR,
            onDeletePressed: _confirmDeleteScreenshot,
            onAddToCollectionPressed: _showAddToCollectionDialog,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String imageName = widget.screenshot.title ?? 'Screenshot';
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 768;

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
                color: widget.screenshot.aiProcessed
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              tooltip: widget.screenshot.aiProcessed
                  ? 'Reprocess with AI'
                  : 'Process with AI',
              onPressed: _processSingleScreenshotWithAI,
            ),
        ],
      ),
      body: isLargeScreen
          ? _buildLargeScreenLayout(imageName)
          : _buildMobileLayout(imageName),
      floatingActionButton: _buildFloatingToolbar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildLargeScreenLayout(String imageName) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: InkWell(
              onTap: () => _openFullScreenViewer(),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: ScreenshotImageWidget(
                  screenshot: widget.screenshot,
                  onImageError: _handleImageError,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 100,
            ),
            child: _buildDetailsWidget(imageName),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(String imageName) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _openFullScreenViewer(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: ScreenshotImageWidget(
                  screenshot: widget.screenshot,
                  onImageError: _handleImageError,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              bottom: 100.0,
            ),
            child: _buildDetailsWidget(imageName),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsWidget(String imageName) {
    return DetailsContent(
      screenshot: widget.screenshot,
      imageName: imageName,
      tags: _tags,
      allCollections: widget.allCollections,
      descriptionController: _descriptionController,
      descriptionFocusNode: _descriptionFocusNode,
      isDescriptionExpanded: _isDescriptionExpanded,
      enhancedAnimationsEnabled: _enhancedAnimationsEnabled,
      onDescriptionExpand: () {
        setState(() {
          _isDescriptionExpanded = true;
        });
      },
      onDescriptionCollapse: () {
        setState(() {
          _isDescriptionExpanded = false;
        });
      },
      onDescriptionChanged: (value) {
        widget.screenshot.description = value;
        setState(() {});
      },
      onDescriptionEditingComplete: () {
        widget.screenshot.description = _descriptionController.text;
        _updateScreenshotDetails();
        FocusScope.of(context).unfocus();
      },
      notesController: _notesController,
      notesFocusNode: _notesFocusNode,
      onNotesChanged: (value) {
        widget.screenshot.notes = value;
        setState(() {});
      },
      onNotesEditingComplete: () {
        widget.screenshot.notes = _notesController.text;
        _updateScreenshotDetails();
        FocusScope.of(context).unfocus();
      },
      onAddTag: _addTag,
      onRemoveTag: _removeTag,
      onTagTapped: _navigateToTagSearch,
      onClearAiReprocessing: _clearAndRequestAiReprocessing,
      onScreenshotUpdated: _updateScreenshotDetails,
    );
  }

  Future<void> _openFullScreenViewer() async {
    AnalyticsService().logFeatureUsed('full_screen_image_viewer');
    final result = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          screenshots: widget.contextualScreenshots ?? [widget.screenshot],
          initialIndex: widget.contextualScreenshots?.indexWhere(
                (s) => s.id == widget.screenshot.id,
              ) ??
              0,
          onScreenshotChanged: widget.onNavigateToIndex,
        ),
      ),
    );

    if (result != null && mounted && widget.onNavigateToIndex != null) {
      widget.onNavigateToIndex!(result);
    }
  }
}
