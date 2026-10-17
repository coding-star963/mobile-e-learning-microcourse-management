import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../models/announcement.dart';
import '../../../providers/announcement_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/announcement_tile.dart';

/// 6.3 View Notifications (new since the last visit) and
/// 6.4 View Notification History (everything seen before).
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  /// What was new when the screen opened; kept so items stay highlighted
  /// after they are marked as seen.
  late final Set<Announcement> _newOnOpen;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AnnouncementProvider>();
    _newOnOpen = provider.unread.toSet();
    final studentId = context.read<AuthProvider>().user?.id;
    if (studentId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => provider.markAllSeen(studentId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnnouncementProvider>();
    final fresh = provider.announcements.where(_newOnOpen.contains).toList();
    final earlier = provider.announcements.where((a) => !_newOnOpen.contains(a)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: provider.announcements.isEmpty
          ? Center(
              child: Text('No notifications yet.', style: TextStyle(color: AppTheme.textMuted)),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Header('New (${fresh.length})'),
                if (fresh.isEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text("You're all caught up.", style: TextStyle(color: AppTheme.textMuted)),
                  ),
                ...fresh.map((a) => AnnouncementTile(announcement: a, isNew: true)),
                if (earlier.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const _Header('Earlier'),
                  ...earlier.map((a) => AnnouncementTile(announcement: a)),
                ],
              ],
            ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text.toUpperCase(),
            style: const TextStyle(
                color: AppTheme.goldPrimary, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1)),
      );
}
