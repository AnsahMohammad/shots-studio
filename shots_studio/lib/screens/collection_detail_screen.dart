import 'package:flutter/material.dart';
import 'package:shots_studio/models/collection_model.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/widgets/screenshot_card.dart';
import 'package:shots_studio/screens/create_collection_screen.dart';
import 'package:shots_studio/screens/screenshot_details_screen.dart';

class CollectionDetailScreen extends StatefulWidget {
  final Collection collection;
  final List<Screenshot> allScreenshots;
  final Function(Collection) onUpdateCollection;
  final Function(String) onDeleteCollection;
  final Function(String) onDeleteScreenshot;

  const CollectionDetailScreen({
    super.key,
    required this.collection,
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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.collection.name);
    _descriptionController = TextEditingController(
      text: widget.collection.description,
    );
    _currentScreenshotIds = List.from(widget.collection.screenshotIds);
    _isAutoAddEnabled = widget.collection.isAutoAddEnabled;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final updatedCollection = widget.collection.copyWith(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      screenshotIds: _currentScreenshotIds,
      lastModified: DateTime.now(),
      screenshotCount: _currentScreenshotIds.length,
      isAutoAddEnabled: _isAutoAddEnabled,
    );
    widget.onUpdateCollection(updatedCollection);
  }

  Future<void> _confirmDelete() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
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
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
    final Set<String> previousScreenshotIds = Set.from(
      _currentScreenshotIds,
    ); // Store current state

    final List<String>? newScreenshotIdsList = await Navigator.of(
      context,
    ).push<List<String>>(
      MaterialPageRoute(
        builder:
            (context) => CreateCollectionScreen(
              availableScreenshots: widget.allScreenshots,
              initialSelectedIds: Set.from(_currentScreenshotIds),
              isEditMode: true,
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
        _saveChanges();
      });
    }
  }

  void _removeScreenshotFromCollection(String screenshotIdToRemove) {
    final screenshot = widget.allScreenshots.firstWhere(
      (s) => s.id == screenshotIdToRemove,
    );
    screenshot.collectionIds.remove(widget.collection.id);
    // }

    setState(() {
      _currentScreenshotIds.remove(screenshotIdToRemove);
      _saveChanges();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenshotsInCollection =
        widget.allScreenshots
            .where((s) => _currentScreenshotIds.contains(s.id))
            .toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          _nameController.text.isEmpty
              ? 'Collection Details'
              : _nameController.text,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              decoration: const InputDecoration(
                hintText: 'Collection Name',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
              onChanged: (value) => setState(() {}),
              onEditingComplete: _saveChanges,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white70),
              decoration: InputDecoration(
                hintText: 'Collection description',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: InputBorder.none,
                filled: true,
                fillColor: Colors.grey[900],
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
              onEditingComplete: _saveChanges,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Tooltip(
                  message:
                      'When enabled, AI will automatically add relevant screenshots to this collection',
                  child: Row(
                    children: [
                      const Text(
                        'Enable Auto-Add Screenshots (AI)',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.amber.shade200,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isAutoAddEnabled,
                  activeColor: Colors.amber.shade200,
                  onChanged: (bool value) {
                    setState(() {
                      _isAutoAddEnabled = value;
                      _saveChanges();
                    });
                  },
                ),
              ],
            ),
            if (_isAutoAddEnabled)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.amber.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: Colors.amber.shade200,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Gemini AI will automatically categorize new screenshots into this collection based on content analysis',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade100,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Screenshots in Collection',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
            Expanded(
              child:
                  screenshotsInCollection.isEmpty
                      ? Center(
                        child: Text(
                          'No screenshots in this collection. Tap + to add.',
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      )
                      : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 1,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                        itemCount: screenshotsInCollection.length,
                        cacheExtent: 800,
                        itemBuilder: (context, index) {
                          final screenshot = screenshotsInCollection[index];
                          return Stack(
                            children: [
                              ScreenshotCard(
                                screenshot: screenshot,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder:
                                          (context) => ScreenshotDetailScreen(
                                            screenshot: screenshot,
                                            allCollections: [widget.collection],
                                            onUpdateCollection:
                                                widget.onUpdateCollection,
                                            onDeleteScreenshot:
                                                widget.onDeleteScreenshot,
                                          ),
                                    ),
                                  );
                                },
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle,
                                    color: Colors.redAccent,
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
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
