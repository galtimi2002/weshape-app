import '../../core/i18n/app_strings.dart';

abstract final class Validators {
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? required(AppStrings t, String? v) => (v == null || v.trim().isEmpty) ? t.fieldRequired : null;

  static String? email(AppStrings t, String? v) {
    if (v == null || v.trim().isEmpty) return t.fieldRequired;
    return _email.hasMatch(v.trim()) ? null : t.invalidEmail;
  }

  /// Firebase accepts 6; 8 is the floor here.
  static String? newPassword(AppStrings t, String? v) {
    if (v == null || v.isEmpty) return t.fieldRequired;
    return v.length < 8 ? t.passwordTooShort : null;
  }
}
