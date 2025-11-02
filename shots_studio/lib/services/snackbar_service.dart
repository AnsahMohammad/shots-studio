import 'package:flutter/material.dart';

class SnackbarService {
  static final SnackbarService _instance = SnackbarService._internal();
  factory SnackbarService() => _instance;
  SnackbarService._internal();

  DateTime? _lastSnackbarTime;
  String? _lastSnackbarMessage;
  final Duration _snackbarCooldown = const Duration(seconds: 2);

  /// Shows a modern, capsule-shaped snackbar with cooldown functionality
  ///
  /// [context] - The BuildContext to show the snackbar in
  /// [message] - The message to display
  /// [backgroundColor] - Optional background color
  /// [duration] - Optional duration, defaults to 3 seconds
  /// [icon] - Optional icon to display
  /// [forceShow] - If true, bypasses cooldown (use sparingly)

  void showSnackbar(
    BuildContext context, {
    required String message,
    Color? backgroundColor,
    Duration? duration,
    IconData? icon,
    bool forceShow = false,
  }) {
    if (!context.mounted) return;

    final now = DateTime.now();

    if (!forceShow &&
        _lastSnackbarTime != null &&
        _lastSnackbarMessage == message &&
        now.difference(_lastSnackbarTime!) < _snackbarCooldown) {
      // Cooldown active for the same message, do not show snackbar
      debugPrint('Snackbar cooldown: Skipping "$message"');
      return;
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Use surface container for default background with elevation tint
    final bgColor = backgroundColor ?? colorScheme.inverseSurface;
    final textColor =
        backgroundColor != null
            ? _getContrastingColor(backgroundColor)
            : colorScheme.onInverseSurface;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 12),
            ],
            Flexible(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        duration: duration ?? const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        elevation: 3,
        dismissDirection: DismissDirection.horizontal,
      ),
    );

    _lastSnackbarTime = now;
    _lastSnackbarMessage = message;
  }

  /// Helper to determine contrasting text color
  Color _getContrastingColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  void showError(
    BuildContext context,
    String message, {
    bool forceShow = false,
  }) {
    final theme = Theme.of(context);
    showSnackbar(
      context,
      message: message,
      backgroundColor: theme.colorScheme.errorContainer,
      icon: Icons.error_outline_rounded,
      forceShow: forceShow,
    );
  }

  void showSuccess(
    BuildContext context,
    String message, {
    bool forceShow = false,
  }) {
    final theme = Theme.of(context);
    showSnackbar(
      context,
      message: message,
      backgroundColor: theme.colorScheme.primaryContainer,
      icon: Icons.check_circle_outline_rounded,
      forceShow: forceShow,
    );
  }

  void showWarning(
    BuildContext context,
    String message, {
    bool forceShow = false,
  }) {
    final theme = Theme.of(context);
    showSnackbar(
      context,
      message: message,
      backgroundColor: theme.colorScheme.tertiaryContainer,
      icon: Icons.warning_amber_rounded,
      forceShow: forceShow,
    );
  }

  void showInfo(
    BuildContext context,
    String message, {
    bool forceShow = false,
  }) {
    final theme = Theme.of(context);
    showSnackbar(
      context,
      message: message,
      backgroundColor: theme.colorScheme.secondaryContainer,
      icon: Icons.info_outline_rounded,
      forceShow: forceShow,
    );
  }

  void clearCooldown() {
    _lastSnackbarTime = null;
    _lastSnackbarMessage = null;
  }
}
