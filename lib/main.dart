import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/api/api_client.dart';
import 'core/auth/auth_controller.dart';
import 'core/auth/auth_service.dart';
import 'core/auth/demo_auth_service.dart';
import 'core/auth/firebase_auth_service.dart';
import 'core/config/app_config.dart';
import 'core/settings/settings_controller.dart';
import 'features/profile/profile_controller.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final AuthService authService = await _createAuthService();
  final settings = SettingsController();
  final auth = AuthController(authService);
  final api = ApiClient(authService: authService);
  final profile = ProfileController(api, settings);

  // Wake the free-tier backend while the login page is being read.
  api.warmUp();

  await Future.wait([settings.load(), auth.initialize()]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsController>.value(value: settings),
        ChangeNotifierProvider<AuthController>.value(value: auth),
        Provider<ApiClient>.value(value: api),
        ChangeNotifierProvider<ProfileController>.value(value: profile),
      ],
      child: const WeShapeApp(),
    ),
  );
}

/// Real Firebase sign-in by default; --dart-define=AUTH_MODE=demo simulates it.
Future<AuthService> _createAuthService() async {
  if (AppConfig.isDemoAuth) return DemoAuthService();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  return FirebaseAuthService();
}
