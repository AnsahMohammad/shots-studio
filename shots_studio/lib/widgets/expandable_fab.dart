import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/analytics/analytics_service.dart';

class ExpandableFab extends StatefulWidget {
  final List<ExpandableFabAction> actions;
  final Widget? child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double distance;
  final Duration animationDuration;

  const ExpandableFab({
    super.key,
    required this.actions,
    this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.distance = 100.0,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _fadeAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 0.125, // 45 degrees (1/8 turn)
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
        // Track FAB expansion
        AnalyticsService().logFeatureUsed('fab_expanded');
      } else {
        _controller.reverse();
      }
    });
  }

  void _closeAndExecute(VoidCallback action) {
    if (_isExpanded) {
      setState(() {
        _isExpanded = false;
      });
      _controller.reverse().then((_) => action());
    } else {
      action();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 180, // Increased width for better text visibility
      height:
          widget.actions.length * 50.0 +
          90, // Reduced spacing and increased distance from main FAB
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.bottomRight, // Align FAB to bottom right
            children: [
              // Background overlay when expanded
              if (_isExpanded)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _toggle,
                    child: Container(
                      color: Colors.transparent,
                    ), // 100% transparent
                  ),
                ),

              // Action buttons
              ...widget.actions.asMap().entries.map((entry) {
                final index = entry.key;
                final action = entry.value;

                // Calculate position: expand up and to the left
                final double spacing =
                    50.0; // Further reduced spacing between items
                final double yOffset =
                    -spacing * (index + 1) -
                    20; // Move up with extra distance from main FAB
                final double xOffset = -10.0; // Slight left alignment

                return AnimatedBuilder(
                  animation: _expandAnimation,
                  builder: (context, child) {
                    final progress = _expandAnimation.value;
                    return Transform.translate(
                      offset: Offset(xOffset * progress, yOffset * progress),
                      child: Transform.scale(
                        scale: progress,
                        child: Opacity(
                          opacity: _fadeAnimation.value,
                          child: Material(
                            elevation: 6,
                            borderRadius: BorderRadius.circular(
                              22,
                            ), // Slightly increased radius for better appearance
                            color:
                                action.backgroundColor ??
                                theme.colorScheme.secondaryContainer,
                            shadowColor: theme.colorScheme.shadow.withOpacity(
                              0.4,
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(22),
                              onTap: () => _closeAndExecute(action.onPressed),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                constraints: const BoxConstraints(
                                  maxWidth:
                                      180, // Increased to accommodate longer text
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        action.label,
                                        style: TextStyle(
                                          color:
                                              action.foregroundColor ??
                                              theme
                                                  .colorScheme
                                                  .onSecondaryContainer,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      action.icon,
                                      size: 18,
                                      color:
                                          action.foregroundColor ??
                                          theme
                                              .colorScheme
                                              .onSecondaryContainer,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),

              // Main FAB
              Transform.rotate(
                angle: _rotateAnimation.value * 2 * math.pi,
                child: FloatingActionButton(
                  heroTag: "main_fab",
                  backgroundColor:
                      widget.backgroundColor ?? theme.colorScheme.primary,
                  foregroundColor:
                      widget.foregroundColor ?? theme.colorScheme.onPrimary,
                  onPressed: _toggle,
                  elevation: _isExpanded ? 8 : 6,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child:
                        _isExpanded
                            ? const Icon(Icons.close, key: ValueKey('close'))
                            : (widget.child ??
                                const Icon(
                                  Icons.add_a_photo,
                                  key: ValueKey('add'),
                                )),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ExpandableFabAction {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const ExpandableFabAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
  });
}
