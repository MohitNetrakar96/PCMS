// ============================================================
// theme.dart — PCMS Material 3 Theme
// Banking / Fintech Field-Collection App
// ============================================================
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// 1. RAW PALETTE
// ─────────────────────────────────────────────────────────────

abstract final class AppPalette {
  static const Color primary = Color(0xFF0B2545);
  static const Color primaryContainer = Color(0xFFD6E4F7);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF0B2545);

  static const Color secondary = Color(0xFF4A6280);
  static const Color secondaryContainer = Color(0xFFDDE5F0);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF1E3048);

  static const Color tertiary = Color(0xFF13A085);
  static const Color tertiaryContainer = Color(0xFFBEF0E6);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFF003D30);

  static const Color success = Color(0xFF13A085);
  static const Color successContainer = Color(0xFFBEF0E6);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color onSuccessContainer = Color(0xFF003D30);

  static const Color warning = Color(0xFFF2A93B);
  static const Color warningContainer = Color(0xFFFEEDCC);
  static const Color onWarning = Color(0xFF1C1C1E);
  static const Color onWarningContainer = Color(0xFF4A2E00);

  static const Color error = Color(0xFFD64545);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF5C0000);

  static const Color locked = Color(0xFF6C6C80);
  static const Color lockedContainer = Color(0xFFE5E5EE);
  static const Color onLocked = Color(0xFFFFFFFF);
  static const Color onLockedContainer = Color(0xFF1C1C2E);

  static const Color background = Color(0xFFF7F9FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEFF3F8);
  static const Color surfaceTint = Color(0xFF0B2545);
  static const Color outline = Color(0xFFB0BEC5);
  static const Color outlineVariant = Color(0xFFD0D9E3);
  static const Color scrim = Color(0xFF000000);

  static const Color textPrimary = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF4A6280);
  static const Color textDisabled = Color(0xFFADB5BD);
  static const Color textOnDark = Color(0xFFFFFFFF);

  static const Color shadow = Color(0x14000000);
  static const Color shadowStrong = Color(0x1F000000);
}

// ─────────────────────────────────────────────────────────────
// 2. THEME EXTENSION  — AppColors
// ─────────────────────────────────────────────────────────────

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.success,
    required this.successContainer,
    required this.onSuccess,
    required this.onSuccessContainer,
    required this.warning,
    required this.warningContainer,
    required this.onWarning,
    required this.onWarningContainer,
    required this.locked,
    required this.lockedContainer,
    required this.onLocked,
    required this.onLockedContainer,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
  });

  final Color success;
  final Color successContainer;
  final Color onSuccess;
  final Color onSuccessContainer;
  final Color warning;
  final Color warningContainer;
  final Color onWarning;
  final Color onWarningContainer;
  final Color locked;
  final Color lockedContainer;
  final Color onLocked;
  final Color onLockedContainer;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>()!;

  StatusChipStyle statusChip(CollectionStatus status) =>
      StatusChipStyles.of(status, this);

  @override
  AppColors copyWith({
    Color? success, Color? successContainer, Color? onSuccess,
    Color? onSuccessContainer, Color? warning, Color? warningContainer,
    Color? onWarning, Color? onWarningContainer, Color? locked,
    Color? lockedContainer, Color? onLocked, Color? onLockedContainer,
    Color? textPrimary, Color? textSecondary, Color? textDisabled,
  }) => AppColors(
    success: success ?? this.success,
    successContainer: successContainer ?? this.successContainer,
    onSuccess: onSuccess ?? this.onSuccess,
    onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
    warning: warning ?? this.warning,
    warningContainer: warningContainer ?? this.warningContainer,
    onWarning: onWarning ?? this.onWarning,
    onWarningContainer: onWarningContainer ?? this.onWarningContainer,
    locked: locked ?? this.locked,
    lockedContainer: lockedContainer ?? this.lockedContainer,
    onLocked: onLocked ?? this.onLocked,
    onLockedContainer: onLockedContainer ?? this.onLockedContainer,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textDisabled: textDisabled ?? this.textDisabled,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      onSuccessContainer: Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      onWarningContainer: Color.lerp(onWarningContainer, other.onWarningContainer, t)!,
      locked: Color.lerp(locked, other.locked, t)!,
      lockedContainer: Color.lerp(lockedContainer, other.lockedContainer, t)!,
      onLocked: Color.lerp(onLocked, other.onLocked, t)!,
      onLockedContainer: Color.lerp(onLockedContainer, other.onLockedContainer, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
    );
  }

  static const light = AppColors(
    success: AppPalette.success,
    successContainer: AppPalette.successContainer,
    onSuccess: AppPalette.onSuccess,
    onSuccessContainer: AppPalette.onSuccessContainer,
    warning: AppPalette.warning,
    warningContainer: AppPalette.warningContainer,
    onWarning: AppPalette.onWarning,
    onWarningContainer: AppPalette.onWarningContainer,
    locked: AppPalette.locked,
    lockedContainer: AppPalette.lockedContainer,
    onLocked: AppPalette.onLocked,
    onLockedContainer: AppPalette.onLockedContainer,
    textPrimary: AppPalette.textPrimary,
    textSecondary: AppPalette.textSecondary,
    textDisabled: AppPalette.textDisabled,
  );
}

