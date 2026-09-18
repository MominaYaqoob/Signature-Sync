import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central design tokens — palette from signature_sync HTML mockups.
class AppColors {
  AppColors._();

  // Surfaces — same as HTML mockups (light content)
  static const Color primaryBackground = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFF9F7FB);
  static const Color altCardBackground = Color(0xFFF5F0FA);

  // Brand accents — Home combo only: navy / blue / purple (no pink).
  static const Color accentPink = Color(0xFFA93EFF); // aliased to purple
  static const Color accentPurple = Color(0xFFA93EFF);
  static const Color accentPurpleDark = Color(0xFF7A2AD4);
  static const Color accentBlue = Color(0xFF2D7BFF);
  static const Color accentBlueLight = Color(0xFF4C6AFF);
  static const Color accentOrange = Color(0xFF2D7BFF); // aliased to blue

  /// Professional navy for header / bottom nav (design reference).
  static const Color navy = Color(0xFF1A2744);
  static const Color navyMuted = Color(0xFFB7C2D6);
  static const Color softNavy = Color(0xFFD8DEEA);

  static const Color accentMintGreen = Color(0xFF2D7BFF); // aliased to blue
  static const Color accentGreenDark = Color(0xFF1E5FCC);
  static const Color accentGreenLight = Color(0xFF4CA1FF);

  static const Color danger = Color(0xFF2D7BFF); // keep usable, no pink

  // Soft pastel fills — navy / blue / purple family only
  static const Color softPink = Color(0xFFF0E4FF); // soft purple
  static const Color softOrange = Color(0xFFC2D6FF); // soft blue
  static const Color softBlue = Color(0xFFC2D6FF);
  static const Color softGreen = Color(0xFFC2D6FF); // soft blue
  static const Color softPurple = Color(0xFFF0E4FF);
  static const Color softSurface = Color(0xFFF7F8FB);
  static const Color softDot = Color(0xFFE8ECF4);
  static const Color softDanger = Color(0xFFE8EEF8);
  static const Color softPdf = Color(0xFFD6E4FF);

  // Text — HTML light theme
  static const Color textPrimary = Color(0xFF241A38);
  static const Color textSecondary = Color(0xFF9B95A8);
  static const Color textMuted = Color(0xFF9B95A8);
  static const Color textDark = Color(0xFF241A38);
  static const Color textOnAccent = Color(0xFFFFFFFF);

  static const Color borderSubtle = Color(0xFFF5F0FA);
  static const Color borderSoft = Color(0xFFE0D6EE);
  static const Color divider = Color(0xFFEDE7F3);
  static const Color cardShadow = Color(0x1A000000);
  static const Color wateryGlow = Color(0x33A93EFF);

  /// Brand: navy → purple → blue (Home combo)
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment(-0.8, -1),
    end: Alignment(0.8, 1),
    colors: [navy, accentPurple, accentBlue],
    stops: [0.0, 0.55, 1.0],
  );

  /// Shell / frame wash
  static const LinearGradient shellGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navy, accentBlue],
  );

  /// Primary CTA — purple only (no pink)
  static const LinearGradient purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC56BFF), accentPurple],
  );

  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4CA1FF), accentBlue],
  );

  static const LinearGradient pinkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC56BFF), accentPurple],
  );

  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4CA1FF), accentBlue],
  );

  static const LinearGradient orangeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4CA1FF), accentBlue],
  );

  /// Violet tile / CTA — light → dark purple
  static const LinearGradient violetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC56BFF), accentPurple],
  );

  /// Navy CTA alternative
  static const LinearGradient navyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF243556), navy],
  );
}

class AppRadii {
  AppRadii._();

  static const double sm = 16;
  static const double md = 20;
  static const double lg = 24;
  static const double xl = 28;
}

/// Shared padding / gap scale for tiles and cards.
class AppSpacing {
  AppSpacing._();

  static const double xs = 8;
  static const double sm = 12;
  static const double md = 14;
  static const double lg = 16;
  static const double xl = 18;

  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets tilePadding = EdgeInsets.all(sm);
}

class AppShadows {
  AppShadows._();

