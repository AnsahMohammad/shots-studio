import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsSection extends StatefulWidget {
  final String? currentApiKey;
  final String currentModelName;
  final Function(String) onApiKeyChanged;
  final Function(String) onModelChanged;

  const SettingsSection({
    super.key,
    this.currentApiKey,
    required this.currentModelName,
    required this.onApiKeyChanged,
    required this.onModelChanged,
  });

  @override
  State<SettingsSection> createState() => _SettingsSectionState();
}

class _SettingsSectionState extends State<SettingsSection> {
  late TextEditingController _apiKeyController;
  late String _selectedModelName;

  static const String _apiKeyPrefKey = 'apiKey';
  static const String _modelNamePrefKey = 'modelName';

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(text: widget.currentApiKey ?? '');
    _selectedModelName = widget.currentModelName;
  }

  @override
  void didUpdateWidget(covariant SettingsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentApiKey != oldWidget.currentApiKey) {
      if (_apiKeyController.text != (widget.currentApiKey ?? '')) {
        _apiKeyController.text = widget.currentApiKey ?? '';
        // Ensure the cursor is at the end of the text after programmatically changing it.
        _apiKeyController.selection = TextSelection.fromPosition(
          TextPosition(offset: _apiKeyController.text.length),
        );
      }
    }
    if (widget.currentModelName != oldWidget.currentModelName) {
      if (_selectedModelName != widget.currentModelName) {
        _selectedModelName = widget.currentModelName;
      }
    }
  }

  Future<void> _saveApiKey(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPrefKey, value);
  }

  Future<void> _saveModelName(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modelNamePrefKey, value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Settings',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          leading: Icon(
            Icons.auto_awesome_outlined,
            color: theme.colorScheme.primary,
          ),
          title: Text(
            'AI Model',
            style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
          ),
          trailing: DropdownButton<String>(
            value: _selectedModelName,
            dropdownColor: theme.colorScheme.secondaryContainer,
            icon: Icon(
              Icons.arrow_drop_down,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
            underline: SizedBox.shrink(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedModelName = newValue;
                });
                widget.onModelChanged(newValue);
                _saveModelName(newValue);
              }
            },
            items:
                <String>[
                  'gemini-2.0-flash',
                  'gemini-2.5-flash-pro',
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
        ListTile(
          leading: Icon(
            Icons.vpn_key_outlined,
            color: theme.colorScheme.primary,
          ),
          title: TextFormField(
            controller: _apiKeyController,
            style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
            decoration: InputDecoration(
              hintText: 'API Key',
              hintStyle: TextStyle(
                color: theme.colorScheme.onSecondaryContainer,
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: theme.colorScheme.outline),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: theme.colorScheme.primary),
              ),
            ),
            obscureText: true,
            onChanged: (value) {
              widget.onApiKeyChanged(value);
              _saveApiKey(value);
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }
}
