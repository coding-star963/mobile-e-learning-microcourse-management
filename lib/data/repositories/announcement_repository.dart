import '../../models/announcement.dart';

/// Contract for Module 6 — Announcements & Notifications (AGENT.md §4.3).
abstract class AnnouncementRepository {
  /// 6.1 / 6.2 / 6.4 — published announcements for the student's courses and
  /// general announcements, newest first.
  Future<List<Announcement>> getAnnouncements(String studentId);

  /// 6.3 — when the student last opened their notifications (null = never).
  Future<DateTime?> getNotificationsSeenAt(String studentId);

  /// 6.3 — remember that the student has seen everything up to [seenAt].
  Future<void> markNotificationsSeen(String studentId, DateTime seenAt);
}
