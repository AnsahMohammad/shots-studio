import 'package:flutter/material.dart';
import 'package:shots_studio/models/collection_model.dart';
import 'package:shots_studio/models/screenshot_model.dart';

class ScreenshotCollectionDialog extends StatefulWidget {
  final List<Collection> collections;
  final Screenshot screenshot;
  final Function(Collection, StateSetter) onCollectionToggle;

  const ScreenshotCollectionDialog({
    super.key,
    required this.collections,
    required this.screenshot,
    required this.onCollectionToggle,
  });

  @override
  State<ScreenshotCollectionDialog> createState() =>
      _ScreenshotCollectionDialogState();
}

class _ScreenshotCollectionDialogState
    extends State<ScreenshotCollectionDialog> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Add to Collection',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child:
                widget.collections.isEmpty
                    ? Center(
                      child: Text(
                        'No collections available.',
                        style: TextStyle(
                          color:
                              Theme.of(
                                context,
                              ).colorScheme.onSecondaryContainer,
                        ),
                      ),
                    )
                    : ListView.builder(
                      itemCount: widget.collections.length,
                      itemBuilder: (context, index) {
                        final collection = widget.collections[index];
                        final bool isAlreadyIn = collection.screenshotIds
                            .contains(widget.screenshot.id);
                        return ListTile(
                          title: Text(
                            collection.name ?? 'Untitled',
                            style: TextStyle(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSecondaryContainer,
                            ),
                          ),
                          trailing: Icon(
                            isAlreadyIn
                                ? Icons.check_circle
                                : Icons.add_circle_outline,
                            color:
                                isAlreadyIn
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.secondary,
                          ),
                          onTap: () {
                            widget.onCollectionToggle(collection, setState);
                          },
                        );
                      },
                    ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              child: Text(
                'DONE',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
