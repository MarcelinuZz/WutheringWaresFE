import 'package:flutter/material.dart';

import '../utils/colors.dart';

class InteractiveSurface extends StatefulWidget {
  const InteractiveSurface({
    super.key,
    required this.child,
    required this.onTap,
    this.borderRadius = 16,
    this.padding = EdgeInsets.zero,
    this.baseColor = Colors.transparent,
    this.hoverColor,
    this.borderColor,
    this.hoverBorderColor,
    this.pressedScale = 0.97,
    this.hoverScale = 1.015,
    this.shadowColor,
  });

  final Widget child;
  final VoidCallback onTap;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color baseColor;
  final Color? hoverColor;
  final Color? borderColor;
  final Color? hoverBorderColor;
  final double pressedScale;
  final double hoverScale;
  final Color? shadowColor;

  @override
  State<InteractiveSurface> createState() => _InteractiveSurfaceState();
}

class _InteractiveSurfaceState extends State<InteractiveSurface> {
  bool _hovered = false;
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final active = _hovered || _pressed;
    final scale = _pressed
        ? widget.pressedScale
        : (_hovered ? widget.hoverScale : 1.0);
    final radius = BorderRadius.circular(widget.borderRadius);
    final borderColor = active
        ? (widget.hoverBorderColor ?? widget.borderColor)
        : widget.borderColor;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: active
                  ? (widget.hoverColor ?? widget.baseColor)
                  : widget.baseColor,
              borderRadius: radius,
              border: borderColor == null
                  ? null
                  : Border.all(color: borderColor),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: (widget.shadowColor ?? AppColors.cyan)
                            .withValues(alpha: 0.16),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
