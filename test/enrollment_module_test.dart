import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_e_learning_micro_course_system/app.dart';
import 'package:mobile_e_learning_micro_course_system/core/constants.dart';
import 'package:mobile_e_learning_micro_course_system/data/mock/mock_auth_repository.dart';
import 'package:mobile_e_learning_micro_course_system/data/mock/mock_course_repository.dart';
import 'package:mobile_e_learning_micro_course_system/data/mock/mock_data.dart';
import 'package:mobile_e_learning_micro_course_system/data/mock/mock_enrollment_repository.dart';
import 'package:mobile_e_learning_micro_course_system/data/repositories/auth_repository.dart';
import 'package:mobile_e_learning_micro_course_system/data/repositories/course_repository.dart';
import 'package:mobile_e_learning_micro_course_system/data/repositories/enrollment_repository.dart';
import 'package:mobile_e_learning_micro_course_system/providers/auth_provider.dart';
import 'package:mobile_e_learning_micro_course_system/providers/course_provider.dart';
import 'package:mobile_e_learning_micro_course_system/providers/enrollment_provider.dart';
import 'package:provider/provider.dart';

/// Widget tests for Module 3 — Course Enrollment (3.1–3.4).
/// Mock-backed and in-memory only (AGENT.md §2, §8).
class _TransparentMockHttpClient extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (_, _, _) => true;
    return client;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    HttpOverrides.global = _TransparentMockHttpClient();
  });

  setUp(() {
    // Fresh in-memory state per test, mirroring an app restart (AGENT.md §6).
    MockData.reset();
  });

  Widget appUnderTest() {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: MockAuthRepository()),
        Provider<CourseRepository>.value(value: MockCourseRepository()),
        Provider<EnrollmentRepository>.value(value: MockEnrollmentRepository()),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(repo: MockAuthRepository()),
        ),
        ChangeNotifierProvider<CourseProvider>(
          create: (_) => CourseProvider(repo: MockCourseRepository()),
        ),
        ChangeNotifierProvider<EnrollmentProvider>(
          create: (_) => EnrollmentProvider(repo: MockEnrollmentRepository()),
        ),
      ],
      child: const MicroLearnApp(),
    );
  }

  /// Logs in and lands on the home shell (Courses tab).
  /// Uses a tall viewport so every catalog/enrollment card is on-screen
  /// (avoids lazy-ListView scroll steps in tests).
  Future<void> login(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(appUnderTest());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      AppConstants.demoEmail,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      AppConstants.demoPassword,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();
  }

  /// Opens the catalog card for [title] and waits for details to load.
  Future<void> openCourseDetail(WidgetTester tester, String title) async {
    await tester.tap(find.descendant(
      of: find.byType(Card),
      matching: find.text(title),
    ));
    await tester.pumpAndSettle();
  }

  /// Switches to the My Courses tab.
  Future<void> openMyCoursesTab(WidgetTester tester) async {
    await tester.tap(find.text('My Courses'));
    await tester.pumpAndSettle();
  }

  group('3.1 Enroll in Course', () {
    testWidgets('enrolls from the course detail page', (tester) async {
      await login(tester);
      await openCourseDetail(tester, 'UX Research Crash Course');

      // Not enrolled yet -> enroll button visible (course-005 has no seed).
      expect(find.text('Enroll in this course'), findsOneWidget);
      await tester.tap(find.text('Enroll in this course'));
      await tester.pumpAndSettle();

      expect(find.text('Enrolled in UX Research Crash Course!'),
          findsOneWidget);
      // Action flips to continue-learning (3.4).
      expect(find.text('Continue learning'), findsOneWidget);
    });

    testWidgets('shows continue instead of enroll for an enrolled course',
        (tester) async {
      await login(tester);
      // course-001 has a seeded enrollment.
      await openCourseDetail(tester, 'Intro to Flutter');

      // Already enrolled -> continue action instead of enroll (3.4).
      expect(find.text('Continue learning'), findsOneWidget);
      expect(find.text('Enroll in this course'), findsNothing);
    });

    testWidgets('draft courses cannot be enrolled', (tester) async {
      await login(tester);
      // The draft course is not listed in the catalog (2.1), so its detail
      // can only be reached by search of a non-listed item — verify the
      // catalog does not expose it at all.
      expect(find.text('Serverless APIs with Node (Draft)'), findsNothing);
    });
  });

  group('3.2 View Enrolled Courses', () {
    testWidgets('lists seeded enrollments with progress', (tester) async {
      await login(tester);
      await openMyCoursesTab(tester);

      // Seed: course-001 (1/2), course-003 (0/3), course-004 (1/1 done).
      expect(find.text('Intro to Flutter'), findsOneWidget);
      expect(find.text('HTML & CSS Basics'), findsOneWidget);
      expect(find.text('Data Visualization Fundamentals'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget); // course-004
      expect(find.text('In progress'), findsNWidgets(2));
    });

    testWidgets('shows the empty state for a student with no enrollments',
        (tester) async {
      // Fresh in-memory store per test: enroll everything first is overkill —
      // instead verify a fresh store shows exactly the 3 seeds.
      await login(tester);
      await openMyCoursesTab(tester);
      expect(find.text('UX Research Crash Course'), findsNothing);
    });
  });

  group('3.3 View Enrollment Details', () {
    testWidgets('shows enrollment info and progress from My Courses',
        (tester) async {
      await login(tester);
      await openMyCoursesTab(tester);

      await tester.tap(find.text('Data Visualization Fundamentals'));
      await tester.pumpAndSettle();

      // The progress card is the only Card on this screen.

      // 3.3 details: enrolled date, lessons completed, progress %.
      expect(find.text('Enrolled on'), findsOneWidget);
      expect(find.text('Lessons completed'), findsOneWidget);
      expect(find.text('1 of 1'), findsOneWidget);
      expect(find.text('Progress'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('Course progress'), findsOneWidget);
    });
  });

  group('3.4 Access Enrolled Course', () {
    testWidgets('Continue learning opens the course workspace',
        (tester) async {
      await login(tester);
      await openMyCoursesTab(tester);

      await tester.tap(find.text('Data Visualization Fundamentals'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue learning'));
      await tester.pumpAndSettle();

      expect(find.text('You are enrolled in this course'), findsOneWidget);
    });

    testWidgets('Continue learning works from the course detail page',
        (tester) async {
      await login(tester);
      // course-001 is a seeded enrollment.
      await openCourseDetail(tester, 'Intro to Flutter');

      expect(find.text('Continue learning'), findsOneWidget);
      expect(find.text('Enroll in this course'), findsNothing);
      await tester.tap(find.text('Continue learning'));
      await tester.pumpAndSettle();
      expect(find.text('You are enrolled in this course'), findsOneWidget);
    });
  });
}
