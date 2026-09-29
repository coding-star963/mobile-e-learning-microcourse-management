import 'package:flutter/material.dart';

/// Luxury & Premium Theme Definition.
/// Features a prestigious obsidian-and-gold masterclass aesthetic,
/// frosted glassmorphic surfaces, subtle metallic glows, and refined typography.
class AppTheme {
  const AppTheme._();

  // Luxury Metallic & Noir Palette
  static const Color goldPrimary = Color(0xFFD4AF37); // Champagne / 24K Gold
  static const Color goldLight = Color(0xFFF3D282);
  static const Color goldDark = Color(0xFFA88421);
  static const Color goldGlow = Color(0x33D4AF37);

  static const Color bgDark = Color(0xFF090D16); // Obsidian Midnight
  static const Color bgCard = Color(0xFF121826); // Deep Slate Caviar
  static const Color bgSurface = Color(0xFF1B2438);
  static const Color borderLight = Color(0xFF28344D);
  static const Color borderGold = Color(0x40D4AF37);

  static const Color accentEmerald = Color(0xFF10B981);
  static const Color accentSapphire = Color(0xFF38BDF8);
  static const Color accentRuby = Color(0xFFF43F5E);

  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Luxury Gradients
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF7DE98), Color(0xFFD4AF37), Color(0xFFAA801E)],
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF161F33), Color(0xFF0E1422)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1C2740), Color(0xFF090D16)],
  );

  static BoxDecoration get luxuryCardDecoration => BoxDecoration(
        gradient: darkCardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderGold.withValues(alpha: 0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      );

  static ThemeData get light => dark; // Default directly to Luxury Dark for full premium feel

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bgDark,
        colorScheme: ColorScheme.dark(
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
        appBarTheme: const AppBarTheme(
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
            side: const BorderSide(color: borderLight, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.only(bottom: 14),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: bgSurface,
          labelStyle: const TextStyle(
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
            borderSide: const BorderSide(color: borderLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: borderLight),
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
          labelStyle: const TextStyle(color: textSecondary),
          hintStyle: const TextStyle(color: textMuted),
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
          backgroundColor: Color(0xFF0E131F),
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
            return const TextStyle(
              color: textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: goldPrimary, size: 24);
            }
            return const IconThemeData(color: textMuted, size: 22);
          }),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: bgSurface,
          contentTextStyle: const TextStyle(color: textPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: borderLight),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: borderLight,
          thickness: 1,
        ),
      );

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
