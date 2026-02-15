import 'package:flutter/material.dart';
import 'link_chip.dart';

/// A collapsible section that shows a limited number of link chips
/// with a "Show more" / "Show less" toggle when there are many links.
class CollapsibleLinksSection extends StatefulWidget {
  final List<String> links;
  final BuildContext parentContext;
  final int initialVisibleCount;

  const CollapsibleLinksSection({
    super.key,
    required this.links,
    required this.parentContext,
    this.initialVisibleCount = 3,
  });

  @override
  State<CollapsibleLinksSection> createState() =>
      _CollapsibleLinksSectionState();
}

class _CollapsibleLinksSectionState extends State<CollapsibleLinksSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final hasMore = widget.links.length > widget.initialVisibleCount;
    final visibleLinks =
        _isExpanded
            ? widget.links
            : widget.links.take(widget.initialVisibleCount).toList();
    final hiddenCount = widget.links.length - widget.initialVisibleCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              visibleLinks
                  .map(
                    (link) => LinkChip(
                      link: link,
                      parentContext: widget.parentContext,
                    ),
                  )
                  .toList(),
        ),
        if (hasMore) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  _isExpanded ? 'Show less' : 'Show $hiddenCount more',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
