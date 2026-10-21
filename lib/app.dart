import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/auth/auth_controller.dart';
import 'core/i18n/app_localizations.dart';
import 'core/settings/settings_controller.dart';
import 'core/theme/weshape_palette.dart';
import 'core/theme/weshape_theme.dart';
import 'features/auth/auth_flow.dart';
import 'features/home/home_screen.dart';
import 'features/profile/complete_profile_screen.dart';
import 'features/profile/profile_controller.dart';
import 'features/splash/splash_screen.dart';

class WeShapeApp extends StatelessWidget {
  const WeShapeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    return MaterialApp(
      title: 'WeShape Energy',
      debugShowCheckedModeBanner: false,
      theme: WeShapeTheme.light(),
      darkTheme: WeShapeTheme.dark(),
      themeMode: settings.themeMode,
      themeAnimationDuration: const Duration(milliseconds: 300),
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const RootGate(),
    );
  }
}

/// Splash, sign-in, "one more step", or home, decided from auth and profile state.
class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  String? _loadedFor;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final settings = context.watch<SettingsController>();
    final profile = context.watch<ProfileController>();

    if (!settings.isLoaded || auth.status == AuthStatus.unknown) return const SplashScreen();

    if (auth.status == AuthStatus.signedOut) {
      if (_loadedFor != null) {
        _loadedFor = null;
        WidgetsBinding.instance.addPostFrameCallback((_) => profile.clear());
      }
      return const AuthFlow(key: ValueKey('auth'));
    }

    // Signed in: load the profile once per account.
    final uid = auth.user!.uid;
    if (_loadedFor != uid) {
      _loadedFor = uid;
      WidgetsBinding.instance.addPostFrameCallback((_) => profile.load());
    }

    if (profile.profile == null) {
      if (profile.error != null && !profile.isLoading) {
        return _LoadError(onRetry: profile.load, onSignOut: auth.signOut);
      }
      return const SplashScreen();
    }

    if (profile.needsProfile) return const CompleteProfileScreen(key: ValueKey('complete'));
    return const HomeScreen(key: ValueKey('home'));
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry, required this.onSignOut});

  final Future<void> Function() onRetry;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final p = context.palette;
    final error = context.watch<ProfileController>().error;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_rounded, size: 44, color: p.muted),
                const SizedBox(height: 14),
                Text(error?.message(t) ?? t.errorGeneric, textAlign: TextAlign.center, style: TextStyle(color: p.muted)),
                const SizedBox(height: 18),
                OutlinedButton(onPressed: onRetry, child: Text(t.retry)),
                const SizedBox(height: 6),
                TextButton(onPressed: onSignOut, child: Text(t.signOut)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