// ─────────────────────────────────────────────────────────────
// 3. STATUS CHIPS
// ─────────────────────────────────────────────────────────────

enum CollectionStatus { collected, pending, notAvailable, locked, paymentTomorrow, shifted }

@immutable
class StatusChipStyle {
  const StatusChipStyle({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    this.icon,
  });
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final IconData? icon;
}

abstract final class StatusChipStyles {
  static StatusChipStyle of(CollectionStatus status, AppColors colors) {
    switch (status) {
      case CollectionStatus.collected:
        return StatusChipStyle(
          label: 'Collected',
          backgroundColor: colors.successContainer,
          foregroundColor: colors.onSuccessContainer,
          borderColor: colors.success,
          icon: Icons.check_circle_outline_rounded,
        );
      case CollectionStatus.pending:
        return StatusChipStyle(
          label: 'Pending',
          backgroundColor: colors.warningContainer,
          foregroundColor: colors.onWarningContainer,
          borderColor: colors.warning,
          icon: Icons.schedule_rounded,
        );
      case CollectionStatus.notAvailable:
        return StatusChipStyle(
          label: 'Not Available',
          backgroundColor: const Color(0xFFEEEEEE),
          foregroundColor: const Color(0xFF5A5A5A),
          borderColor: const Color(0xFFBDBDBD),
          icon: Icons.block_rounded,
        );
      case CollectionStatus.locked:
        return StatusChipStyle(
          label: 'Locked',
          backgroundColor: colors.lockedContainer,
          foregroundColor: colors.onLockedContainer,
          borderColor: colors.locked,
          icon: Icons.lock_outline_rounded,
        );
      case CollectionStatus.paymentTomorrow:
        return const StatusChipStyle(
          label: 'Tomorrow',
          backgroundColor: Color(0xFFDBEAFE),
          foregroundColor: Color(0xFF1E3A8A),
          borderColor: Color(0xFF2563EB),
          icon: Icons.calendar_today_outlined,
        );
      case CollectionStatus.shifted:
        return const StatusChipStyle(
          label: 'Shifted',
          backgroundColor: Color(0xFFF3F4F6),
          foregroundColor: Color(0xFF374151),
          borderColor: Color(0xFF6B7280),
          icon: Icons.move_to_inbox_outlined,
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────
// 4. TYPOGRAPHY  —  Inter + tabular figures
// ─────────────────────────────────────────────────────────────

abstract final class AppTextStyles {
  static const String _fontFamily = 'Inter';
  static const List<FontFeature> _tabularFigures = [
    FontFeature.tabularFigures(),
  ];

  // Display
  static const TextStyle displayLarge = TextStyle(
    fontFamily: _fontFamily, fontSize: 57, fontWeight: FontWeight.w300,
    letterSpacing: -0.25, height: 1.12, color: AppPalette.textPrimary,
  );
  static const TextStyle displayMedium = TextStyle(
    fontFamily: _fontFamily, fontSize: 45, fontWeight: FontWeight.w300,
    letterSpacing: 0, height: 1.16, color: AppPalette.textPrimary,
  );
  static const TextStyle displaySmall = TextStyle(
    fontFamily: _fontFamily, fontSize: 36, fontWeight: FontWeight.w400,
    letterSpacing: 0, height: 1.22, color: AppPalette.textPrimary,
  );

  // Headline
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: _fontFamily, fontSize: 32, fontWeight: FontWeight.w600,
    letterSpacing: 0, height: 1.25, color: AppPalette.textPrimary,
  );
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: _fontFamily, fontSize: 28, fontWeight: FontWeight.w600,
    letterSpacing: 0, height: 1.29, color: AppPalette.textPrimary,
  );
  static const TextStyle headlineSmall = TextStyle(
    fontFamily: _fontFamily, fontSize: 24, fontWeight: FontWeight.w600,
    letterSpacing: 0, height: 1.33, color: AppPalette.textPrimary,
  );

  // Title
  static const TextStyle titleLarge = TextStyle(
    fontFamily: _fontFamily, fontSize: 22, fontWeight: FontWeight.w600,
    letterSpacing: 0, height: 1.27, color: AppPalette.textPrimary,
  );
  static const TextStyle titleMedium = TextStyle(
    fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w600,
    letterSpacing: 0.15, height: 1.50, color: AppPalette.textPrimary,
  );
  static const TextStyle titleSmall = TextStyle(
    fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w600,
    letterSpacing: 0.1, height: 1.43, color: AppPalette.textPrimary,
  );

  // Body
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w400,
    letterSpacing: 0.5, height: 1.50, color: AppPalette.textPrimary,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w400,
    letterSpacing: 0.25, height: 1.43, color: AppPalette.textPrimary,
  );
  static const TextStyle bodySmall = TextStyle(
    fontFamily: _fontFamily, fontSize: 12, fontWeight: FontWeight.w400,
    letterSpacing: 0.4, height: 1.33, color: AppPalette.textSecondary,
  );
  // Numeric body variants with tabular figures
  static const TextStyle bodyLargeNumeric = TextStyle(
    fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w500,
    letterSpacing: 0.5, height: 1.50, color: AppPalette.textPrimary,
    fontFeatures: _tabularFigures,
  );
  static const TextStyle bodyMediumNumeric = TextStyle(
    fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w500,
    letterSpacing: 0.25, height: 1.43, color: AppPalette.textPrimary,
    fontFeatures: _tabularFigures,
  );

  // Label
  static const TextStyle labelLarge = TextStyle(
    fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w600,
    letterSpacing: 0.1, height: 1.43, color: AppPalette.textPrimary,
  );
  static const TextStyle labelMedium = TextStyle(
    fontFamily: _fontFamily, fontSize: 12, fontWeight: FontWeight.w600,
    letterSpacing: 0.5, height: 1.33, color: AppPalette.textPrimary,
    fontFeatures: _tabularFigures,
  );
  static const TextStyle labelSmall = TextStyle(
    fontFamily: _fontFamily, fontSize: 11, fontWeight: FontWeight.w600,
    letterSpacing: 0.5, height: 1.45, color: AppPalette.textSecondary,
    fontFeatures: _tabularFigures,
  );

  // Caption — always tabular for dates/times alignment
  static const TextStyle caption = TextStyle(
    fontFamily: _fontFamily, fontSize: 11, fontWeight: FontWeight.w400,
    letterSpacing: 0.4, height: 1.45, color: AppPalette.textSecondary,
    fontFeatures: _tabularFigures,
  );
  static const TextStyle captionBold = TextStyle(
    fontFamily: _fontFamily, fontSize: 11, fontWeight: FontWeight.w600,
    letterSpacing: 0.4, height: 1.45, color: AppPalette.textSecondary,
    fontFeatures: _tabularFigures,
  );

  // Amount / Currency hero
  static const TextStyle amountDisplay = TextStyle(
    fontFamily: _fontFamily, fontSize: 36, fontWeight: FontWeight.w700,
    letterSpacing: -0.5, height: 1.10, color: AppPalette.primary,
    fontFeatures: _tabularFigures,
  );
  static const TextStyle amountLarge = TextStyle(
    fontFamily: _fontFamily, fontSize: 24, fontWeight: FontWeight.w700,
    letterSpacing: -0.25, height: 1.20, color: AppPalette.primary,
    fontFeatures: _tabularFigures,
  );
}

// ─────────────────────────────────────────────────────────────
// 5. SHADOWS & DECORATION HELPERS
// ─────────────────────────────────────────────────────────────

abstract final class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0A0B2545), blurRadius: 8, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x140B2545), blurRadius: 20, offset: Offset(0, 6)),
  ];
  static const List<BoxShadow> elevated = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 24, offset: Offset(0, 8)),
  ];
  static const List<BoxShadow> appBar = [
    BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 2)),
  ];
}

