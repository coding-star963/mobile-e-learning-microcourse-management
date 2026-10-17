import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../models/enrollment.dart';
import '../../../models/lesson.dart';
import '../../../providers/course_provider.dart';
import '../../../providers/enrollment_provider.dart';
import '../../../providers/lesson_provider.dart';
import '../lesson/lesson_detail_screen.dart';
import '../lesson/lesson_list_screen.dart';

/// 3.4 Access Enrolled Course & Module 4 Learning Workspace.
/// The executive command center where the student continues learning,
/// accesses lessons, videos, and curriculum resources.
class CourseWorkspaceScreen extends StatefulWidget {
  const CourseWorkspaceScreen({super.key, required this.courseId});

  final String courseId;

  @override
  State<CourseWorkspaceScreen> createState() => _CourseWorkspaceScreenState();
}

class _CourseWorkspaceScreenState extends State<CourseWorkspaceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        context.read<LessonProvider>().loadLessons(widget.courseId);
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final course = context.watch<CourseProvider>().courseById(widget.courseId);
    LessonProvider? lessonProvider;
    try {
      lessonProvider = context.watch<LessonProvider>();
    } catch (_) {}
    final lessons = lessonProvider?.lessonsFor(widget.courseId) ?? const [];

    // A teacher may have suspended, cancelled or deleted this enrollment on the web portal.
    EnrollmentProvider? enrollmentProvider;
    try {
      enrollmentProvider = context.watch<EnrollmentProvider>();
    } catch (_) {}
    final enrollment = enrollmentProvider?.enrollmentFor(widget.courseId);
    final enrollmentRemoved =
        enrollment == null && (enrollmentProvider?.hasLoaded ?? false);
    final EnrollmentStatus? enrollmentStatus = enrollment?.status;
    final enrollmentOpen =
        !enrollmentRemoved && (enrollmentStatus?.isOpen ?? true);
    final badgeColor = enrollmentOpen ? AppTheme.goldPrimary : AppTheme.accentRuby;

    Lesson? nextIncompleteLesson;
    for (final l in lessons) {
      if (!(lessonProvider?.isCompleted(l.id) ?? false) && !l.isLocked) {
        nextIncompleteLesson = l;
        break;
      }
    }
    nextIncompleteLesson ??= lessons.isNotEmpty ? lessons.first : null;

    final completedCount = lessons
        .where((l) => lessonProvider?.isCompleted(l.id) ?? false)
        .length;
    final totalLessons = lessons.length;
    final progress = totalLessons > 0 ? completedCount / totalLessons : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(course?.title ?? 'Workspace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_rounded, color: AppTheme.goldPrimary),
            tooltip: 'All Lessons',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LessonListScreen(courseId: widget.courseId),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Status Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: AppTheme.luxuryCardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: badgeColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          enrollmentRemoved
                              ? 'You are no longer enrolled — enroll again from the catalog'
                              : enrollmentOpen
                                  ? 'You are enrolled in this course'
                                  : 'Enrollment ${enrollmentStatus!.label.toLowerCase()} — contact your teacher',
                          style: TextStyle(
                            color: badgeColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${(progress * 100).toInt()}% Done',
                        style: TextStyle(
                          color: AppTheme.goldLight,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    course?.title ?? 'Course Workspace',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    course?.description ?? 'Explore modules and master the skills.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 20),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: AppTheme.bgSurface,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.goldPrimary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$completedCount of $totalLessons modules completed',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 20),

                  // 5.5 Continue Learning CTA button (only while the enrollment is open)
                  if (enrollmentOpen && nextIncompleteLesson != null)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.goldPrimary,
                        foregroundColor: Colors.black,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 22),
                      label: Text(
                        'Continue Learning: ${nextIncompleteLesson.title}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => LessonDetailScreen(
                              courseId: widget.courseId,
                              lessonId: nextIncompleteLesson!.id,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Curriculum Header
            Row(
              children: [
                const Icon(Icons.auto_stories,
                    size: 20, color: AppTheme.goldPrimary),
                const SizedBox(width: 8),
                Text(
                  'Course Curriculum',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            LessonListScreen(courseId: widget.courseId),
                      ),
                    );
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if ((lessonProvider?.isLoading ?? false) && lessons.isEmpty)
              const Center(
                child: CircularProgressIndicator(color: AppTheme.goldPrimary),
              )
            else if (lessons.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Center(
                  child: Text(
                    'No lessons currently available.',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                ),
              )
            else
              ...lessons.take(4).map((lesson) {
                final isDone = lessonProvider?.isCompleted(lesson.id) ?? false;
                final isLocked = lesson.isLocked;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDone
                          ? AppTheme.accentEmerald.withValues(alpha: 0.3)
                          : AppTheme.borderLight,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: ListTile(
                      onTap: isLocked
                          ? null
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
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDone
                            ? AppTheme.accentEmerald.withValues(alpha: 0.15)
                            : (isLocked ? AppTheme.bgSurface : AppTheme.goldGlow),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isDone
                            ? Icons.check
                            : (isLocked
                                ? Icons.lock
                                : (lesson.hasVideo
                                    ? Icons.play_arrow
                                    : Icons.article)),
                        color: isDone
                            ? AppTheme.accentEmerald
                            : (isLocked
                                ? AppTheme.textMuted
                                : AppTheme.goldPrimary),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      lesson.title,
                      style: TextStyle(
                        color: isLocked
                            ? AppTheme.textMuted
                            : AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      '${lesson.displayDuration} • ${lesson.resources.length} resources',
                      style: TextStyle(
                          color: AppTheme.textMuted, fontSize: 12),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        size: 14, color: AppTheme.borderGold),
                  ),
                ),
              );
              }),
          ],
        ),
      ),
    );
  }
}
