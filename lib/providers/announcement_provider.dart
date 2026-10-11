import 'package:flutter/foundation.dart';

import '../data/repositories/announcement_repository.dart';
import '../models/announcement.dart';

/// State holder for Module 6 — Announcements & Notifications (6.1–6.4).
class AnnouncementProvider extends ChangeNotifier {
  AnnouncementProvider({required AnnouncementRepository repo}) : _repository = repo;

  final AnnouncementRepository _repository;

  List<Announcement> announcements = [];
  DateTime? seenAt;
  bool isLoading = false;
  String? error;

  /// 6.2 Filter: null = all, or 'course_update' / 'important' / 'general'.
  String? typeFilter;

  List<Announcement> get filtered => typeFilter == null
      ? announcements
      : announcements.where((a) => a.type == typeFilter).toList();

  /// 6.3 Notifications the student has not opened yet.
  List<Announcement> get unread => announcements
      .where((a) => seenAt == null || (a.publishedAt?.isAfter(seenAt!) ?? false))
      .toList();

  /// 6.4 Previously seen notifications.
  List<Announcement> get history =>
      announcements.where((a) => !unread.contains(a)).toList();

  int get unreadCount => unread.length;

  /// 6.1 View Announcements. [silent] refreshes in the background: no
  /// spinner, and the current list stays on screen if the request fails.
  Future<void> load(String studentId, {bool silent = false}) async {
    if (silent) {
      try {
        final latest = await _repository.getAnnouncements(studentId);
        seenAt = await _repository.getNotificationsSeenAt(studentId);
        announcements = latest;
        error = null;
        notifyListeners();
      } on Exception catch (_) {}
      return;
    }
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      announcements = await _repository.getAnnouncements(studentId);
      seenAt = await _repository.getNotificationsSeenAt(studentId);
    } on Exception catch (e) {
      error = 'Could not load announcements. $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setTypeFilter(String? type) {
    typeFilter = type;
    notifyListeners();
  }

  /// 6.3 Mark every current notification as seen.
  Future<void> markAllSeen(String studentId) async {
    final now = DateTime.now();
    await _repository.markNotificationsSeen(studentId, now);
    seenAt = now;
    notifyListeners();
  }
}
