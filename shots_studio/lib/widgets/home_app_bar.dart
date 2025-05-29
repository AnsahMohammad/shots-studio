import 'package:flutter/material.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onProcessWithAI;
  final bool isProcessingAI;
  final int aiProcessedCount;
  final int aiTotalToProcess;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onStopProcessingAI;

  const HomeAppBar({
    super.key,
    this.onProcessWithAI,
    this.isProcessingAI = false,
    this.aiProcessedCount = 0,
    this.aiTotalToProcess = 0,
    this.onSearchPressed,
    this.onStopProcessingAI,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text(
        'Shots Studio',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
      ),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: 'Search Screenshots',
          onPressed: onSearchPressed,
        ),
        if (isProcessingAI)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Center(
              child: Text(
                'Analyzed $aiProcessedCount/$aiTotalToProcess',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        if (isProcessingAI)
          IconButton(
            icon: const Icon(Icons.stop_circle_outlined),
            tooltip: 'Stop Processing',
            onPressed: onStopProcessingAI,
          )
        else if (onProcessWithAI != null)
          IconButton(
            icon: const Icon(Icons.auto_awesome_outlined),
            tooltip: 'Process with AI',
            onPressed: onProcessWithAI,
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
