import 'package:flutter/material.dart';

import '../utils/colors.dart';
import 'status_text.dart';

class TerminalField extends StatelessWidget {
  const TerminalField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.error,
    this.errorSuccess = false,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final String? error;
  final bool errorSuccess;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          onChanged: onChanged,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.textMuted.withValues(alpha: 0.65),
            ),
            filled: true,
            fillColor: AppColors.input,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.stroke),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.cyan),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 5),
          StatusText(error!, success: errorSuccess),
        ],
      ],
    );
  }
}
