import 'package:flutter/material.dart';
import 'package:shots_studio/services/snackbar_service.dart';
import 'package:shots_studio/models/collection_model.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/widgets/screenshots/screenshot_card.dart';
import 'package:uuid/uuid.dart';

class CreateCollectionScreen extends StatefulWidget {
  final List<Screenshot> availableScreenshots;
  final Set<String>? initialSelectedIds;
  final Collection? existingCollection;

  const CreateCollectionScreen({
    super.key,
    required this.availableScreenshots,
    this.initialSelectedIds,
    this.existingCollection,
  });

  @override
  State<CreateCollectionScreen> createState() => _CreateCollectionScreenState();
}

class _CreateCollectionScreenState extends State<CreateCollectionScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  late Set<String> _selectedScreenshotIds;
  final Uuid _uuid = const Uuid();
  bool _isAutoAddEnabled = false;

  @override
  void initState() {
    super.initState();

    // If editing an existing collection, populate the fields
    if (widget.existingCollection != null) {
      _titleController.text = widget.existingCollection!.name ?? '';
      _descriptionController.text =
          widget.existingCollection!.description ?? '';
      _isAutoAddEnabled = widget.existingCollection!.isAutoAddEnabled;
    }

    _selectedScreenshotIds =
        widget.initialSelectedIds != null
            ? Set.from(widget.initialSelectedIds!)
            : {};

    _titleController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _titleController.removeListener(() {
      setState(() {});
    });
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _toggleScreenshotSelection(String screenshotId) {
    setState(() {
      if (_selectedScreenshotIds.contains(screenshotId)) {
        _selectedScreenshotIds.remove(screenshotId);
      } else {
        _selectedScreenshotIds.add(screenshotId);
      }
    });
  }

  void _save() {
    final String title = _titleController.text.trim();

    if (title.isEmpty) {
      SnackbarService().showError(
        context,
        'Please enter a title for your collection',
      );
      return;
    }

    final Collection collection;
    if (widget.existingCollection != null) {
      // Update existing collection
      collection = widget.existingCollection!.copyWith(
        name: title,
        description: _descriptionController.text.trim(),
        screenshotIds: _selectedScreenshotIds.toList(),
        lastModified: DateTime.now(),
        screenshotCount: _selectedScreenshotIds.length,
        isAutoAddEnabled: _isAutoAddEnabled,
      );
    } else {
      // Create new collection
      collection = Collection(
        id: _uuid.v4(),
        name: title,
        description: _descriptionController.text.trim(),
        screenshotIds: _selectedScreenshotIds.toList(),
        lastModified: DateTime.now(),
        screenshotCount: _selectedScreenshotIds.length,
        isAutoAddEnabled: _isAutoAddEnabled,
      );
    }
    Navigator.of(context).pop(collection);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.existingCollection != null
              ? 'Edit Collection'
              : 'Create Collection',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
              decoration: InputDecoration(
                hintText: 'Collection Title',
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
              decoration: InputDecoration(
                hintText: 'Add a description...',
                filled: true,
                fillColor: Theme.of(context).colorScheme.secondaryContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Tooltip(
                    message:
                        'When enabled, AI will automatically add relevant screenshots to this collection',
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Enable Auto-Add Screenshots',
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ],
                    ),
                  ),
                ),
                Switch(
                  value: _isAutoAddEnabled,
                  activeColor: Theme.of(context).colorScheme.primary,
                  onChanged: (bool value) {
                    setState(() {
                      _isAutoAddEnabled = value;
                    });
                  },
                ),
              ],
            ),
            if (_isAutoAddEnabled)
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.tertiary.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Gemini AI will automatically categorize new screenshots into this collection based on content analysis.',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              Theme.of(context).colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Select Screenshots',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 16),

            // Screenshots grid
            Expanded(
              child:
                  widget.availableScreenshots.isEmpty
                      ? Center(
                        child: Text(
                          'No screenshots available',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                      : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 1,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemCount: widget.availableScreenshots.length,
                        cacheExtent: 1200,
                        itemBuilder: (context, index) {
                          final screenshot = widget.availableScreenshots[index];
                          final isSelected = _selectedScreenshotIds.contains(
                            screenshot.id,
                          );

                          return GestureDetector(
                            onTap:
                                () => _toggleScreenshotSelection(screenshot.id),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ScreenshotCard(
                                  screenshot: screenshot,
                                  onTap:
                                      () => _toggleScreenshotSelection(
                                        screenshot.id,
                                      ),
                                ),

                                if (isSelected)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surface
                                          .withValues(alpha: 0.7),
                                      border: Border.all(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.check_circle,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                        size: 36,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
