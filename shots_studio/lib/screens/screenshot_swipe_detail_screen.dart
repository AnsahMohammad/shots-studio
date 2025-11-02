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

  // Cache for pre-built widgets to improve performance
  final Map<int, Widget> _pageCache = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(
      initialPage: widget.initialIndex,
      viewportFraction: 1.0,
      keepPage: true,
    );

    AnalyticsService().logScreenView('screenshot_swipe_detail_screen');
    AnalyticsService().logFeatureUsed('screenshot_swipe_viewer_opened');
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pageCache.clear();
    super.dispose();
  }

  void _onPageChanged(int index) {
    AnalyticsService().logFeatureUsed('screenshot_swipe_navigation');

    setState(() {
      _currentIndex = index;
    });

    _pageCache.removeWhere((key, value) => (key - index).abs() > 2);
  }

  void _navigateToIndex(int index) {
    if (index >= 0 &&
        index < widget.screenshots.length &&
        index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });

      if (_pageController.hasClients) {
        _pageController.jumpToPage(index);
      }
    }
  }

  void _onScreenshotDeleted(String screenshotId) {
    final deletedIndex = widget.screenshots.indexWhere(
      (s) => s.id == screenshotId,
    );

    if (deletedIndex != -1) {
      widget.onDeleteScreenshot(screenshotId);
      widget.screenshots.removeAt(deletedIndex);
      _pageCache.clear();

      if (widget.screenshots.isEmpty) {
        Navigator.of(context).pop();
        return;
      }

      int newIndex = _currentIndex;
      if (deletedIndex == _currentIndex) {
        if (_currentIndex >= widget.screenshots.length) {
          newIndex = widget.screenshots.length - 1;
        }
      } else if (deletedIndex < _currentIndex) {
        newIndex = _currentIndex - 1;
      }

      setState(() {
        _currentIndex = newIndex;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients && mounted) {
          _pageController.jumpToPage(_currentIndex);
        }
      });
    }
  }

  void _onNavigateAfterDelete() {
    // Navigation is handled by _onScreenshotDeleted
  }

  Widget _buildPage(int index) {
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
        disableAnimations: true,
      ),
    );

    if (shouldCache) {
      _pageCache[index] = page;
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
        padEnds: false,
        allowImplicitScrolling: true,
        physics: const ClampingScrollPhysics(),
        clipBehavior: Clip.none,
        itemBuilder: (context, index) {
          return _buildPage(index);
          return _buildPage(index);
        },
      ),
    );
  }
}
