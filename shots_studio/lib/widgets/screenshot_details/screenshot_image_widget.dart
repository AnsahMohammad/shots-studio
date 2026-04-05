import 'package:flutter/material.dart';
import 'dart:io';
import 'package:shots_studio/models/screenshot_model.dart';

/// A widget that displays the screenshot image with error handling.
/// Supports both file path and byte array sources.
class ScreenshotImageWidget extends StatelessWidget {
  final Screenshot screenshot;
  final VoidCallback? onImageError;

  const ScreenshotImageWidget({
    super.key,
    required this.screenshot,
    this.onImageError,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    final screenshotPath = screenshot.path;
    if (screenshotPath != null) {
      final file = File(screenshotPath);
      if (file.existsSync()) {
        imageWidget = Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            onImageError?.call();
            return _buildErrorWidget(context, 'Image could not be loaded');
          },
        );
      } else {
        // File not found
        onImageError?.call();
        imageWidget = _buildErrorWidget(
          context,
          'Image file not found',
          subtitle: 'The original file may have been moved or deleted',
        );
      }
    } else if (screenshot.bytes != null) {
      imageWidget = Image.memory(
        screenshot.bytes!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          onImageError?.call();
          return _buildErrorWidget(context, 'Image could not be loaded');
        },
      );
    } else {
      // No image data available
      onImageError?.call();
      imageWidget = _buildErrorWidget(context, 'No image available');
    }

    return imageWidget;
  }

  Widget _buildErrorWidget(
    BuildContext context,
    String message, {
    String? subtitle,
  }) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            message.contains('not found')
                ? Icons.image_not_supported_outlined
                : Icons.broken_image_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
