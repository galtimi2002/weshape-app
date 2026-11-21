// Metric and US units: the conversions, how each language writes the result, which countries
// start on US units, and that every text with a measure in it is filled in, in every language.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weshape_app/core/i18n/app_localizations.dart';
import 'package:weshape_app/core/i18n/app_strings.dart';
import 'package:weshape_app/core/i18n/languages.dart';
import 'package:weshape_app/core/units/units.dart';
import 'package:weshape_app/features/assessment/controls.dart';

void main() {
  const metricEn = Units(UnitSystem.metric, 'en');
  const usEn = Units(UnitSystem.us, 'en');

  group('conversions', () {
    test('exact definitions', () {
      expect(usEn.toDisplay(1, Measure.length), closeTo(3.28084, 1e-5));
      expect(usEn.toDisplay(1, Measure.distance), closeTo(0.621371, 1e-6));
      expect(usEn.toDisplay(1, Measure.area), closeTo(10.7639, 1e-4));
      expect(usEn.toDisplay(2.54, Measure.smallLength), closeTo(1, 1e-12));
      expect(usEn.toDisplay(1, Measure.speed), closeTo(2.23694, 1e-5));
      expect(usEn.toDisplay(1, Measure.flow), closeTo(35.3147, 1e-4));
      expect(usEn.toDisplay(0, Measure.temperature), 32);
      expect(usEn.toDisplay(100, Measure.temperature), 212);
      expect(usEn.toDisplay(-40, Measure.temperature), -40);
      // A cord is 128 cubic feet, about 3.62 m³.
      expect(m3PerCord, closeTo(3.6246, 1e-4));
      expect(m3PerCcf, closeTo(2.8317, 1e-4));
    });

    test('there and back again gives the same number', () {
      for (final m in Measure.values) {
        for (final v in [0.0, 1.0, 7.25, 140.0, 2500.0]) {
          expect(usEn.fromDisplay(usEn.toDisplay(v, m), m), closeTo(v, 1e-9), reason: '$m $v');
        }
      }
    });

    test('metric is left alone', () {
      for (final m in Measure.values) {
        expect(metricEn.toDisplay(12.5, m), 12.5);
        expect(metricEn.fromDisplay(12.5, m), 12.5);
      }
    });
  });

  group('text', () {
    test('metric, as before', () {
      expect(metricEn.round(100, Measure.length), '100 m');
      expect(metricEn.range(5, 10, Measure.length), '5–10 m');
      expect(metricEn.round(60, Measure.area), '60 m²');
      expect(metricEn.distance(0.4), '0.4 km');
      expect(metricEn.speed(4.24), '4.2 m/s');
      expect(metricEn.one(Measure.volume), '1 m³');
      expect(metricEn.temperature(12.34), '12.3 °C');
    });

    test('US: round numbers as people say them', () {
      expect(usEn.round(100, Measure.length), '330 ft');
      expect(usEn.round(20, Measure.length), '66 ft');
      expect(usEn.range(5, 10, Measure.length), '16–33 ft');
      expect(usEn.range(1, 2, Measure.length), '3–7 ft');
      expect(usEn.range(5, 10, Measure.smallLength), '2–4 in');
      expect(usEn.round(60, Measure.area), '650 sq ft');
      expect(usEn.round(30, Measure.area), '320 sq ft');
      expect(usEn.round(25, Measure.distance), '16 mi');
      expect(usEn.round(2, Measure.distance), '1.2 mi');
      expect(usEn.speed(4.24), '9.5 mph');
      expect(usEn.temperature(12.34), '54.2 °F');
    });

    test('US: one cord, two cords', () {
      expect(usEn.one(Measure.volume), '1 cord');
      expect(usEn.round(8, Measure.volume), '2 cords');
    });

    test('each language writes numbers and units its own way', () {
      expect(const Units(UnitSystem.metric, 'hu').speed(4.24), '4,2 m/s');
      expect(const Units(UnitSystem.metric, 'ru').round(100, Measure.length), '100 м');
      expect(const Units(UnitSystem.metric, 'ru').speed(4.24), '4,2 м/с');
      expect(const Units(UnitSystem.metric, 'ko').round(60, Measure.area), '60m²');
      expect(const Units(UnitSystem.metric, 'sw').range(5, 10, Measure.length), 'm 5–10');
      expect(const Units(UnitSystem.metric, 'zh').round(2, Measure.distance), '2 公里');
      expect(const Units(UnitSystem.us, 'de').round(1000, Measure.area), '10.800 sq ft');
      expect(const Units(UnitSystem.us, 'fr').round(1000, Measure.area), '10 800 sq ft');
    });

    test('decimal comma and thousands for the newer languages too', () {
      expect(formatDecimal(4.26, 'cs'), '4,3');
      expect(formatDecimal(4.26, 'uk'), '4,3');
      expect(formatDecimal(4.26, 'mt'), '4.3');
      expect(groupDigits(1276, 'sl'), '1.276');
      expect(groupDigits(1276, 'cs'), '1 276');
      expect(groupDigits(1276, 'ga'), '1,276');
    });
  });

  group('which units a country starts on', () {
    test('the US and the places that measure like it', () {
      for (final c in ['US', 'us', 'PR', 'LR']) {
        expect(defaultUnitSystemFor(c), UnitSystem.us, reason: c);
      }
    });

    test('everyone else, and an unknown country, start metric', () {
      for (final c in ['HU', 'RO', 'GB', 'CA', 'MM', 'IN', null]) {
        expect(defaultUnitSystemFor(c), UnitSystem.metric, reason: '$c');
      }
    });

    test('the profile spells them METRIC and US; anything else means "follow the country"', () {
      expect(unitSystemFromApi('METRIC'), UnitSystem.metric);
      expect(unitSystemFromApi('US'), UnitSystem.us);
      expect(unitSystemFromApi(null), isNull);
      expect(unitSystemFromApi('AUTO'), isNull);
      expect(unitSystemToApi(UnitSystem.us), 'US');
      expect(unitSystemToApi(null), isNull);
    });
  });

  group('area units', () {
    test('exact definitions', () {
      expect(AreaUnit.hectare.toM2(1), 10000);
      expect(AreaUnit.are.toM2(1), 100);
      expect(AreaUnit.sotka.toM2(6), 600);
      expect(AreaUnit.negyszogol.toM2(1600), closeTo(AreaUnit.hold.toM2(1), 0.01));
      expect(AreaUnit.mu.toM2(15), closeTo(10000, 1e-9));
      expect(AreaUnit.pyeong.toM2(1), closeTo(3.3058, 1e-4));
      expect(AreaUnit.sqft.toM2(sqFtPerM2), closeTo(1, 1e-12));
      for (final u in AreaUnit.values) {
        expect(u.fromM2(u.toM2(123.4)), closeTo(123.4, 1e-9), reason: u.name);
      }
    });

    test('each country is offered its own units', () {
      expect(plotAreaUnits(UnitSystem.metric, 'HU'), [AreaUnit.m2, AreaUnit.negyszogol]);
      expect(plotAreaUnits(UnitSystem.metric, 'HU', land: true),
          [AreaUnit.m2, AreaUnit.negyszogol, AreaUnit.hectare, AreaUnit.acre, AreaUnit.hold]);
      expect(plotAreaUnits(UnitSystem.metric, 'RO', land: true), [AreaUnit.m2, AreaUnit.are, AreaUnit.hectare, AreaUnit.acre]);
      expect(plotAreaUnits(UnitSystem.metric, 'ua'), [AreaUnit.m2, AreaUnit.sotka]);
      expect(plotAreaUnits(UnitSystem.us, 'US'), [AreaUnit.sqft]);
      expect(plotAreaUnits(UnitSystem.metric, 'DE'), [AreaUnit.m2]);
      expect(fieldAreaUnits('HU'), [AreaUnit.hectare, AreaUnit.acre, AreaUnit.hold]);
      expect(fieldAreaUnits(null), [AreaUnit.hectare, AreaUnit.acre]);
    });

    test('fields start on acres in US units, mu in China, hectares elsewhere', () {
      expect(defaultFieldAreaUnit(UnitSystem.us, 'RO'), AreaUnit.acre);
      expect(defaultFieldAreaUnit(UnitSystem.metric, 'CN'), AreaUnit.mu);
      expect(defaultFieldAreaUnit(UnitSystem.metric, 'HU'), AreaUnit.hectare);
    });
  });

  test('"1.200" may mean 1200: the field asks; plain decimals do not', () {
    expect(looksLikeThousands('1.200'), '1200');
    expect(looksLikeThousands('1,200'), '1200');
    expect(looksLikeThousands('12.500'), '12500');
    expect(looksLikeThousands('1.2'), isNull);
    expect(looksLikeThousands('1.25'), isNull);
    expect(looksLikeThousands('0.125'), isNull);
    expect(looksLikeThousands('1200'), isNull);
    expect(looksLikeThousands('1234.567'), isNull);
  });

  // Every text with a measure in it, filled in for both systems in every language: nothing like
  // "{size}" may be left over, and the measure must really be in it.
  test('every measure text is filled in, in every language and both systems', () {
    final problems = <String>[];
    for (final lang in AppLanguages.all) {
      final t = AppLocalizations.stringsFor(Locale(lang.code));
      for (final system in UnitSystem.values) {
        final u = Units(system, lang.code);
        final texts = _measureTexts(t, u);
        texts.forEach((key, text) {
          if (RegExp(r'\{\w+\}').hasMatch(text)) problems.add('${lang.code} ${system.name} $key: "$text"');
        });
        final ft = texts['treeMedium']!;
        final want = u.range(5, 10, Measure.length);
        if (!ft.contains(want)) problems.add('${lang.code} ${system.name} treeMedium lacks "$want": "$ft"');
      }
    }
    expect(problems, isEmpty);
  });

  test('US units never show metric symbols in the measure texts (English)', () {
    final t = AppLocalizations.stringsFor(const Locale('en'));
    final texts = _measureTexts(t, usEn);
    final metric = RegExp(r'\d ?(m|km|cm|m²|m³|m/s|°C)\b|· (m|m³/s|m/s|°C)$');
    texts.forEach((key, text) => expect(metric.hasMatch(text), isFalse, reason: '$key: "$text"'));
  });
}

