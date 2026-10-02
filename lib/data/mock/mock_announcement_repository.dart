import '../../core/constants.dart';
import '../../models/announcement.dart';
import '../repositories/announcement_repository.dart';
import 'mock_data.dart';

/// Mock implementation of [AnnouncementRepository] (Module 6).
class MockAnnouncementRepository implements AnnouncementRepository {
  @override
  Future<List<Announcement>> getAnnouncements(String studentId) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    final list = MockData.announcements;
    list.sort((a, b) => (b.publishedAt ?? DateTime(0)).compareTo(a.publishedAt ?? DateTime(0)));
    return list;
  }

  @override
  Future<DateTime?> getNotificationsSeenAt(String studentId) async =>
      MockData.notificationsSeenAt[studentId];

  @override
  Future<void> markNotificationsSeen(String studentId, DateTime seenAt) async {
    MockData.notificationsSeenAt[studentId] = seenAt;
  }
}
