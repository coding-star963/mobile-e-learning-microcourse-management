import 'package:flutter/material.dart';

import '../../models/course.dart';

/// Reusable card for catalog lists: thumbnail, title, difficulty, and the
/// course status (2.5). Tapping opens the course detail page (2.4).
class CourseCard extends StatelessWidget {
  const CourseCard({
    super.key,
    required this.course,
    required this.categoryName,
    required this.onTap,
  });

  final Course course;
  final String categoryName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail (2.4)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 96,
                  height: 72,
                  child: Image.network(
                    course.thumbnailUrl ?? '',
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) =>
                        progress == null ? child : _thumbPlaceholder(theme),
                    errorBuilder: (_, _, _) => _thumbPlaceholder(theme),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      categoryName,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.outline),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Difficulty level (2.4)
                        Chip(
                          label: Text(course.difficultyLevel),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          labelStyle: theme.textTheme.labelSmall,
                        ),
                        const SizedBox(width: 8),
                        // 2.5 View Course Status
                        _StatusChip(isPublished: course.isPublished),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbPlaceholder(ThemeData theme) => ColoredBox(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.school_outlined,
          color: theme.colorScheme.outline,
        ),
      );
}

/// 2.5 View Course Status — shows whether the course is available for
/// enrollment or learning.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isPublished});

  final bool isPublished;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      label: Text(isPublished ? 'Open for enrollment' : 'Not available'),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      labelStyle: theme.textTheme.labelSmall?.copyWith(
        color: isPublished
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onErrorContainer,
      ),
      backgroundColor: isPublished
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.errorContainer,
    );
  }
}
