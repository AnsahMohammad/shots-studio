import 'package:flutter/material.dart';
import 'package:shots_studio/l10n/app_localizations.dart';

/// An expandable text field for editing screenshot descriptions.
/// Features a gradient overlay and expand/collapse controls when text overflows.
class DescriptionField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isExpanded;
  final bool enhancedAnimationsEnabled;
  final VoidCallback onExpand;
  final VoidCallback onCollapse;
  final ValueChanged<String> onChanged;
  final VoidCallback onEditingComplete;

  const DescriptionField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isExpanded,
    required this.enhancedAnimationsEnabled,
    required this.onExpand,
    required this.onCollapse,
    required this.onChanged,
    required this.onEditingComplete,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.trim().isNotEmpty;
    final textSpan = TextSpan(
      text: controller.text,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSecondaryContainer,
        fontSize: 16,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      maxLines: 4,
      textDirection: Directionality.of(context),
    );

    textPainter.layout(maxWidth: MediaQuery.of(context).size.width - 64);
    final isOverflowing = textPainter.didExceedMaxLines;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: enhancedAnimationsEnabled
              ? const Duration(milliseconds: 500)
              : const Duration(milliseconds: 200),
          curve: enhancedAnimationsEnabled ? Curves.easeOutBack : Curves.easeInOut,
          child: Stack(
            children: [
              TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText:
                      AppLocalizations.of(context)?.addDescription ??
                      'Add a description...',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.secondaryContainer,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                  fontSize: 16,
                ),
                maxLines: isExpanded ? null : 4,
                onChanged: onChanged,
                onEditingComplete: onEditingComplete,
              ),
              // Gradient overlay and expand button
              if (hasText && isOverflowing && !isExpanded)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    ignoring: false,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Theme.of(context)
                                .colorScheme
                                .secondaryContainer
                                .withValues(alpha: 0.0),
                            Theme.of(context)
                                .colorScheme
                                .secondaryContainer
                                .withValues(alpha: 0.7),
                            Theme.of(context).colorScheme.secondaryContainer,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onExpand,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Read more',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 20,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Collapse button when expanded
        if (isExpanded && isOverflowing)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: TextButton.icon(
                onPressed: onCollapse,
                icon: Icon(
                  Icons.keyboard_arrow_up_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                label: Text(
                  'Show less',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
