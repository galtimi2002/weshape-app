import '../i18n/app_strings.dart';

enum AuthFailureKind { invalidCredentials, emailInUse, weakPassword, invalidEmail, tooManyRequests, network, cancelled, unknown }

class AuthFailure implements Exception {
  const AuthFailure(this.kind, [this.detail]);

  final AuthFailureKind kind;
  final String? detail;

  bool get isCancelled => kind == AuthFailureKind.cancelled;

  String message(AppStrings t) => switch (kind) {
        AuthFailureKind.invalidCredentials => t.errorInvalidCredentials,
        AuthFailureKind.emailInUse => t.errorEmailInUse,
        AuthFailureKind.weakPassword => t.passwordTooShort,
        AuthFailureKind.invalidEmail => t.invalidEmail,
        AuthFailureKind.tooManyRequests => t.errorTooManyRequests,
        AuthFailureKind.network => t.errorNetwork,
        AuthFailureKind.cancelled || AuthFailureKind.unknown => t.errorGeneric,
      };

  @override
  String toString() => 'AuthFailure($kind${detail == null ? '' : ': $detail'})';
}
