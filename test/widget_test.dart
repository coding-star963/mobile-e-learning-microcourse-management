import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_e_learning_micro_course_system/app.dart';
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
import 'package:mobile_e_learning_micro_course_system/data/mock/mock_lesson_repository.dart';
import 'package:mobile_e_learning_micro_course_system/providers/lesson_provider.dart';
import 'package:provider/provider.dart';

import 'support/student_overview_providers.dart';

/// Widget tests for Module 1 — Authentication & Profile Management (1.1–1.4).
/// Mock-backed and in-memory only (AGENT.md §2, §8).
void main() {
  AuthRepository authRepository = MockAuthRepository();

  Widget appUnderTest() {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: authRepository),
        Provider<CourseRepository>.value(value: MockCourseRepository()),
        Provider<EnrollmentRepository>.value(value: MockEnrollmentRepository()),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(repo: authRepository),
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

  Future<void> typeCredentials(WidgetTester tester) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      AppConstants.demoEmail,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      AppConstants.demoPassword,
    );
  }

  group('1.1 Login', () {
    testWidgets('logs in with valid demo credentials and shows home shell',
        (tester) async {
      await tester.pumpWidget(appUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNWidgets(2));
      await typeCredentials(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
      await tester.pumpAndSettle();

      // Home shell opens on the student dashboard (Module 7)...
      expect(find.text('MicroLearn'), findsOneWidget);
      expect(find.text('Hi, Alex!'), findsOneWidget);
      expect(find.text('Enrolled'), findsOneWidget);

      // ...and hosts the course catalog (Module 2) in the Courses tab.
      await openTab(tester, 'Courses');
      expect(find.widgetWithText(TextField, 'Search courses by title or keyword'),
          findsOneWidget);
    });

    testWidgets('rejects wrong credentials with a friendly error',
        (tester) async {
      await tester.pumpWidget(appUnderTest());
      await tester.pumpAndSettle();

      await typeCredentials(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'wrong-password',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
      await tester.pumpAndSettle();

      expect(find.text('Incorrect email or password.'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2)); // still on login
    });

    testWidgets('blocks submit while a login is in flight', (tester) async {
      await tester.pumpWidget(appUnderTest());
      await tester.pump();

      await typeCredentials(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
      await tester.pump(); // loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });

  group('1.2 Logout', () {
    testWidgets('logs out from the home shell and returns to login',
        (tester) async {
      await tester.pumpWidget(appUnderTest());
      await tester.pumpAndSettle();

      await typeCredentials(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
      await tester.pumpAndSettle();
      expect(find.text('MicroLearn'), findsOneWidget);

      // 1.2 Logout via the app bar action + confirmation dialog.
      await tester.tap(find.byTooltip('Log out'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNWidgets(2)); // back to login
    });
  });

  group('1.3 Password Recovery', () {
    testWidgets('verifies the email then sets a new password (no OTP)', (tester) async {
      await tester.pumpWidget(appUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        AppConstants.demoEmail,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();

      // Step 2: straight to the new password form, no token field.
      expect(find.text('Set a new password'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Reset token'), findsNothing);
      // Reuse the demo password so later tests can still log in (shared mock state).
      await tester.enterText(find.widgetWithText(TextFormField, 'New password'), AppConstants.demoPassword);
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm new password'), AppConstants.demoPassword);
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Reset password'));
      await tester.tap(find.widgetWithText(FilledButton, 'Reset password'));
      await tester.pumpAndSettle();

      // Returns to the login screen after success.
      expect(find.widgetWithText(FilledButton, 'Log in'), findsOneWidget);
    });

    testWidgets('rejects an unknown email with a friendly error',
        (tester) async {
      await tester.pumpWidget(appUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'nobody@nowhere.com',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();

      expect(
        find.text('No account found with that email address.'),
        findsOneWidget,
      );
    });
  });

  group('1.4 Profile Management', () {
    testWidgets('shows the logged-in student profile', (tester) async {
      await tester.pumpWidget(appUnderTest());
      await tester.pumpAndSettle();

      await typeCredentials(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('My profile'));
      await tester.pumpAndSettle();

      expect(find.text('My Profile'), findsOneWidget);
      expect(
        (tester.widget(find.widgetWithText(TextFormField, 'Full name'))
                as TextFormField)
            .controller!
            .text,
        'Alex Rivera',
      );
      expect(
        (tester.widget(find.widgetWithText(TextFormField, 'Email'))
                as TextFormField)
            .controller!
            .text,
        AppConstants.demoEmail,
      );
    });

    testWidgets('updates the display name in memory', (tester) async {
      await tester.pumpWidget(appUnderTest());
      await tester.pumpAndSettle();

      await typeCredentials(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('My profile'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Full name'),
        'Jordan Lee',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
      await tester.pumpAndSettle();

      expect(find.text('Profile updated.'), findsOneWidget);
    });
  });

  group('1.4 Change password', () {
    testWidgets('requires the correct current password', (tester) async {
      await tester.pumpWidget(appUnderTest());
      await tester.pumpAndSettle();

      await typeCredentials(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('My profile'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Current password'),
        'wrong',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'New password'),
        'newSecret123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm new password'),
        'newSecret123',
      );
      await tester.ensureVisible(
        find.widgetWithText(OutlinedButton, 'Update password'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Update password'));
      await tester.pumpAndSettle();

      expect(find.text('Current password is incorrect.'), findsOneWidget);
    });
  });

  group('Navigation & Login UI', () {
    testWidgets('does not display Server Configuration on the login screen',
        (tester) async {
      await tester.pumpWidget(appUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Server Configuration'), findsNothing);
      expect(find.byIcon(Icons.dns_outlined), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Log in'), findsOneWidget);
    });

    testWidgets(
        'navigating back from profile and course details returns to home, not login',
        (tester) async {
      await tester.pumpWidget(appUnderTest());
      await tester.pumpAndSettle();

      // 1. Log in
      await typeCredentials(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
      await tester.pumpAndSettle();
      expect(find.text('MicroLearn'), findsOneWidget);

      // 2. Go to Profile
      await tester.tap(find.byTooltip('My profile'));
      await tester.pumpAndSettle();
      expect(find.text('My Profile'), findsOneWidget);

      // 3. Back from Profile
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // MUST be on HomeShell, NOT on LoginScreen
      expect(find.text('MicroLearn'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Log in'), findsNothing);

      // 4. Logout should properly take user back to LoginScreen
      await tester.tap(find.byTooltip('Log out'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Log in'), findsOneWidget);
    });
  });
}
