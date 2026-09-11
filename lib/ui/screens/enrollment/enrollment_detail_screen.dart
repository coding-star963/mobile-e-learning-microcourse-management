import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
                    Chip(
                      label: Text(
                        enrollment.status == EnrollmentStatus.completed
                            ? 'Completed'
                            : 'In progress',
                        style: theme.textTheme.labelSmall,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
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
                  label: 'Enrolled on',
                  value: _formatDate(enrollment.enrolledAt),
                ),
                _InfoRow(
                  label: 'Lessons completed',
                  value:
                      '${enrollment.completedLessonIds.length} of $totalLessons',
                ),
                _InfoRow(
                  label: 'Progress',
                  value: '${(fraction * 100).round()}%',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // -- Progress bar (5.2/5.3 preview) ------------------------------
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ProgressBar(
            fraction: fraction,
            label: 'Course progress',
          ),
        ),
        const SizedBox(height: 24),

        // -- 3.4 Access Enrolled Course ----------------------------------
        FilledButton.icon(
          onPressed: onContinue,
          icon: const Icon(Icons.play_arrow_outlined),
          label: const Text('Continue learning'),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
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
