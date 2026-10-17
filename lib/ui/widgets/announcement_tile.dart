import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/announcement.dart';

/// One announcement in a list (6.1–6.4, 7.4). Tapping opens the full text.
class AnnouncementTile extends StatelessWidget {
  const AnnouncementTile({
    super.key,
    required this.announcement,
    this.isNew = false,
  });

  final Announcement announcement;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final a = announcement;
    final color = a.isImportant
        ? AppTheme.accentRuby
        : (a.isCourseUpdate || a.isEnrollmentNotice
            ? AppTheme.accentEmerald
            : AppTheme.goldPrimary);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNew ? color.withValues(alpha: 0.6) : AppTheme.borderLight,
        ),
      ),
      // Transparent Material so the ListTile's tap ripple shows on the card.
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6,
          ),
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(
              a.isImportant
                  ? Icons.priority_high_rounded
                  : (a.isEnrollmentNotice
                        ? Icons.how_to_reg_rounded
                        : (a.isCourseUpdate
                              ? Icons.update_rounded
                              : Icons.campaign_outlined)),
              color: color,
              size: 20,
            ),
          ),
          title: Text(
            a.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: isNew ? FontWeight.w800 : FontWeight.w600,
              fontSize: 14,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${a.typeLabel} • ${a.courseTitle ?? (a.isEnrollmentNotice ? 'Your account' : 'All courses')}${a.publishedAt != null ? ' • ${formatShortDate(a.publishedAt!)}' : ''}',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ),
          trailing: isNew
              ? Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
          onTap: () => showAnnouncementSheet(context, a),
        ),
      ),
    );
  }
}

/// Full announcement text in a bottom sheet.
Future<void> showAnnouncementSheet(BuildContext context, Announcement a) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppTheme.bgCard,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              a.typeLabel.toUpperCase(),
              style: const TextStyle(
                color: AppTheme.goldPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              a.title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              [
                a.courseTitle ?? (a.isEnrollmentNotice ? 'Your account' : 'All courses'),
                if (a.authorName != null) a.authorName!,
                if (a.publishedAt != null) formatShortDate(a.publishedAt!),
              ].join(' • '),
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 18),
            Text(
              a.content,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// e.g. "Sep 25, 2026".
String formatShortDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
