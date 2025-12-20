import 'package:flutter/material.dart';
import 'dart:math';
import '../../services/sponsorship_service.dart';
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
  late AnimationController _textController;
  late Animation<double> _heartbeatAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _textAnimation;

  int _currentTextIndex = 0;
  bool _showSupportButton = false;

  String _getCurrentGiftText(BuildContext context) {
    switch (_currentTextIndex) {
      case 0:
        return 'Gift \$10';
      case 1:
        return 'Gift \$15';
      case 2:
        return 'Gift \$20';
      default:
        return 'Gift \$10';
    }
  }

  @override
  void initState() {
    super.initState();

    // Random 4/10 (40%) chance to show support button
    _showSupportButton = Random().nextInt(10) < 4;

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

    // Text shifting animation
    _textController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _textAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeInOut),
    );

    // Start animations
    _heartbeatController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);

    // Text shifting with listener
    _textController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _currentTextIndex =
              (_currentTextIndex + 1) % 3; // 3 gift text options
        });
        _textController.reset();
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            _textController.forward();
          }
        });
      }
    });
    _textController.forward();
  }

  @override
  void dispose() {
    _heartbeatController.dispose();
    _pulseController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _showSponsorshipDialog() {
    // Enhanced analytics for sponsorship access from drawer header
    AnalyticsService().logFeatureUsed('random_support_button_engaged');
    AnalyticsService().logFeatureAdopted('support_button_interaction');

    // Log which text was showing when clicked
    final giftTexts = ['support_us', 'gift_dollar1', 'gift_dollar5'];
    AnalyticsService().logFeatureUsed(
      'support_clicked_on_${giftTexts[_currentTextIndex]}',
    );

    final sponsorshipOptions = SponsorshipService.getAllOptions();

    // Route to fullscreen dialog
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (context) =>
                SponsorshipDialog(sponsorshipOptions: sponsorshipOptions),
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
              // App icon with theme coloring
              Container(
                width: 48,
                height: 48,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onPrimaryContainer.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
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

          // Beautiful Support Button (Top Right) - Only shown 20% of the time
          if (_showSupportButton)
            Positioned(
              top: 8,
              right: 8,
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _heartbeatAnimation,
                  _pulseAnimation,
                  _textAnimation,
                ]),
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(
                            0.4 * _pulseAnimation.value,
                          ),
                          blurRadius: 20 * _pulseAnimation.value,
                          spreadRadius: 5 * _pulseAnimation.value,
                        ),
                      ],
                    ),
                    child: Material(
                      borderRadius: BorderRadius.circular(20),
                      color: theme.colorScheme.onPrimaryContainer.withOpacity(
                        0.1,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: _showSponsorshipDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Transform.scale(
                                scale: _heartbeatAnimation.value,
                                child: Icon(
                                  Icons.favorite,
                                  color: theme.colorScheme.onPrimaryContainer,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 6),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 400),
                                transitionBuilder: (
                                  Widget child,
                                  Animation<double> animation,
                                ) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0.0, 0.3),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Text(
                                  _getCurrentGiftText(context),
                                  key: ValueKey<String>(
                                    _getCurrentGiftText(context),
                                  ),
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