abstract final class AppRadius {
  static const double xs   = 4;
  static const double sm   = 8;
  static const double md   = 12;  // cards
  static const double lg   = 16;
  static const double xl   = 24;
  static const double pill = 100; // status chips, pill buttons
}

BoxDecoration get appCardDecoration => BoxDecoration(
      color: AppPalette.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppPalette.outlineVariant, width: 0.5),
      boxShadow: AppShadows.card,
    );

// ─────────────────────────────────────────────────────────────
// 6. COMPONENT THEMES
// ─────────────────────────────────────────────────────────────

CardTheme _buildCardTheme() => CardTheme(
      elevation: 0,
      color: AppPalette.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppPalette.outlineVariant, width: 0.5),
      ),
      margin: EdgeInsets.zero,
    );

ElevatedButtonThemeData _buildElevatedButtonTheme() =>
    ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppPalette.primary,
        foregroundColor: AppPalette.onPrimary,
        disabledBackgroundColor: AppPalette.outlineVariant,
        disabledForegroundColor: AppPalette.textDisabled,
        elevation: 0,
        shadowColor: Colors.transparent,
        textStyle: AppTextStyles.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        minimumSize: const Size(88, 48),
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith<Color?>((s) {
          if (s.contains(WidgetState.pressed)) return Colors.white.withOpacity(0.08);
          if (s.contains(WidgetState.hovered)) return Colors.white.withOpacity(0.05);
          return null;
        }),
      ),
    );

