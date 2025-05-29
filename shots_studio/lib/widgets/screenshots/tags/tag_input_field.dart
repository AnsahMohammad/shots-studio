import 'package:flutter/material.dart';

class TagInputField extends StatefulWidget {
  final Function(String) onTagAdded;

  const TagInputField({super.key, required this.onTagAdded});

  @override
  State<TagInputField> createState() => _TagInputFieldState();
}

class _TagInputFieldState extends State<TagInputField> {
  final TextEditingController _controller = TextEditingController();
  bool _isEditing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submitTag() {
    final tag = _controller.text.trim();
    if (tag.isNotEmpty) {
      widget.onTagAdded(tag);
      _controller.clear();
    }
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEditing) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(80),
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          onTap: () => setState(() => _isEditing = true),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add,
                size: 16,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
              SizedBox(width: 4),
              Text(
                'Add Tag',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: TextField(
              controller: _controller,
              autofocus: true,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                isDense: true,
              ),
              onSubmitted: (_) => _submitTag(),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.check,
              size: 16,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: _submitTag,
          ),
        ],
      ),
    );
  }
}
