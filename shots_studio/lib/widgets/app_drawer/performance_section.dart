import 'package:flutter/material.dart';
import 'package:shots_studio/screens/performance_monitor_screen.dart';

class PerformanceSection extends StatelessWidget {
  const PerformanceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: theme.colorScheme.outline),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Performance',
            style: TextStyle(
              color: theme.colorScheme.onSecondaryContainer,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
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
            Icons.info_outline,
            color: theme.colorScheme.onSecondaryContainer,
            size: 16,
          ),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PerformanceMonitor(),
              ),
            );
          },
        ),
      ],
    );
  }
}
