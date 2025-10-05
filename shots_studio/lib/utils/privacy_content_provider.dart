import 'package:flutter/material.dart';

/// A utility class that provides standardized privacy policy content
/// to be used consistently across different parts of the application.
class PrivacyContentProvider {
  /// Returns common privacy policy information as a list of widgets
  static List<Widget> getPrivacyContent(
    BuildContext context, {
    required Function(BuildContext, String) launchUrlCallback,
  }) {
    final theme = Theme.of(context);

    return [
      // Header
      Text(
        "Privacy Policy & Data Processing Information",
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 16),

      // Introduction Paragraph
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome to Shots Studio",
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "At Shots Studio, we believe your privacy is fundamental. This privacy policy explains how we handle your data, what information we collect (if any), and how we protect your personal information. We've designed our app with privacy-first principles, ensuring that your screenshots and personal data remain under your control.",
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Please take a moment to read through this information to understand how Shots Studio respects and protects your privacy.",
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),

      // AI Processing Options
      Text(
        "Image Processing Options",
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        "Shots Studio offers two distinct AI processing methods for processing your images, each with different privacy implications:",
        style: TextStyle(
          color: theme.colorScheme.onSurfaceVariant,
          height: 1.4,
        ),
      ),
      const SizedBox(height: 12),

      // Local AI Section
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "Local AI Processing (Gemma)",
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "• Processes all data entirely on your device\n"
              "• No internet connection required for AI features\n"
              "• Your images and data never leave your device\n"
              "• Complete privacy and data sovereignty",
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),

      // Cloud AI Section
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cloud_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "Cloud AI Processing (Google Gemini)",
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "• Optional feature requiring your personal Google Gemini API key\n"
              "• Images are transmitted to Google's servers for processing\n"
              "• Subject to Google's data handling practices\n"
              "• Only activated when you explicitly configure and enable it",
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // Data Collection Section
      Text(
        "Data Collection & Storage Practices",
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 8),

      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "What We DO NOT Collect:",
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "• Personal identification information\n"
              "• Your original screenshots or images\n"
              "• Device-specific identifiers\n"
              "• Location data or browsing history",
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "What We MAY Collect (Optional & Anonymous):",
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "• Anonymous usage patterns and feature interactions\n"
              "• Performance metrics and crash reports\n"
              "• General app usage statistics for improvement purposes\n"
              "• No personally identifiable information is ever collected",
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // Third Party Services
      Text(
        "Third-Party Service Integration",
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        "When using cloud AI features, your data may be processed by:",
        style: TextStyle(
          color: theme.colorScheme.onSurfaceVariant,
          height: 1.4,
        ),
      ),
      const SizedBox(height: 8),

      InkWell(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.open_in_new,
                color: theme.colorScheme.primary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                "Google Privacy Policy",
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        onTap:
            () => launchUrlCallback(
              context,
              'https://policies.google.com/privacy',
            ),
      ),
      const SizedBox(height: 8),

      InkWell(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.open_in_new,
                color: theme.colorScheme.primary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                "Google Gemini API Terms",
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        onTap: () => launchUrlCallback(context, 'https://ai.google.dev/terms'),
      ),
      const SizedBox(height: 16),

      // Complete Privacy Policy Link
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.primary),
          borderRadius: BorderRadius.circular(8),
          color: theme.colorScheme.primaryContainer.withOpacity(0.1),
        ),
        child: InkWell(
          child: Row(
            children: [
              Icon(
                Icons.policy_outlined,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Complete Privacy Policy",
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "View our comprehensive privacy policy for detailed information",
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: theme.colorScheme.primary,
                size: 16,
              ),
            ],
          ),
          onTap:
              () => launchUrlCallback(
                context,
                'https://ansahmohammad.github.io/shots-studio/privacy.html',
              ),
        ),
      ),
      const SizedBox(height: 16),
    ];
  }
}
