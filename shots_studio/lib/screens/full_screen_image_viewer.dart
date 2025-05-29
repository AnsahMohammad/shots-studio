import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shots_studio/models/screenshot_model.dart';

class FullScreenImageViewer extends StatelessWidget {
  final Screenshot screenshot;

  const FullScreenImageViewer({super.key, required this.screenshot});

  @override
  Widget build(BuildContext context) {
    Widget imageContent;

    if (screenshot.path != null) {
      imageContent = Image.file(File(screenshot.path!));
    } else if (screenshot.bytes != null) {
      imageContent = Image.memory(screenshot.bytes!);
    } else {
      imageContent = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image,
              size: 100,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 16),
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

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        title: Text(
          screenshot.title ?? 'Screenshot',
          style: TextStyle(
            fontSize: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: imageContent,
        ),
      ),
    );
  }
}
