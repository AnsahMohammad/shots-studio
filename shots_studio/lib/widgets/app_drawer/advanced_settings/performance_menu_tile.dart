import 'package:flutter/material.dart';
import 'package:shots_studio/screens/performance_monitor_screen.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';

/// A tile that navigates to the Performance Monitor screen.
class PerformanceMenuTile extends StatelessWidget {
  const PerformanceMenuTile({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(Icons.speed, color: theme.colorScheme.primary),
      title: Text(
        'Performance Menu',
        style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
      ),
      subtitle: Text(
        'Lower limits improve performance with many screenshots',
        style: TextStyle(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 12,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.colorScheme.onSecondaryContainer,
      ),
      onTap: () {
        // Log analytics for performance section access
        AnalyticsService().logFeatureUsed('performance_menu_accessed');
        AnalyticsService().logScreenView('performance_monitor_screen');

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PerformanceMonitor()),
        );
      },
    );
  }
}
