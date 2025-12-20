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

                  // Gemini Models
                  const ModelCard(
                    modelName: 'Gemini (Cloud)',
                    description: 'Fast, accurate, requires API key',
                    icon: Icons.cloud,
                    iconColor: Colors.blue,
                    useCases: [
                      '2.0 Flash - Basic, least expensive',
                      '2.5 Flash Lite - Best balance (recommended)',
                      '2.5 Flash - High quality, fast',
                      '2.5 Pro - Maximum accuracy',
                    ],
                    recommended: true,
                  ),
                  const SizedBox(height: 12),

                  // Gemma (Local)
                  const ModelCard(
                    modelName: 'Gemma (Local)',
                    description: 'Offline, private, no API costs',
                    icon: Icons.security,
                    iconColor: Colors.green,
                    useCases: [
                      'Complete privacy (no data sent online)',
                      'Works without internet',
                      'Slower processing',
                    ],
                    isLocal: true,
                  ),
                  const SizedBox(height: 12),

                  // OCR (Tesseract)
                  const ModelCard(
                    modelName: 'OCR (Tesseract)',
                    description: 'Text extraction only, no AI analysis',
                    icon: Icons.text_fields,
                    iconColor: Colors.teal,
                    useCases: [
                      'Extracts visible text from screenshots',
                      'Sets text as description only',
                      'No auto-categorization support',
                      'Offline, fast, no API needed',
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
