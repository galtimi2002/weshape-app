import '../../core/i18n/app_strings.dart';

/// The rules a new password must meet, each checked on its own so the registration form can tick
/// them off while the person types.
enum PasswordRule { length, upper, lower, digit, special }

abstract final class Validators {
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _upper = RegExp(r'\p{Lu}', unicode: true);
  static final RegExp _lower = RegExp(r'\p{Ll}', unicode: true);
  static final RegExp _digit = RegExp(r'\p{Nd}', unicode: true);

  /// Anything that is not a letter, a digit or a space: ! ? # @ - _ and so on.
  static final RegExp _special = RegExp(r'[^\p{L}\p{Nd}\s]', unicode: true);

  /// Shortest new password; Firebase itself accepts 6.
  static const minPasswordLength = 8;

  static String? required(AppStrings t, String? v) => (v == null || v.trim().isEmpty) ? t.fieldRequired : null;

  static bool isEmail(String v) => _email.hasMatch(v.trim());

  static String? email(AppStrings t, String? v) {
    if (v == null || v.trim().isEmpty) return t.fieldRequired;
    return _email.hasMatch(v.trim()) ? null : t.invalidEmail;
  }

  /// Whether [password] meets [rule].
  static bool meets(PasswordRule rule, String password) => switch (rule) {
        PasswordRule.length => password.runes.length >= minPasswordLength,
        PasswordRule.upper => _upper.hasMatch(password),
        PasswordRule.lower => _lower.hasMatch(password),
        PasswordRule.digit => _digit.hasMatch(password),
        PasswordRule.special => _special.hasMatch(password),
      };

  static String ruleText(AppStrings t, PasswordRule rule) => switch (rule) {
        PasswordRule.length => t.pwRuleLength,
        PasswordRule.upper => t.pwRuleUpper,
        PasswordRule.lower => t.pwRuleLower,
        PasswordRule.digit => t.pwRuleDigit,
        PasswordRule.special => t.pwRuleSpecial,
      };

  /// A new password (registration): every rule must be met.
  static String? newPassword(AppStrings t, String? v) {
    if (v == null || v.isEmpty) return t.fieldRequired;
    return PasswordRule.values.every((r) => meets(r, v)) ? null : t.passwordWeak;
  }
}
