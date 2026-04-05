import 'package:flutter/material.dart';
import 'link_utils.dart';

/// A clickable chip that displays a link with appropriate icon.
/// Automatically detects link type (URL, email, phone) and styles accordingly.
class LinkChip extends StatelessWidget {
  final String link;
  final BuildContext parentContext;

  const LinkChip({super.key, required this.link, required this.parentContext});

  @override
  Widget build(BuildContext context) {
    final linkInfo = LinkUtils.getLinkInfo(
      context,
      link,
      (url) {
        LinkUtils.launchLink(parentContext, url);
      },
      (text) {
        LinkUtils.copyToClipboard(parentContext, text);
      },
    );
    final displayText = LinkUtils.getDisplayText(link);

    return GestureDetector(
      onTap: linkInfo['action'],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: linkInfo['color'].withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(linkInfo['icon'], size: 16, color: linkInfo['color']),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                displayText,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
