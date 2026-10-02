import '../../models/student_dashboard.dart';

/// Contract for Module 7 — Student Dashboard (AGENT.md §4.3).
abstract class DashboardRepository {
  /// 7.1–7.4 — enrolled courses, progress, recent activity and announcements.
  Future<StudentDashboard> getDashboard(String studentId);
}
