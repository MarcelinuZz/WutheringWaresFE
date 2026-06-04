import 'package:flutter/material.dart';

import '../utils/colors.dart';

class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    super.key,
    required this.text,
    required this.loading,
    required this.onPressed,
  });

  final String text;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style:
            ElevatedButton.styleFrom(
              backgroundColor: AppColors.cyan,
              foregroundColor: Colors.black,
              elevation: 0,
              shadowColor: AppColors.cyan.withValues(alpha: 0.35),
              animationDuration: const Duration(milliseconds: 180),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ).copyWith(
              elevation: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.hovered) ? 5 : 0,
              ),
              overlayColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.pressed)
                    ? Colors.black.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.08),
              ),
            ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
      ),
    );
  }
}

class SecondaryActionButton extends StatelessWidget {
  const SecondaryActionButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
  });

  final String text;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(text),
        style:
            OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.stroke),
              animationDuration: const Duration(milliseconds: 180),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ).copyWith(
              side: WidgetStateProperty.resolveWith(
                (states) => BorderSide(
                  color: states.contains(WidgetState.hovered)
                      ? AppColors.cyan
                      : AppColors.stroke,
                ),
              ),
              overlayColor: WidgetStateProperty.all(
                AppColors.cyan.withValues(alpha: 0.08),
              ),
            ),
      ),
    );
  }
}
