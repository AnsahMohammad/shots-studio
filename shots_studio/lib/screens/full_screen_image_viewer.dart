import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';

class FullScreenImageViewer extends StatefulWidget {
  final List<Screenshot> screenshots;
  final int initialIndex;
  final Function(int)? onScreenshotChanged;

  const FullScreenImageViewer({
    super.key,
    required this.screenshots,
    required this.initialIndex,
    this.onScreenshotChanged,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;
  bool _isDisposed = false;

  // Zoom state management
  late TransformationController _transformationController;
  late List<TransformationController> _transformationControllers;
  late AnimationController _animationController;
  late Animation<Matrix4> _matrixAnimation;
  static const double _minScale = 0.5;
  static const double _maxScale = 4.0;
  static const double _doubleTapZoomScale = 2.0;

  // Double tap detection
  Offset? _lastTapPosition;
  DateTime? _lastTapTime;

  // Performance optimization: Cache for pre-built image widgets
  final Map<int, Widget> _imageCache = {};

  // Preloaded image cache to prevent flickering
  final Map<int, ImageProvider> _preloadedImages = {};

  // Track which images are currently being preloaded
  final Set<int> _preloadingImages = {};

  @override
  void initState() {
    super.initState();
    // Ensure initialIndex is within bounds
    _currentIndex = widget.initialIndex.clamp(0, widget.screenshots.length - 1);
    _pageController = PageController(
      initialPage: _currentIndex,
      viewportFraction: 1.0, // Ensure full viewport for smooth scrolling
      keepPage: true, // Keep page state when off-screen
    );

    // Initialize transformation controllers
    _transformationController = TransformationController();
    _transformationControllers = List.generate(
      widget.screenshots.length,
      (index) => TransformationController(),
    );

    // Initialize animation controller for smooth zoom transitions
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Track full screen viewer access
    AnalyticsService().logScreenView('full_screen_image_viewer');

    // Start preloading images around the initial index to prevent flickering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposed) {
        _preloadImages(_currentIndex);
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _pageController.dispose();
    _transformationController.dispose();
    _animationController.dispose();
    for (final controller in _transformationControllers) {
      controller.dispose();
    }
    _imageCache.clear(); // Clear cache to prevent memory leaks
    _preloadedImages.clear();
    _preloadingImages.clear();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (_isDisposed || !mounted) return;

    setState(() {
      _currentIndex = index;
    });
    widget.onScreenshotChanged?.call(index);

    // Preload images around the new current index to prevent flickering
    _preloadImages(index);

    // Clean up very distant cached images to manage memory (more generous range)
    _imageCache.removeWhere((key, value) => (key - index).abs() > 5);
    _preloadedImages.removeWhere((key, value) => (key - index).abs() > 15);

    // Track swipe navigation
    AnalyticsService().logFeatureUsed('full_screen_swipe_navigation');
  }

  void _handleTap(Offset position, TransformationController controller) {
    final now = DateTime.now();

    // Check if this is a double tap
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!).inMilliseconds < 300 &&
        _lastTapPosition != null &&
        (position - _lastTapPosition!).distance < 50) {
      // This is a double tap
      _handleDoubleTap(position, controller);
      _lastTapTime = null;
      _lastTapPosition = null;
    } else {
      // First tap or single tap
      _lastTapTime = now;
      _lastTapPosition = position;
    }
  }

  void _handleDoubleTap(
    Offset tapPosition,
    TransformationController controller,
  ) {
    // Prevent multiple animations from running at the same time
    if (_animationController.isAnimating) return;

    final Matrix4 currentTransform = controller.value;
    final double currentScale = currentTransform.getMaxScaleOnAxis();

    Matrix4 targetMatrix;

    if (currentScale > 1.1) {
      // If zoomed in, zoom out to fit
      targetMatrix = Matrix4.identity();
    } else {
      // If zoomed out, zoom in to the tap location
      // Create a matrix that zooms into the tap position
      targetMatrix =
          Matrix4.identity()
            ..translate(tapPosition.dx, tapPosition.dy)
            ..scale(_doubleTapZoomScale)
            ..translate(-tapPosition.dx, -tapPosition.dy);
    }

    // Animate smoothly to the target transformation
    _animateToMatrix(controller, currentTransform, targetMatrix);

    // Track double tap zoom usage
    AnalyticsService().logFeatureUsed('double_tap_zoom');
  }

  void _animateToMatrix(
    TransformationController controller,
    Matrix4 begin,
    Matrix4 end,
  ) {
    // Remove previous listener to prevent memory leaks
    _animationController.removeListener(() {});

    _matrixAnimation = Matrix4Tween(begin: begin, end: end).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    void animationListener() {
      if (mounted && !_isDisposed) {
        controller.value = _matrixAnimation.value;
      }
    }

    _animationController.addListener(animationListener);

    _animationController.forward(from: 0.0).then((_) {
      // Clean up listener after animation completes
      _animationController.removeListener(animationListener);
    });
  }

