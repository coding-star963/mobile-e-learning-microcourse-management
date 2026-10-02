import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_e_learning_micro_course_system/data/mock/mock_announcement_repository.dart';
import 'package:mobile_e_learning_micro_course_system/data/mock/mock_dashboard_repository.dart';
import 'package:mobile_e_learning_micro_course_system/data/mock/mock_progress_repository.dart';
import 'package:mobile_e_learning_micro_course_system/providers/announcement_provider.dart';
import 'package:mobile_e_learning_micro_course_system/providers/dashboard_provider.dart';
import 'package:mobile_e_learning_micro_course_system/providers/progress_provider.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Mock-backed providers for the home shell's dashboard (Module 7),
/// announcements (Module 6) and learning history (5.4).
List<SingleChildWidget> studentOverviewProviders() => [
      ChangeNotifierProvider<AnnouncementProvider>(
        create: (_) => AnnouncementProvider(repo: MockAnnouncementRepository()),
      ),
      ChangeNotifierProvider<DashboardProvider>(
        create: (_) => DashboardProvider(repo: MockDashboardRepository()),
      ),
      ChangeNotifierProvider<ProgressProvider>(
        create: (_) => ProgressProvider(repo: MockProgressRepository()),
      ),
    ];

/// Switches the home shell to the tab with [label] (Home, Courses, My Courses, Updates).
Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
  await tester.pumpAndSettle();
}
