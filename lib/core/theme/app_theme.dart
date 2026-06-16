import 'package:flutter/material.dart';

import '../constants/app_dimensions.dart';

class AppColors {
  static const bg = Color(0xFFF6F7F4);
  static const card = Color(0xFFFFFFFF);
  static const primary = Color(0xFF161A22);
  static const muted = Color(0xFF667085);
  static const faint = Color(0xFF98A2B3);
  static const border = Color(0xFFE4E7EC);
  static const accent = Color(0xFF315CFF);
  static const accentDark = Color(0xFF1D2D70);
  static const accentSoft = Color(0xFFEAF0FF);
  static const teal = Color(0xFF047A72);
  static const tealSoft = Color(0xFFE6F7F5);
  static const success = Color(0xFF12805C);
  static const successSoft = Color(0xFFECFDF5);
  static const warning = Color(0xFFB76E00);
  static const warningSoft = Color(0xFFFFF7E6);
  static const danger = Color(0xFFD92D20);
  static const dangerSoft = Color(0xFFFFF1F2);
}

ThemeData buildMikiezyTheme({Brightness brightness = Brightness.light}) {
  final dark = brightness == Brightness.dark;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        brightness: brightness,
      ).copyWith(
        primary: AppColors.accent,
        onPrimary: Colors.white,
        primaryContainer: dark ? const Color(0xFF27356F) : AppColors.accentSoft,
        onPrimaryContainer: dark
            ? const Color(0xFFDCE5FF)
            : AppColors.accentDark,
        secondary: dark ? const Color(0xFF5DD9D0) : AppColors.teal,
        secondaryContainer: dark ? const Color(0xFF123D3E) : AppColors.tealSoft,
        tertiary: AppColors.warning,
        error: AppColors.danger,
        surface: dark ? const Color(0xFF11151C) : AppColors.card,
        surfaceContainerLowest: dark ? const Color(0xFF090C11) : AppColors.bg,
        surfaceContainerLow: dark ? const Color(0xFF151922) : AppColors.card,
        surfaceContainer: dark
            ? const Color(0xFF191E28)
            : const Color(0xFFFBFCFA),
        surfaceContainerHigh: dark
            ? const Color(0xFF202633)
            : const Color(0xFFF2F4F0),
        surfaceContainerHighest: dark
            ? const Color(0xFF252C39)
            : const Color(0xFFEFF2ED),
        outline: dark ? const Color(0xFF454C5C) : const Color(0xFFD0D5DD),
        outlineVariant: dark ? const Color(0xFF2B3340) : AppColors.border,
      );

  final baseTextTheme = Typography.material2021(
    platform: TargetPlatform.android,
    colorScheme: scheme,
  ).black;
  final textTheme = baseTextTheme.apply(
    bodyColor: scheme.onSurface,
    displayColor: scheme.onSurface,
    fontFamily: 'Roboto',
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surfaceContainerLowest,
    fontFamily: 'Roboto',
    visualDensity: VisualDensity.standard,
    splashFactory: InkSparkle.splashFactory,
    textTheme: textTheme.copyWith(
      headlineSmall: textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
        height: 1.12,
      ),
      titleLarge: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
        height: 1.16,
      ),
      titleMedium: textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
        height: 1.18,
      ),
      bodyLarge: textTheme.bodyLarge?.copyWith(height: 1.38),
      bodyMedium: textTheme.bodyMedium?.copyWith(height: 1.38),
      bodySmall: textTheme.bodySmall?.copyWith(height: 1.34),
      labelLarge: textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surfaceContainerLowest,
      foregroundColor: scheme.onSurface,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w900,
      ),
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainerLow,
      elevation: 0,
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.card,
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHigh,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      hintStyle: TextStyle(
        color: scheme.onSurfaceVariant.withValues(alpha: .7),
      ),
      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      helperStyle: TextStyle(color: scheme.onSurfaceVariant),
      errorMaxLines: 2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: BorderSide(color: scheme.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: BorderSide(color: scheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: BorderSide(color: scheme.error, width: 1.6),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        elevation: 0,
        shadowColor: Colors.transparent,
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.onSurface,
        backgroundColor: scheme.surfaceContainerLow,
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(44, 44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 2,
      focusElevation: 3,
      hoverElevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      elevation: 0,
      backgroundColor: scheme.surface.withValues(alpha: dark ? .96 : .98),
      indicatorColor: scheme.primaryContainer,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11,
          fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
          color: selected ? scheme.primary : scheme.onSurfaceVariant,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 22,
          color: selected ? scheme.primary : scheme.onSurfaceVariant,
        );
      }),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: scheme.surfaceContainerHighest,
      selectedColor: scheme.primaryContainer,
      disabledColor: scheme.surfaceContainerHighest.withValues(alpha: .5),
      side: BorderSide(color: scheme.outlineVariant),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      labelStyle: TextStyle(
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      secondaryLabelStyle: TextStyle(
        color: scheme.onPrimaryContainer,
        fontWeight: FontWeight.w800,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      showDragHandle: true,
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? const Color(0xFFE6EAF2) : AppColors.primary,
      contentTextStyle: TextStyle(
        color: dark ? AppColors.primary : Colors.white,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return scheme.primary;
        return scheme.outline;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return scheme.primary.withValues(alpha: .22);
        }
        return scheme.surfaceContainerHighest;
      }),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: scheme.primary,
      inactiveTrackColor: scheme.primary.withValues(alpha: .16),
      thumbColor: scheme.primary,
      overlayColor: scheme.primary.withValues(alpha: .12),
    ),
  );
}

extension MikiezyThemeX on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get pageBackground => colors.surfaceContainerLowest;
  Color get cardBackground => colors.surfaceContainerLow;
  Color get mutedText => colors.onSurfaceVariant;
  Color get subtleBorder => colors.outlineVariant;

  List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDarkMode ? .22 : .06),
      blurRadius: 28,
      offset: const Offset(0, 14),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: isDarkMode ? .16 : .025),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  LinearGradient get premiumGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: isDarkMode
        ? const [Color(0xFF101722), Color(0xFF1A2232), Color(0xFF123837)]
        : const [Color(0xFF111827), Color(0xFF1A2A6C), Color(0xFF047A72)],
  );

  LinearGradient get actionGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primary, AppColors.accentDark],
  );
}
