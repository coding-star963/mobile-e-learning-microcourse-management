import 'announcement.dart';
import 'learning_activity.dart';

/// Student dashboard for Module 7 (7.1–7.4) and Continue Learning (5.5).
/// Mirrors `GET /dashboard` for a student. Pure Dart (AGENT.md §7).
class StudentDashboard {
  const StudentDashboard({
    this.enrolledCourses = 0,
    this.inProgressCourses = 0,
    this.completedCourses = 0,
    this.completedLessons = 0,
    this.averageProgress = 0,
    this.continueLearning,
    this.courses = const [],
    this.recentActivity = const [],
    this.recentAnnouncements = const [],
  });

  factory StudentDashboard.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] is Map ? json['summary'] as Map : const {};
    List<Map<String, dynamic>> maps(dynamic list) => list is List
        ? list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : const [];
    final continueJson = json['continue_learning'];

    return StudentDashboard(
      enrolledCourses: _toInt(summary['enrolled_courses']),
      inProgressCourses: _toInt(summary['in_progress_courses']),
      completedCourses: _toInt(summary['completed_courses']),
      completedLessons: _toInt(summary['completed_lessons']),
      averageProgress: _toDouble(summary['average_progress']),
      continueLearning: continueJson is Map
          ? DashboardCourse.fromJson(Map<String, dynamic>.from(continueJson))
          : null,
      courses: maps(json['courses']).map(DashboardCourse.fromJson).toList(),
      recentActivity: maps(json['recent_activity']).map(LearningActivity.fromJson).toList(),
      recentAnnouncements: maps(json['recent_announcements']).map(Announcement.fromJson).toList(),
    );
  }

  final int enrolledCourses;
  final int inProgressCourses;
  final int completedCourses;
  final int completedLessons;

  /// 0–100.
  final double averageProgress;

  /// 5.5 Continue Learning — the course to resume, if any.
  final DashboardCourse? continueLearning;
  final List<DashboardCourse> courses;
  final List<LearningActivity> recentActivity;
  final List<Announcement> recentAnnouncements;
}

/// One enrolled course with its progress (7.2, 7.3).
class DashboardCourse {
  const DashboardCourse({
    required this.courseId,
    required this.title,
    this.category = '',
    this.status = 'active',
    this.totalLessons = 0,
    this.completedLessons = 0,
    this.progress = 0,
    this.nextLessonId,
    this.nextLessonTitle,
  });

  factory DashboardCourse.fromJson(Map<String, dynamic> json) {
    final course = json['course'] is Map ? json['course'] as Map : const {};
    final next = json['next_lesson'] is Map ? json['next_lesson'] as Map : null;
    return DashboardCourse(
      courseId: course['id']?.toString() ?? '',
      title: (course['title'] ?? '').toString(),
      category: (course['category'] ?? '').toString(),
      status: (json['status'] ?? 'active').toString(),
      totalLessons: _toInt(json['total_lessons']),
      completedLessons: _toInt(json['completed_lessons']),
      progress: _toDouble(json['progress']),
      nextLessonId: next?['id']?.toString(),
      nextLessonTitle: next?['title']?.toString(),
    );
  }

  final String courseId;
  final String title;
  final String category;
  final String status;
  final int totalLessons;
  final int completedLessons;

  /// 0–100.
  final double progress;
  final String? nextLessonId;
  final String? nextLessonTitle;

  bool get isCompleted => status == 'completed';
}

int _toInt(dynamic value) => value is num ? value.toInt() : int.tryParse('$value') ?? 0;

double _toDouble(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