OutlinedButtonThemeData _buildOutlinedButtonTheme() =>
    OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppPalette.primary,
        disabledForegroundColor: AppPalette.textDisabled,
        textStyle: AppTextStyles.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        side: const BorderSide(color: AppPalette.primary, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        minimumSize: const Size(88, 48),
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith<Color?>((s) {
          if (s.contains(WidgetState.pressed)) return AppPalette.primary.withOpacity(0.08);
          if (s.contains(WidgetState.hovered)) return AppPalette.primary.withOpacity(0.04);
          return null;
        }),
        side: WidgetStateProperty.resolveWith<BorderSide?>((s) {
          if (s.contains(WidgetState.disabled))
            return const BorderSide(color: AppPalette.outlineVariant, width: 1.5);
          return const BorderSide(color: AppPalette.primary, width: 1.5);
        }),
      ),
    );

TextButtonThemeData _buildTextButtonTheme() => TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppPalette.primary,
        disabledForegroundColor: AppPalette.textDisabled,
        textStyle: AppTextStyles.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith<Color?>((s) {
          if (s.contains(WidgetState.pressed)) return AppPalette.primary.withOpacity(0.08);
          return null;
        }),
      ),
    );

ChipThemeData _buildChipTheme() => ChipThemeData(
      backgroundColor: AppPalette.surfaceVariant,
      disabledColor: AppPalette.outlineVariant,
      selectedColor: AppPalette.primaryContainer,
      secondarySelectedColor: AppPalette.primaryContainer,
      labelStyle: AppTextStyles.labelMedium,
      secondaryLabelStyle: AppTextStyles.labelMedium.copyWith(
        color: AppPalette.onPrimaryContainer,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      side: BorderSide.none,
      elevation: 0,
      pressElevation: 0,
    );

AppBarTheme _buildAppBarTheme() => const AppBarTheme(
      backgroundColor: AppPalette.surface,
      foregroundColor: AppPalette.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: Color(0x14000000),
      titleTextStyle: AppTextStyles.titleMedium,
      centerTitle: false,
      iconTheme: IconThemeData(color: AppPalette.textPrimary, size: 24),
      actionsIconTheme: IconThemeData(color: AppPalette.primary, size: 24),
    );

BottomNavigationBarThemeData _buildBottomNavTheme() =>
    const BottomNavigationBarThemeData(
      backgroundColor: AppPalette.surface,
      selectedItemColor: AppPalette.primary,
      unselectedItemColor: AppPalette.textSecondary,
      selectedLabelStyle: AppTextStyles.labelSmall,
      unselectedLabelStyle: AppTextStyles.labelSmall,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    );

NavigationBarThemeData _buildNavigationBarTheme() => NavigationBarThemeData(
      backgroundColor: AppPalette.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppPalette.primaryContainer,
      iconTheme: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.selected))
          return const IconThemeData(color: AppPalette.onPrimaryContainer);
        return const IconThemeData(color: AppPalette.textSecondary);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.selected))
          return AppTextStyles.labelSmall.copyWith(
            color: AppPalette.primary, fontWeight: FontWeight.w700);
        return AppTextStyles.labelSmall;
      }),
      elevation: 4,
    );

