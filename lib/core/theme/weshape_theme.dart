import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'weshape_palette.dart';

abstract final class WeShapeTheme {
  /// Tests pass false: Google Fonts would try to download the font.
  static bool useGoogleFonts = true;

  static ThemeData light() => _build(Brightness.light, WeShapePalette.light);

  static ThemeData dark() => _build(Brightness.dark, WeShapePalette.dark);

  static ThemeData _build(Brightness brightness, WeShapePalette p) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: p.primary,
      onPrimary: p.onPrimary,
      secondary: p.primary,
      onSecondary: p.onPrimary,
      error: p.error,
      onError: p.surface,
      surface: p.surface,
      onSurface: p.text,
      onSurfaceVariant: p.muted,
      outline: p.border,
      outlineVariant: p.border,
      surfaceContainerHighest: p.selected,
    );

    final base = ThemeData(brightness: brightness, colorScheme: scheme, useMaterial3: true);
    final textTheme = useGoogleFonts ? GoogleFonts.plusJakartaSansTextTheme(base.textTheme) : base.textTheme;
    final radius = BorderRadius.circular(10);

    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: color, width: width));

    return base.copyWith(
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      extensions: [p],
      textTheme: textTheme.apply(bodyColor: p.text, displayColor: p.text),
      dividerColor: p.border,
      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.input,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        hintStyle: TextStyle(color: p.muted, fontSize: 14),
        labelStyle: TextStyle(color: p.muted, fontSize: 14),
        floatingLabelStyle: TextStyle(color: p.primary),
        errorStyle: TextStyle(color: p.error, fontSize: 12),
        border: border(p.border),
        enabledBorder: border(p.border),
        focusedBorder: border(p.primary, 1.5),
        errorBorder: border(p.error),
        focusedErrorBorder: border(p.error, 1.5),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.text,
          backgroundColor: p.surface,
          minimumSize: const Size.fromHeight(44),
          side: BorderSide(color: p.border),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        side: BorderSide(color: p.border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.primary : p.input),
        checkColor: WidgetStatePropertyAll(p.onPrimary),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: p.border)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.text,
        contentTextStyle: TextStyle(color: p.background),
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.primary),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: p.text, borderRadius: BorderRadius.circular(6)),
        textStyle: TextStyle(color: p.background, fontSize: 12),
      ),
    );
  }
}
