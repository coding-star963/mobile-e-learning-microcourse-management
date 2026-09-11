import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../models/course.dart';
import '../../../models/enrollment.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/course_provider.dart';
import '../../../providers/enrollment_provider.dart';
import '../../widgets/progress_bar.dart';

/// 3.3 View Enrollment Details — basic info about the student's enrollment in
/// a selected course, with the 3.4 access action. Full lesson content arrives
/// in Sprint 4 (Module 4).
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
      // Ensure the course record is cached for title/lesson lookups (3.3).
      await courseProvider.loadCourseDetails(enrollment.courseId);
      if (!mounted) return;
      setState(() => _enrollment = enrollment);
    } on Exception {
      if (!mounted) return;
      setState(() => _error = 'Could not load this enrollment.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enrollmentProvider = context.watch<EnrollmentProvider>();
    final courseProvider = context.watch<CourseProvider>();
    final enrollment = _enrollment;
    final course =
        enrollment == null ? null : courseProvider.cachedCourseDetails(enrollment.courseId);

    return Scaffold(
      appBar: AppBar(title: Text(course?.title ?? 'Enrollment')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null || enrollment == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error ?? 'Enrollment not found.',
                        style: theme.textTheme.bodyLarge,
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
                  categoryName:
                      courseProvider.categoryNameOf(enrollment.courseId),
                  enrollmentsCount: enrollmentProvider.enrollments.length,
                  onContinue: () => Navigator.of(context).pushNamed(
                    '/course-workspace',
                    arguments: enrollment.courseId,
                  ),
                ),
    );
  }
}

/// Content branch with a non-null [Enrollment] (3.3 details + 3.4 action).
class _EnrollmentContentView extends StatelessWidget {
  const _EnrollmentContentView({
    required this.enrollment,
    required this.course,
    required this.categoryName,
    required this.enrollmentsCount,
    required this.onContinue,
  });

  final Enrollment enrollment;
  final Course? course;
  final String categoryName;
  final int enrollmentsCount;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalLessons = course?.lessonIds.length ?? 0;
    final fraction = enrollment.progressFraction(totalLessons);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // -- Basic enrollment info (3.3) --------------------------------
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        course?.title ?? enrollment.courseId,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    _StatusPill(status: enrollment.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$categoryName • ${course?.difficultyLevel ?? ''}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.event_outlined,
                  label: 'Enrolled on',
                  value: _formatDate(enrollment.enrolledAt),
                ),
                _InfoRow(
                  icon: Icons.task_alt_outlined,
                  label: 'Lessons completed',
                  value:
                      '${enrollment.completedLessonIds.length} of $totalLessons',
                ),
                _InfoRow(
                  icon: Icons.percent_outlined,
                  label: 'Progress',
                  value: '${(fraction * 100).round()}%',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // -- Progress card (5.2/5.3 preview) -----------------------------
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.insights_outlined,
                        size: 18, color: AppTheme.accentTeal),
                    const SizedBox(width: 8),
                    Text(
                      'Course progress',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Text(
                      '${(fraction * 100).round()}%',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.accentTeal,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ProgressBar(fraction: fraction),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // -- 3.4 Access Enrolled Course ----------------------------------
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onContinue,
            icon: const Icon(Icons.play_arrow_outlined),
            label: const Text('Continue learning'),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }
}

/// Status pill matching the My Courses card style.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final EnrollmentStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completed = status == EnrollmentStatus.completed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: completed
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        completed ? 'Completed' : 'In progress',
        style: theme.textTheme.labelSmall?.copyWith(
          color: completed
              ? theme.colorScheme.onPrimaryContainer
              : theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.outline),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            value,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
