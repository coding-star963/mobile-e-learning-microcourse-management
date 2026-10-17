import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_e_learning_micro_course_system/app.dart';
import 'package:mobile_e_learning_micro_course_system/core/theme.dart';
import 'package:mobile_e_learning_micro_course_system/data/mock/mock_auth_repository.dart';
import 'package:mobile_e_learning_micro_course_system/providers/auth_provider.dart';
import 'package:mobile_e_learning_micro_course_system/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Light and dark mode: the switch on the login screen (and home app bar)
/// changes every color in place and is remembered on the device.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => AppTheme.brightness = Brightness.dark);

  Widget appUnderTest(ThemeProvider themeProvider) => MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => AuthProvider(repo: MockAuthRepository()),
          ),
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ],
        child: const MicroLearnApp(),
      );

  Color titleColor(WidgetTester tester) =>
      tester.widget<Text>(find.text('Log in').last).style?.color ??
      DefaultTextStyle.of(tester.element(find.text('Log in').last)).style.color!;

  testWidgets('switches between dark and light mode and remembers it', (tester) async {
    final themeProvider = ThemeProvider();
    await tester.pumpWidget(appUnderTest(themeProvider));
    await tester.pumpAndSettle();

    expect(AppTheme.isDark, isTrue);
    final scaffoldBg = Theme.of(tester.element(find.byType(Scaffold).first)).scaffoldBackgroundColor;
    expect(scaffoldBg, AppTheme.dark.scaffoldBackgroundColor);

    await tester.tap(find.byTooltip('Switch to light mode'));
    await tester.pumpAndSettle();

    expect(themeProvider.mode, ThemeMode.light);
    expect(AppTheme.isDark, isFalse);
    expect(Theme.of(tester.element(find.byType(Scaffold).first)).brightness, Brightness.light);
    expect(find.byTooltip('Switch to dark mode'), findsOneWidget);
    // The login form is still there (switching keeps the screen's state).
    expect(find.text('Log in'), findsWidgets);
    expect(titleColor(tester), isNotNull);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), 'light');

    // A restart picks the saved choice back up.
    final restored = ThemeProvider();
    await restored.load();
    expect(restored.mode, ThemeMode.light);
  });

  test('light mode uses dark text on light backgrounds', () {
    AppTheme.brightness = Brightness.light;
    expect(AppTheme.bgDark.computeLuminance(), greaterThan(0.8));
    expect(AppTheme.textPrimary.computeLuminance(), lessThan(0.1));
    AppTheme.brightness = Brightness.dark;
    expect(AppTheme.bgDark.computeLuminance(), lessThan(0.05));
    expect(AppTheme.textPrimary.computeLuminance(), greaterThan(0.8));
  });
}
