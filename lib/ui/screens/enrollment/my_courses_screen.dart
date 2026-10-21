import 'package:flutter/material.dart';

import '../../../core/media_url.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../models/enrollment.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/course_provider.dart';
import '../../../providers/enrollment_provider.dart';
import '../../../providers/lesson_provider.dart';
import '../../widgets/progress_bar.dart';

/// 3.2 Luxury Enrolled Courses View.
/// Displays student enrollments, module completion metrics, and learning pathways.
class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class MyCoursesPage extends StatelessWidget {
  const MyCoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Masterclasses')),
      body: const MyCoursesScreen(),
    );
  }
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  String? _loadedForUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadIfNeeded());
  }

  void _loadIfNeeded() {
    final user = context.read<AuthProvider>().user;
    if (user == null || _loadedForUserId == user.id) return;
    _loadedForUserId = user.id;
    context.read<EnrollmentProvider>().loadEnrollments(user.id);
  }

  @override
  Widget build(BuildContext context) {
    final enrollmentProvider = context.watch<EnrollmentProvider>();
    final courseProvider = context.watch<CourseProvider>();
    final lessonProvider = context.watch<LessonProvider>();

    return enrollmentProvider.isLoading && enrollmentProvider.enrollments.isEmpty
        ? const Center(
            child: CircularProgressIndicator(color: AppTheme.goldPrimary),
          )
        : enrollmentProvider.error != null &&
                enrollmentProvider.enrollments.isEmpty
            ? Center(
                child: Text(
                  enrollmentProvider.error!,
                  style: const TextStyle(color: AppTheme.accentRuby),
                ),
              )
            : enrollmentProvider.enrollments.isEmpty
                ? const _EmptyState()
                : RefreshIndicator(
                    color: AppTheme.goldPrimary,
                    backgroundColor: AppTheme.bgCard,
                    onRefresh: () async {
                      final user = context.read<AuthProvider>().user;
                      if (user != null) {
                        await context
                            .read<EnrollmentProvider>()
                            .loadEnrollments(user.id);
                      }
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: enrollmentProvider.enrollments.length,
                      itemBuilder: (context, index) {
                        final enrollment =
                            enrollmentProvider.enrollments[index];
                        return _EnrollmentCard(
                          key: ValueKey(enrollment.id),
                          enrollment: enrollment,
                          courseProvider: courseProvider,
                          lessonProvider: lessonProvider,
                        );
                      },
                    ),
                  );
  }
}

class _EnrollmentCard extends StatelessWidget {
  const _EnrollmentCard({
    super.key,
    required this.enrollment,
    required this.courseProvider,
    required this.lessonProvider,
  });

  final Enrollment enrollment;
  final CourseProvider courseProvider;
  final LessonProvider lessonProvider;

  @override
  Widget build(BuildContext context) {
    final course = courseProvider.courseById(enrollment.courseId);
    final courseLessons = lessonProvider.lessonsFor(enrollment.courseId);
    final totalLessons = course?.lessonIds.isNotEmpty == true
        ? course!.lessonIds.length
        : (courseLessons.isNotEmpty ? courseLessons.length : 1);
    final completedCount = enrollment.completedLessonIds.length;
    final fraction = totalLessons > 0 ? (completedCount / totalLessons).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.borderGold.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.of(context).pushNamed(
            '/enrollment-detail',
            arguments: enrollment.id,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 76,
                        height: 76,
                        color: AppTheme.bgSurface,
                        child: course?.thumbnailUrl != null &&
                                course!.thumbnailUrl!.isNotEmpty
                            ? Image.network(
                                course.thumbnailUrl!,
                                headers: MediaUrl.headersFor(course.thumbnailUrl!),
                                fit: BoxFit.cover,
                                // The API media endpoint supports cross-origin image requests.
                                webHtmlElementStrategy:
                                    WebHtmlElementStrategy.fallback,
                                errorBuilder: (_, _, _) =>
                                    _thumbPlaceholder(),
                              )
                            : _thumbPlaceholder(),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _StatusPill(status: enrollment.status),
                              const Spacer(),
                              Text(
                                '${(fraction * 100).toInt()}% Done',
                                style: TextStyle(
                                  color: AppTheme.goldLight,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            course?.title ?? 'Enrolled Course',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Enrolled ${_formatDate(enrollment.enrolledAt)}',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Progress Bar
                ProgressBar(
                  fraction: fraction,
                  label: '$completedCount of $totalLessons sessions completed',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  Widget _thumbPlaceholder() => const Center(
        child: Icon(Icons.school_outlined,
            color: AppTheme.goldPrimary, size: 28),
      );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final EnrollmentStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      EnrollmentStatus.completed => AppTheme.accentEmerald,
      EnrollmentStatus.active => AppTheme.goldPrimary,
      _ => AppTheme.accentRuby,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status == EnrollmentStatus.active ? AppTheme.goldLight : color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.borderGold),
              ),
              child: const Icon(Icons.bookmark_outline_rounded,
                  size: 38, color: AppTheme.goldPrimary),
            ),
            const SizedBox(height: 20),
            Text(
              'No active enrollments',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Discover executive micro-courses in the catalog and begin your journey.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
