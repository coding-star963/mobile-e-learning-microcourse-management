import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../models/course.dart';
import '../../../models/enrollment.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/course_provider.dart';
import '../../../providers/enrollment_provider.dart';
import '../../../data/repositories/course_repository.dart';

/// 2.4 View Course Details — title, description, category, learning
/// objectives, difficulty level, thumbnail, and available lessons; plus the
/// course status (2.5). Enrollment actions: 3.1 Enroll / 3.4 Continue.
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
      final course = await context
          .read<CourseProvider>()
          .loadCourseDetails(widget.courseId);
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
    final courseProvider = context.watch<CourseProvider>();
    final course = _course;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _loadCourse)
              : RefreshIndicator(
                  onRefresh: _loadCourse,
                  child: CustomScrollView(
                    slivers: [
                      // -- Gradient hero header (2.4) ----------------------
                      SliverAppBar(
                        expandedHeight: 220,
                        pinned: true,
                        title: Text(course!.title),
                        flexibleSpace: FlexibleSpaceBar(
                          background: _HeroHeader(
                            course: course,
                            categoryName: courseProvider
                                .categoryNameOf(course.categoryId),
                          ),
                        ),
                      ),

                      // -- Content ------------------------------------------
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title + status (2.4, 2.5)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      course.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _StatusBadge(isPublished: course.isPublished),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Category + difficulty (2.4)
                              Text(
                                '${courseProvider.categoryNameOf(course.categoryId)}'
                                '  •  ${course.difficultyLevel}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color:
                                            Theme.of(context).colorScheme.outline),
                              ),
                              const SizedBox(height: 24),

                              // Description (2.4)
                              _SectionHeader(
                                icon: Icons.info_outline,
                                title: 'About this course',
                              ),
                              const SizedBox(height: 8),
                              Text(course.description,
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                              const SizedBox(height: 24),

                              // Learning objectives (2.4)
                              _SectionHeader(
                                icon: Icons.track_changes_outlined,
                                title: 'What you will learn',
                              ),
                              const SizedBox(height: 8),
                              for (final objective in course.objectives)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 22,
                                        height: 22,
                                        margin:
                                            const EdgeInsets.only(right: 10),
                                        decoration: BoxDecoration(
                                          color: AppTheme.accentTeal
                                              .withValues(alpha: 0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.check,
                                            size: 14,
                                            color: AppTheme.accentTeal),
                                      ),
                                      Expanded(
                                        child: Text(objective,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 24),

                              // Available lessons (2.4)
                              _SectionHeader(
                                icon: Icons.play_lesson_outlined,
                                title: 'Lessons',
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.format_list_numbered_outlined,
                                      size: 16,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${course.lessonIds.length} lesson(s) in this course.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      // -- Sticky bottom action bar: 3.1 Enroll / 3.4 Continue -------------
      bottomNavigationBar: (_isLoading || _error != null)
          ? null
          : Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 14,
                bottom: MediaQuery.of(context).padding.bottom + 14,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: _isEnrollmentLoading
                  ? const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _myEnrollment != null
                      ? FilledButton.icon(
                          // 3.4 Access Enrolled Course.
                          onPressed: () => Navigator.of(context).pushNamed(
                            '/course-workspace',
                            arguments: course!.id,
                          ),
                          icon: const Icon(Icons.play_arrow_outlined),
                          label: const Text('Continue learning'),
                        )
                      : SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            // 3.1 Enroll in Course.
                            onPressed:
                                course!.isPublished ? _enroll : null,
                            icon: const Icon(Icons.how_to_reg_outlined),
                            label: Text(
                              course.isPublished
                                  ? 'Enroll in this course'
                                  : 'Not open for enrollment',
                            ),
                          ),
                        ),
            ),
    );
  }
}

/// Gradient hero with thumbnail-free brand background, title, category, and
/// difficulty badge (2.4).
class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.course, required this.categoryName});

  final Course course;
  final String categoryName;

  @override
  Widget build(BuildContext context) {
    final difficultyColor = AppTheme.difficultyColor(course.difficultyLevel);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.deepNavy, AppTheme.seedColor, AppTheme.accentTeal],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: difficultyColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                course.difficultyLevel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              course.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.category_outlined,
                    size: 14, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  categoryName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(width: 14),
                Icon(Icons.play_lesson_outlined,
                    size: 14, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  '${course.lessonIds.length} lessons',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 2.5 status badge shown next to the title.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isPublished});

  final bool isPublished;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isPublished
            ? AppTheme.accentTeal.withValues(alpha: 0.12)
            : theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPublished ? Icons.check_circle_outline : Icons.lock_outline,
            size: 14,
            color: isPublished
                ? AppTheme.accentTeal
                : theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 4),
          Text(
            isPublished ? 'Open' : 'Not available',
            style: theme.textTheme.labelSmall?.copyWith(
              color: isPublished
                  ? AppTheme.accentTeal
                  : theme.colorScheme.onErrorContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section title with a small leading icon.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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
