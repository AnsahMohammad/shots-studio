import 'package:flutter/material.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';
import 'package:shots_studio/services/snackbar_service.dart';
import 'package:shots_studio/utils/reminder_utils.dart';
import 'toolbar_button.dart';

/// A floating action toolbar with share, reminder, OCR, delete, and collection buttons.
/// Animated with a bouncy scale effect on entrance.
class FloatingToolbar extends StatelessWidget {
  final Animation<double> scaleAnimation;
  final Screenshot screenshot;
  final bool isProcessingOCR;
  final VoidCallback onShare;
  final VoidCallback onReminderPressed;
  final VoidCallback? onOCRPressed;
  final VoidCallback onDeletePressed;
  final VoidCallback onAddToCollectionPressed;

  const FloatingToolbar({
    super.key,
    required this.scaleAnimation,
    required this.screenshot,
    required this.isProcessingOCR,
    required this.onShare,
    required this.onReminderPressed,
    required this.onOCRPressed,
    required this.onDeletePressed,
    required this.onAddToCollectionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scaleAnimation.value,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Main action buttons container
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 12),
                  ToolbarButton(
                    icon: Icons.share_outlined,
                    tooltip: 'Share',
                    onPressed: onShare,
                  ),
                  ToolbarButton(
                    icon: screenshot.reminderTime != null
                        ? Icons.alarm
                        : Icons.alarm_outlined,
                    tooltip: 'Set reminder',
                    isHighlighted: screenshot.reminderTime != null,
                    onPressed: onReminderPressed,
                  ),
                  ToolbarButton(
                    icon: Icons.text_fields_outlined,
                    tooltip: 'Extract text with OCR',
                    onPressed: isProcessingOCR ? null : onOCRPressed,
                  ),
                  ToolbarButton(
                    icon: Icons.delete_outline,
                    tooltip: 'Delete',
                    onPressed: onDeletePressed,
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Add to collection button - separate rounded square
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: onAddToCollectionPressed,
                  child: Icon(
                    Icons.add_rounded,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
