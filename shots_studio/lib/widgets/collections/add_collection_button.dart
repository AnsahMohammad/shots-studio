import 'package:flutter/material.dart';

class AddCollectionButton extends StatefulWidget {
  final VoidCallback onTap;

  const AddCollectionButton({super.key, required this.onTap});

  @override
  State<AddCollectionButton> createState() => _AddCollectionButtonState();
}

class _AddCollectionButtonState extends State<AddCollectionButton> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: Card(
        child: Material(
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color:
                    isHovered
                        ? Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.8)
                        : Theme.of(context).colorScheme.primary,
              ),
              child: Icon(
                Icons.add,
                size: isHovered ? 38 : 32,
                color: Theme.of(
                  context,
                ).colorScheme.onPrimary.withValues(alpha: isHovered ? 0.8 : 1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