  /// Soft elevation for light cards (HTML-style).
  static List<BoxShadow> get card => [
        BoxShadow(
          color: AppColors.accentPurple.withValues(alpha: 0.10),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get elevated => [
        BoxShadow(
          color: AppColors.accentPurple.withValues(alpha: 0.18),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> tinted({required Color color}) => [
        BoxShadow(
          color: color.withValues(alpha: 0.28),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ];
}

class AppDecorations {
  AppDecorations._();

  /// Soft top-edge highlight — lightens the same base hue (no palette change).
  static LinearGradient sheenGradient(Color base) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.alphaBlend(Colors.white.withValues(alpha: 0.42), base),
        base,
      ],
    );
  }

  static BoxDecoration card({
    Color? color,
    double radius = AppRadii.lg,
    bool elevated = true,
    bool prominent = false,
    bool sheen = true,
    Gradient? gradient,
    Color? borderColor,
  }) {
    final base = color ?? AppColors.cardBackground;
    final wash = gradient ?? (sheen ? sheenGradient(base) : null);
    final edge = borderColor ??
        AppColors.accentPurple.withValues(alpha: 0.14);
    final shadows = !elevated
        ? null
        : (prominent ? AppShadows.elevated : AppShadows.card);

    return BoxDecoration(
      gradient: wash,
      color: wash == null ? base : null,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: edge, width: 1.2),
      boxShadow: shadows,
    );
  }

  static BoxDecoration altCard({double radius = AppRadii.lg}) {
    return card(color: AppColors.altCardBackground, radius: radius);
  }

  static BoxDecoration purpleButton({double radius = AppRadii.md}) {
    return BoxDecoration(
      gradient: AppColors.violetGradient,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 1),
      boxShadow: AppShadows.tinted(color: AppColors.accentPurple),
    );
  }

  static BoxDecoration greenButton({double radius = AppRadii.md}) {
    return BoxDecoration(
      gradient: AppColors.blueGradient,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 1),
      boxShadow: AppShadows.tinted(color: AppColors.accentBlue),
    );
  }
}

class AppTextStyles {
  AppTextStyles._();

  /// Splash / marketing hero
  static TextStyle get displayLarge => GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.2,
        letterSpacing: -0.4,
      );

  /// Onboarding hero title
  static TextStyle get headlineLarge => GoogleFonts.poppins(
        fontSize: 25,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.22,
        letterSpacing: -0.3,
      );

  /// Success / feature headlines
  static TextStyle get headlineMedium => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  /// Screen titles (Home, Settings, etc.)
  static TextStyle get titleLarge => GoogleFonts.poppins(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.25,
      );

  /// Section titles
  static TextStyle get titleMedium => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  /// Emphasized body / dialog titles
  static TextStyle get bodyLarge => GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.45,
      );

  /// Default body copy
  static TextStyle get bodyMedium => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.45,
      );

  /// Captions / meta / nav labels
  static TextStyle get bodySmall => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  /// Primary CTA on accent / gradient buttons
  static TextStyle get labelLarge => GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textOnAccent,
        letterSpacing: 0.15,
      );

  /// Secondary labels, chips
  static TextStyle get labelMedium => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        letterSpacing: 0.2,
      );

  /// Muted supporting text
  static TextStyle get secondary => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.45,
      );

  /// Welcome / eyebrow above screen titles
  static TextStyle get eyebrow => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.3,
      );

  /// Quick-action tile labels
  static TextStyle get tileLabel => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  /// Handwritten signature preview
  static TextStyle signaturePreview({Color? color, double size = 28}) =>
      GoogleFonts.greatVibes(
        fontSize: size,
        color: color ?? AppColors.accentPurple,
        height: 1.1,
      );

  /// White text for gradient / dark surfaces
  static TextStyle get onAccentTitle =>
      headlineLarge.copyWith(color: AppColors.textOnAccent);

  static TextStyle get onAccentBody => secondary.copyWith(
        color: AppColors.textOnAccent.withValues(alpha: 0.85),
      );

  static TextStyle get onAccentLabel =>
      labelLarge.copyWith(color: AppColors.textOnAccent);

  static TextStyle get link => labelMedium.copyWith(
        color: AppColors.accentPurple,
        fontWeight: FontWeight.w500,
      );
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark => light;

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.primaryBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.accentPurple,
        secondary: AppColors.accentBlue,
        surface: AppColors.cardBackground,
        onPrimary: AppColors.textOnAccent,
        onSecondary: AppColors.textOnAccent,
        onSurface: AppColors.textPrimary,
        error: AppColors.danger,
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryBackground,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.headlineMedium,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.accentPurple,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: Colors.white.withValues(alpha: 0.18),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Colors.white);
          }
          return const IconThemeData(color: Colors.white70);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? Colors.white : Colors.white70,
          );
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accentPurple,
        foregroundColor: AppColors.textOnAccent,
        elevation: 6,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.altCardBackground,
        hintStyle: AppTextStyles.secondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.accentPurple, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.accentPurple,
        textColor: AppColors.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.altCardBackground,
        contentTextStyle: AppTextStyles.bodyMedium,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
      ),
    );
  }
}
