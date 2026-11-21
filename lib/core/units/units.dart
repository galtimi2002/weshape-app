import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../settings/settings_controller.dart';

/// How lengths, areas, speeds and temperatures are shown and typed.
///
/// Everything inside the app and on the server stays metric; only what a person reads or types
/// is converted, at the edge. `us` is the US customary system: feet, miles, square feet, °F, mph,
/// cords of firewood and therms of gas.
enum UnitSystem { metric, us }

/// Countries that measure in US customary units in daily life. Everyone else starts on metric;
/// anyone can switch in the language menu.
const Set<String> usCustomaryCountries = {'US', 'PR', 'GU', 'VI', 'AS', 'MP', 'UM', 'LR', 'MH', 'FM', 'PW'};

UnitSystem defaultUnitSystemFor(String? country) =>
    usCustomaryCountries.contains(country?.toUpperCase()) ? UnitSystem.us : UnitSystem.metric;

UnitSystem? unitSystemFromApi(String? value) => switch (value) {
      'METRIC' => UnitSystem.metric,
      'US' => UnitSystem.us,
      _ => null,
    };

String? unitSystemToApi(UnitSystem? system) => switch (system) {
      UnitSystem.metric => 'METRIC',
      UnitSystem.us => 'US',
      null => null,
    };

// ---------------------------------------------------------------------------------------------
// Numbers as each language writes them.

/// Languages that write 4,2 rather than 4.2.
const Set<String> _decimalComma = {
  'hu', 'ro', 'de', 'fr', 'es', 'it', 'pt', 'nl', 'pl', 'hr', 'fi', 'ru', 'tr', 'sv', 'da', 'el', 'id', 'vi',
  'cs', 'sk', 'bg', 'sl', 'lt', 'lv', 'et', 'uk', 'sr', 'nb', 'sq', 'mk', 'bs', 'ca', 'be', 'is', 'lb', 'eu',
  'gl',
};

/// Languages that group thousands with a dot (1.276); [_spaceGroup] with a space (1 276); the rest
/// with a comma (1,276).
const Set<String> _dotGroup = {
  'de', 'nl', 'id', 'it', 'es', 'pt', 'tr', 'da', 'el', 'ro', 'hr', 'vi', 'sl', 'sr', 'mk', 'bs', 'ca', 'is',
  'lb', 'eu', 'gl',
};
const Set<String> _spaceGroup = {
  'hu', 'fr', 'pl', 'fi', 'sv', 'ru', 'cs', 'sk', 'bg', 'lt', 'lv', 'et', 'uk', 'be', 'nb', 'sq',
};

bool usesDecimalComma(String language) => _decimalComma.contains(language);

/// 1,276 / 1.276 / 1 276, as each language writes thousands.
String groupDigits(int v, String language) {
  final sep = _dotGroup.contains(language) ? '.' : (_spaceGroup.contains(language) ? ' ' : ',');
  final digits = v.abs().toString();
  final out = StringBuffer(v < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(sep);
    out.write(digits[i]);
  }
  return out.toString();
}

/// 4.2 / 4,2 with exactly [digits] decimals.
String formatDecimal(double v, String language, {int digits = 1}) {
  final text = v.toStringAsFixed(digits);
  return usesDecimalComma(language) ? text.replaceAll('.', ',') : text;
}

/// A measured value with as many digits as it deserves: 1,230 · 42 · 7.2 · 0.45.
String formatNumber(double v, String language) {
  final a = v.abs();
  if (a >= 100) return groupDigits(v.round(), language);
  if (a >= 10) return '${v.round()}';
  var text = v.toStringAsFixed(a >= 1 ? 1 : 2);
  if (text.contains('.')) text = text.replaceFirst(RegExp(r'\.?0+$'), '');
  return usesDecimalComma(language) ? text.replaceAll('.', ',') : text;
}

