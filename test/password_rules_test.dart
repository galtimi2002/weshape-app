import 'package:flutter_test/flutter_test.dart';
import 'package:weshape_app/core/i18n/strings/strings_en.dart';
import 'package:weshape_app/features/auth/validators.dart';

void main() {
  group('new password rules', () {
    bool meets(PasswordRule r, String p) => Validators.meets(r, p);

    test('each rule on its own', () {
      expect(meets(PasswordRule.length, 'Abcdef1!'), isTrue);
      expect(meets(PasswordRule.length, 'Abcde1!'), isFalse);
      expect(meets(PasswordRule.upper, 'abc'), isFalse);
      expect(meets(PasswordRule.upper, 'aBc'), isTrue);
      expect(meets(PasswordRule.upper, 'árvíztűrő Á'), isTrue);
      expect(meets(PasswordRule.lower, 'ABC'), isFalse);
      expect(meets(PasswordRule.lower, 'ABc'), isTrue);
      expect(meets(PasswordRule.digit, 'abc'), isFalse);
      expect(meets(PasswordRule.digit, 'ab3'), isTrue);
      expect(meets(PasswordRule.special, 'Ab3 x'), isFalse);
      expect(meets(PasswordRule.special, 'Ab3#'), isTrue);
      expect(meets(PasswordRule.special, 'Ab3-'), isTrue);
    });

    test('the form accepts a password only when every rule is met', () {
      const t = kStringsEn;
      expect(Validators.newPassword(t, ''), t.fieldRequired);
      expect(Validators.newPassword(t, 'abcdefgh'), t.passwordWeak);
      expect(Validators.newPassword(t, 'Abcdefg1'), t.passwordWeak);
      expect(Validators.newPassword(t, 'Abcdef1!'), isNull);
    });
  });
}
