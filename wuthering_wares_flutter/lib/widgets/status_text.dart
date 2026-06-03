import 'package:flutter/material.dart';

import '../utils/colors.dart';

class StatusText extends StatelessWidget {
  const StatusText(this.text, {super.key, required this.success});

  final String text;
  final bool success;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: success ? AppColors.success : AppColors.error,
      fontSize: 12,
      height: 1.35,
    ),
  );
}
