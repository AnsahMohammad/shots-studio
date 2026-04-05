import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/analytics/analytics_service.dart';

class SponsorshipDialog extends StatelessWidget {
  const SponsorshipDialog({super.key});

  static const String _githubProfileUrl = 'https://github.com/AnsahMohammad/';
  static const String _githubRepoUrl =
      'https://github.com/AnsahMohammad/shots-studio';
  static const String _githubIssuesUrl =
      'https://github.com/AnsahMohammad/shots-studio/issues';

  Future<void> _launchURL(String urlString) async {
    AnalyticsService().logFeatureUsed('support_url_clicked');
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog.fullscreen(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              isDark
                  ? theme.colorScheme.surface.withValues(alpha: 0.8)
                  : theme.colorScheme.primary.withValues(alpha: 0.02),
            ],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(
                Icons.close_rounded,
                color: theme.colorScheme.onSurface,
              ),
              onPressed: () {
                AnalyticsService().logFeatureUsed('support_dialog_closed');
                Navigator.pop(context);
              },
            ),
            title: Text(
              'Support the Project',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            centerTitle: false,
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero section
                _buildHeroSection(context, theme),

                const SizedBox(height: 12),

                // "How you can help" section header
                _buildSectionHeader(context, theme, 'Ways to Support'),

                const SizedBox(height: 16),

                // Support cards
                _buildSupportCard(
                  context,
                  theme: theme,
                  icon: Icons.star_rounded,
                  iconColor: theme.colorScheme.tertiary.withValues(alpha: 0.5),
                  title: 'Star us on GitHub',
                  subtitle:
                      'Help us reach more developers by giving the repo a ⭐',
                  onTap: () {
                    AnalyticsService().logFeatureUsed('support_star_github');
                    Navigator.pop(context);
                    _launchURL(_githubRepoUrl);
                  },
                ),

                _buildSupportCard(
                  context,
                  theme: theme,
                  icon: Icons.share_rounded,
                  iconColor: theme.colorScheme.secondary.withValues(alpha: 0.5),
                  title: 'Spread the Word',
                  subtitle:
                      'Share Shots Studio with your peers or on social media',
                  onTap: null, // No URL needed, just informational
                ),

                _buildSupportCard(
                  context,
                  theme: theme,
                  icon: Icons.code_rounded,
                  iconColor: theme.colorScheme.tertiary.withValues(alpha: 0.5),
                  title: 'Contribute',
                  subtitle:
                      'Found a bug? Have a feature idea? Open an issue or submit a Pull Request on GitHub',
                  onTap: () {
                    AnalyticsService().logFeatureUsed('support_contribute');
                    Navigator.pop(context);
                    _launchURL(_githubIssuesUrl);
                  },
                ),

                _buildSupportCard(
                  context,
                  theme: theme,
                  icon: Icons.feedback_rounded,
                  iconColor: theme.colorScheme.secondary.withValues(alpha: 0.5),
                  title: 'Feedback',
                  subtitle:
                      'Tell us how you use the app! Your insights help shape the future of the tool',
                  onTap: () {
                    AnalyticsService().logFeatureUsed('support_feedback');
                    Navigator.pop(context);
                    _launchURL(_githubIssuesUrl);
                  },
                ),

                // Footer
                const SizedBox(height: 32),
                _buildFooter(context, theme, isDark),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          children: [
            // Heart icon with glow
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Icon(
                Icons.favorite_rounded,
                color: theme.colorScheme.onPrimary,
                size: 32,
              ),
            ),
            const SizedBox(height: 24),

            // "Made with love" text with clickable author
            Column(
              children: [
                Text(
                  'Shots Studio is a free and open-source project created and maintained by',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    height: 1.6,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _launchURL(_githubProfileUrl),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_rounded,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ansahk',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    ThemeData theme,
    String title,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard(
    BuildContext context, {
    required ThemeData theme,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Card(
        elevation: 0,
        color:
            theme.brightness == Brightness.dark
                ? theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.8)
                : theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: iconColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(icon, color: iconColor, size: 28),
                  ),
                  const SizedBox(width: 20),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Arrow (only for tappable cards)
                  if (onTap != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.open_in_new_rounded,
            color: theme.colorScheme.primary,
            size: 28,
          ),
          const SizedBox(height: 12),
          Text(
            'Visit us on GitHub',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Explore the source code, report issues, or contribute to the project.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: () {
              AnalyticsService().logFeatureUsed('support_github_repo');
              _launchURL(_githubRepoUrl);
            },
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.open_in_new_rounded, size: 18),
                SizedBox(width: 8),
                Text('Open on GitHub'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
