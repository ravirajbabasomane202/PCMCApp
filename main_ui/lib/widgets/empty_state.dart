// lib/widgets/empty_state.dart
import 'package:flutter/material.dart';

class EmptyState extends StatefulWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? actionButton;
  final Color? iconColor; // Optional icon color
  final TextStyle? titleStyle; // Optional title style
  final TextStyle? messageStyle; // Optional message style
  final Color? backgroundColor; // Optional background color

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionButton,
    this.iconColor,
    this.titleStyle,
    this.messageStyle,
    this.backgroundColor,
  });

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Semantics(
      label: 'Empty state: ${widget.title}',
      child: Container(
        color: widget.backgroundColor ?? theme.colorScheme.surface,
        padding: EdgeInsets.all(isSmallScreen ? 16.0 : 32.0),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    widget.icon,
                    size: isSmallScreen ? 48 : 64,
                    color: widget.iconColor ??
                        theme.colorScheme.onSurface.withValues (alpha: 0.4),
                    semanticLabel: 'Empty state icon',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.title,
                    style: widget.titleStyle ??
                        theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                    textAlign: TextAlign.center,
                    semanticsLabel: widget.title,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.message,
                    style: widget.messageStyle ??
                        theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues (alpha: 0.7),
                              height: 1.5,
                            ),
                    textAlign: TextAlign.center,
                    semanticsLabel: widget.message,
                  ),
                  if (widget.actionButton != null) ...[
                    const SizedBox(height: 24),
                    widget.actionButton!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
