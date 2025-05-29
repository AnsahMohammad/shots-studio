import 'package:flutter/material.dart';
import 'package:shots_studio/models/collection_model.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/screens/collection_detail_screen.dart';
import 'package:shots_studio/widgets/collections/collection_list_item.dart';

class AllCollectionsScreen extends StatelessWidget {
  final List<Collection> collections;
  final List<Screenshot> allScreenshots;
  final Function(Collection) onUpdateCollection;
  final Function(String) onDeleteCollection;
  final Function(String) onDeleteScreenshot;

  const AllCollectionsScreen({
    super.key,
    required this.collections,
    required this.allScreenshots,
    required this.onUpdateCollection,
    required this.onDeleteCollection,
    required this.onDeleteScreenshot,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collections'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body:
          collections.isEmpty
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
              : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: collections.length,
                itemBuilder: (context, index) {
                  final collection = collections[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: CollectionListItem(
                      collection: collection,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (context) => CollectionDetailScreen(
                                  collection: collection,
                                  allScreenshots: allScreenshots,
                                  onUpdateCollection: onUpdateCollection,
                                  onDeleteCollection: onDeleteCollection,
                                  onDeleteScreenshot: onDeleteScreenshot,
                                ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
    );
  }
}
