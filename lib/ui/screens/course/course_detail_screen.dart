import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/course.dart';
import '../../../models/enrollment.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/course_provider.dart';
import '../../../providers/enrollment_provider.dart';
import '../../../data/repositories/course_repository.dart';

/// 2.4 View Course Details — title, description, category, learning
/// objectives, difficulty level, thumbnail, and available lessons; plus the
/// course status (2.5). Enroll/continue actions arrive in Sprints 3–5.
class CourseDetailScreen extends StatefulWidget {
  const CourseDetailScreen({super.key, required this.courseId});

  final String courseId;

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  Course? _course;
  bool _isLoading = true;
  String? _error;
  Enrollment? _myEnrollment;
  bool _isEnrollmentLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourse();
  }

  Future<void> _loadCourse() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // 2.4 fetched through the provider -> repository contract only.
      final course =
          await context.read<CourseProvider>().loadCourseDetails(widget.courseId);
      if (!mounted) return;
      setState(() => _course = course);
      // 3.4 check whether the current student already holds an enrollment.
      await _loadEnrollmentState();
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is CourseNotFoundException
            ? 'This course could not be found.'
            : 'Could not load the course. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 3.1/3.4 — resolve the current student's enrollment for this course.
  Future<void> _loadEnrollmentState() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final enrollment = await context
        .read<EnrollmentProvider>()
        .getEnrollmentForCourse(studentId: user.id, courseId: widget.courseId);
    if (!mounted) return;
    setState(() {
      _myEnrollment = enrollment;
      _isEnrollmentLoading = false;
    });
  }

  /// 3.1 Enroll in Course.
  Future<void> _enroll() async {
    final user = context.read<AuthProvider>().user;
    if (user == null || _course == null) return;
    final enrollmentProvider = context.read<EnrollmentProvider>();
    final ok = await enrollmentProvider.enroll(
      studentId: user.id,
      courseId: _course!.id,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Enrolled in ${_course!.title}!'
              : (enrollmentProvider.error ?? 'Could not enroll.'),
        ),
      ),
    );
    if (ok) await _loadEnrollmentState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final courseProvider = context.watch<CourseProvider>();
    final course = _course;

    return Scaffold(
      appBar: AppBar(title: Text(course?.title ?? 'Course')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _loadCourse)
              : RefreshIndicator(
                  onRefresh: _loadCourse,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Thumbnail (2.4)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            course!.thumbnailUrl ?? '',
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => ColoredBox(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Icon(Icons.school_outlined,
                                  size: 48, color: theme.colorScheme.outline),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Title + status (2.4, 2.5)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              course.title,
                              style: theme.textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(
                              course.isPublished
                                  ? 'Open for enrollment'
                                  : 'Not available',
                              style: theme.textTheme.labelSmall,
                            ),
                            backgroundColor: course.isPublished
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.errorContainer,
                          ),
                        ],
                      ),

                      // Category + difficulty (2.4)
                      const SizedBox(height: 4),
                      Text(
                        '${courseProvider.categoryNameOf(course.categoryId)}'
                        '  •  ${course.difficultyLevel}',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.outline),
                      ),
                      const SizedBox(height: 16),

                      // Description (2.4)
                      Text('About this course',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(course.description,
                          style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 24),

                      // Learning objectives (2.4)
                      Text('What you will learn',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      for (final objective in course.objectives)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.check_circle_outline,
                                  size: 18, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(objective,
                                    style: theme.textTheme.bodyMedium),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Available lessons (2.4) — full lesson browsing arrives
                      // with Module 4 inside the enrolled-course workspace.
                      Text('Lessons',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        '${course.lessonIds.length} lesson(s) in this course.',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.outline),
                      ),
                      const SizedBox(height: 32),

                      // -- 3.1 / 3.4 enrollment actions -----------------------
                      if (_isEnrollmentLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (_myEnrollment != null) ...[
                        FilledButton.icon(
                          // 3.4 Access Enrolled Course.
                          onPressed: () => Navigator.of(context).pushNamed(
                            '/course-workspace',
                            arguments: course.id,
                          ),
                          icon: const Icon(Icons.play_arrow_outlined),
                          label: const Text('Continue learning'),
                        ),
                      ] else ...[
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            // 3.1 Enroll in Course.
                            onPressed: course.isPublished
                                ? _enroll
                                : null, // 2.5 drafts are not enrollable
                            icon: const Icon(Icons.how_to_reg_outlined),
                            label: Text(
                              course.isPublished
                                  ? 'Enroll in this course'
                                  : 'Not open for enrollment',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
          const SizedBox(height: 12),
          Text(message, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
