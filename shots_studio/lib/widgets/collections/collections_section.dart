import 'package:flutter/material.dart';
import 'package:shots_studio/models/collection_model.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/screens/create_collection_screen.dart';
import 'package:shots_studio/screens/collection_detail_screen.dart';
import 'package:shots_studio/screens/all_collections_screen.dart';
import 'package:shots_studio/widgets/collections/collection_card.dart';
import 'package:shots_studio/widgets/collections/add_collection_button.dart';

class CollectionsSection extends StatelessWidget {
  final List<Collection> collections;
  final List<Screenshot> screenshots;
  final Function(Collection) onCollectionAdded;
  final Function(Collection) onUpdateCollection;
  final Function(String) onDeleteCollection;
  final Function(String) onDeleteScreenshot;

  const CollectionsSection({
    super.key,
    required this.collections,
    required this.screenshots,
    required this.onCollectionAdded,
    required this.onUpdateCollection,
    required this.onDeleteCollection,
    required this.onDeleteScreenshot,
  });

  Future<void> _createCollection(BuildContext context) async {
    final Collection? newCollection = await Navigator.of(
      context,
    ).push<Collection>(
      MaterialPageRoute(
        builder:
            (context) =>
                CreateCollectionScreen(availableScreenshots: screenshots),
      ),
    );

    if (newCollection != null) {
      onCollectionAdded(newCollection);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Collections',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (context) => AllCollectionsScreen(
                            collections: collections,
                            allScreenshots: screenshots,
                            onUpdateCollection: onUpdateCollection,
                            onDeleteCollection: onDeleteCollection,
                            onDeleteScreenshot: onDeleteScreenshot,
                          ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        Container(
          height: 150,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child:
              collections.isEmpty
                  ? ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildCreateFirstCollectionCard(context),
                      AddCollectionButton(
                        onTap: () => _createCollection(context),
                      ),
                    ],
                  )
                  : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: collections.length + 1,
                    itemBuilder: (context, index) {
                      if (index < collections.length) {
                        return CollectionCard(
                          collection: collections[index],
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (context) => CollectionDetailScreen(
                                      collection: collections[index],
                                      allScreenshots: screenshots,
                                      onUpdateCollection: onUpdateCollection,
                                      onDeleteCollection: onDeleteCollection,
                                      onDeleteScreenshot: onDeleteScreenshot,
                                    ),
                              ),
                            );
                          },
                        );
                      } else {
                        // Add collection button at the end
                        return AddCollectionButton(
                          onTap: () => _createCollection(context),
                        );
                      }
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildCreateFirstCollectionCard(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create your first collection to',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'organize your screenshots',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
