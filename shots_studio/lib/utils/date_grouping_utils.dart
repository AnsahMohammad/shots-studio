import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shots_studio/models/screenshot_model.dart';

/// Utility class for grouping screenshots by date.
class DateGroupingUtils {
  /// Groups screenshots by their `addedOn` date (day-level granularity).
  /// Returns a [LinkedHashMap] sorted in descending order (newest first).
  static LinkedHashMap<DateTime, List<Screenshot>> groupByDate(
    List<Screenshot> screenshots,
  ) {
    final groups = <DateTime, List<Screenshot>>{};

    for (final screenshot in screenshots) {
      final dateKey = DateTime(
        screenshot.addedOn.year,
        screenshot.addedOn.month,
        screenshot.addedOn.day,
      );
      groups.putIfAbsent(dateKey, () => []).add(screenshot);
    }

    // Sort keys descending (newest first)
    final sortedKeys = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    final sorted = LinkedHashMap<DateTime, List<Screenshot>>();
    for (final key in sortedKeys) {
      sorted[key] = groups[key]!;
    }
    return sorted;
  }

  /// Formats a date key into a human-readable header string.
  /// Returns "Today", "Yesterday", or "MMM d, yyyy" (e.g. "Feb 12, 2026").
  static String formatDateHeader(DateTime date, BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) {
      return 'Today';
    } else if (date == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }
}
