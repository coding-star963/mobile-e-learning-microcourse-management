import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/course_provider.dart';

/// 3.4 Access Enrolled Course — the enrolled-course workspace where the
/// student opens and continues learning. Lesson content lands here in
/// Sprint 4 (Module 4); for now it shows the lesson plan and progress.
class CourseWorkspaceScreen extends StatelessWidget {
  const CourseWorkspaceScreen({super.key, required this.courseId});

  final String courseId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final courseProvider = context.watch<CourseProvider>();
    final course = courseProvider.cachedCourseDetails(courseId);
    final lessonCount = course?.lessonIds.length ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(course?.title ?? 'Course')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_lesson_outlined,
                  size: 72, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'You are enrolled in this course',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                lessonCount > 0
                    ? 'This course has $lessonCount lesson(s). Lessons, videos, '
                        'and resources arrive in the next sprint.'
                    : 'Lessons, videos, and resources arrive in the next sprint.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
