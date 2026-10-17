import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../models/course.dart';
import '../../../models/lesson.dart';
import '../../../providers/course_provider.dart';
import '../../../providers/lesson_provider.dart';
import 'lesson_detail_screen.dart';

/// Module 4: View Course Lessons Screen (4.1, 4.5, 4.6, 5.2).
/// Displays structured learning modules in order with status indicators and progress.
class LessonListScreen extends StatefulWidget {
  const LessonListScreen({super.key, required this.courseId});

  final String courseId;

  @override
  State<LessonListScreen> createState() => _LessonListScreenState();
}

class _LessonListScreenState extends State<LessonListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LessonProvider>().loadLessons(widget.courseId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final course = context.watch<CourseProvider>().courseById(widget.courseId);
    final lessonProvider = context.watch<LessonProvider>();
    final lessons = lessonProvider.lessonsFor(widget.courseId);

    final completedCount = lessons
        .where((l) => lessonProvider.isCompleted(l.id))
        .length;
    final totalCount = lessons.length;
    final progressFraction = totalCount > 0 ? completedCount / totalCount : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(course?.title ?? 'Course Curriculum'),
      ),
      body: lessonProvider.isLoading && lessons.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.goldPrimary),
            )
          : RefreshIndicator(
              color: AppTheme.goldPrimary,
              backgroundColor: AppTheme.bgCard,
              onRefresh: () =>
                  lessonProvider.loadLessons(widget.courseId),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // -- Course Progress Overview Card ------------------------
                  _buildCurriculumHeader(
                      course, completedCount, totalCount, progressFraction),
                  const SizedBox(height: 20),

                  // Section Title
                  Row(
                    children: [
                      const Icon(Icons.menu_book_rounded,
                          size: 18, color: AppTheme.goldPrimary),
                      const SizedBox(width: 8),
                      Text(
                        'COURSE MODULES ($totalCount)',
                        style: TextStyle(
                          color: AppTheme.goldLight,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // -- Lessons List (4.1, 4.5, 4.6) -------------------------
                  if (lessons.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: AppTheme.luxuryCardDecoration,
                      child: Center(
                        child: Text(
                          'No lessons available yet for this course.',
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                      ),
                    )
                  else
                    ...lessons.map((lesson) {
                      final isDone = lessonProvider.isCompleted(lesson.id);
                      return _buildLessonTile(lesson, isDone);
                    }),
                ],
              ),
            ),
    );
  }

  Widget _buildCurriculumHeader(
    Course? course,
    int completedCount,
    int totalCount,
    double progress,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.luxuryCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.goldPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppTheme.goldPrimary.withValues(alpha: 0.4)),
                ),
                child: Text(
                  (course?.difficultyLevel ?? 'BEGINNER').toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.goldPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).toInt()}% COMPLETED',
                style: TextStyle(
                  color: AppTheme.goldLight,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            course?.title ?? 'Micro-Course Workspace',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          // Progress track
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppTheme.bgSurface,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.goldPrimary),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$completedCount of $totalCount completed',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              Text(
                'Self-Paced Masterclass',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLessonTile(Lesson lesson, bool isDone) {
    final isLocked = lesson.isLocked;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone
              ? AppTheme.accentEmerald.withValues(alpha: 0.35)
              : (isLocked ? AppTheme.borderLight : AppTheme.borderGold.withValues(alpha: 0.2)),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: isLocked
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      lesson.lockedReason,
                    ),
                  ),
                );
              }
            : () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LessonDetailScreen(
                      courseId: widget.courseId,
                      lessonId: lesson.id,
                    ),
                  ),
                );
              },
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDone
                ? AppTheme.accentEmerald.withValues(alpha: 0.15)
                : (isLocked
                    ? AppTheme.bgSurface
                    : AppTheme.goldPrimary.withValues(alpha: 0.12)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isDone
                ? Icons.check_circle
                : (isLocked
                    ? Icons.lock_outline
                    : (lesson.hasVideo
                        ? Icons.play_arrow_rounded
                        : (lesson.hasAudio
                            ? Icons.audiotrack
                            : Icons.article_outlined))),
            color: isDone
                ? AppTheme.accentEmerald
                : (isLocked ? AppTheme.textMuted : AppTheme.goldPrimary),
            size: 22,
          ),
        ),
        title: Text(
          lesson.title,
          style: TextStyle(
            color: isLocked ? AppTheme.textMuted : AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Text(
                lesson.displayDuration,
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
              if (lesson.isFreePreview) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.accentEmerald.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'FREE PREVIEW',
                    style: TextStyle(
                      color: AppTheme.accentEmerald,
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
              if (lesson.resources.isNotEmpty) ...[
                const SizedBox(width: 8),
                Icon(Icons.attachment, size: 12, color: AppTheme.textMuted),
                const SizedBox(width: 2),
                Text(
                  '${lesson.resources.length}',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ],
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: isLocked ? AppTheme.borderLight : AppTheme.goldPrimary,
        ),
      ),
    ),
  );
  }
}