InputDecorationTheme _buildInputDecorationTheme() {
  const br = BorderRadius.all(Radius.circular(AppRadius.sm));
  return InputDecorationTheme(
    filled: true,
    fillColor: AppPalette.surfaceVariant,
    hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppPalette.textDisabled),
    labelStyle: AppTextStyles.labelLarge.copyWith(color: AppPalette.textSecondary),
    floatingLabelStyle: AppTextStyles.labelLarge.copyWith(color: AppPalette.primary),
    helperStyle: AppTextStyles.caption,
    errorStyle: AppTextStyles.caption.copyWith(color: AppPalette.error),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: const OutlineInputBorder(borderRadius: br, borderSide: BorderSide(color: AppPalette.outline)),
    enabledBorder: const OutlineInputBorder(borderRadius: br, borderSide: BorderSide(color: AppPalette.outlineVariant)),
    focusedBorder: const OutlineInputBorder(borderRadius: br, borderSide: BorderSide(color: AppPalette.primary, width: 2)),
    errorBorder: const OutlineInputBorder(borderRadius: br, borderSide: BorderSide(color: AppPalette.error)),
    focusedErrorBorder: const OutlineInputBorder(borderRadius: br, borderSide: BorderSide(color: AppPalette.error, width: 2)),
    disabledBorder: const OutlineInputBorder(borderRadius: br, borderSide: BorderSide(color: AppPalette.outlineVariant)),
  );
}

DividerThemeData _buildDividerTheme() => const DividerThemeData(
      color: AppPalette.outlineVariant, thickness: 1, space: 1);

DialogTheme _buildDialogTheme() => DialogTheme(
      backgroundColor: AppPalette.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shadowColor: AppPalette.shadow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      titleTextStyle: AppTextStyles.titleLarge,
      contentTextStyle: AppTextStyles.bodyMedium,
    );

FloatingActionButtonThemeData _buildFabTheme() =>
    FloatingActionButtonThemeData(
      backgroundColor: AppPalette.primary,
      foregroundColor: AppPalette.onPrimary,
      elevation: 4, focusElevation: 6, hoverElevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
    );

ListTileThemeData _buildListTileTheme() => const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      tileColor: Colors.transparent,
      selectedTileColor: AppPalette.primaryContainer,
      selectedColor: AppPalette.onPrimaryContainer,
      iconColor: AppPalette.textSecondary,
      textColor: AppPalette.textPrimary,
      subtitleTextStyle: AppTextStyles.bodySmall,
      titleTextStyle: AppTextStyles.bodyMedium,
      leadingAndTrailingTextStyle: AppTextStyles.labelMedium,
      minLeadingWidth: 24, minVerticalPadding: 12,
    );

ProgressIndicatorThemeData _buildProgressIndicatorTheme() =>
    const ProgressIndicatorThemeData(
      color: AppPalette.primary,
      linearTrackColor: AppPalette.primaryContainer,
      circularTrackColor: AppPalette.primaryContainer,
      linearMinHeight: 6,
    );

SnackBarThemeData _buildSnackBarTheme() => SnackBarThemeData(
      backgroundColor: AppPalette.textPrimary,
      contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
      actionTextColor: AppPalette.tertiary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      behavior: SnackBarBehavior.floating,
      elevation: 4,
    );

TabBarTheme _buildTabBarTheme() => TabBarTheme(
      labelColor: AppPalette.primary,
      unselectedLabelColor: AppPalette.textSecondary,
      labelStyle: AppTextStyles.labelLarge,
      unselectedLabelStyle: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w500),
      indicatorColor: AppPalette.primary,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: AppPalette.outlineVariant,
    );

SwitchThemeData _buildSwitchTheme() => SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.selected)) return AppPalette.onPrimary;
        return AppPalette.textSecondary;
      }),
      trackColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.selected)) return AppPalette.primary;
        return AppPalette.outlineVariant;
      }),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    );

CheckboxThemeData _buildCheckboxTheme() => CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.selected)) return AppPalette.primary;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(AppPalette.onPrimary),
      side: const BorderSide(color: AppPalette.outline, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xs)),
    );

RadioThemeData _buildRadioTheme() => RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.selected)) return AppPalette.primary;
        return AppPalette.outline;
      }),
    );

