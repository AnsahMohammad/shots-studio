import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shots_studio/models/collection_model.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/services/autoCategorization/ai_categorization_service.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';
import 'package:shots_studio/services/hard_delete_service.dart';
import 'package:shots_studio/widgets/screenshots/screenshot_card.dart';
import 'package:shots_studio/widgets/screenshots/auto-scan_dialogue.dart';
import 'package:shots_studio/screens/manage_collection_screenshots_screen.dart';
import 'package:shots_studio/screens/screenshot_swipe_detail_screen.dart';
import 'package:shots_studio/screens/edit_collection_screen.dart';
import 'package:shots_studio/utils/responsive_utils.dart';

class CollectionDetailScreen extends StatefulWidget {
  final Collection collection;
  final List<Collection> allCollections;
  final List<Screenshot> allScreenshots;
  final Function(Collection) onUpdateCollection;
  final Function(String) onDeleteCollection;
  final Function(String) onDeleteScreenshot;

  const CollectionDetailScreen({
    super.key,
    required this.collection,
    required this.allCollections,
    required this.allScreenshots,
    required this.onUpdateCollection,
    required this.onDeleteCollection,
    required this.onDeleteScreenshot,
  });

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late List<String> _currentScreenshotIds;
  late bool _isAutoAddEnabled;

  // Auto-categorization state
  final AICategorizer _aiCategorizer = AICategorizer();

