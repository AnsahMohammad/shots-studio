import 'package:flutter/material.dart';
import 'package:shots_studio/models/screenshot_model.dart';

class PrefilterStatusSection extends StatelessWidget {
  final Screenshot screenshot;
  final VoidCallback onAllow;
  final VoidCallback onMarkSensitive;

  const PrefilterStatusSection({
    super.key, required this.screenshot,
    required this.onAllow, required this.onMarkSensitive,
  });

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final status = screenshot.prefilterStatus;
    if (status == null) return const SizedBox.shrink(); // mode is 'none'

    final isBlocked = status == 'blocked';
    final isAllowed = status == 'allowed';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isBlocked
            ? theme.colorScheme.errorContainer.withOpacity(0.6)
            : isAllowed
                ? theme.colorScheme.tertiaryContainer.withOpacity(0.5)
                : theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isBlocked
              ? theme.colorScheme.error.withOpacity(0.3)
              : theme.colorScheme.outline.withOpacity(0.15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          Row(children: [
            Icon(
              isBlocked ? Icons.warning_rounded : isAllowed ? Icons.lock_open_outlined : Icons.shield_outlined,
              size: 18,
              color: isBlocked ? theme.colorScheme.error
                  : isAllowed  ? theme.colorScheme.tertiary
                               : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 7),
            Text('Privacy', style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700,
                letterSpacing: 0.5, color: theme.colorScheme.onSurfaceVariant)),
          ]),
          const SizedBox(height: 6),

          Text(
            isBlocked
                ? (screenshot.prefilterReason ?? 'Sensitive content detected')
                : isAllowed
                    ? 'Allowed by you — will be sent to AI'
                    : 'No sensitive content found',
            style: TextStyle(
              fontSize: 13,
              color: isBlocked
                  ? theme.colorScheme.onErrorContainer
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),

          if (isBlocked)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.lock_open_outlined, size: 14),
                label: const Text('Allow anyway'),
                onPressed: onAllow,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.shield_outlined, size: 14),
                label: const Text('Mark as sensitive'),
                onPressed: onMarkSensitive,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurfaceVariant,
                  side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}
