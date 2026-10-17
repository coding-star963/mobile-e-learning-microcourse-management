import 'package:flutter/material.dart';

/// Luxury & Premium Theme Definition.
/// Features a prestigious obsidian-and-gold masterclass aesthetic,
/// frosted glassmorphic surfaces, subtle metallic glows, and refined typography.
class AppTheme {
  const AppTheme._();

  // Luxury Metallic & Noir Palette — gold and accents are the same in both modes.
  static const Color goldPrimary = Color(0xFFD4AF37); // Champagne / 24K Gold
  static const Color goldDark = Color(0xFFA88421);
  static const Color goldGlow = Color(0x33D4AF37);
  static const Color borderGold = Color(0x40D4AF37);

  static const Color accentEmerald = Color(0xFF10B981);
  static const Color accentSapphire = Color(0xFF38BDF8);
  static const Color accentRuby = Color(0xFFF43F5E);

  /// Brightness the neutral colors below follow. Set by the app from the
  /// active theme (see [ThemeProvider]); dark is the original look.
  static Brightness brightness = Brightness.dark;
  static bool get isDark => brightness == Brightness.dark;
  static _Palette get _p => isDark ? _Palette.dark : _Palette.light;

  // Neutral colors: they switch between dark and light mode.
  static Color get goldLight => _p.goldLight;
  static Color get bgDark => _p.background;
  static Color get bgCard => _p.card;
  static Color get bgSurface => _p.surface;
  static Color get borderLight => _p.border;
  static Color get navBar => _p.navBar;
  static Color get textPrimary => _p.textPrimary;
  static Color get textSecondary => _p.textSecondary;
  static Color get textMuted => _p.textMuted;

  // Luxury Gradients
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF7DE98), Color(0xFFD4AF37), Color(0xFFAA801E)],
  );

  static LinearGradient get darkCardGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _p.cardGradient,
      );

  static LinearGradient get heroGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: _p.heroGradient,
      );

  static BoxDecoration get luxuryCardDecoration => BoxDecoration(
        gradient: darkCardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderGold.withValues(alpha: isDark ? 0.25 : 0.45), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      );

  static ThemeData get light => _build(_Palette.light, Brightness.light);

  static ThemeData get dark => _build(_Palette.dark, Brightness.dark);

  static ThemeData _build(_Palette p, Brightness mode) {
    final bgDark = p.background;
    final bgCard = p.card;
    final bgSurface = p.surface;
    final borderLight = p.border;
    final goldLight = p.goldLight;
    final textPrimary = p.textPrimary;
    final textSecondary = p.textSecondary;
    final textMuted = p.textMuted;
    final scheme = mode == Brightness.dark ? ColorScheme.dark : ColorScheme.light;
    return ThemeData(
        useMaterial3: true,
        brightness: mode,
        scaffoldBackgroundColor: bgDark,
        colorScheme: scheme(
          primary: goldPrimary,
          onPrimary: Colors.black,
          primaryContainer: goldDark,
          secondary: goldLight,
          onSecondary: Colors.black,
          surface: bgCard,
          onSurface: textPrimary,
          error: accentRuby,
          outline: textMuted,
        ),
        appBarTheme: AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: bgDark,
          foregroundColor: textPrimary,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: bgCard,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: borderLight, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.only(bottom: 14),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: bgSurface,
          labelStyle: TextStyle(
            color: textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          side: BorderSide(color: borderLight.withValues(alpha: 0.6)),
          showCheckmark: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: borderLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: goldPrimary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: accentRuby),
          ),
          filled: true,
          fillColor: bgCard,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          labelStyle: TextStyle(color: textSecondary),
          hintStyle: TextStyle(color: textMuted),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: goldPrimary,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              letterSpacing: 0.3,
            ),
            elevation: 4,
            shadowColor: goldPrimary.withValues(alpha: 0.4),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: goldPrimary,
            side: const BorderSide(color: goldPrimary, width: 1.2),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          height: 72,
          elevation: 0,
          backgroundColor: p.navBar,
          indicatorColor: goldPrimary.withValues(alpha: 0.18),
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: goldPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              );
            }
            return TextStyle(
              color: textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: goldPrimary, size: 24);
            }
            return IconThemeData(color: textMuted, size: 22);
          }),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: bgSurface,
          contentTextStyle: TextStyle(color: textPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: borderLight),
          ),
        ),
        dividerTheme: DividerThemeData(
          color: borderLight,
          thickness: 1,
        ),
      );
  }

  static Color difficultyColor(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return accentEmerald;
      case 'intermediate':
        return goldPrimary;
      case 'advanced':
        return accentRuby;
      default:
        return textSecondary;
    }
  }
}

/// Neutral colors for one mode.
class _Palette {
  const _Palette({
    required this.background,
    required this.card,
    required this.surface,
    required this.border,
    required this.navBar,
    required this.goldLight,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.cardGradient,
    required this.heroGradient,
  });

  final Color background;
  final Color card;
  final Color surface;
  final Color border;
  final Color navBar;
  final Color goldLight;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final List<Color> cardGradient;
  final List<Color> heroGradient;

  /// The original obsidian look.
  static const dark = _Palette(
    background: Color(0xFF090D16), // Obsidian Midnight
    card: Color(0xFF121826), // Deep Slate Caviar
    surface: Color(0xFF1B2438),
    border: Color(0xFF28344D),
    navBar: Color(0xFF0E131F),
    goldLight: Color(0xFFF3D282),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFF94A3B8),
    textMuted: Color(0xFF64748B),
    cardGradient: [Color(0xFF161F33), Color(0xFF0E1422)],
    heroGradient: [Color(0xFF1C2740), Color(0xFF090D16)],
  );

  /// Ivory and gold: readable in daylight, same accents.
  static const light = _Palette(
    background: Color(0xFFF7F5EF),
    card: Color(0xFFFFFFFF),
    surface: Color(0xFFEFEBE0),
    border: Color(0xFFDDD6C4),
    navBar: Color(0xFFFFFFFF),
    goldLight: Color(0xFF8A6A12), // darker gold so gold text stays readable on white
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF475569),
    textMuted: Color(0xFF64748B),
    cardGradient: [Color(0xFFFFFFFF), Color(0xFFFAF7EF)],
    heroGradient: [Color(0xFFFFFBF0), Color(0xFFF7F5EF)],
  );
}
