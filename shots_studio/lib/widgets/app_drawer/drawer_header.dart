import 'package:flutter/material.dart';
import 'dart:math';
import '../../utils/splash_texts.dart';

import '../../services/analytics/analytics_service.dart';
import '../sponsorship/sponsorship_dialog.dart';

class AppDrawerHeader extends StatefulWidget {
  const AppDrawerHeader({super.key});

  @override
  State<AppDrawerHeader> createState() => _AppDrawerHeaderState();
}

class _AppDrawerHeaderState extends State<AppDrawerHeader>
    with TickerProviderStateMixin {
  late AnimationController _heartbeatController;
  late AnimationController _pulseController;
  late Animation<double> _heartbeatAnimation;
  late Animation<double> _pulseAnimation;

  int _currentTextIndex = 0;
  bool _showSupportButton = false;

  String _getCurrentGiftText(BuildContext context) {
    return SplashTexts.items[_currentTextIndex].text;
  }

  @override
  void initState() {
    super.initState();

    // Random 2/10 (20%) chance to show support button
    _showSupportButton = Random().nextInt(100) < 20;

    // Pick a random gift text index
    _currentTextIndex = Random().nextInt(SplashTexts.items.length);

    // Log analytics for support button visibility
    if (_showSupportButton) {
      AnalyticsService().logFeatureUsed('support_button_shown');
      AnalyticsService().logFeatureUsed('drawer_header_support_visible');
    }

    // Heartbeat animation for the heart icon
    _heartbeatController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _heartbeatAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _heartbeatController, curve: Curves.easeInOut),
    );

    // Pulse animation for the background
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start animations
    _heartbeatController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _heartbeatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _showSponsorshipDialog() {
    // Enhanced analytics for sponsorship access from drawer header
    AnalyticsService().logFeatureUsed('random_support_button_engaged');
    AnalyticsService().logFeatureAdopted('support_button_interaction');

    // Log which text was showing when clicked
    AnalyticsService().logFeatureUsed(
      'support_clicked_on_${SplashTexts.items[_currentTextIndex].analyticsKey}',
    );

    // Route to fullscreen dialog
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const SponsorshipDialog(),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DrawerHeader(
      decoration: BoxDecoration(color: theme.colorScheme.primaryContainer),
      child: Stack(
        children: [
          // Main content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // App icon with heartbeat animation
              AnimatedBuilder(
                animation: Listenable.merge([
                  _heartbeatAnimation,
                  _pulseAnimation,
                ]),
                builder: (context, child) {
                  return Transform.scale(
                    scale: _heartbeatAnimation.value,
                    child: Container(
                      width: 48,
                      height: 48,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onPrimaryContainer.withOpacity(
                          0.1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(
                              0.35 * _pulseAnimation.value,
                            ),
                            blurRadius: 18 * _pulseAnimation.value,
                            spreadRadius: 4 * _pulseAnimation.value,
                          ),
                        ],
                      ),
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          theme.colorScheme.onPrimaryContainer,
                          BlendMode.srcIn,
                        ),
                        child: Image.asset(
                          'assets/icon/ic_launcher_monochrome.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  );
                },
              ),
              Text(
                'Shots Studio',
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Screenshot Manager',
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),

          // Splash text (top-right) - plain rotated text, tappable when support button is shown
          if (_showSupportButton)
            Positioned(
              top: 8,
              right: 0,
              child: GestureDetector(
                onTap: _showSponsorshipDialog,
                child: Transform.rotate(
                  angle: -0.40, // ~-30 degrees in radians
                  child: Text(
                    _getCurrentGiftText(context),
                    style: TextStyle(
                      color: theme.colorScheme.primary.withOpacity(0.90),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
