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
    required this.switchTrack,
    required this.switchKnob,
    required this.switchIcon,
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

  /// Theme switch: pale sun in light mode, white-silver moon in dark mode.
  final Gradient switchTrack;
  final Gradient switchKnob;
  final Color switchIcon;

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
      colors: [Color(0xFF2C4F8C), Color(0xFF1A3363)],
    ),
    onPrimary: Color(0xFFF5F7FA),
    input: Color(0xFFF5F7FA),
    green: Color(0xFF2E9E66),
    error: Color(0xFFA0523F),
    errorBackground: Color(0xFFF7EDE9),
    selected: Color(0xFFEEF2F8),
    switchTrack: LinearGradient(colors: [Color(0xFFE9EEF6), Color(0xFFD5DFEC)]),
    switchKnob: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFF8DE), Color(0xFFFFE08A)],
    ),
    switchIcon: Color(0xFFC99A1E),
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
      colors: [Color(0xFFB6CBEE), Color(0xFF86A4D9)],
    ),
    onPrimary: Color(0xFF0E1A30),
    input: Color(0xFF0E131B),
    green: Color(0xFF4CC487),
    error: Color(0xFFE09A86),
    errorBackground: Color(0xFF2A1D1A),
    selected: Color(0xFF1C2534),
    switchTrack: LinearGradient(colors: [Color(0xFF1C2535), Color(0xFF2A3549)]),
    switchKnob: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFFFFF), Color(0xFFD6DCE7)],
    ),
    switchIcon: Color(0xFF3A4660),
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
      switchTrack: Gradient.lerp(switchTrack, other.switchTrack, t)!,
      switchKnob: Gradient.lerp(switchKnob, other.switchKnob, t)!,
      switchIcon: c(switchIcon, other.switchIcon),
    );
  }
}

extension WeShapePaletteX on BuildContext {
  WeShapePalette get palette => Theme.of(this).extension<WeShapePalette>() ?? WeShapePalette.light;
}
