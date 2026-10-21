import 'package:flutter/material.dart';

/// The WeShape colors, from the approved sketch.
///
/// Navy carries the interface in light mode; a soft sky blue takes over in
/// dark mode, where navy would disappear. Green appears only in the logo and
/// the small "online" dot, never on controls.
@immutable
class WeShapePalette extends ThemeExtension<WeShapePalette> {
  const WeShapePalette({
    required this.background,
    required this.surface,
    required this.text,
    required this.muted,
    required this.border,
    required this.primary,
    required this.primaryGradient,
    required this.onPrimary,
    required this.input,
    required this.green,
    required this.error,
    required this.errorBackground,
    required this.selected,
    required this.stageTop,
    required this.stageMiddle,
    required this.stageBottom,
    required this.glowBlue,
    required this.glowGreen,
    required this.fieldFill,
    required this.fieldBorder,
    required this.buttonShadow,
    required this.sunLight,
    required this.sunDeep,
    required this.sunRay,
    required this.moonLight,
    required this.moonDeep,
  });

  final Color background;
  final Color surface;
  final Color text;
  final Color muted;
  final Color border;
  final Color primary;
  final Gradient primaryGradient;
  final Color onPrimary;
  final Color input;
  final Color green;

  /// Muted terracotta rather than red, so errors read clearly without shouting.
  final Color error;
  final Color errorBackground;
  final Color selected;

  /// The sign-in pages' background: a soft diagonal gradient with a faint
  /// blue light behind the logo and a breath of green in the corner. Kept as
  /// plain colours, not a Gradient, so a theme change can blend every stop.
  final Color stageTop;
  final Color stageMiddle;
  final Color stageBottom;
  final Color glowBlue;
  final Color glowGreen;

  /// Inputs and secondary buttons sit on the gradient without a card, so they
  /// are slightly translucent with a hairline border.
  final Color fieldFill;
  final Color fieldBorder;
  final Color buttonShadow;

  /// Theme icon: pale yellow sun, white moon.
  final Color sunLight;
  final Color sunDeep;
  final Color sunRay;
  final Color moonLight;
  final Color moonDeep;

  LinearGradient get stageGradient => LinearGradient(
        begin: const Alignment(-0.6, -1),
        end: const Alignment(0.6, 1),
        colors: [stageTop, stageMiddle, stageBottom],
        stops: const [0, 0.55, 1],
      );

  static const WeShapePalette light = WeShapePalette(
    background: Color(0xFFF5F7FA),
    surface: Color(0xFFFFFFFF),
    text: Color(0xFF1F2A3D),
    muted: Color(0xFF6B7686),
    border: Color(0xFFDCE3EC),
    primary: Color(0xFF1E3A6E),
    primaryGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF3A62A6), Color(0xFF244987), Color(0xFF17305E)],
      stops: [0, 0.45, 1],
    ),
    onPrimary: Color(0xFFF5F7FA),
    input: Color(0xFFF5F7FA),
    green: Color(0xFF2E9E66),
    error: Color(0xFFA0523F),
    errorBackground: Color(0xFFF7EDE9),
    selected: Color(0xFFEEF2F8),
    stageTop: Color(0xFFF8FAFD),
    stageMiddle: Color(0xFFEDF2F9),
    stageBottom: Color(0xFFE4EBF5),
    glowBlue: Color(0x292C4F8C),
    glowGreen: Color(0x1A2E9E66),
    fieldFill: Color(0xC7FFFFFF),
    fieldBorder: Color(0x1A1E3A6E),
    buttonShadow: Color(0x8C1A3363),
    sunLight: Color(0xFFFFF4C9),
    sunDeep: Color(0xFFF6C548),
    sunRay: Color(0xFFE8B23A),
    moonLight: Color(0xFFFFFFFF),
    moonDeep: Color(0xFFD9E1EE),
  );

  static const WeShapePalette dark = WeShapePalette(
    background: Color(0xFF0E131B),
    surface: Color(0xFF151C27),
    text: Color(0xFFE3E8EF),
    muted: Color(0xFF8A95A6),
    border: Color(0xFF263042),
    primary: Color(0xFF9DB8E6),
    primaryGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFC6D6F2), Color(0xFF9DB8E6), Color(0xFF7E9DD3)],
      stops: [0, 0.5, 1],
    ),
    onPrimary: Color(0xFF0E1A30),
    input: Color(0xFF0E131B),
    green: Color(0xFF4CC487),
    error: Color(0xFFE09A86),
    errorBackground: Color(0xFF2A1D1A),
    selected: Color(0xFF1C2534),
    stageTop: Color(0xFF0B1017),
    stageMiddle: Color(0xFF101824),
    stageBottom: Color(0xFF152033),
    glowBlue: Color(0x2986A4D9),
    glowGreen: Color(0x124CC487),
    fieldFill: Color(0x09FFFFFF),
    fieldBorder: Color(0x219DB8E6),
    buttonShadow: Color(0x7386A4D9),
    sunLight: Color(0xFFFFF4C9),
    sunDeep: Color(0xFFF6C548),
    sunRay: Color(0xFFE8B23A),
    moonLight: Color(0xFFFFFFFF),
    moonDeep: Color(0xFFD9E1EE),
  );

  @override
  WeShapePalette copyWith() => this;

  @override
  WeShapePalette lerp(ThemeExtension<WeShapePalette>? other, double t) {
    if (other is! WeShapePalette) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return WeShapePalette(
      background: c(background, other.background),
      surface: c(surface, other.surface),
      text: c(text, other.text),
      muted: c(muted, other.muted),
      border: c(border, other.border),
      primary: c(primary, other.primary),
      primaryGradient: Gradient.lerp(primaryGradient, other.primaryGradient, t)!,
      onPrimary: c(onPrimary, other.onPrimary),
      input: c(input, other.input),
      green: c(green, other.green),
      error: c(error, other.error),
      errorBackground: c(errorBackground, other.errorBackground),
      selected: c(selected, other.selected),
      stageTop: c(stageTop, other.stageTop),
      stageMiddle: c(stageMiddle, other.stageMiddle),
      stageBottom: c(stageBottom, other.stageBottom),
      glowBlue: c(glowBlue, other.glowBlue),
      glowGreen: c(glowGreen, other.glowGreen),
      fieldFill: c(fieldFill, other.fieldFill),
      fieldBorder: c(fieldBorder, other.fieldBorder),
      buttonShadow: c(buttonShadow, other.buttonShadow),
      sunLight: c(sunLight, other.sunLight),
      sunDeep: c(sunDeep, other.sunDeep),
      sunRay: c(sunRay, other.sunRay),
      moonLight: c(moonLight, other.moonLight),
      moonDeep: c(moonDeep, other.moonDeep),
    );
  }
}

extension WeShapePaletteX on BuildContext {
  WeShapePalette get palette => Theme.of(this).extension<WeShapePalette>() ?? WeShapePalette.light;
}
