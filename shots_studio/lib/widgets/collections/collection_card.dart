import 'package:flutter/material.dart';
import 'dart:io';
import 'package:shots_studio/models/collection_model.dart';
import 'package:shots_studio/models/screenshot_model.dart';

class CollectionCard extends StatefulWidget {
  final Collection collection;
  final List<Screenshot> screenshots;
  final VoidCallback? onTap;

  const CollectionCard({
    super.key,
    required this.collection,
    required this.screenshots,
    this.onTap,
  });

  @override
  State<CollectionCard> createState() => _CollectionCardState();
}

class _CollectionCardState extends State<CollectionCard> {
  late List<Screenshot> _cachedScreenshots;
  Widget? _cachedThumbnails;
  final Map<String, Widget> _imageCache = {};
  static final Map<String, Widget> _globalImageCache =
      {}; // Global cache across all collection cards

  @override
  void initState() {
    super.initState();
    _updateCachedScreenshots();
  }

  @override
  void didUpdateWidget(CollectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if collection changed (including lastModified which changes on updates)
    final collectionChanged =
        oldWidget.collection.id != widget.collection.id ||
        oldWidget.collection.lastModified != widget.collection.lastModified ||
        !_screenshotIdsEqual(
          oldWidget.collection.screenshotIds,
          widget.collection.screenshotIds,
        );

    // Check if screenshots list changed
    final screenshotsChanged =
        !_screenshotsEqual(oldWidget.screenshots, widget.screenshots);

    if (collectionChanged || screenshotsChanged) {
      _updateCachedScreenshots();
    }
  }

  @override
  void dispose() {
    // Don't clear global cache on dispose, only local cache
    _imageCache.clear();
    super.dispose();
  }

  void _updateCachedScreenshots() {
    final collectionScreenshots =
        widget.screenshots
            .where(
              (screenshot) =>
                  widget.collection.screenshotIds.contains(screenshot.id) &&
                  !screenshot.isDeleted, // Exclude deleted screenshots
            )
            .take(3)
            .toList();

    _cachedScreenshots = collectionScreenshots;
    _cachedThumbnails = null; // Reset cached thumbnails to force rebuild

    // Also clear the local image cache for screenshots no longer in this collection
    final currentIds = collectionScreenshots.map((s) => s.id).toSet();
    _imageCache.removeWhere((id, widget) => !currentIds.contains(id));
  }

