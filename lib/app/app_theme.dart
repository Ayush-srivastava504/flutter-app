import 'package:flutter/material.dart';

/// ClipForge's palette. Warm ink greys (not blue-black) and one ember accent
/// taken from the logo; mode colours are used only to tell the three video
/// modes apart, never as decoration.
abstract final class AppColors {
  static const ink = Color(0xFF101114); // app background
  static const canvas = Color(0xFF0A0A0C); // behind the video preview
  static const surface = Color(0xFF17181C); // cards, docked panels
  static const surfaceHigh = Color(0xFF202127); // raised rows, chips
  static const surfaceTop = Color(0xFF2A2B32); // pressed / selected
  static const line = Color(0xFF2E3038);

  static const text = Color(0xFFF2EEE8);
  static const textDim = Color(0xFFA29E97);
  static const textFaint = Color(0xFF6E6B66);

  static const ember = Color(0xFFFF7A45);
  static const emberDeep = Color(0xFFE2582A);

  static const youtube = Color(0xFFF0575D);
  static const insta = Color(0xFFC58BF2);
  static const normal = Color(0xFF58C9B0);
  static const photo = Color(0xFF7FB2FF);
  static const pro = Color(0xFFE8B65A);

  static const ok = Color(0xFF7BD389);
  static const warn = Color(0xFFF2B655);
}

abstract final class AppRadii {
  static const sm = 10.0;
  static const md = 16.0;
  static const lg = 22.0;
}

ThemeData buildAppTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.ember,
    onPrimary: Color(0xFF1A0E08),
    primaryContainer: Color(0xFF4A2414),
    onPrimaryContainer: Color(0xFFFFD9C9),
    secondary: AppColors.pro,
    onSecondary: Color(0xFF1E1606),
    tertiary: AppColors.normal,
    onTertiary: Color(0xFF06201A),
    error: Color(0xFFFF6B6B),
    onError: Color(0xFF2A0606),
    surface: AppColors.ink,
    onSurface: AppColors.text,
    onSurfaceVariant: AppColors.textDim,
    surfaceContainerLowest: AppColors.canvas,
    surfaceContainerLow: AppColors.surface,
    surfaceContainer: AppColors.surface,
    surfaceContainerHigh: AppColors.surfaceHigh,
    surfaceContainerHighest: AppColors.surfaceTop,
    outline: AppColors.line,
    outlineVariant: Color(0xFF24252B),
  );

  final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: Brightness.dark);
  final text = base.textTheme.apply(bodyColor: AppColors.text, displayColor: AppColors.text);

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.ink,
    canvasColor: AppColors.ink,
    dividerColor: AppColors.line,
    textTheme: text.copyWith(
      headlineMedium: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.8),
      headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      labelSmall: text.labelSmall?.copyWith(letterSpacing: 0.6),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w700),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        side: const BorderSide(color: AppColors.line),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: AppColors.line,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.surfaceHigh,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.surfaceTop,
      contentTextStyle: const TextStyle(color: AppColors.text),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm + 4)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        side: const BorderSide(color: AppColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm + 4)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.ember,
      foregroundColor: Color(0xFF1A0E08),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppColors.surfaceHigh,
      side: const BorderSide(color: AppColors.line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
    ),
    sliderTheme: base.sliderTheme.copyWith(
      inactiveTrackColor: AppColors.surfaceTop,
      trackHeight: 3,
    ),
    listTileTheme: const ListTileThemeData(iconColor: AppColors.textDim),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceHigh,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