  Widget _buildZoomableImage(
    TransformationController controller,
    Widget child,
  ) {
    return RepaintBoundary(
      child: RawGestureDetector(
        gestures: <Type, GestureRecognizerFactory>{
          TapGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                () => TapGestureRecognizer(),
                (TapGestureRecognizer instance) {
                  instance.onTapDown = (TapDownDetails details) {
                    _handleTap(details.localPosition, controller);
                  };
                },
              ),
        },
        child: InteractiveViewer(
          transformationController: controller,
          panEnabled: true,
          minScale: _minScale,
          maxScale: _maxScale,
          clipBehavior: Clip.none, // Reduce clipping overhead
          child: Center(child: child),
        ),
      ),
    );
  }

  Widget _buildImageContent(Screenshot screenshot) {
    if (screenshot.path != null) {
      final file = File(screenshot.path!);
      if (file.existsSync()) {
        return Image.file(
          file,
          key: ValueKey('file_${screenshot.path}'),
          // Performance optimizations for large images
          cacheWidth: null, // Let Flutter handle optimal caching
          cacheHeight: null,
          filterQuality:
              FilterQuality.medium, // Balance between quality and performance
          gaplessPlayback: true, // Prevent flickering during transitions
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) return child;
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 200),
              child: child,
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image_outlined,
                    size: 100,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Image could not be loaded',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      } else {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported_outlined,
                size: 100,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Image file not found',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The original file may have been moved or deleted',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }
    } else if (screenshot.bytes != null) {
      return Image.memory(
        screenshot.bytes!,
        key: ValueKey('memory_${screenshot.id}'),
        // Performance optimizations for memory images
        cacheWidth: null, // Let Flutter handle optimal caching
        cacheHeight: null,
        filterQuality:
            FilterQuality.medium, // Balance between quality and performance
        gaplessPlayback: true, // Prevent flickering during transitions
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            child: child,
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image_outlined,
                  size: 100,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'Image could not be loaded',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image_outlined,
              size: 100,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Image not available',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }
  }

  void _preloadImages(int currentIndex) {
    // Preload images in a wider range to prevent flickering during fast swipes
    final preloadRange = 3; // Preload 3 images in each direction

    for (int i = -preloadRange; i <= preloadRange; i++) {
      final targetIndex = currentIndex + i;
      if (targetIndex >= 0 &&
          targetIndex < widget.screenshots.length &&
          !_preloadingImages.contains(targetIndex) &&
          !_preloadedImages.containsKey(targetIndex)) {
        _preloadingImages.add(targetIndex);
        _preloadImageAtIndex(targetIndex);
      }
    }
  }

  void _preloadImageAtIndex(int index) async {
    final screenshot = widget.screenshots[index];
    ImageProvider? imageProvider;

    try {
      if (screenshot.path != null) {
        final file = File(screenshot.path!);
        if (file.existsSync()) {
          imageProvider = FileImage(file);
        }
      } else if (screenshot.bytes != null) {
        imageProvider = MemoryImage(screenshot.bytes!);
      }

      if (imageProvider != null && mounted && !_isDisposed) {
        // Preload the image to cache
        await precacheImage(imageProvider, context);
        if (mounted && !_isDisposed) {
          _preloadedImages[index] = imageProvider;
        }
      }
    } catch (e) {
      // Ignore preload errors
    } finally {
      _preloadingImages.remove(index);
    }
  }

  Widget _buildCachedImage(int index) {
    // Use more aggressive caching - cache all visible and nearby images

    // Always return cached widget if available to prevent rebuilds
    if (_imageCache.containsKey(index)) {
      return _imageCache[index]!;
    }

    // Build the image widget with consistent key to prevent rebuilds
    final image = RepaintBoundary(
      key: ValueKey('fullscreen_${widget.screenshots[index].id}'),
      child: _buildZoomableImage(
        _transformationControllers[index],
        _buildOptimizedImageContent(widget.screenshots[index], index),
      ),
    );

    // Cache the widget regardless of distance to prevent flickering
    _imageCache[index] = image;

    // Only remove very distant images to prevent excessive memory usage
    _imageCache.removeWhere((key, value) => (key - _currentIndex).abs() > 5);

    return image;
  }

  Widget _buildOptimizedImageContent(Screenshot screenshot, int index) {
    // Use preloaded image if available to prevent loading delays
    if (_preloadedImages.containsKey(index)) {
      return RepaintBoundary(
        child: Image(
          key: ValueKey('preloaded_${screenshot.id}'),
          image: _preloadedImages[index]!,
          filterQuality: FilterQuality.medium,
          fit: BoxFit.contain,
          gaplessPlayback: true, // Prevent flickering during image transitions
          errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
        ),
      );
    }

    // Fallback to regular image loading with optimizations
    return RepaintBoundary(child: _buildImageContent(screenshot));
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: 100,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Image could not be loaded',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ensure currentIndex is still valid (defensive programming)
    if (_currentIndex < 0 || _currentIndex >= widget.screenshots.length) {
      _currentIndex = 0;
    }

    if (_isDisposed || !mounted) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentScreenshot = widget.screenshots[_currentIndex];

    return PopScope(
      canPop: false, // Prevent default pop behavior
      onPopInvoked: (didPop) {
        if (!didPop) {
          // Handle the back gesture/button by returning the current index
          Navigator.of(context).pop(_currentIndex);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(_currentIndex),
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          title: Text(
            currentScreenshot.title ?? 'Screenshot',
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            if (widget.screenshots.length > 1)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    '${_currentIndex + 1} / ${widget.screenshots.length}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
        body:
            widget.screenshots.length == 1
                ? _buildZoomableImage(
                  _transformationController,
                  _buildImageContent(currentScreenshot),
                )
                : PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: widget.screenshots.length,
                  // Performance optimizations
                  padEnds:
                      false, // Reduces over-scroll and improves performance
                  allowImplicitScrolling: true, // Better scroll behavior
                  physics:
                      const ClampingScrollPhysics(), // Optimized physics for better performance
                  clipBehavior: Clip.none, // Reduce clipping overhead
                  itemBuilder: (context, index) {
                    return _buildCachedImage(index);
                  },
                ),
      ),
    );
  }
}
