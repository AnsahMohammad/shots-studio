import 'package:flutter/material.dart';
import 'package:shots_studio/models/collection_model.dart';

class CollectionListItem extends StatelessWidget {
  final Collection collection;
  final VoidCallback? onTap;

  const CollectionListItem({super.key, required this.collection, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: ListTile(
        onTap: onTap,
        title: Text(
          collection.name ?? 'Untitled Collection',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle:
            collection.description != null && collection.description!.isNotEmpty
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
    );
  }
}
