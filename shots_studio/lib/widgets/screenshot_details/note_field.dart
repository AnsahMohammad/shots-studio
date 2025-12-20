import 'package:flutter/material.dart';

/// An expandable text field for editing personal notes.
/// Features auto-expanding height based on content.
class NoteField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enhancedAnimationsEnabled;
  final ValueChanged<String> onChanged;
  final VoidCallback onEditingComplete;

  const NoteField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.enhancedAnimationsEnabled,
    required this.onChanged,
    required this.onEditingComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: enhancedAnimationsEnabled
              ? const Duration(milliseconds: 300)
              : const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              floatingLabelBehavior: FloatingLabelBehavior.always,
              hintText: 'Add a note...',
              filled: true,
              fillColor: Theme.of(context).colorScheme.outlineVariant,
              suffixIcon: Icon(
                Icons.edit,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
              fontSize: 14,
            ),
            maxLines: null, // Auto-expand based on content
            minLines: 1,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            onChanged: onChanged,
            onEditingComplete: onEditingComplete,
          ),
        ),
      ],
    );
  }
}