  bool _screenshotsEqual(List<Screenshot> list1, List<Screenshot> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id) return false;
    }
    return true;
  }

  bool _screenshotIdsEqual(List<String> list1, List<String> list2) {
    if (identical(list1, list2)) return true; // Same reference
    if (list1.length != list2.length) return false;

    // Check if all elements are equal in order
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    const double kDefaultInnerPadding = 8.0;
    const double kDefaultOuterOffset = 6.0;
    const double kIconContainerSize = 24.0;
    const double kIconGlyphSize = 16.0;
    const double kThumbnailSize = 60.0;

    final double textContainerLeftPadding = kDefaultInnerPadding;

    return RepaintBoundary(
      child: Card(
        color: Theme.of(context).colorScheme.secondaryContainer,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
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
                    // Collection name - fixed height container
                    SizedBox(
                      height: 50, // Increased height to fit two rows of text
                      child: Text(
                        widget.collection.name ?? 'Untitled Collection',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color:
                              Theme.of(
                                context,
                              ).colorScheme.onSecondaryContainer,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Thumbnails section - always at same position
                    if (_cachedScreenshots.isNotEmpty)
                      SizedBox(
                        height: kThumbnailSize,
                        child: _buildLayeredThumbnails(context, kThumbnailSize),
                      ),
                  ],
                ),
              ),
              // Screenshot count badge
              Positioned(
                right: kDefaultOuterOffset,
                bottom: kDefaultOuterOffset,
                child: Container(
                  constraints: BoxConstraints(
                    minWidth: kIconContainerSize,
                    minHeight: kIconContainerSize,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.collection.screenshotCount}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              // Auto-add indicator
              if (widget.collection.isAutoAddEnabled)
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
      ),
    );
  }

  Widget _buildLayeredThumbnails(BuildContext context, double thumbnailSize) {
    // Use cached thumbnails if available
    if (_cachedThumbnails != null) {
      return _cachedThumbnails!;
    }

    if (_cachedScreenshots.isEmpty) return const SizedBox.shrink();

    Widget thumbnailWidget;
    final stackSpacing = 6.0;
    final verticalOffset = 1.0;

    if (_cachedScreenshots.length == 1) {
      // Single image - show full size
      thumbnailWidget = Container(
        width: thumbnailSize,
        height: thumbnailSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.secondary,
            width: 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: _buildThumbnailImage(_cachedScreenshots[0]),
      );
    } else {
      // Multiple images - use stacked layout
      thumbnailWidget = SizedBox(
        width: thumbnailSize,
        height: thumbnailSize,
        child: Stack(
          children: [
            // Bottom image (if there are 3 images)
            if (_cachedScreenshots.length >= 3)
              Positioned(
                top: verticalOffset * 2,
                right: 1,
                child: Transform.translate(
                  offset: Offset(stackSpacing * 3, 0),
                  child: Container(
                    width: thumbnailSize - (stackSpacing * 2),
                    height: thumbnailSize - (verticalOffset * 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.secondary,
                        width: 2,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _buildThumbnailImage(_cachedScreenshots[2]),
                  ),
                ),
              ),
            // Middle image (if there are 2 or more images)
            if (_cachedScreenshots.length >= 2)
              Positioned(
                top: verticalOffset,
                right: 1,
                child: Transform.translate(
                  offset: Offset(stackSpacing * 1.5, 0),
                  child: Container(
                    width: thumbnailSize - stackSpacing,
                    height: thumbnailSize - verticalOffset,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.secondary,
                        width: 2,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _buildThumbnailImage(_cachedScreenshots[1]),
                  ),
                ),
              ),
            // Top image (fully visible)
            Container(
              width: thumbnailSize,
              height: thumbnailSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.secondary,
                  width: 2,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildThumbnailImage(_cachedScreenshots[0]),
            ),
          ],
        ),
      );
    }

    // Cache the built thumbnails
    _cachedThumbnails = thumbnailWidget;
    return thumbnailWidget;
  }

  Widget _buildThumbnailImage(Screenshot screenshot) {
    if (_globalImageCache.containsKey(screenshot.id)) {
      return _globalImageCache[screenshot.id]!;
    }

    if (_imageCache.containsKey(screenshot.id)) {
      return _imageCache[screenshot.id]!;
    }

    Widget imageWidget;
    if (screenshot.path != null) {
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(8), // Match container border radius
        child: Image.file(
          File(screenshot.path!),
          fit: BoxFit.cover,
          cacheWidth: 200,
          errorBuilder: (context, error, stackTrace) => _buildErrorThumbnail(),
        ),
      );
    } else if (screenshot.bytes != null) {
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          screenshot.bytes!,
          fit: BoxFit.cover,
          cacheWidth: 200,
          errorBuilder: (context, error, stackTrace) => _buildErrorThumbnail(),
        ),
      );
    } else {
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _buildErrorThumbnail(),
      );
    }

    _imageCache[screenshot.id] = imageWidget;
    _globalImageCache[screenshot.id] = imageWidget;

    if (_globalImageCache.length > 100) {
      final keys = _globalImageCache.keys.toList();
      for (int i = 0; i < 20; i++) {
        _globalImageCache.remove(keys[i]);
      }
    }

    return imageWidget;
  }

  Widget _buildErrorThumbnail() {
    return Container(
      color: Colors.grey[300],
      child: const Icon(Icons.image, color: Colors.grey, size: 24),
    );
  }
}
