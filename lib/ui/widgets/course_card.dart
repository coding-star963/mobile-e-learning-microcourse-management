import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/course.dart';

/// Luxury Course Card for catalog lists and discovery.
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
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: AppTheme.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: AppTheme.borderGold.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail with Luxury Rounded Corners
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 106,
                    height: 84,
                    color: AppTheme.bgSurface,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (course.thumbnailUrl != null &&
                            course.thumbnailUrl!.isNotEmpty)
                          Image.network(
                            course.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                _thumbPlaceholder(),
                          )
                        else
                          _thumbPlaceholder(),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.5),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Course Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.category_outlined,
                              size: 13, color: AppTheme.goldLight),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              categoryName,
                              style: const TextStyle(
                                color: AppTheme.goldLight,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          // Difficulty Pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.difficultyColor(
                                course.difficultyLevel,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              course.difficultyLevel.toUpperCase(),
                              style: TextStyle(
                                color: AppTheme.difficultyColor(
                                  course.difficultyLevel,
                                ),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Module count
                          if (course.lessonIds.isNotEmpty)
                            Text(
                              '${course.lessonIds.length} modules',
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          const Spacer(),
                          const Icon(Icons.arrow_forward_ios,
                              size: 13, color: AppTheme.goldPrimary),
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

  Widget _thumbPlaceholder() {
    return Container(
      color: const Color(0xFF192235),
      child: const Center(
        child: Icon(
          Icons.school_outlined,
          size: 32,
          color: AppTheme.goldPrimary,
        ),
      ),
    );
  }
}
