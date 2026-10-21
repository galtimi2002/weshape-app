// Named widget_test.dart on purpose: `flutter create` writes a counter-app
// test under this name unless the file already exists, and that test does
// not compile against this app.

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
import 'package:weshape_app/core/widgets/language_menu.dart';
import 'package:weshape_app/core/widgets/theme_switch.dart';
import 'package:weshape_app/features/profile/profile_controller.dart';

Widget _harness(SettingsController settings) {
  final api = ApiClient(authService: DemoAuthService(), baseUrl: 'http://localhost:1');
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<SettingsController>.value(value: settings),
      ChangeNotifierProvider<ProfileController>(create: (_) => ProfileController(api, settings)),
    ],
    child: Consumer<SettingsController>(
      builder: (context, s, _) => MaterialApp(
        theme: WeShapeTheme.light(),
        darkTheme: WeShapeTheme.dark(),
        themeMode: s.themeMode,
        locale: s.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) => Scaffold(
            appBar: AppBar(actions: const [LanguageMenu(), ThemeSwitch()]),
            body: Center(child: Text(context.t.signIn)),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUp(() {
    WeShapeTheme.useGoogleFonts = false;
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('picking Magyar switches the interface and is remembered', (tester) async {
    final settings = SettingsController();
    await settings.load();
    await tester.pumpWidget(_harness(settings));
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Magyar').last);
    await tester.pumpAndSettle();

    expect(find.text('Bejelentkezés'), findsOneWidget);
    expect(settings.languageCode, 'hu');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('weshape.language'), 'hu');
  });

  testWidgets('the sun/moon switch flips the theme and remembers it', (tester) async {
    final settings = SettingsController();
    await settings.load();
    await settings.setThemeMode(ThemeMode.light);
    await tester.pumpWidget(_harness(settings));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.light_mode_rounded), findsOneWidget);

    await tester.tap(find.byType(ThemeSwitch));
    await tester.pumpAndSettle();

    expect(settings.themeMode, ThemeMode.dark);
    expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('weshape.themeMode'), 'dark');
  });
}