/// A round number a person would say: 330 ft, not 328 ft; 650 sq ft, not 646.
/// Keeps two significant digits (three from 1,000 up) and never rounds to zero.
double roundNicely(double v) {
  final a = v.abs();
  if (a < 10) return (v * 10).round() / 10;
  if (a < 100) return v.roundToDouble();
  final step = a < 1000 ? 10 : (a < 10000 ? 50 : 100);
  return (v / step).round() * step.toDouble();
}

// ---------------------------------------------------------------------------------------------
// Conversions. Exact definitions, not rounded factors.

const double feetPerMetre = 1 / 0.3048;
const double milesPerKm = 1 / 1.609344;
const double sqFtPerM2 = feetPerMetre * feetPerMetre;
const double inchesPerCm = 1 / 2.54;
const double mphPerMs = 3600 / 1609.344;
const double cubicFeetPerM3 = sqFtPerM2 * feetPerMetre;

/// A cord: a stack 4 × 4 × 8 ft = 128 cubic feet.
const double m3PerCord = 128 / cubicFeetPerM3;

/// A therm: 100,000 BTU.
const double kwhPerTherm = 29.3071;

/// CCF: a hundred cubic feet of gas.
const double m3PerCcf = 100 / cubicFeetPerM3;

const double kgPerLb = 0.45359237;
const double litresPerGallon = 3.785411784;

double celsiusToFahrenheit(double c) => c * 9 / 5 + 32;
double fahrenheitToCelsius(double f) => (f - 32) * 5 / 9;

// ---------------------------------------------------------------------------------------------
// Unit symbols, and where a language puts them.

enum Measure { length, distance, area, volume, smallLength, speed, flow, temperature, mass }

/// Metric symbols that differ from the international ones in some languages.
const Map<String, Map<Measure, String>> _metricSymbols = {
  'ru': {Measure.length: 'м', Measure.distance: 'км', Measure.area: 'м²', Measure.volume: 'м³', Measure.smallLength: 'см', Measure.speed: 'м/с', Measure.flow: 'м³/с'},
  'uk': {Measure.length: 'м', Measure.distance: 'км', Measure.area: 'м²', Measure.volume: 'м³', Measure.smallLength: 'см', Measure.speed: 'м/с', Measure.flow: 'м³/с'},
  'be': {Measure.length: 'м', Measure.distance: 'км', Measure.area: 'м²', Measure.volume: 'м³', Measure.smallLength: 'см', Measure.speed: 'м/с', Measure.flow: 'м³/с'},
  'zh': {Measure.length: '米', Measure.distance: '公里', Measure.volume: '立方米', Measure.smallLength: '厘米', Measure.speed: '米/秒'},
  'ar': {Measure.length: 'م', Measure.distance: 'كم', Measure.volume: 'م³', Measure.smallLength: 'سم', Measure.speed: 'م/ث'},
  'bn': {Measure.length: 'মি.', Measure.smallLength: 'সেমি', Measure.speed: 'মি/সে'},
  'hi': {Measure.smallLength: 'सेमी'},
};

const Map<Measure, String> _metric = {
  Measure.length: 'm',
  Measure.distance: 'km',
  Measure.area: 'm²',
  Measure.volume: 'm³',
  Measure.smallLength: 'cm',
  Measure.speed: 'm/s',
  Measure.flow: 'm³/s',
  Measure.temperature: '°C',
  Measure.mass: 'kg',
};

const Map<Measure, String> _us = {
  Measure.length: 'ft',
  Measure.distance: 'mi',
  Measure.area: 'sq ft',
  Measure.volume: 'cord',
  Measure.smallLength: 'in',
  Measure.speed: 'mph',
  Measure.flow: 'ft³/s',
  Measure.temperature: '°F',
  Measure.mass: 'lb',
};

/// Languages that write the unit first: "m 5–10".
const Set<String> _unitFirst = {'sw', 'ha'};

/// Languages that write short units right after the number: "20m".
const Set<String> _noSpace = {'ko'};

/// Shows and reads measures in one unit system and one language.
///
/// Each method takes the metric value the app works with and returns the text a person reads:
/// `units.length(20)` is "20 m" or "66 ft". The `to…`/`from…` pairs convert typed numbers.
class Units {
  const Units(this.system, this.language);

