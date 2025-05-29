import 'package:flutter/material.dart';

class SnackbarService {
  static final SnackbarService _instance = SnackbarService._internal();
  factory SnackbarService() => _instance;
  SnackbarService._internal();

  DateTime? _lastSnackbarTime;
  String? _lastSnackbarMessage;
  final Duration _snackbarCooldown = const Duration(seconds: 2);

  /// Shows a snackbar with cooldown functionality to prevent spam
  ///
  /// [context] - The BuildContext to show the snackbar in
  /// [message] - The message to display
  /// [backgroundColor] - Optional background color
  /// [duration] - Optional duration, defaults to 2 seconds
  /// [forceShow] - If true, bypasses cooldown (use sparingly)

  void showSnackbar(
    BuildContext context, {
    required String message,
    Color? backgroundColor,
    Duration? duration,
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration ?? const Duration(seconds: 2),
      ),
    );

    _lastSnackbarTime = now;
    _lastSnackbarMessage = message;
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
      backgroundColor: theme.colorScheme.error,
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
      backgroundColor: theme.colorScheme.primary,
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
      backgroundColor: theme.colorScheme.tertiary,
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
      backgroundColor: theme.colorScheme.secondary,
      forceShow: forceShow,
    );
  }

  void clearCooldown() {
    _lastSnackbarTime = null;
    _lastSnackbarMessage = null;
  }
}
