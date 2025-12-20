import 'package:flutter/material.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';
import 'package:shots_studio/widgets/ai_settings/model_card.dart';

/// Shows a dialog guide for selecting the right AI model.
class ModelSelectionGuideDialog {
  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'How to choose the right model ?',
                  softWrap: true,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose the right AI model based on your needs:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Gemini 2.0 Flash
                  const ModelCard(
                    modelName: 'Gemini 2.0 Flash',
                    description: '2.0 model, least expensive',
                    icon: Icons.flash_on,
                    iconColor: Colors.yellow,
                    useCases: [
                      'Basic screenshot analysis',
                      'Limited daily processing',
                      'Cost-conscious users',
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Gemini 2.5 Flash Lite
                  const ModelCard(
                    modelName: 'Gemini 2.5 Flash Lite',
                    description: 'Better than 2.0 and cost effective',
                    icon: Icons.flash_auto,
                    iconColor: Colors.orange,
                    useCases: [
                      'Lots of images without hitting free quota',
                      'Good balance of quality and cost',
                      'Regular daily usage',
                    ],
                    recommended: true,
                  ),
                  const SizedBox(height: 12),

                  // Gemini 2.5 Flash
                  const ModelCard(
                    modelName: 'Gemini 2.5 Flash',
                    description: 'High quality analysis with fast processing',
                    icon: Icons.flash_on,
                    iconColor: Colors.blue,
                    useCases: [
                      'High volume processing',
                      'Better accuracy for complex screenshots',
                      'Professional use cases',
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Gemini 2.5 Pro
                  const ModelCard(
                    modelName: 'Gemini 2.5 Pro',
                    description: 'Premium model with highest accuracy',
                    icon: Icons.star,
                    iconColor: Colors.purple,
                    useCases: [
                      'Maximum accuracy needed',
                      'Complex screenshot analysis',
                      'Professional/enterprise use',
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Gemma (Local)
                  const ModelCard(
                    modelName: 'Gemma (Local)',
                    description: 'Offline processing, completely private',
                    icon: Icons.security,
                    iconColor: Colors.green,
                    useCases: [
                      'Complete privacy (no data sent online)',
                      'Works without internet connection',
                      'Takes more time to process',
                      'No API costs',
                    ],
                    isLocal: true,
                  ),

                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(
                        0.3,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You can change models anytime in the main settings.',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );

    // Track analytics for model guide usage
    AnalyticsService().logFeatureUsed('model_selection_guide_viewed');
  }
}
