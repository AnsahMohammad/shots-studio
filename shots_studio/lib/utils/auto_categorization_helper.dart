import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/models/collection_model.dart';
import 'package:shots_studio/services/analytics_service.dart';

class AutoCategorizationHelper {
  /// Handle auto-categorization for a screenshot based on AI suggestions
  static void handleAutoCategorization(
    Screenshot screenshot,
    Map<String, dynamic> response,
    List<Collection> collections,
    Function(Collection) onUpdateCollection,
  ) {
    try {
      Map<dynamic, dynamic>? suggestionsMap;
      if (response['suggestedCollections'] is Map<String, List<String>>) {
        suggestionsMap =
            response['suggestedCollections'] as Map<String, List<String>>;
      } else if (response['suggestedCollections'] is Map<dynamic, dynamic>) {
        suggestionsMap =
            response['suggestedCollections'] as Map<dynamic, dynamic>;
      }

      List<String> suggestedCollections = [];
      if (suggestionsMap != null && suggestionsMap.containsKey(screenshot.id)) {
        final suggestions = suggestionsMap[screenshot.id];
        if (suggestions is List) {
          suggestedCollections = List<String>.from(
            suggestions.whereType<String>(),
          );
        } else if (suggestions is String) {
          suggestedCollections = [suggestions];
        }
      }

      if (suggestedCollections.isNotEmpty) {
        int autoAddedCount = 0;
        for (var collection in collections) {
          if (collection.isAutoAddEnabled &&
              suggestedCollections.contains(collection.name) &&
              !screenshot.collectionIds.contains(collection.id) &&
              !collection.screenshotIds.contains(screenshot.id)) {
            // Auto-add screenshot to this collection
            final updatedCollection = collection.addScreenshot(
              screenshot.id,
              isAutoCategorized: true,
            );
            onUpdateCollection(updatedCollection);
            autoAddedCount++;
          }
        }

        if (autoAddedCount > 0) {
          print(
            "AutoCategorizationHelper: Auto-categorized screenshot ${screenshot.id} into $autoAddedCount collection(s)",
          );

          // Log auto-categorization analytics
          AnalyticsService().logScreenshotsAutoCategorized(autoAddedCount);
          AnalyticsService().logFeatureUsed('auto_categorization');
        }
      }
    } catch (e) {
      print('AutoCategorizationHelper: Error handling auto-categorization: $e');
    }
  }
}