// ─────────────────────────────────────────────────────────────
// 7.  COLOR SCHEME
// ─────────────────────────────────────────────────────────────

const ColorScheme _lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: AppPalette.primary,
  onPrimary: AppPalette.onPrimary,
  primaryContainer: AppPalette.primaryContainer,
  onPrimaryContainer: AppPalette.onPrimaryContainer,
  secondary: AppPalette.secondary,
  onSecondary: AppPalette.onSecondary,
  secondaryContainer: AppPalette.secondaryContainer,
  onSecondaryContainer: AppPalette.onSecondaryContainer,
  tertiary: AppPalette.tertiary,
  onTertiary: AppPalette.onTertiary,
  tertiaryContainer: AppPalette.tertiaryContainer,
  onTertiaryContainer: AppPalette.onTertiaryContainer,
  error: AppPalette.error,
  onError: AppPalette.onError,
  errorContainer: AppPalette.errorContainer,
  onErrorContainer: AppPalette.onErrorContainer,
  surface: AppPalette.surface,
  onSurface: AppPalette.textPrimary,
  surfaceContainerHighest: AppPalette.surfaceVariant,
  onSurfaceVariant: AppPalette.textSecondary,
  outline: AppPalette.outline,
  outlineVariant: AppPalette.outlineVariant,
  shadow: AppPalette.shadow,
  scrim: AppPalette.scrim,
  inverseSurface: AppPalette.textPrimary,
  onInverseSurface: AppPalette.background,
  inversePrimary: AppPalette.primaryContainer,
  surfaceTint: AppPalette.surfaceTint,
);

// ─────────────────────────────────────────────────────────────
// 8.  TEXT THEME
// ─────────────────────────────────────────────────────────────

const TextTheme _textTheme = TextTheme(
  displayLarge:   AppTextStyles.displayLarge,
  displayMedium:  AppTextStyles.displayMedium,
  displaySmall:   AppTextStyles.displaySmall,
  headlineLarge:  AppTextStyles.headlineLarge,
  headlineMedium: AppTextStyles.headlineMedium,
  headlineSmall:  AppTextStyles.headlineSmall,
  titleLarge:     AppTextStyles.titleLarge,
  titleMedium:    AppTextStyles.titleMedium,
  titleSmall:     AppTextStyles.titleSmall,
  bodyLarge:      AppTextStyles.bodyLarge,
  bodyMedium:     AppTextStyles.bodyMedium,
  bodySmall:      AppTextStyles.bodySmall,
  labelLarge:     AppTextStyles.labelLarge,
  labelMedium:    AppTextStyles.labelMedium,
  labelSmall:     AppTextStyles.labelSmall,
);

// ─────────────────────────────────────────────────────────────
// 9.  ASSEMBLED THEME
// ─────────────────────────────────────────────────────────────

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: _lightColorScheme,
        scaffoldBackgroundColor: AppPalette.background,
        fontFamily: 'Inter',
        textTheme: _textTheme,
        primaryTextTheme: _textTheme,
        appBarTheme: _buildAppBarTheme(),
        cardTheme: _buildCardTheme(),
        chipTheme: _buildChipTheme(),
        elevatedButtonTheme: _buildElevatedButtonTheme(),
        outlinedButtonTheme: _buildOutlinedButtonTheme(),
        textButtonTheme: _buildTextButtonTheme(),
        inputDecorationTheme: _buildInputDecorationTheme(),
        bottomNavigationBarTheme: _buildBottomNavTheme(),
        navigationBarTheme: _buildNavigationBarTheme(),
        dividerTheme: _buildDividerTheme(),
        dialogTheme: _buildDialogTheme(),
        floatingActionButtonTheme: _buildFabTheme(),
        listTileTheme: _buildListTileTheme(),
        progressIndicatorTheme: _buildProgressIndicatorTheme(),
        snackBarTheme: _buildSnackBarTheme(),
        tabBarTheme: _buildTabBarTheme(),
        switchTheme: _buildSwitchTheme(),
        checkboxTheme: _buildCheckboxTheme(),
        radioTheme: _buildRadioTheme(),
        extensions: const <ThemeExtension<dynamic>>[AppColors.light],
      );
}

// ─────────────────────────────────────────────────────────────
// 10. CONVENIENCE EXTENSION ON BuildContext
// ─────────────────────────────────────────────────────────────

extension AppThemeContext on BuildContext {
  AppColors get appColors => AppColors.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
}
