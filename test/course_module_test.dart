import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_e_learning_micro_course_system/app.dart';
import 'package:mobile_e_learning_micro_course_system/ui/screens/course/course_detail_screen.dart';
import 'package:mobile_e_learning_micro_course_system/core/constants.dart';
import 'package:mobile_e_learning_micro_course_system/data/mock/mock_auth_repository.dart';
import 'package:mobile_e_learning_micro_course_system/data/mock/mock_course_repository.dart';
import 'package:mobile_e_learning_micro_course_system/data/mock/mock_enrollment_repository.dart';
import 'package:mobile_e_learning_micro_course_system/data/repositories/auth_repository.dart';
import 'package:mobile_e_learning_micro_course_system/data/repositories/course_repository.dart';
import 'package:mobile_e_learning_micro_course_system/data/repositories/enrollment_repository.dart';
import 'package:mobile_e_learning_micro_course_system/providers/auth_provider.dart';
import 'package:mobile_e_learning_micro_course_system/providers/course_provider.dart';
import 'package:mobile_e_learning_micro_course_system/providers/enrollment_provider.dart';
import 'package:provider/provider.dart';

/// Stabilizes mock thumbnails in widget tests: network images would otherwise
/// throw under the test binding (AGENT.md §8 — tests must not hit network).
class _TransparentMockHttpClient extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (_, _, _) => true;
    return client;
  }
}

/// Widget tests for Module 2 — Course Discovery & Browsing (2.1–2.5).
/// Mock-backed and in-memory only (AGENT.md §2, §8).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    HttpOverrides.global = _TransparentMockHttpClient();
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

  /// Logs in and waits for the catalog to finish loading (2.1).
  Future<void> loginAndOpenCatalog(WidgetTester tester) async {
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

  group('2.1 View Available Courses', () {
    testWidgets('lists published courses after login', (tester) async {
      await loginAndOpenCatalog(tester);

      expect(find.text('Intro to Flutter'), findsOneWidget);
      expect(find.text('HTML & CSS Basics'), findsOneWidget);
      // Unpublished draft must not appear in the catalog (2.1/2.5).
      expect(find.text('Serverless APIs with Node (Draft)'), findsNothing);
    });

    testWidgets('shows the empty state when a category has no courses',
        (tester) async {
      await loginAndOpenCatalog(tester);

      // 'UX & Design' has courses; use search to guarantee an empty result.
      await tester.enterText(
        find.widgetWithText(TextField, 'Search courses by title or keyword'),
        'zzz-no-match',
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.text('No courses match your search.'), findsOneWidget);
    });
  });

  group('2.2 Search Courses', () {
    testWidgets('filters courses by title keyword', (tester) async {
      await loginAndOpenCatalog(tester);

      await tester.enterText(
        find.widgetWithText(TextField, 'Search courses by title or keyword'),
        'flutter',
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.text('Intro to Flutter'), findsOneWidget);
      expect(find.text('HTML & CSS Basics'), findsNothing);
      expect(find.text('UX Research Crash Course'), findsNothing);
    });

    testWidgets('clearing search restores the full catalog', (tester) async {
      await loginAndOpenCatalog(tester);

      await tester.enterText(
        find.widgetWithText(TextField, 'Search courses by title or keyword'),
        'flutter',
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.text('HTML & CSS Basics'), findsNothing);

      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();

      expect(find.text('HTML & CSS Basics'), findsOneWidget);
      expect(find.text('Intro to Flutter'), findsOneWidget);
    });
  });

  group('2.3 Browse by Category', () {
    testWidgets('filters the catalog by a category chip', (tester) async {
      await loginAndOpenCatalog(tester);

      await tester.tap(find.widgetWithText(FilterChip, 'Web Development'));
      await tester.pumpAndSettle();

      expect(find.text('HTML & CSS Basics'), findsOneWidget);
      expect(find.text('Intro to Flutter'), findsNothing);
      expect(find.text('UX Research Crash Course'), findsNothing);
    });

    testWidgets('returns to all courses with the All chip', (tester) async {
      await loginAndOpenCatalog(tester);

      await tester.tap(find.widgetWithText(FilterChip, 'Mobile Development'));
      await tester.pumpAndSettle();
      expect(find.text('HTML & CSS Basics'), findsNothing);

      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      expect(find.text('HTML & CSS Basics'), findsOneWidget);
      expect(find.text('Intro to Flutter'), findsOneWidget);
    });
  });

  group('2.4 View Course Details', () {
    testWidgets('shows full course details when a card is tapped',
        (tester) async {
      await loginAndOpenCatalog(tester);

      // Tap the catalog card (not the AppBar title of the same name).
      await tester.tap(find.descendant(
        of: find.byType(Card),
        matching: find.text('Intro to Flutter'),
      ));
      await tester.pumpAndSettle();

      // 2.4 fields visible in the header: title (sliver bar + hero + content
      // header), status chip (2.5), category, and difficulty. Category and
      // difficulty share one combined line, so match by substring.
      expect(find.text('Intro to Flutter'), findsNWidgets(3));
      expect(find.text('Open'), findsOneWidget);
      expect(find.textContaining('Mobile Development'), findsWidgets);
      expect(find.textContaining('beginner'), findsWidgets);

      // The detail body is a lazy ListView — scroll to reveal each section.
      await tester.scrollUntilVisible(
        find.text('About this course'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('About this course'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('What you will learn'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('What you will learn'), findsOneWidget);
      expect(
        find.text('Install the Flutter SDK and tooling'),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.text('2 lesson(s) in this course.'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('2 lesson(s) in this course.'), findsOneWidget);
    });

    testWidgets('shows an error state for an unknown course id',
        (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<CourseRepository>.value(value: MockCourseRepository()),
            Provider<EnrollmentRepository>.value(
                value: MockEnrollmentRepository()),
            ChangeNotifierProvider<CourseProvider>(
              create: (_) => CourseProvider(repo: MockCourseRepository()),
            ),
            ChangeNotifierProvider<EnrollmentProvider>(
              create: (_) =>
                  EnrollmentProvider(repo: MockEnrollmentRepository()),
            ),
          ],
          child: const MaterialApp(
            home: CourseDetailScreen(courseId: 'course-does-not-exist'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('This course could not be found.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('2.5 View Course Status', () {
    testWidgets('detail page shows the open-for-enrollment status',
        (tester) async {
      await loginAndOpenCatalog(tester);

      await tester.tap(find.text('Intro to Flutter'));
      await tester.pumpAndSettle();

      // 2.5 status badge on the detail page (shortened label in the new UI).
      expect(find.text('Open'), findsOneWidget);
    });
  });
}
