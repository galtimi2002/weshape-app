// The input fields with units, on screen: what a person types in their units is saved in metric
// (m², kg), and a number that looks like a thousands separator was meant gets a note.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weshape_app/core/api/api_client.dart';
import 'package:weshape_app/core/auth/demo_auth_service.dart';
import 'package:weshape_app/core/i18n/app_localizations.dart';
import 'package:weshape_app/core/settings/settings_controller.dart';
import 'package:weshape_app/core/theme/weshape_theme.dart';
import 'package:weshape_app/core/units/units.dart';
import 'package:weshape_app/features/assessment/controls.dart';
import 'package:weshape_app/features/profile/profile_controller.dart';

/// [field] on a page, with the app's settings, language and units.
Future<SettingsController> _pump(WidgetTester tester, Widget field, {UnitSystem units = UnitSystem.metric, String language = 'en'}) async {
  final settings = SettingsController();
  await settings.load();
  await settings.setLanguage(language);
  await settings.setUnitSystem(units);
  final api = ApiClient(authService: DemoAuthService(), baseUrl: 'http://localhost:1');
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider<SettingsController>.value(value: settings),
      ChangeNotifierProvider<ProfileController>(create: (_) => ProfileController(api, settings)),
    ],
    child: MaterialApp(
      theme: WeShapeTheme.light(),
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: field)),
    ),
  ));
  await tester.pumpAndSettle();
  return settings;
}

void main() {
  setUp(() {
    WeShapeTheme.useGoogleFonts = false;
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('areas', () {
    testWidgets('sq ft typed in US units is saved as m²', (tester) async {
      double? saved;
      await _pump(tester, MeasureField(value: null, measure: Measure.area, onChanged: (v) => saved = v), units: UnitSystem.us);
      expect(find.text('sq ft'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '1000');
      await tester.pump();
      expect(saved, closeTo(1000 / 10.7639104, 1e-6)); // 92.90 m²
    });

    testWidgets('a saved m² area shows in sq ft in US units', (tester) async {
      await _pump(tester, MeasureField(value: 92.9030, measure: Measure.area, onChanged: (_) {}), units: UnitSystem.us);
      expect(find.text('1000'), findsOneWidget);
    });

    testWidgets('m² typed in metric units is saved as it is', (tester) async {
      double? saved;
      await _pump(tester, MeasureField(value: null, measure: Measure.area, onChanged: (v) => saved = v));
      expect(find.text('m²'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '120');
      await tester.pump();
      expect(saved, 120);
    });

    testWidgets('négyszögöl picked and typed is saved as m²', (tester) async {
      double? saved;
      await _pump(
        tester,
        StatefulBuilder(
          builder: (context, setState) => AreaField(
            value: saved,
            units: const [AreaUnit.m2, AreaUnit.negyszogol],
            onChanged: (v) => setState(() => saved = v),
          ),
        ),
        language: 'hu',
      );
      await tester.tap(find.text('négyszögöl'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '200');
      await tester.pump();
      expect(saved, closeTo(200 * 3.596652, 1e-6)); // 719.33 m²

      // Back to m²: the same area, now in m².
      await tester.tap(find.text('m²'));
      await tester.pumpAndSettle();
      expect(find.text('719.33'), findsOneWidget);
    });

    testWidgets('a saved m² area shows in kat. hold when that is picked', (tester) async {
      await _pump(
        tester,
        AreaField(value: 5754.642, units: const [AreaUnit.hectare, AreaUnit.acre, AreaUnit.hold], onChanged: (_) {}),
        language: 'hu',
      );
      expect(find.text('0.58'), findsOneWidget); // hectares, two decimals
      await tester.tap(find.text('kat. hold'));
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);
    });
  });

  group('weights', () {
    testWidgets('a bag typed in lb in US units is saved in kg', (tester) async {
      double? saved;
      await _pump(tester, MeasureField(value: null, measure: Measure.mass, onChanged: (v) => saved = v), units: UnitSystem.us);
      expect(find.text('lb'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '40');
      await tester.pump();
      expect(saved, closeTo(18.1436948, 1e-6));
    });

    testWidgets('the 15 kg bag shows as 15 kg in metric units', (tester) async {
      await _pump(tester, MeasureField(value: 15, measure: Measure.mass, onChanged: (_) {}));
      expect(find.text('15'), findsOneWidget);
      expect(find.text('kg'), findsOneWidget);
    });

    testWidgets('a 40 lb bag saved in kg shows as 40 lb again', (tester) async {
      await _pump(tester, MeasureField(value: 40 * kgPerLb, measure: Measure.mass, onChanged: (_) {}), units: UnitSystem.us);
      expect(find.text('40'), findsOneWidget);
    });
  });

  group('"did you mean 1200?"', () {
    testWidgets('1.200 gets the note, and its button makes it 1200', (tester) async {
      double? saved;
      await _pump(tester, NumberField(value: null, onChanged: (v) => saved = v, suffix: 'kWh'));
      await tester.enterText(find.byType(TextField), '1.200');
      await tester.pump();
      expect(saved, 1.2);
      expect(find.text('Did you mean 1.2? If you meant 1200, type 1200.'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, '1200'));
      await tester.pump();
      expect(saved, 1200);
      expect(find.textContaining('Did you mean'), findsNothing);
    });

    testWidgets('in Hungarian the note writes the decimal with a comma', (tester) async {
      await _pump(tester, NumberField(value: null, onChanged: (_) {}), language: 'hu');
      await tester.enterText(find.byType(TextField), '1,200');
      await tester.pump();
      expect(find.textContaining('1,2?'), findsOneWidget);
      expect(find.textContaining('1.200'), findsNothing);
      expect(find.widgetWithText(TextButton, '1200'), findsOneWidget);
    });

    testWidgets('1.250 reads as 1.25, 3.000 as 3', (tester) async {
      await _pump(tester, NumberField(value: null, onChanged: (_) {}));
      await tester.enterText(find.byType(TextField), '1.250');
      await tester.pump();
      expect(find.text('Did you mean 1.25? If you meant 1250, type 1250.'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '3.000');
      await tester.pump();
      expect(find.text('Did you mean 3? If you meant 3000, type 3000.'), findsOneWidget);
    });

    testWidgets('ordinary numbers get no note', (tester) async {
      await _pump(tester, NumberField(value: null, onChanged: (_) {}));
      for (final text in ['1200', '1.2', '4.25', '0.125', '12']) {
        await tester.enterText(find.byType(TextField), text);
        await tester.pump();
        expect(find.textContaining('Did you mean'), findsNothing, reason: text);
      }
    });

    testWidgets('money never gets the note (cents have two digits)', (tester) async {
      await _pump(tester, NumberField(value: null, money: true, onChanged: (_) {}));
      await tester.enterText(find.byType(TextField), '1.20');
      await tester.pump();
      expect(find.textContaining('Did you mean'), findsNothing);
    });
  });
}
