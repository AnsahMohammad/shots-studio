import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shots_studio/models/collection_model.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/services/ai_autocategorization_service.dart';
import 'package:shots_studio/services/analytics_service.dart';
import 'package:shots_studio/widgets/screenshots/screenshot_card.dart';
import 'package:shots_studio/screens/manage_collection_screenshots_screen.dart';
import 'package:shots_studio/screens/screenshot_swipe_detail_screen.dart';
import 'package:shots_studio/screens/create_collection_screen.dart';
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
  bool _devMode = false;

  // Auto-categorization state
  final AICategorizer _aiCategorizer = AICategorizer();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.collection.name);
    _descriptionController = TextEditingController(
      text: widget.collection.description,
    );
    _currentScreenshotIds = List.from(widget.collection.screenshotIds);
    _isAutoAddEnabled = widget.collection.isAutoAddEnabled;

    _loadDevMode();

    if (_isAutoAddEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Log analytics for automatic auto-categorization trigger on screen load
        AnalyticsService().logFeatureUsed(
          'auto_categorization_automatic_trigger',
        );
        _startAutoCategorization();
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
    final currentCollection = widget.collection.copyWith(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      screenshotIds: List<String>.from(
        _currentScreenshotIds,
      ), // Create new list
      isAutoAddEnabled: _isAutoAddEnabled,
    );

    final Collection? updatedCollection = await Navigator.of(
      context,
    ).push<Collection>(
      MaterialPageRoute(
        builder:
            (context) => CreateCollectionScreen(
              availableScreenshots: widget.allScreenshots,
              initialSelectedIds: Set.from(_currentScreenshotIds),
              existingCollection: currentCollection,
            ),
      ),
    );

    if (updatedCollection != null) {
      setState(() {
        _nameController.text = updatedCollection.name ?? '';
        _descriptionController.text = updatedCollection.description ?? '';
        _currentScreenshotIds = List.from(updatedCollection.screenshotIds);
        _isAutoAddEnabled = updatedCollection.isAutoAddEnabled;
      });

      widget.onUpdateCollection(updatedCollection);
    }
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

  Future<void> _removeScreenshotFromCollection(
    String screenshotIdToRemove,
  ) async {
    final screenshot = widget.allScreenshots.firstWhere(
      (s) => s.id == screenshotIdToRemove,
    );
    screenshot.collectionIds.remove(widget.collection.id);
    // }

    setState(() {
      _currentScreenshotIds.remove(screenshotIdToRemove);
    });
    await _saveChanges();
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

  Future<void> _startAutoCategorization() async {
    // Load the most current collection data from SharedPreferences
    // to ensure we have the latest scannedSet
    Collection currentCollection = await _loadCurrentCollectionFromPrefs();

    // Log analytics for manual auto-categorization trigger
    AnalyticsService().logFeatureUsed('auto_categorization_manual_trigger');

    final result = await _aiCategorizer.startAutoCategorization(
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

  void _stopAutoCategorization() {
    AnalyticsService().logFeatureUsed('auto_categorization_manual_stop');
    _aiCategorizer.stopAutoCategorization();
    if (mounted) {
      setState(() {
        // State will be updated through the service
      });
    }
  }

  Future<void> _loadDevMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _devMode = prefs.getBool('dev_mode') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenshotsInCollection =
        widget.allScreenshots
            .where((s) => _currentScreenshotIds.contains(s.id))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _nameController.text.isEmpty
              ? 'Collection Details'
              : _nameController.text,
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          if (_isAutoAddEnabled && _aiCategorizer.isRunning && _devMode)
            IconButton(
              icon: const Icon(Icons.stop, size: 16),
              onPressed: _stopAutoCategorization,
              tooltip: 'Stop Auto-categorization',
            ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _editCollection,
            tooltip: 'Edit Collection',
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
            onPressed: _confirmDelete,
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
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
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
                              'When enabled, AI will automatically add relevant screenshots to this collection',
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
                        activeColor: Theme.of(context).colorScheme.primary,
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
                        color: Theme.of(
                          context,
                        ).colorScheme.tertiaryContainer.withValues(alpha: 0.3),
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
                              'Gemini AI will automatically categorize new screenshots into this collection based on content analysis',
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
                                'Auto-categorizing screenshots...',
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      'No screenshots in this collection. Tap + to add.',
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
                    return Stack(
                      children: [
                        GestureDetector(
                          onTap: () async {
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
                          },
                          child: ScreenshotCard(screenshot: screenshot),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            icon: Icon(
                              Icons.remove_circle,
                              color: theme.colorScheme.error,
                            ),
                            onPressed:
                                () => _removeScreenshotFromCollection(
                                  screenshot.id,
                                ),
                            tooltip: 'Remove from collection',
                            iconSize: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
                    );
                  }, childCount: screenshotsInCollection.length),
                ),
              ),
          // Add bottom padding for better scrolling experience
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}
