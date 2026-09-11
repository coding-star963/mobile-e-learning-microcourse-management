import 'package:flutter/material.dart';

/// Reusable linear progress display used by 3.3 enrollment details and the
/// Module 5 progress screens (AGENT.md §4.2 shared widgets).
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.fraction,
    this.height = 8,
    this.label,
  });

  /// Completion fraction between 0.0 and 1.0 (5.3).
  final double fraction;
  final double height;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(label!, style: theme.textTheme.bodySmall),
          const SizedBox(height: 4),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: LinearProgressIndicator(
            value: fraction.clamp(0.0, 1.0),
            minHeight: height,
          ),
        ),
      ],
    );
  }
}
