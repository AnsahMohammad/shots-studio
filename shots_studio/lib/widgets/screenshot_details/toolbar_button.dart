import 'package:flutter/material.dart';

/// A reusable toolbar button widget for the floating toolbar.
/// Displays an icon with tooltip and optional highlight state.
class ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool isHighlighted;

  const ToolbarButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        height: 44,
        width: 44,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isHighlighted
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onPressed,
            child: Icon(
              icon,
              size: 22,
              color: isHighlighted
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : (onPressed == null
                      ? Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.4)
                      : Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        ),
      ),
    );
  }
}
