import 'package:flutter/material.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/widgets/screenshots/screenshot_card.dart';

class ScreenshotsSection extends StatefulWidget {
  final List<Screenshot> screenshots;
  final Function(Screenshot) onScreenshotTap;

  const ScreenshotsSection({
    super.key,
    required this.screenshots,
    required this.onScreenshotTap,
  });

  @override
  State<ScreenshotsSection> createState() => _ScreenshotsSectionState();
}

class _ScreenshotsSectionState extends State<ScreenshotsSection> {
  static const int _itemsPerPage = 60; // Load 60 items at a time (20 rows of 3)
  int _currentPageIndex = 0;
  bool _isLoadingMore = false;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreItems();
    }
  }

  void _loadMoreItems() {
    if (_isLoadingMore) return;

    final int totalItems = widget.screenshots.length;
    final int currentlyShowing = (_currentPageIndex + 1) * _itemsPerPage;

    if (currentlyShowing >= totalItems) return;

    setState(() {
      _isLoadingMore = true;
    });

    // Simulate a small delay to prevent rapid loading
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _currentPageIndex++;
          _isLoadingMore = false;
        });
      }
    });
  }

  List<Screenshot> get _visibleScreenshots {
    final int endIndex = (_currentPageIndex + 1) * _itemsPerPage;
    return widget.screenshots.take(endIndex).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Screenshots',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              Text(
                'Total : ${widget.screenshots.length}',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 4,
            ),
            itemCount: _visibleScreenshots.length + (_isLoadingMore ? 3 : 0),
            itemBuilder: (context, index) {
              if (index >= _visibleScreenshots.length) {
                return Card(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                );
              }

              return ScreenshotCard(
                screenshot: _visibleScreenshots[index],
                onTap: () => widget.onScreenshotTap(_visibleScreenshots[index]),
              );
            },
          ),
        ),
        if (widget.screenshots.length > _visibleScreenshots.length)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: TextButton.icon(
                onPressed: _isLoadingMore ? null : _loadMoreItems,
                icon:
                    _isLoadingMore
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.expand_more),
                label: Text(_isLoadingMore ? 'Loading...' : 'Load More'),
              ),
            ),
          ),
      ],
    );
  }
}
