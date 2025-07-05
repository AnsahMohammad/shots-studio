import 'package:shots_studio/models/collection_model.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/services/analytics_service.dart';

class CollectionHelper {
  /// Log collection statistics
  static void logCollectionStats(List<Collection> collections) {
    if (collections.isEmpty) return;

    // Calculate collection statistics
    final screenshotCounts =
        collections.map((c) => c.screenshotIds.length).toList();
    final totalScreenshots = screenshotCounts.fold(
      0,
      (sum, count) => sum + count,
    );
    final avgScreenshots = totalScreenshots / collections.length;
    final minScreenshots = screenshotCounts.reduce((a, b) => a < b ? a : b);
    final maxScreenshots = screenshotCounts.reduce((a, b) => a > b ? a : b);

    // Log collection statistics
    AnalyticsService().logCollectionStats(
      collections.length,
      avgScreenshots.round(),
      minScreenshots,
      maxScreenshots,
    );
  }

  /// Update collection and maintain bidirectional relationship with screenshots
  static void updateCollectionRelationships(
    Collection updatedCollection,
    Collection? oldCollection,
    List<Screenshot> screenshots,
  ) {
    if (oldCollection != null) {
      // Find screenshots that were added to the collection
      final addedScreenshots =
          updatedCollection.screenshotIds
              .where((id) => !oldCollection.screenshotIds.contains(id))
              .toList();

      // Find screenshots that were removed from the collection
      final removedScreenshots =
          oldCollection.screenshotIds
              .where((id) => !updatedCollection.screenshotIds.contains(id))
              .toList();

      // Update added screenshots' collectionIds
      for (String screenshotId in addedScreenshots) {
        final screenshotIndex = screenshots.indexWhere(
          (s) => s.id == screenshotId,
        );
        if (screenshotIndex != -1) {
          final screenshot = screenshots[screenshotIndex];
          if (!screenshot.collectionIds.contains(updatedCollection.id)) {
            screenshot.collectionIds.add(updatedCollection.id);
          }
        }
      }

      // Update removed screenshots' collectionIds
      for (String screenshotId in removedScreenshots) {
        final screenshotIndex = screenshots.indexWhere(
          (s) => s.id == screenshotId,
        );
        if (screenshotIndex != -1) {
          final screenshot = screenshots[screenshotIndex];
          screenshot.collectionIds.remove(updatedCollection.id);
        }
      }
    }
  }

  /// Add collection and maintain bidirectional relationship with screenshots
  static void addCollectionRelationships(
    Collection collection,
    List<Screenshot> screenshots,
  ) {
    // Update screenshots' collectionIds to maintain bidirectional relationship
    for (String screenshotId in collection.screenshotIds) {
      final screenshotIndex = screenshots.indexWhere(
        (s) => s.id == screenshotId,
      );
      if (screenshotIndex != -1) {
        final screenshot = screenshots[screenshotIndex];
        if (!screenshot.collectionIds.contains(collection.id)) {
          screenshot.collectionIds.add(collection.id);
        }
      }
    }
  }

  /// Remove collection and clean up relationships with screenshots
  static void removeCollectionRelationships(
    String collectionId,
    List<Screenshot> screenshots,
  ) {
    for (var screenshot in screenshots) {
      screenshot.collectionIds.remove(collectionId);
    }
  }
}
