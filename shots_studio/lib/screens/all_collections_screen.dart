import 'package:flutter/material.dart';
import 'package:shots_studio/models/collection_model.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/screens/collection_detail_screen.dart';
import 'package:shots_studio/services/analytics_service.dart';
import 'package:shots_studio/widgets/collections/collection_list_item.dart';

class AllCollectionsScreen extends StatefulWidget {
  final List<Collection> collections;
  final List<Screenshot> allScreenshots;
  final Function(Collection) onUpdateCollection;
  final Function(List<Collection>) onUpdateCollections;
  final Function(String) onDeleteCollection;
  final Function(String) onDeleteScreenshot;

  const AllCollectionsScreen({
    super.key,
    required this.collections,
    required this.allScreenshots,
    required this.onUpdateCollection,
    required this.onUpdateCollections,
    required this.onDeleteCollection,
    required this.onDeleteScreenshot,
  });

  @override
  State<AllCollectionsScreen> createState() => _AllCollectionsScreenState();
}

class _AllCollectionsScreenState extends State<AllCollectionsScreen> {
  bool _isReorderMode = false;
  late List<Collection> _sortedCollections;

  @override
  void initState() {
    super.initState();
    _sortedCollections = List.from(widget.collections);
    _sortedCollections.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  }

  @override
  void didUpdateWidget(AllCollectionsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.collections != widget.collections) {
      _sortedCollections = List.from(widget.collections);
      _sortedCollections.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    }
  }

  void _toggleReorderMode() {
    setState(() {
      _isReorderMode = !_isReorderMode;
    });
    
    // Log analytics for reorder mode toggle
    AnalyticsService().logFeatureUsed(_isReorderMode ? 'collection_reorder_mode_enabled' : 'collection_reorder_mode_disabled');
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final Collection item = _sortedCollections.removeAt(oldIndex);
      _sortedCollections.insert(newIndex, item);
    });
  }

  void _saveOrder() {
    // Update display order for all collections
    final List<Collection> updatedCollections = [];
    for (int i = 0; i < _sortedCollections.length; i++) {
      updatedCollections.add(_sortedCollections[i].copyWith(displayOrder: i));
    }
    
    // Call the callback to update all collections
    widget.onUpdateCollections(updatedCollections);
    
    // Exit reorder mode
    setState(() {
      _isReorderMode = false;
    });
    
    // Log analytics for successful reordering
    AnalyticsService().logFeatureUsed('collections_reordered');
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Collection order saved!'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    // Track screen access
    AnalyticsService().logScreenView('all_collections_screen');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Collections'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isReorderMode) ...[
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveOrder,
              tooltip: 'Save Order',
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isReorderMode = false;
                  // Reset to original order
                  _sortedCollections = List.from(widget.collections);
                  _sortedCollections.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
                });
              },
              tooltip: 'Cancel',
            ),
          ] else if (_sortedCollections.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.swap_vert),
              onPressed: _toggleReorderMode,
              tooltip: 'Reorder Collections',
            ),
          ],
        ],
      ),
      body: _sortedCollections.isEmpty
          ? Center(
              child: Text(
                'No collections yet. Create one from the home screen!',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            )
          : _isReorderMode
              ? ReorderableListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _sortedCollections.length,
                  onReorder: _onReorder,
                  itemBuilder: (context, index) {
                    final collection = _sortedCollections[index];
                    return Container(
                      key: ValueKey(collection.id),
                      margin: const EdgeInsets.only(bottom: 16.0),
                      child: Card(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        child: ListTile(
                          leading: Icon(
                            Icons.drag_handle,
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                          ),
                          title: Text(
                            collection.name ?? 'Untitled Collection',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                            ),
                          ),
                          subtitle: collection.description != null && collection.description!.isNotEmpty
                              ? Text(
                                  collection.description!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${collection.screenshotCount}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _sortedCollections.length,
                  itemBuilder: (context, index) {
                    final collection = _sortedCollections[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: CollectionListItem(
                        collection: collection,
                        onTap: () {
                          AnalyticsService().logFeatureUsed(
                            'collection_opened_from_all_collections',
                          );
                          Navigator.of(context)
                              .push(
                                MaterialPageRoute(
                                  builder:
                                      (context) => CollectionDetailScreen(
                                        collection: collection,
                                        allCollections: widget.collections,
                                        allScreenshots: widget.allScreenshots,
                                        onUpdateCollection: (updatedCollection) {
                                          widget.onUpdateCollection(
                                            updatedCollection,
                                          );
                                          setState(() {
                                            // This will trigger a rebuild of the UI
                                          });
                                        },
                                        onDeleteCollection:
                                            widget.onDeleteCollection,
                                        onDeleteScreenshot:
                                            widget.onDeleteScreenshot,
                                      ),
                                ),
                              )
                              .then((_) {
                                // Refresh the UI when returning from collection detail
                                setState(() {});
                              });
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