Map<String, String> _measureTexts(AppStrings t, Units u) => {
      'atHeight': t.atHeightFor(u.round(100, Measure.length)),
      'legendWindSpeed': t.legendWindSpeedFor(u.round(100, Measure.length), u.symbol(Measure.speed)),
      'legendPowerDensity': t.legendPowerDensityFor(u.round(100, Measure.length)),
      'legendRiverFlow': t.legendRiverFlowFor(u.symbol(Measure.flow)),
      'legendHead': t.legendHeadFor(u.symbol(Measure.length)),
      'legendGroundTemp': t.legendGroundTempFor(u.symbol(Measure.temperature)),
      'legendDepthTemp': t.legendDepthTempFor(u.round(2, Measure.distance), u.symbol(Measure.temperature)),
      'depthTempTitle': t.depthTempTitleFor(u.round(2, Measure.distance)),
      'legendBioResource': t.legendBioResourceFor(u.round(25, Measure.distance)),
      'legendBioEnergy': t.legendBioEnergyFor(u.round(25, Measure.distance)),
      'withinRadius': t.withinRadiusFor(u.round(25, Measure.distance)),
      'riverAway': t.riverAwayFor(u.distance(0.4)),
      'noHydroDataHere': t.noHydroDataHereFor(u.round(2, Measure.distance)),
      'insThin': t.insThinFor(u.round(5, Measure.smallLength)),
      'insMedium': t.insMediumFor(u.range(5, 10, Measure.smallLength)),
      'insThick': t.insThickFor(u.round(10, Measure.smallLength)),
      'aboutM2': t.aboutM2For(u.round(60, Measure.area)),
      'newDrawArea': t.newDrawAreaFor(u.round(60, Measure.area)),
      'landSmall': t.landSmallFor(u.round(20, Measure.area)),
      'balconySmall': t.balconySmallFor(u.range(1, 2, Measure.length)),
      'balconyLarge': t.balconyLargeFor(u.round(3, Measure.length)),
      'treeLow': t.treeLowFor(u.round(5, Measure.length)),
      'treeMedium': t.treeMediumFor(u.range(5, 10, Measure.length)),
      'treeTall': t.treeTallFor(u.round(10, Measure.length)),
      'riverFound': t.riverFoundFor(u.round(350, Measure.length)),
      'windFound': t.windFoundFor(u.speed(4.2), u.round(20, Measure.length)),
      'woodPriceQ': t.woodPriceQFor(u.one(Measure.volume)),
      'unsureAmount': t.unsureAmountFor(u.round(8, Measure.volume)),
      'bottleSizeNote': u.isUs ? t.bottleSizeNoteFor('20 lb', '4.7 gal') : t.bottleSizeNoteFor('26 L', '11 kg'),
    };
