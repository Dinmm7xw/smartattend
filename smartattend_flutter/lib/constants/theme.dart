import 'package:flutter/material.dart';

// ── SmartAttend — Clean iOS-inspired Design System ─────────
class AppColors {
  // Primary
  static const Color primary = Color(0xFF007AFF);
  static const Color primaryLight = Color(0xFFE8F2FF);
  static const Color primaryDark = Color(0xFF0056CC);

  // Backgrounds
  static const Color background = Color(0xFFF2F2F7);   // iOS grouped
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFF9F9F9);

  // Text
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textTertiary = Color(0xFFC7C7CC);

  // System colors (iOS palette)
  static const Color success = Color(0xFF34C759);
  static const Color successLight = Color(0xFFE8F9ED);
  static const Color warning = Color(0xFFFF9500);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color danger = Color(0xFFFF3B30);
  static const Color dangerLight = Color(0xFFFFEBEA);
  static const Color info = Color(0xFF007AFF);
  static const Color infoLight = Color(0xFFE8F2FF);

  // Teacher / Dean
  static const Color teacher = Color(0xFF5856D6);
  static const Color teacherLight = Color(0xFFEEEDFB);
  static const Color dean = Color(0xFFFF9500);
  static const Color deanLight = Color(0xFFFFF3E0);

  // Separator
  static const Color separator = Color(0xFFE5E5EA);
  static const Color separatorOpaque = Color(0xFFC6C6C8);

  // Scanner
  static const Color scanFrame = Color(0xFF007AFF);
  static const Color scanLine = Color(0xFF007AFF);
}

class AppRadius {
  static const double xs = 6.0;
  static const double sm = 10.0;
  static const double md = 14.0;
  static const double lg = 18.0;
  static const double xl = 22.0;
  static const double xxl = 28.0;
  static const double pill = 100.0;
}

class AppShadows {
  static List<BoxShadow> get card => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get button => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.35),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get tabBar => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, -2),
        ),
      ];
}

class AppTextStyles {
  static const String font = 'Inter';

  static const TextStyle largeTitle = TextStyle(
    fontFamily: font, fontSize: 34, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, letterSpacing: 0.37,
  );
  static const TextStyle title1 = TextStyle(
    fontFamily: font, fontSize: 28, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static const TextStyle title2 = TextStyle(
    fontFamily: font, fontSize: 22, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static const TextStyle title3 = TextStyle(
    fontFamily: font, fontSize: 20, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle headline = TextStyle(
    fontFamily: font, fontSize: 17, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle body = TextStyle(
    fontFamily: font, fontSize: 17, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );
  static const TextStyle callout = TextStyle(
    fontFamily: font, fontSize: 16, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );
  static const TextStyle subheadline = TextStyle(
    fontFamily: font, fontSize: 15, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  static const TextStyle footnote = TextStyle(
    fontFamily: font, fontSize: 13, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  static const TextStyle caption1 = TextStyle(
    fontFamily: font, fontSize: 12, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  static const TextStyle caption2 = TextStyle(
    fontFamily: font, fontSize: 11, fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
  );
}

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        fontFamily: AppTextStyles.font,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          surface: AppColors.surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            textStyle: const TextStyle(
              fontFamily: AppTextStyles.font,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.separator),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.separator),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
      );
}
