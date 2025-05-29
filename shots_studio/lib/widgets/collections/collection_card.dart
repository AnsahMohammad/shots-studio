import 'package:flutter/material.dart';
import 'package:shots_studio/models/collection_model.dart';

class CollectionCard extends StatelessWidget {
  final Collection collection;
  final VoidCallback? onTap;

  const CollectionCard({super.key, required this.collection, this.onTap});

  @override
  Widget build(BuildContext context) {
    const double kDefaultInnerPadding = 8.0;
    const double kDefaultOuterOffset = 6.0;
    const double kIconContainerSize = 24.0;
    const double kIconGlyphSize = 16.0;

    final double textContainerLeftPadding = kDefaultInnerPadding;

    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Container(
              width: 120,
              padding: EdgeInsets.fromLTRB(
                textContainerLeftPadding,
                kDefaultInnerPadding,
                kDefaultInnerPadding,
                kDefaultInnerPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    collection.name ?? 'Untitled Collection',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Positioned(
              right: kDefaultOuterOffset,
              bottom: kDefaultOuterOffset,
              child: Container(
                width: kIconContainerSize,
                height: kIconContainerSize,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${collection.screenshotCount}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
            if (collection.isAutoAddEnabled)
              Positioned(
                left: kDefaultOuterOffset,
                bottom: kDefaultOuterOffset,
                child: Container(
                  width: kIconContainerSize,
                  height: kIconContainerSize,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.auto_awesome_outlined,
                    size: kIconGlyphSize,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
