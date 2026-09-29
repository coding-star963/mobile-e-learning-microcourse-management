import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Luxury Linear Progress Bar with gold metallic styling.
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.fraction,
    this.height = 7,
    this.label,
  });

  final double fraction;
  final double height;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final clamped = fraction.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: LinearProgressIndicator(
            value: clamped,
            minHeight: height,
            backgroundColor: AppTheme.bgSurface,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.goldPrimary),
          ),
        ),
      ],
    );
  }
}
