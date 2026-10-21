import '../i18n/app_strings.dart';

class ApiException implements Exception {
  const ApiException({required this.statusCode, this.serverMessage, this.fieldErrors = const {}});

  const ApiException.network() : this(statusCode: 0);

  final int statusCode;
  final String? serverMessage;
  final Map<String, String> fieldErrors;

  bool get isNetwork => statusCode == 0;
  bool get isUnauthorized => statusCode == 401;

  /// Translated text. Server messages are English-only, so they are not shown;
  /// the status decides which of the app's own messages fits.
  String message(AppStrings t) {
    if (isNetwork) return t.errorNetwork;
    if (isUnauthorized) return t.errorSessionExpired;
    if (statusCode == 409) return t.errorEmailInUse;
    return t.errorGeneric;
  }

  @override
  String toString() => 'ApiException($statusCode, $serverMessage, $fieldErrors)';
}
