import 'package:shared_preferences/shared_preferences.dart';

import '../../models/announcement.dart';
import '../repositories/announcement_repository.dart';
import 'api_client.dart';

/// Module 6 against the Laravel REST API. The server only returns published
/// announcements for all courses or the student's enrolled courses.
class RestAnnouncementRepository implements AnnouncementRepository {
  final ApiClient _api = ApiClient.instance;

  /// Announcements plus the student's personal notices (type "enrollment":
  /// a teacher enrolled, suspended, reactivated, cancelled or deleted one of
  /// their enrollments), newest first.
  @override
  Future<List<Announcement>> getAnnouncements(String studentId) async {
    final results = await Future.wait([
      _api.get('/announcements', query: {'per_page': 100}),
      _api.get('/notifications', query: {'per_page': 50}),
    ]);
    final res = results[0];
    if (!res.isSuccess) _api.fail(res, 'Could not load announcements.');
    final list = ApiClient.dataList(res.data).map(Announcement.fromJson).toList();
    // Personal notices are optional: announcements still show if they fail.
    if (results[1].isSuccess) {
      list.addAll(ApiClient.dataList(results[1].data).map(Announcement.fromJson));
    }
    list.sort((a, b) => (b.publishedAt ?? DateTime(0)).compareTo(a.publishedAt ?? DateTime(0)));
    return list;
  }

  /// 6.3 The "seen" time is kept on this device, per student.
  @override
  Future<DateTime?> getNotificationsSeenAt(String studentId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_seenKey(studentId));
    return raw == null ? null : DateTime.tryParse(raw);
  }

  @override
  Future<void> markNotificationsSeen(String studentId, DateTime seenAt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_seenKey(studentId), seenAt.toIso8601String());
  }

  static String _seenKey(String studentId) => 'notifications_seen_at_$studentId';
}
