import 'package:flutter/material.dart';
import 'package:shots_studio/models/screenshot_model.dart';

class PrefilterBadge extends StatelessWidget {
  final Screenshot screenshot;
  const PrefilterBadge({super.key, required this.screenshot});

  @override
  Widget build(BuildContext context) {
    if (screenshot.prefilterStatus != 'blocked') return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.amber, // Warning color
        borderRadius: const BorderRadius.only(
          bottomRight: Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      child: const Icon(
        Icons.warning_rounded,
        color: Colors.black87, // Better contrast on yellow
        size: 18,
      ),
    );
  }
}