  final UnitSystem system;
  final String language;

  bool get isUs => system == UnitSystem.us;

  /// The symbol for [measure]: "m²", "м²", "sq ft".
  String symbol(Measure measure) {
    if (isUs) return measure == Measure.volume ? 'cords' : _us[measure]!;
    return _metricSymbols[language]?[measure] ?? _metric[measure]!;
  }

  /// "[number] [symbol]" in this language's order and spacing.
  String _with(String number, Measure measure, {bool singular = false}) {
    var sym = symbol(measure);
    if (isUs && measure == Measure.volume && singular) sym = 'cord';
    if (_unitFirst.contains(language)) return '$sym $number';
    final tight = _noSpace.contains(language) && !isUs && measure != Measure.distance;
    return tight ? '$number$sym' : '$number $sym';
  }

  // Converting, for fields where people type a number.

  double toDisplay(double metric, Measure measure) {
    if (!isUs) return metric;
    return switch (measure) {
      Measure.length => metric * feetPerMetre,
      Measure.distance => metric * milesPerKm,
      Measure.area => metric * sqFtPerM2,
      Measure.volume => metric / m3PerCord,
      Measure.smallLength => metric * inchesPerCm,
      Measure.speed => metric * mphPerMs,
      Measure.flow => metric * cubicFeetPerM3,
      Measure.temperature => celsiusToFahrenheit(metric),
      Measure.mass => metric / kgPerLb,
    };
  }

  double fromDisplay(double shown, Measure measure) {
    if (!isUs) return shown;
    return switch (measure) {
      Measure.length => shown / feetPerMetre,
      Measure.distance => shown / milesPerKm,
      Measure.area => shown / sqFtPerM2,
      Measure.volume => shown * m3PerCord,
      Measure.smallLength => shown / inchesPerCm,
      Measure.speed => shown / mphPerMs,
      Measure.flow => shown / cubicFeetPerM3,
      Measure.temperature => fahrenheitToCelsius(shown),
      Measure.mass => shown * kgPerLb,
    };
  }

  // Text for reading.

  /// A measured value, digits as it deserves: "4.2 m/s", "9.4 mph", "1,230 m³/s".
  String value(double metric, Measure measure) => _with(formatNumber(toDisplay(metric, measure), language), measure);

  /// A converted value rounded as people say it: whole feet and inches (3 ft, not 3.3 ft), miles
  /// to one decimal under 10 (1.2 mi), larger numbers to two or three significant digits.
  double _nice(double metric, Measure measure) {
    final shown = toDisplay(metric, measure);
    if (!isUs) return shown;
    if (shown.abs() < 10) return measure == Measure.distance ? (shown * 10).round() / 10 : shown.roundToDouble();
    return roundNicely(shown);
  }

  String _plain(double v) => v == v.roundToDouble() ? groupDigits(v.round(), language) : formatDecimal(v, language);

  /// A value given in round numbers, for heights and sizes on buttons: "100 m", "330 ft".
  String round(double metric, Measure measure) {
    final nice = _nice(metric, measure);
    return _with(_plain(nice), measure, singular: nice == 1);
  }

  /// "5–10 m", "16–33 ft".
  String range(double fromMetric, double toMetric, Measure measure) =>
      _with('${_plain(_nice(fromMetric, measure))}–${_plain(_nice(toMetric, measure))}', measure);

  /// One of the unit, for prices: "1 m³", "1 cord".
  String one(Measure measure) => _with('1', measure, singular: true);

  /// A wind speed with one decimal: "4.2 m/s", "9.4 mph".
  String speed(double ms) => _with(formatDecimal(toDisplay(ms, Measure.speed), language), Measure.speed);

  /// A measured distance: "0.05 km", "0.4 km", "12 km"; "0.2 mi".
  String distance(double km) => _with(formatNumber(toDisplay(km, Measure.distance), language), Measure.distance);

  /// A temperature: "12.3 °C", "54.1 °F".
  String temperature(double celsius) =>
      '${formatDecimal(toDisplay(celsius, Measure.temperature), language)} ${symbol(Measure.temperature)}';
}