  // Selection mode state
  bool _isSelectionMode = false;
  final Set<String> _selectedScreenshotIds = <String>{};
  bool _hardDeleteEnabled = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.collection.name);
    _descriptionController = TextEditingController(
      text: widget.collection.description,
    );
    _currentScreenshotIds = List.from(widget.collection.screenshotIds);
    _isAutoAddEnabled = widget.collection.isAutoAddEnabled;
    _loadHardDeleteSetting();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadHardDeleteSetting() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _hardDeleteEnabled = prefs.getBool('hard_delete_enabled') ?? false;
      });
    }
  }

  Future<void> _saveChanges() async {
    // Load the most current collection data to preserve scannedSet
    final currentCollection = await _loadCurrentCollectionFromPrefs();

    final updatedCollection = currentCollection.copyWith(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      screenshotIds: List<String>.from(
        _currentScreenshotIds,
      ), // Create new list
      lastModified: DateTime.now(),
      screenshotCount: _currentScreenshotIds.length,
      isAutoAddEnabled: _isAutoAddEnabled,
    );
    widget.onUpdateCollection(updatedCollection);
  }

  Future<void> _editCollection() async {
    await Navigator.of(context).push<Collection>(
      MaterialPageRoute(
        builder:
            (context) => EditCollectionScreen(
              collection: widget.collection.copyWith(
                name: _nameController.text.trim(),
                description: _descriptionController.text.trim(),
                screenshotIds: List<String>.from(_currentScreenshotIds),
                isAutoAddEnabled: _isAutoAddEnabled,
              ),
              allScreenshots: widget.allScreenshots,
              onUpdateCollection: (Collection updated) {
                setState(() {
                  _nameController.text = updated.name ?? '';
                  _descriptionController.text = updated.description ?? '';
                  _currentScreenshotIds = List.from(updated.screenshotIds);
                  _isAutoAddEnabled = updated.isAutoAddEnabled;
                });
                widget.onUpdateCollection(updated);
              },
            ),
      ),
    );
    // No need to do anything here, onUpdateCollection is called from EditCollectionScreen
  }

  Future<void> _confirmDelete() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: const Text('Delete Collection?'),
          content: const Text(
            'Are you sure you want to delete this collection?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text(
                'Delete',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      widget.onDeleteCollection(widget.collection.id);
      Navigator.of(context).pop();
    }
  }

  Future<void> _addOrManageScreenshots() async {
    final Set<String> previousScreenshotIds = Set.from(_currentScreenshotIds);

    final List<String>? newScreenshotIdsList = await Navigator.of(
      context,
    ).push<List<String>>(
      MaterialPageRoute(
        builder:
            (context) => ManageCollectionScreenshotsScreen(
              availableScreenshots: widget.allScreenshots,
              initialSelectedIds: Set.from(_currentScreenshotIds),
            ),
      ),
    );

    if (newScreenshotIdsList != null) {
      final Set<String> newScreenshotIdsSet = Set.from(newScreenshotIdsList);

      // Update Screenshot models' collectionIds
      for (var screenshot in widget.allScreenshots) {
        final bool wasInCollection = previousScreenshotIds.contains(
          screenshot.id,
        );
        final bool isInCollection = newScreenshotIdsSet.contains(screenshot.id);

        if (isInCollection && !wasInCollection) {
          // Screenshot was added to this collection
          if (!screenshot.collectionIds.contains(widget.collection.id)) {
            screenshot.collectionIds.add(widget.collection.id);
          }
        } else if (!isInCollection && wasInCollection) {
          // Screenshot was removed from this collection
          screenshot.collectionIds.remove(widget.collection.id);
        }
      }

      setState(() {
        _currentScreenshotIds = newScreenshotIdsList;
      });
      await _saveChanges();
    }
  }

  Future<Collection> _loadCurrentCollectionFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedCollections = prefs.getString('collections');

    if (storedCollections != null && storedCollections.isNotEmpty) {
      final List<dynamic> decodedCollections = jsonDecode(storedCollections);
      final collections =
          decodedCollections
              .map((json) => Collection.fromJson(json as Map<String, dynamic>))
              .toList();

      // Find the current collection by ID
      final currentCollection = collections.firstWhere(
        (c) => c.id == widget.collection.id,
        orElse:
            () =>
                widget.collection, // Fallback to widget collection if not found
      );

      return currentCollection;
    }

    // If no stored data, return the original collection
    return widget.collection;
  }

  Future<void> _startScanning() async {
    // Load the most current collection data from SharedPreferences
    // to ensure we have the latest scannedSet
    Collection currentCollection = await _loadCurrentCollectionFromPrefs();

    // Log analytics for manual scanning trigger
    AnalyticsService().logFeatureUsed('scanning_manual_trigger');

    final result = await _aiCategorizer.startScanning(
      collection: currentCollection,
      allScreenshots: widget.allScreenshots,
      currentScreenshotIds: _currentScreenshotIds,
      context: context,
      onUpdateCollection: widget.onUpdateCollection,
      onScreenshotsAdded: (List<String> addedScreenshotIds) async {
        if (mounted) {
          setState(() {
            // Add matching screenshots from this batch immediately
            _currentScreenshotIds = [
              ..._currentScreenshotIds,
              ...addedScreenshotIds,
            ];
          });

          // Log analytics for screenshots added to this specific collection
          AnalyticsService().logScreenshotsInCollection(
            widget.collection.hashCode, // Use collection hashCode as ID
            _currentScreenshotIds.length,
          );

          await _saveChanges();
        }
      },
      onProgressUpdate: (int processed, int total) {
        if (mounted) {
          setState(() {
            // Progress is handled by the service
          });
        }
      },
      onCompleted: () {
        // Immediately update UI when categorization completes
        if (mounted) {
          setState(() {
            // Force UI refresh to hide progress indicator immediately
          });
        }
      },
    );

    // Final save after completion and force UI update
    if (mounted) {
      setState(() {
        // Force UI refresh to hide progress indicator
      });
      if (result.success) {
        await _saveChanges();
      }
    }
  }

  void _stopScanning() {
    AnalyticsService().logFeatureUsed('scanning_manual_stop');
    _aiCategorizer.stopScanning();
    if (mounted) {
      setState(() {
        // State will be updated through the service
      });
    }
  }

  void _enterSelectionMode(String screenshotId) {
    HapticFeedback.mediumImpact();

    setState(() {
      _isSelectionMode = true;
      _selectedScreenshotIds.add(screenshotId);
    });
    AnalyticsService().logFeatureUsed(
      'collection_screenshot_selection_mode_entered',
    );
  }

  void _exitSelectionMode() {
    // Provide light haptic feedback when exiting selection mode
    HapticFeedback.lightImpact();

    setState(() {
      _isSelectionMode = false;
      _selectedScreenshotIds.clear();
    });
    AnalyticsService().logFeatureUsed(
      'collection_screenshot_selection_mode_exited',
    );
  }

  void _toggleScreenshotSelection(String screenshotId) {
    HapticFeedback.lightImpact();

    setState(() {
      if (_selectedScreenshotIds.contains(screenshotId)) {
        _selectedScreenshotIds.remove(screenshotId);
        AnalyticsService().logFeatureUsed('collection_screenshot_deselected');

        // Exit selection mode if no screenshots are selected
        if (_selectedScreenshotIds.isEmpty) {
          _isSelectionMode = false;
          AnalyticsService().logFeatureUsed(
            'collection_screenshot_selection_mode_auto_exited',
          );
        }
      } else {
        _selectedScreenshotIds.add(screenshotId);
        AnalyticsService().logFeatureUsed('collection_screenshot_selected');
      }
    });
  }

  void _bulkDeleteSelected() async {
    if (_selectedScreenshotIds.isEmpty) return;

    // Build dialog content based on hard delete setting
    String dialogTitle =
        'Delete ${_selectedScreenshotIds.length} Screenshot${_selectedScreenshotIds.length > 1 ? 's' : ''}?';
    String dialogContent =
        'This action cannot be undone. Are you sure you want to delete the selected screenshot${_selectedScreenshotIds.length > 1 ? 's' : ''}?';

    if (_hardDeleteEnabled && HardDeleteService.isHardDeleteAvailable()) {
      dialogContent =
          'This will:\n'
          '1. Remove ${_selectedScreenshotIds.length} screenshot${_selectedScreenshotIds.length > 1 ? 's' : ''} from the app\n'
          '2. Delete the image file${_selectedScreenshotIds.length > 1 ? 's' : ''} from your device\n\n'
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
              child: const Text('Cancel'),
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
      await _performBulkDelete();
    } else {
      AnalyticsService().logFeatureUsed(
        'collection_screenshot_bulk_delete_cancelled',
      );
    }
  }

  /// Perform the actual bulk deletion (soft delete + optional hard delete)
  Future<void> _performBulkDelete() async {
    try {
      // Provide haptic feedback for bulk delete
      HapticFeedback.heavyImpact();

      // Log bulk delete analytics
      AnalyticsService().logFeatureUsed(
        'collection_screenshot_bulk_delete_confirmed',
      );

      final selectedIds = List<String>.from(_selectedScreenshotIds);

      // Step 1: Perform soft delete first (remove from collection and mark as deleted)
      setState(() {
        _currentScreenshotIds.removeWhere((id) => selectedIds.contains(id));
      });

      // Delete screenshots completely using the parent's delete callback
      for (String screenshotId in selectedIds) {
        widget.onDeleteScreenshot(screenshotId);
      }

      // Step 2: Attempt hard delete if enabled and available
      String deleteMessage =
          '${selectedIds.length} screenshot${selectedIds.length > 1 ? 's' : ''} deleted successfully';

      if (_hardDeleteEnabled && HardDeleteService.isHardDeleteAvailable()) {
        print(
          'HardDeleteService: Attempting bulk hard delete for ${selectedIds.length} screenshots',
        );

        // Get the screenshots to delete
        final screenshotsToDelete =
            widget.allScreenshots
                .where((s) => selectedIds.contains(s.id))
                .toList();

        if (screenshotsToDelete.isNotEmpty) {
          final bulkDeleteResult =
              await HardDeleteService.hardDeleteScreenshots(
                screenshotsToDelete,
              );

          if (bulkDeleteResult.successCount > 0) {
            if (bulkDeleteResult.failureCount == 0) {
              deleteMessage =
                  '${selectedIds.length} screenshot${selectedIds.length > 1 ? 's' : ''} deleted from app and device';
            } else {
              deleteMessage =
                  '${bulkDeleteResult.successCount} screenshot${bulkDeleteResult.successCount > 1 ? 's' : ''} deleted completely, ${bulkDeleteResult.failureCount} removed from app only';
            }
            print(
              'HardDeleteService: Bulk hard delete completed - ${bulkDeleteResult.successCount}/${selectedIds.length} successful',
            );
          } else {
            deleteMessage =
                '${selectedIds.length} screenshot${selectedIds.length > 1 ? 's' : ''} deleted from app, but file deletion failed';
            print('HardDeleteService: Bulk hard delete failed for all files');
          }

          print(
            'HardDeleteService: Bulk hard delete result: $bulkDeleteResult',
          );
        }
      } else {
        print(
          'HardDeleteService: Hard delete not available or disabled for bulk operation',
        );
      }

      // Save changes
      await _saveChanges();

      // Exit selection mode
      _exitSelectionMode();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(deleteMessage),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }

      // Log analytics for the number of screenshots deleted
      AnalyticsService().logFeatureUsed(
        'collection_screenshot_bulk_delete_count_${selectedIds.length}',
      );
    } catch (e) {
      print('Error during bulk delete operation: $e');

      // Exit selection mode even on error
      _exitSelectionMode();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during bulk delete: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenshotsInCollection =
        widget.allScreenshots
            .where((s) => _currentScreenshotIds.contains(s.id))
            .toList();

    return PopScope(
      canPop: !_isSelectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (_isSelectionMode && !didPop) {
          _exitSelectionMode();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _nameController.text.isEmpty
                ? 'Collection Details'
                : _nameController.text,
          ),
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              onPressed: _confirmDelete,
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: _editCollection,
              tooltip: 'Edit Collection',
            ),
            if (_isAutoAddEnabled)
              IconButton(
                icon: Icon(
                  _aiCategorizer.isRunning ? Icons.stop : Icons.auto_fix_high,
                ),
                onPressed: () async {
                  if (_aiCategorizer.isRunning) {
                    _stopScanning();
                  } else {
                    // Check if dialog should be shown
                    final prefs = await SharedPreferences.getInstance();
                    final shouldShow =
                        !(prefs.getBool('scan_dialog_dont_show_again') ??
                            false);

                    if (shouldShow) {
                      showDialog(
                        context: context,
                        builder:
                            (context) => ScanConfirmationDialog(
                              onConfirm: _startScanning,
                              collectionName:
                                  _nameController.text.isEmpty
                                      ? 'this collection'
                                      : _nameController.text,
                            ),
                      );
                    } else {
                      // Directly proceed with the scan if user chose not to show dialog
                      _startScanning();
                    }
                  }
                },
                tooltip:
                    _aiCategorizer.isRunning
                        ? 'Stop Scanning'
                        : 'Find Matching Screenshots',
              ),
          ],
        ),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nameController.text.isEmpty
                          ? 'Collection Name'
                          : _nameController.text,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      style: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Collection description',
                        hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        border: InputBorder.none,
                        filled: true,
                        fillColor:
                            Theme.of(context).colorScheme.secondaryContainer,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1,
                          ),
                        ),
                      ),
                      maxLines: 3,
                      readOnly: true,
                      enableInteractiveSelection: true,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Tooltip(
                            message:
                                'AI will automatically add matching screenshots to this collection',
                            child: Row(
                              children: [
                                const Flexible(
                                  child: Text(
                                    'Smart Categorization',
                                    style: TextStyle(fontSize: 16),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Switch(
                          value: _isAutoAddEnabled,
                          activeThumbColor:
                              Theme.of(context).colorScheme.primary,
                          onChanged: (bool value) async {
                            setState(() {
                              _isAutoAddEnabled = value;
                            });

                            AnalyticsService().logFeatureUsed(
                              value
                                  ? 'auto_categorization_enabled'
                                  : 'auto_categorization_disabled',
                            );

                            await _saveChanges();
                          },
                        ),
                      ],
                    ),
                    if (_isAutoAddEnabled)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.tertiaryContainer
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.tertiary.withValues(alpha: 0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: Theme.of(context).colorScheme.tertiary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'AI will automatically sort new screenshots into this collection',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onTertiaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Scanning Progress
                    if (_isAutoAddEnabled && _aiCategorizer.isRunning)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Finding matching screenshots...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  '${_aiCategorizer.processedCount}/${_aiCategorizer.totalCount}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value:
                                  _aiCategorizer.totalCount > 0
                                      ? _aiCategorizer.processedCount /
                                          _aiCategorizer.totalCount
                                      : null,
                              backgroundColor:
                                  Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    // Header with selection controls
                    _isSelectionMode
                        ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: _exitSelectionMode,
                                  tooltip: 'Cancel selection',
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${_selectedScreenshotIds.length} selected',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                if (_selectedScreenshotIds.length ==
                                    screenshotsInCollection.length)
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedScreenshotIds.clear();
                                      });
                                      AnalyticsService().logFeatureUsed(
                                        'collection_screenshot_deselect_all',
                                      );
                                    },
                                    child: const Text('Deselect All'),
                                  )
                                else
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedScreenshotIds.addAll(
                                          screenshotsInCollection.map(
                                            (s) => s.id,
                                          ),
                                        );
                                      });
                                      AnalyticsService().logFeatureUsed(
                                        'collection_screenshot_select_all',
                                      );
                                    },
                                    child: const Text('Select All'),
                                  ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                  onPressed:
                                      _selectedScreenshotIds.isNotEmpty
                                          ? _bulkDeleteSelected
                                          : null,
                                  tooltip: 'Delete selected screenshots',
                                ),
                              ],
                            ),
                          ],
                        )
                        : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Screenshots in Collection',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSecondaryContainer,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Total: ${screenshotsInCollection.length}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.add_photo_alternate_outlined,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              onPressed: _addOrManageScreenshots,
                              tooltip: 'Add/Manage Screenshots',
                            ),
                          ],
                        ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            screenshotsInCollection.isEmpty
                ? SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        'No screenshots yet. Tap + to add some.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
                : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverGrid(
                    gridDelegate: ResponsiveUtils.getResponsiveGridDelegate(
                      context,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final screenshot = screenshotsInCollection[index];
                      final isSelected = _selectedScreenshotIds.contains(
                        screenshot.id,
                      );

                      return GestureDetector(
                        onTap: () async {
                          if (_isSelectionMode) {
                            _toggleScreenshotSelection(screenshot.id);
                          } else {
                            final int initialIndex = screenshotsInCollection
                                .indexWhere((s) => s.id == screenshot.id);

                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (context) => ScreenshotSwipeDetailScreen(
                                      screenshots: List.from(
                                        screenshotsInCollection,
                                      ),
                                      initialIndex:
                                          initialIndex >= 0 ? initialIndex : 0,
                                      allCollections: widget.allCollections,
                                      allScreenshots: widget.allScreenshots,
                                      onUpdateCollection:
                                          widget.onUpdateCollection,
                                      onDeleteScreenshot:
                                          widget.onDeleteScreenshot,
                                      onScreenshotUpdated: () {
                                        // This callback is called from the detail screen
                                        // We don't need to do anything here as we'll handle
                                        // cleanup when we return
                                      },
                                    ),
                              ),
                            );

                            // When we return from the detail screen, clean up deleted screenshots
                            if (mounted) {
                              final originalCount =
                                  _currentScreenshotIds.length;
                              _currentScreenshotIds.removeWhere((id) {
                                final screenshot = widget.allScreenshots
                                    .firstWhere(
                                      (s) => s.id == id,
                                      orElse:
                                          () => Screenshot(
                                            id: '',
                                            path: null,
                                            addedOn: DateTime.now(),
                                            collectionIds: [],
                                            tags: [],
                                            links: [],
                                            aiProcessed: false,
                                            isDeleted: true,
                                          ),
                                    );
                                return screenshot.isDeleted;
                              });

                              // Only update if something was actually removed
                              if (_currentScreenshotIds.length !=
                                  originalCount) {
                                setState(() {});
                                await _saveChanges();
                              }
                            }
                          }
                        },
                        child: ScreenshotCard(
                          screenshot: screenshot,
                          isSelectionMode: _isSelectionMode,
                          isSelected: isSelected,
                          onLongPress: () => _enterSelectionMode(screenshot.id),
                          onSelectionToggle:
                              () => _toggleScreenshotSelection(screenshot.id),
                          onCorruptionDetected: () {
                            setState(() {});
                          },
                          onTap:
                              _isSelectionMode
                                  ? () =>
                                      _toggleScreenshotSelection(screenshot.id)
                                  : null,
                        ),
                      );
                    }, childCount: screenshotsInCollection.length),
                  ),
                ),
            // Add bottom padding for better scrolling experience
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
      ),
    );
  }
}
