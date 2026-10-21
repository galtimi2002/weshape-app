/// Build-time configuration, all overridable with --dart-define.
///
///   flutter run --dart-define=API_BASE_URL=https://weshape-backend.onrender.com \
///               --dart-define=AUTH_MODE=firebase
abstract final class AppConfig {
  /// Base URL of weshape-backend, without a trailing slash.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  /// 'demo'     sign-in is simulated on the device and the app sends dev tokens.
  ///            Pair with WESHAPE_AUTH_MODE=dev on the backend.
  /// 'firebase' real Firebase Authentication. Needs firebase_options.dart from
  ///            `flutterfire configure`.
  static const String authMode = String.fromEnvironment('AUTH_MODE', defaultValue: 'demo');

  static bool get isDemoAuth => authMode != 'firebase';

  static const Duration requestTimeout = Duration(seconds: 20);

  /// The free Render tier stops the backend when idle and the request that
  /// wakes it can take most of a minute, so the first call gets a longer budget.
  static const Duration coldStartTimeout = Duration(seconds: 75);

  /// How long the splash waits before explaining that the server is starting.
  static const Duration coldStartHintDelay = Duration(seconds: 6);
}