extension UnitsContext on BuildContext {
  /// The units the current person sees, following the settings and the language.
  Units get units {
    final s = watch<SettingsController>();
    return Units(s.unitSystem, s.languageCode);
  }

  /// Same, without rebuilding when they change (for callbacks).
  Units get unitsNow {
    final s = read<SettingsController>();
    return Units(s.unitSystem, s.languageCode);
  }
}

// ---------------------------------------------------------------------------------------------
// Area units people use for land and homes, some only in a few countries.

enum AreaUnit {
  m2(1, 'm²'),
  sqft(1 / sqFtPerM2, 'sq ft'),
  hectare(10000, 'ha'),
  acre(4046.8564224, 'acre'),
  /// Romania, Moldova: ar, 100 m².
  are(100, 'ar'),
  /// Russia, Ukraine, Belarus, Kazakhstan: сотка, 100 m² (a hundredth of a hectare).
  sotka(100, 'сотка'),
  /// Hungary: négyszögöl, a square fathom, 3.5966 m².
  negyszogol(3.596652, 'négyszögöl'),
  /// Hungary: kataszteri hold, 1,600 négyszögöl.
  hold(5754.642, 'kat. hold'),
  /// China: 亩, 666.67 m².
  mu(2000 / 3, '亩'),
  /// Korea: 평, 3.3058 m² (homes and flats).
  pyeong(400 / 121, '평'),
  /// Japan: 坪, the same 3.3058 m².
  tsubo(400 / 121, '坪');

  const AreaUnit(this.m2PerUnit, this.label);

  final double m2PerUnit;
  final String label;

  double toM2(double v) => v * m2PerUnit;
  double fromM2(double m2) => m2 / m2PerUnit;
}

/// Local area units, by country: small ones for a plot or a home, large ones for fields.
const Map<String, List<AreaUnit>> _smallAreaUnits = {
  'HU': [AreaUnit.negyszogol],
  'RO': [AreaUnit.are],
  'MD': [AreaUnit.are],
  'RU': [AreaUnit.sotka],
  'UA': [AreaUnit.sotka],
  'BY': [AreaUnit.sotka],
  'KZ': [AreaUnit.sotka],
  'KR': [AreaUnit.pyeong],
  'JP': [AreaUnit.tsubo],
  'CN': [AreaUnit.mu],
};
const Map<String, List<AreaUnit>> _fieldAreaUnits = {
  'HU': [AreaUnit.hold],
  'RO': [AreaUnit.are],
  'MD': [AreaUnit.are],
  'RU': [AreaUnit.sotka],
  'UA': [AreaUnit.sotka],
  'BY': [AreaUnit.sotka],
  'KZ': [AreaUnit.sotka],
  'CN': [AreaUnit.mu],
};

/// Units for the size of a roof, garden or plot: m² (or sq ft), the country's own, and for open
/// land also hectares and acres.
List<AreaUnit> plotAreaUnits(UnitSystem system, String? country, {bool land = false}) => [
      system == UnitSystem.us ? AreaUnit.sqft : AreaUnit.m2,
      ...?_smallAreaUnits[country?.toUpperCase()],
      if (land) ...[
        for (final u in [AreaUnit.hectare, AreaUnit.acre, ...?_fieldAreaUnits[country?.toUpperCase()]])
          if (!(_smallAreaUnits[country?.toUpperCase()]?.contains(u) ?? false)) u,
      ],
    ];

/// Units for fields of crops: hectares and acres, and the country's own.
List<AreaUnit> fieldAreaUnits(String? country) => [
      AreaUnit.hectare,
      AreaUnit.acre,
      ...?_fieldAreaUnits[country?.toUpperCase()],
    ];

/// The unit fields of crops start in: acres in US units, hectares otherwise. The person's units decide,
/// not the country; the country's own units are offered beside them ([fieldAreaUnits]).
AreaUnit defaultFieldAreaUnit(UnitSystem system) => system == UnitSystem.us ? AreaUnit.acre : AreaUnit.hectare;
