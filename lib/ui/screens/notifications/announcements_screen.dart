import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../providers/announcement_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/announcement_tile.dart';

/// 6.1 View Announcements and 6.2 Receive Course Updates (filterable).
class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  static const _filters = <String?, String>{
    null: 'All',
    'course_update': 'Course updates',
    'important': 'Important',
    'general': 'General',
    'enrollment': 'My enrollments',
  };

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnnouncementProvider>();
    final studentId = context.read<AuthProvider>().user?.id ?? '';
    final items = provider.filtered;

    return RefreshIndicator(
      color: AppTheme.goldPrimary,
      onRefresh: () => provider.load(studentId),
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const Text('Announcements',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final entry in _filters.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(entry.value),
                      selected: provider.typeFilter == entry.key,
                      onSelected: (_) => provider.setTypeFilter(entry.key),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (provider.isLoading && provider.announcements.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(child: CircularProgressIndicator(color: AppTheme.goldPrimary)),
            )
          else if (provider.error != null && provider.announcements.isEmpty)
            _Message(icon: Icons.cloud_off_rounded, text: provider.error!)
          else if (items.isEmpty)
            const _Message(icon: Icons.campaign_outlined, text: 'No announcements yet.')
          else
            ...items.map((a) => AnnouncementTile(announcement: a)),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppTheme.textMuted),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}
