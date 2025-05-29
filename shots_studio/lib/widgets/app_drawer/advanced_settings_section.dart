import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdvancedSettingsSection extends StatefulWidget {
  final int currentLimit;
  final Function(int) onLimitChanged;
  final int currentMaxParallel;
  final Function(int) onMaxParallelChanged;

  const AdvancedSettingsSection({
    super.key,
    required this.currentLimit,
    required this.onLimitChanged,
    required this.currentMaxParallel,
    required this.onMaxParallelChanged,
  });

  @override
  State<AdvancedSettingsSection> createState() =>
      _AdvancedSettingsSectionState();
}

class _AdvancedSettingsSectionState extends State<AdvancedSettingsSection> {
  late TextEditingController _limitController;
  late TextEditingController _maxParallelController;

  static const String _limitPrefKey = 'limit';
  static const String _maxParallelPrefKey = 'maxParallel';

  @override
  void initState() {
    super.initState();
    _limitController = TextEditingController(
      text: widget.currentLimit.toString(),
    );
    _maxParallelController = TextEditingController(
      text: widget.currentMaxParallel.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant AdvancedSettingsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentLimit != oldWidget.currentLimit) {
      if (_limitController.text != widget.currentLimit.toString()) {
        _limitController.text = widget.currentLimit.toString();
        _limitController.selection = TextSelection.fromPosition(
          TextPosition(offset: _limitController.text.length),
        );
      }
    }
    if (widget.currentMaxParallel != oldWidget.currentMaxParallel) {
      if (_maxParallelController.text != widget.currentMaxParallel.toString()) {
        _maxParallelController.text = widget.currentMaxParallel.toString();
        _maxParallelController.selection = TextSelection.fromPosition(
          TextPosition(offset: _maxParallelController.text.length),
        );
      }
    }
  }

  Future<void> _saveLimit(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_limitPrefKey, value);
  }

  Future<void> _saveMaxParallel(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_maxParallelPrefKey, value);
  }

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
            'Advanced Settings',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          leading: Icon(Icons.filter_list, color: theme.colorScheme.primary),
          title: Text(
            'Screenshot Limit',
            style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
          ),
          subtitle: TextFormField(
            controller: _limitController,
            style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
            decoration: InputDecoration(
              hintText: 'e.g., 50',
              hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: theme.colorScheme.outline),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: theme.colorScheme.primary),
              ),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final intValue = int.tryParse(value);
              if (intValue != null) {
                widget.onLimitChanged(intValue);
                _saveLimit(intValue);
              }
            },
          ),
        ),
        ListTile(
          leading: Icon(Icons.sync_alt, color: theme.colorScheme.primary),
          title: Text(
            'Max Parallel AI Processes',
            style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
          ),
          subtitle: TextFormField(
            controller: _maxParallelController,
            style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
            decoration: InputDecoration(
              hintText: 'e.g., 4',
              hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: theme.colorScheme.outline),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: theme.colorScheme.primary),
              ),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final intValue = int.tryParse(value);
              if (intValue != null) {
                widget.onMaxParallelChanged(intValue);
                _saveMaxParallel(intValue);
              }
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _limitController.dispose();
    _maxParallelController.dispose();
    super.dispose();
  }
}
