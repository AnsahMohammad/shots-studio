import 'package:flutter/material.dart';
import 'package:shots_studio/utils/ai_provider_config.dart';

/// A card for toggling an AI provider on/off.
class ProviderToggleCard extends StatelessWidget {
  final String provider;
  final bool isEnabled;
  final bool canToggle;
  final bool forceDisabled;
  final String? disabledReason;
  final Function(String, bool) onToggle;

  const ProviderToggleCard({
    super.key,
    required this.provider,
    required this.isEnabled,
    required this.onToggle,
    this.canToggle = true,
    this.forceDisabled = false,
    this.disabledReason,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final models = AIProviderConfig.getModelsForProvider(provider);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.toUpperCase(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color:
                          forceDisabled
                              ? theme.colorScheme.onSurfaceVariant.withOpacity(
                                0.6,
                              )
                              : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    disabledReason ?? models.join(', '),
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          forceDisabled
                              ? theme.colorScheme.error.withOpacity(0.7)
                              : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: forceDisabled ? false : isEnabled,
              onChanged:
                  canToggle ? (value) => onToggle(provider, value) : null,
              activeThumbColor: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
