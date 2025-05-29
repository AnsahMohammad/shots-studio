import 'package:flutter/material.dart';
import 'package:shots_studio/models/collection_model.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/screens/screenshot_details_screen.dart';
import 'package:shots_studio/widgets/screenshots/screenshot_card.dart';

class SearchScreen extends StatefulWidget {
  final List<Screenshot> allScreenshots;
  final List<Collection> allCollections;
  final Function(Collection) onUpdateCollection;
  final Function(String) onDeleteScreenshot;

  const SearchScreen({
    super.key,
    required this.allScreenshots,
    required this.allCollections,
    required this.onUpdateCollection,
    required this.onDeleteScreenshot,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _searchQuery = '';
  List<Screenshot> _filteredScreenshots = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredScreenshots = widget.allScreenshots;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredScreenshots = widget.allScreenshots;
      } else {
        // Match if it's a whole word OR starts with the word OR ends with the word
        final RegExp wordPattern = RegExp(
          r'(?:^|[\s.,!?])' +
              RegExp.escape(_searchQuery) +
              r'|' + // Whole word or word at start
              r'\b' +
              RegExp.escape(_searchQuery) +
              r'\w*|' + // Word starting with query
              r'\w*' +
              RegExp.escape(_searchQuery) +
              r'(?:[\s.,!?]|$)', // Word ending with query
          caseSensitive: false,
        );

        _filteredScreenshots =
            widget.allScreenshots.where((screenshot) {
              final titleMatch =
                  screenshot.title != null &&
                  wordPattern.hasMatch(screenshot.title!.toLowerCase());

              final descriptionMatch =
                  screenshot.description != null &&
                  wordPattern.hasMatch(screenshot.description!.toLowerCase());

              final tagsMatch = screenshot.tags.any(
                (tag) => tag.toLowerCase() == _searchQuery,
              );

              return titleMatch || descriptionMatch || tagsMatch;
            }).toList();
      }
    });
  }

  void _showScreenshotDetail(Screenshot screenshot) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => ScreenshotDetailScreen(
              screenshot: screenshot,
              allCollections: widget.allCollections,
              onUpdateCollection: widget.onUpdateCollection,
              onDeleteScreenshot: widget.onDeleteScreenshot,
              onScreenshotUpdated: () {
                setState(() {});
              },
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search by title, description, tags...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
      ),
      body:
          _filteredScreenshots.isEmpty && _searchQuery.isNotEmpty
              ? Center(
                child: Text(
                  'No screenshots found for "$_searchQuery"',
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
              : GridView.builder(
                padding: const EdgeInsets.all(16.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _filteredScreenshots.length,
                cacheExtent: 500,
                itemBuilder: (context, index) {
                  final screenshot = _filteredScreenshots[index];
                  return ScreenshotCard(
                    screenshot: screenshot,
                    onTap: () => _showScreenshotDetail(screenshot),
                  );
                },
              ),
    );
  }
}
