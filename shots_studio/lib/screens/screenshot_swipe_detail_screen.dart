import 'package:flutter/material.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/models/collection_model.dart';
import 'package:shots_studio/screens/screenshot_details_screen.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';

class ScreenshotSwipeDetailScreen extends StatefulWidget {
  final List<Screenshot> screenshots;
  final int initialIndex;
  final List<Collection> allCollections;
  final List<Screenshot> allScreenshots;
  final Function(Collection) onUpdateCollection;
  final Function(String) onDeleteScreenshot;
  final VoidCallback? onScreenshotUpdated;

  const ScreenshotSwipeDetailScreen({
    super.key,
    required this.screenshots,
    required this.initialIndex,
    required this.allCollections,
    required this.allScreenshots,
    required this.onUpdateCollection,
    required this.onDeleteScreenshot,
    this.onScreenshotUpdated,
  });

  @override
  State<ScreenshotSwipeDetailScreen> createState() =>
      _ScreenshotSwipeDetailScreenState();
}

class _ScreenshotSwipeDetailScreenState
    extends State<ScreenshotSwipeDetailScreen> {
  late PageController _pageController;
  late int _currentIndex;

  // Cache for pre-built widgets to improve performance
  final Map<int, Widget> _pageCache = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(
      initialPage: widget.initialIndex,
      viewportFraction: 1.0, // Ensure full viewport for smooth scrolling
      keepPage: true, // Keep page state when off-screen
    );

    // Track screen access
    AnalyticsService().logScreenView('screenshot_swipe_detail_screen');
    AnalyticsService().logFeatureUsed('screenshot_swipe_viewer_opened');
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pageCache.clear(); // Clear cache to prevent memory leaks
    super.dispose();
  }

  void _onPageChanged(int index) {
    // Track page swipe analytics
    AnalyticsService().logFeatureUsed('screenshot_swipe_navigation');

    setState(() {
      _currentIndex = index;
    });

    // Clean up distant cached pages to manage memory
    _pageCache.removeWhere((key, value) => (key - index).abs() > 2);
  }

  void _navigateToIndex(int index) {
    if (index >= 0 &&
        index < widget.screenshots.length &&
        index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });

      // Jump instantly to the new page without animation
      if (_pageController.hasClients) {
        _pageController.jumpToPage(index);
      }
    }
  }

  void _onScreenshotDeleted(String screenshotId) {
    // Find the index of the deleted screenshot
    final deletedIndex = widget.screenshots.indexWhere(
      (s) => s.id == screenshotId,
    );

    if (deletedIndex != -1) {
      setState(() {
        // Remove the screenshot from our local list
        widget.screenshots.removeAt(deletedIndex);

        // Determine the new index to navigate to
        if (widget.screenshots.isEmpty) {
          // Will navigate back below
          print('DEBUG: No screenshots remaining, will go back');
        } else if (deletedIndex == _currentIndex) {
          // We deleted the current screenshot, stay at same index or go to previous
          if (_currentIndex >= widget.screenshots.length) {
            _currentIndex = widget.screenshots.length - 1;
          }
          // If we deleted the last screenshot, current index is now the previous one
          // If we deleted any other screenshot, current index now shows the next one
        } else if (deletedIndex < _currentIndex) {
          // We deleted a screenshot before the current one, adjust index down
          _currentIndex--;
        } else {
          // Deleted screenshot after current, index stays $_currentIndex
        }
        // If deletedIndex > _currentIndex, no change needed to _currentIndex
      });

      // Call the parent's delete callback
      widget.onDeleteScreenshot(screenshotId);

      // If this was the last screenshot, go back
      if (widget.screenshots.isEmpty) {
        Navigator.of(context).pop();
        return;
      }

      // Navigate to the adjusted index immediately
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          print('DEBUG: Navigating to index $_currentIndex');
          _pageController.animateToPage(
            _currentIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  void _onNavigateAfterDelete() {
    // Do nothing - the navigation is handled by _onScreenshotDeleted
    // This callback just prevents the default Navigator.pop() behavior
  }

  Widget _buildPage(int index) {
    // Implement simple caching to reduce rebuilds during rapid scrolling
    // Only cache current and adjacent pages to limit memory usage
    final shouldCache = (index - _currentIndex).abs() <= 1;

    if (shouldCache && _pageCache.containsKey(index)) {
      return _pageCache[index]!;
    }

    final page = RepaintBoundary(
      key: ValueKey('screenshot_${widget.screenshots[index].id}_$index'),
      child: ScreenshotDetailScreen(
        screenshot: widget.screenshots[index],
        allCollections: widget.allCollections,
        allScreenshots: widget.allScreenshots,
        contextualScreenshots: widget.screenshots,
        onUpdateCollection: widget.onUpdateCollection,
        onDeleteScreenshot: _onScreenshotDeleted,
        onScreenshotUpdated: widget.onScreenshotUpdated,
        currentIndex: index,
        totalCount: widget.screenshots.length,
        onNavigateAfterDelete: _onNavigateAfterDelete,
        onNavigateToIndex: _navigateToIndex,
        disableAnimations:
            true, // Disable bounce animations in PageView for better performance
      ),
    );

    // Cache current and adjacent pages only
    if (shouldCache) {
      _pageCache[index] = page;

      // Limit cache size - remove pages that are too far away
      _pageCache.removeWhere((key, value) => (key - _currentIndex).abs() > 2);
    }

    return page;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.screenshots.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('No Screenshots')),
        body: const Center(child: Text('No screenshots available')),
      );
    }

    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        itemCount: widget.screenshots.length,
        // Performance optimizations
        padEnds: false, // Reduces over-scroll and improves performance
        allowImplicitScrolling: true, // Better scroll behavior
        physics:
            const ClampingScrollPhysics(), // Use clamping physics for better performance on Android
        clipBehavior: Clip.none, // Reduce clipping overhead
        itemBuilder: (context, index) {
          return _buildPage(index);
        },
      ),
    );
  }
}
