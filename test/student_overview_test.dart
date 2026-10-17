import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_e_learning_micro_course_system/app.dart';
import 'package:mobile_e_learning_micro_course_system/core/constants.dart';
import 'package:mobile_e_learning_micro_course_system/data/mock/mock_auth_repository.dart';
import 'package:mobile_e_learning_micro_course_system/data/mock/mock_course_repository.dart';
import 'package:mobile_e_learning_micro_course_system/data/mock/mock_data.dart';
import 'package:mobile_e_learning_micro_course_system/data/mock/mock_enrollment_repository.dart';
import 'package:mobile_e_learning_micro_course_system/providers/auth_provider.dart';
import 'package:mobile_e_learning_micro_course_system/providers/course_provider.dart';
import 'package:mobile_e_learning_micro_course_system/providers/enrollment_provider.dart';
import 'package:mobile_e_learning_micro_course_system/data/mock/mock_lesson_repository.dart';
import 'package:mobile_e_learning_micro_course_system/providers/lesson_provider.dart';
import 'package:provider/provider.dart';

import 'support/student_overview_providers.dart';

/// Widget tests for Module 5.4 (Learning History), Module 6 (Announcements &
/// Notifications) and Module 7 (Student Dashboard). Mock-backed, in-memory.
void main() {
  setUp(MockData.reset);

  Widget appUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(repo: MockAuthRepository()),
        ),
        ChangeNotifierProvider<CourseProvider>(
          create: (_) => CourseProvider(repo: MockCourseRepository()),
        ),
        ChangeNotifierProvider<EnrollmentProvider>(
          create: (_) => EnrollmentProvider(repo: MockEnrollmentRepository()),
        ),
        ChangeNotifierProvider<LessonProvider>(
          create: (_) => LessonProvider(repo: MockLessonRepository()),
        ),
        ...studentOverviewProviders(),
      ],
      child: const MicroLearnApp(),
    );
  }

  Future<void> login(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(appUnderTest());
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Gmail address'), AppConstants.demoEmail);
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), AppConstants.demoPassword);
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();
  }

  group('7 Student Dashboard', () {
    testWidgets('7.1–7.4 shows summary, courses, continue learning and announcements',
        (tester) async {
      await login(tester);

      expect(find.text('Hi, Alex!'), findsOneWidget);
      // 7.3 Progress summary tiles.
      expect(find.text('Enrolled'), findsOneWidget);
      expect(find.text('In progress'), findsOneWidget);
      expect(find.text('Avg. progress'), findsOneWidget);
      // 5.5 Continue learning card for an unfinished course.
      expect(find.text('Continue learning'), findsOneWidget);
      // 7.2 My courses summary.
      expect(find.text('My courses'), findsOneWidget);
      expect(find.text('Data Visualization Fundamentals'), findsOneWidget);
      // 7.4 Recent announcements.
      expect(find.text('Recent announcements'), findsOneWidget);
      expect(find.text('Quiz schedule moved'), findsOneWidget);
    });

    testWidgets('5.4 opens the learning history', (tester) async {
      await login(tester);

      await tester.tap(find.text('Learning history'));
      await tester.pumpAndSettle();

      expect(find.text('Learning History'), findsOneWidget);
      expect(find.text('Completed courses'), findsOneWidget);
      expect(find.text('Completed lessons'), findsOneWidget);
      expect(find.textContaining('Welcome to Flutter Architecture'), findsOneWidget);
    });
  });

  group('6 Announcements & Notifications', () {
    testWidgets('6.1 / 6.2 lists announcements and filters course updates',
        (tester) async {
      await login(tester);
      await openTab(tester, 'Updates');

      expect(find.text('Welcome to the new semester'), findsOneWidget);
      expect(find.text('Quiz schedule moved'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Course updates'));
      await tester.pumpAndSettle();
      expect(find.text('New lesson: High-Performance Widgets & Layouts'), findsOneWidget);
      expect(find.text('Quiz schedule moved'), findsNothing);

      // Tapping opens the full announcement.
      await tester.tap(find.text('New lesson: High-Performance Widgets & Layouts'));
      await tester.pumpAndSettle();
      expect(find.text('A new lesson is now available in Intro to Flutter.'), findsOneWidget);
    });

    testWidgets('6.3 / 6.4 new notifications become history once seen', (tester) async {
      await login(tester);

      // Badge shows 3 unread notifications.
      final badge = find.descendant(of: find.byTooltip('Notifications'), matching: find.text('3'));
      expect(badge, findsOneWidget);

      await tester.tap(find.byTooltip('Notifications'));
      await tester.pumpAndSettle();
      expect(find.text('NEW (3)'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(badge, findsNothing);

      await tester.tap(find.byTooltip('Notifications'));
      await tester.pumpAndSettle();
      expect(find.text('NEW (0)'), findsOneWidget);
      expect(find.text('EARLIER'), findsOneWidget);
      expect(find.text('Welcome to the new semester'), findsOneWidget);
    });
  });
}
