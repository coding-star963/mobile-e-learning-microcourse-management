import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/live_sync.dart';
import '../../../core/theme.dart';
import '../../../models/course.dart';
import '../../../models/enrollment.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/course_provider.dart';
import '../../../providers/enrollment_provider.dart';
import '../../../providers/lesson_provider.dart';
import '../../widgets/progress_bar.dart';
import '../lesson/lesson_list_screen.dart';

/// 3.3 Luxury Enrollment Details Screen.
class EnrollmentDetailScreen extends StatefulWidget {
  const EnrollmentDetailScreen({super.key, required this.enrollmentId});

  final String enrollmentId;

  @override
  State<EnrollmentDetailScreen> createState() =>
      _EnrollmentDetailScreenState();
}

class _EnrollmentDetailScreenState extends State<EnrollmentDetailScreen> {
  Enrollment? _enrollment;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    LiveSync.revision.addListener(_onLiveSync);
  }

  @override
  void dispose() {
    LiveSync.revision.removeListener(_onLiveSync);
    super.dispose();
  }

  /// A teacher changed something on the web portal: reload this record
  /// quietly, or explain that it was deleted.
  Future<void> _onLiveSync() async {
    // Only the screen on top reloads; screens underneath catch up via the providers.
    if (!mounted || _enrollment == null || !(ModalRoute.of(context)?.isCurrent ?? true)) return;
    try {
      final user = context.read<AuthProvider>().user!;
      final enrollment = await context.read<EnrollmentProvider>().loadEnrollmentDetails(
            studentId: user.id,
            enrollmentId: widget.enrollmentId,
          );
      if (mounted) setState(() => _enrollment = enrollment);
    } on Exception {
      if (!mounted) return;
      final stillEnrolled = context
          .read<EnrollmentProvider>()
          .enrollments
          .any((e) => e.id == widget.enrollmentId);
      if (!stillEnrolled) {
        setState(() {
          _enrollment = null;
          _error = 'This enrollment record was deleted by an administrator. '
              'You can enroll again from the course catalog.';
        });
      }
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final user = context.read<AuthProvider>().user!;
      final enrollmentProvider = context.read<EnrollmentProvider>();
      final courseProvider = context.read<CourseProvider>();
      final enrollment = await enrollmentProvider.loadEnrollmentDetails(
        studentId: user.id,
        enrollmentId: widget.enrollmentId,
      );
      await courseProvider.loadCourseDetails(enrollment.courseId);
      if (mounted) {
        context.read<LessonProvider>().loadLessons(enrollment.courseId);
      }
      if (!mounted) return;
      setState(() => _enrollment = enrollment);
    } on Exception {
      if (!mounted) return;
      setState(() => _error = 'Could not load enrollment records.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enrollmentProvider = context.watch<EnrollmentProvider>();
    final courseProvider = context.watch<CourseProvider>();
    final lessonProvider = context.watch<LessonProvider>();
    final enrollment = _enrollment;
    final course = enrollment == null
        ? null
        : courseProvider.cachedCourseDetails(enrollment.courseId);

    return Scaffold(
      appBar: AppBar(title: Text(course?.title ?? 'Enrollment Record')),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.goldPrimary),
            )
          : _error != null || enrollment == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error ?? 'Enrollment not found.',
                        style: const TextStyle(color: AppTheme.accentRuby),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _EnrollmentContentView(
                  enrollment: enrollment,
                  course: course,
                  categoryName: courseProvider
                      .categoryNameOf(course?.categoryId ?? ''),
                  enrollmentsCount: enrollmentProvider.enrollments.length,
                  lessonProvider: lessonProvider,
                  onContinue: () => Navigator.of(context).pushNamed(
                    '/course-workspace',
                    arguments: enrollment.courseId,
                  ),
                ),
    );
  }
}

class _EnrollmentContentView extends StatelessWidget {
  const _EnrollmentContentView({
    required this.enrollment,
    required this.course,
    required this.categoryName,
    required this.enrollmentsCount,
    required this.lessonProvider,
    required this.onContinue,
  });

  final Enrollment enrollment;
  final Course? course;
  final String categoryName;
  final int enrollmentsCount;
  final LessonProvider lessonProvider;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final courseLessons = lessonProvider.lessonsFor(enrollment.courseId);
    final totalLessons = course?.lessonIds.isNotEmpty == true
        ? course!.lessonIds.length
        : (courseLessons.isNotEmpty ? courseLessons.length : 1);
    final completedCount = enrollment.completedLessonIds.length;
    final fraction = totalLessons > 0 ? (completedCount / totalLessons).clamp(0.0, 1.0) : 0.0;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Enrollment Summary Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.luxuryCardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      course?.title ?? enrollment.courseId,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _StatusPill(status: enrollment.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '$categoryName • ${course?.difficultyLevel.toUpperCase() ?? ""}',
                style: TextStyle(
                  color: AppTheme.goldLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 14),
              _InfoRow(
                icon: Icons.calendar_today_outlined,
                label: 'Enrolled on',
                value: _formatDate(enrollment.enrolledAt),
              ),
              _InfoRow(
                icon: Icons.task_alt_outlined,
                label: 'Lessons completed',
                value: '$completedCount of $totalLessons',
              ),
              _InfoRow(
                icon: Icons.speed_rounded,
                label: 'Progress',
                value: '${(fraction * 100).round()}%',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Progress Details Card
        Card(
          color: AppTheme.bgCard,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppTheme.borderLight),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.insights,
                        size: 18, color: AppTheme.goldPrimary),
                    const SizedBox(width: 8),
                    Text(
                      'Course progress',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(fraction * 100).round()}%',
                      style: TextStyle(
                        color: AppTheme.goldLight,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ProgressBar(
                  fraction: fraction,
                  label: '$completedCount of $totalLessons completed',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Continue Learning Button
        Container(
          decoration: BoxDecoration(
            gradient: AppTheme.goldGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.goldPrimary.withValues(alpha: 0.3),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.black,
              shadowColor: Colors.transparent,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 24),
            label: const Text(
              'Continue learning',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            onPressed: onContinue,
          ),
        ),
        const SizedBox(height: 12),

        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
          ),
          icon: const Icon(Icons.list_alt_rounded),
          label: const Text('VIEW ALL LESSONS'),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LessonListScreen(courseId: enrollment.courseId),
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.goldPrimary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
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
