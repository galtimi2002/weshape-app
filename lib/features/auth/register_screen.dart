import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/auth/auth_failure.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/i18n/languages.dart';
import '../../core/models/user_profile.dart';
import '../../core/settings/settings_controller.dart';
import '../../core/theme/weshape_palette.dart';
import '../../core/widgets/auth_layout.dart';
import '../../core/widgets/country_field.dart';
import '../../core/widgets/language_field.dart';
import '../../core/widgets/primary_button.dart';
import '../profile/profile_controller.dart';
import 'masked_controller.dart';
import 'validators.dart';

/// Registration: name, email, country, language, password.
///
/// The language starts as whatever the page is in (English on a first visit).
/// Picking a country switches it to that country's language on the spot, until
/// the person chooses a language themselves; from then on their choice stays.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = MaskedController();
  final _confirm = MaskedController();
  String? _country;

  /// The email is checked once the person leaves the field (they have finished typing it); from then
  /// on the message comes and goes as they correct it.
  final _emailFocus = FocusNode();
  bool _emailLeft = false;
  bool _obscure = true;
  AuthFailure? _failure;

  /// The language the app had when this page opened, or the last one this
  /// page set from a country. Anything else on screen means the person chose.
  late String _languageWeSet;

  @override
  void initState() {
    super.initState();
    _languageWeSet = context.read<SettingsController>().languageCode;
    // The button turns on and off as the fields fill in.
    for (final c in [_firstName, _lastName, _email, _password, _confirm]) {
      c.addListener(_refresh);
    }
    _emailFocus.addListener(() {
      if (!_emailFocus.hasFocus && _email.text.trim().isNotEmpty && !_emailLeft) {
        setState(() => _emailLeft = true);
      }
    });
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  /// Everything filled in and right: only then can the account be created. No "required" messages;
  /// the button simply stays off until then.
  bool get _complete =>
      _firstName.text.trim().isNotEmpty &&
      _lastName.text.trim().isNotEmpty &&
      Validators.isEmail(_email.text) &&
      _country != null &&
      PasswordRule.values.every((r) => Validators.meets(r, _password.text)) &&
      _confirm.text == _password.text;

  @override
  void dispose() {
    for (final c in [_firstName, _lastName, _email, _password, _confirm]) {
      c.dispose();
    }
    _emailFocus.dispose();
    super.dispose();
  }

  void _onCountry(String country) {
    setState(() => _country = country);
    final current = context.read<SettingsController>().languageCode;
    if (current == _languageWeSet) {
      _languageWeSet = AppLanguages.forCountry(country);
      context.read<ProfileController>().changeLanguage(_languageWeSet);
    }
  }

  Future<void> _register() async {
    setState(() => _failure = null);
    if (!_complete) return;

    final settings = context.read<SettingsController>();
    final auth = context.read<AuthController>();
    final profile = context.read<ProfileController>()
      ..setPendingRegistration(ProfileDraft(
        firstName: _firstName.text,
        lastName: _lastName.text,
        country: _country!,
        preferredLanguage: settings.languageCode,
        themeMode: settings.themeMode,
      ));

    try {
      await auth.run(() => auth.service.registerWithEmail(_email.text, _password.text));
    } on AuthFailure catch (e) {
      profile.clearPendingRegistration();
      if (mounted) setState(() => _failure = e);
    }
  }

  Future<void> _google() async {
    setState(() => _failure = null);
    final auth = context.read<AuthController>();
    try {
      await auth.run(auth.service.signInWithGoogle);
    } on AuthFailure catch (e) {
      if (mounted && !e.isCancelled) setState(() => _failure = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final p = context.palette;
    final busy = context.watch<AuthController>().busy;
    final language = context.watch<SettingsController>().languageCode;
    final wide = MediaQuery.sizeOf(context).width >= 700;

    final firstName = LabeledField(
      label: t.firstName,
      child: TextFormField(
        controller: _firstName,
        textCapitalization: TextCapitalization.words,
        autofillHints: const [AutofillHints.givenName],
        textInputAction: TextInputAction.next,
      ),
    );
    final lastName = LabeledField(
      label: t.lastName,
      child: TextFormField(
        controller: _lastName,
        textCapitalization: TextCapitalization.words,
        autofillHints: const [AutofillHints.familyName],
        textInputAction: TextInputAction.next,
      ),
    );

    final email = LabeledField(
      label: t.email,
      child: TextFormField(
        controller: _email,
        focusNode: _emailFocus,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          errorText: _emailLeft && _email.text.trim().isNotEmpty && !Validators.isEmail(_email.text)
              ? t.invalidEmail
              : null,
        ),
      ),
    );
    final country = LabeledField(
      label: t.country,
      child: CountryField(
        initialValue: _country,
        onChanged: _onCountry,
      ),
    );
    final languageField = LabeledField(
      label: t.language,
      child: LanguageField(
        value: language,
        onChanged: (code) => context.read<ProfileController>().changeLanguage(code),
      ),
    );
    final password = LabeledField(
      label: t.password,
      child: TextFormField(
        controller: _password,
        // Not a browser password field (no obscureText): Edge, Chrome, Safari and Firefox then show
        // no "suggested strong password" pop-up over the rules. The controller draws dots instead.
        enableSuggestions: false,
        autocorrect: false,
        enableIMEPersonalizedLearning: false,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          // The button never takes the focus away from the field (see the login screen).
          suffixIcon: ExcludeFocus(
            child: IconButton(
              tooltip: t.password,
              icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20, color: p.muted),
              onPressed: () => setState(() {
                _obscure = !_obscure;
                _password.obscure = _obscure;
                _confirm.obscure = _obscure;
              }),
            ),
          ),
        ),
      ),
    );
    final confirm = LabeledField(
      label: t.confirmPassword,
      child: TextFormField(
        controller: _confirm,
        // Not a browser password field (no obscureText): Edge, Chrome, Safari and Firefox then show
        // no "suggested strong password" pop-up over the rules. The controller draws dots instead.
        enableSuggestions: false,
        autocorrect: false,
        enableIMEPersonalizedLearning: false,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _register(),
      ),
    );

    // Two fields side by side on wide screens, stacked on phones.
    List<Widget> pair(Widget a, Widget b) => wide
        ? [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Expanded(child: a), const SizedBox(width: 12), Expanded(child: b)],
            ),
          ]
        : [a, const SizedBox(height: 12), b];

    return AuthLayout(
      maxWidth: wide ? 520 : 340,
      // Leaving the page never asks the browser to save anything.
      child: AutofillGroup(
        onDisposeAction: AutofillContextAction.cancel,
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthHeading(title: t.createAccountTitle),
              const SizedBox(height: 16),
              ...pair(firstName, lastName),
              const SizedBox(height: 12),
              email,
              const SizedBox(height: 12),
              ...pair(country, languageField),
              const SizedBox(height: 4),
              Text(t.languageHint, style: TextStyle(fontSize: 11.5, color: p.muted)),
              const SizedBox(height: 12),
              ...pair(password, confirm),
              // Once the person starts typing, only what is still missing shows; each line goes away
              // as soon as it is met. The same for the confirmation not matching.
              if (_password.text.isNotEmpty && !PasswordRule.values.every((r) => Validators.meets(r, _password.text))) ...[
                const SizedBox(height: 10),
                _PasswordRules(password: _password.text),
              ],
              if (_confirm.text.isNotEmpty && _confirm.text != _password.text) ...[
                const SizedBox(height: 6),
                _Check(text: t.passwordsDoNotMatch, color: p.error),
              ],
              if (_failure != null) ...[const SizedBox(height: 12), ErrorBanner(_failure!.message(t))],
              const SizedBox(height: 16),
              PrimaryButton(label: t.createAccount, busy: busy, onPressed: _complete ? _register : null),
              const SizedBox(height: 12),
              OrDivider(t.orDivider),
              const SizedBox(height: 12),
              GoogleButton(label: t.continueWithGoogle, onPressed: busy ? null : _google),
              const SizedBox(height: 6),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(t.haveAccount, style: TextStyle(color: p.muted, fontSize: 12.5)),
                  TextButton(onPressed: busy ? null : widget.onSignIn, child: Text(t.signIn)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The password rules still missing; each line goes away as soon as the password meets it.
class _PasswordRules extends StatelessWidget {
  const _PasswordRules({required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        for (final rule in PasswordRule.values)
          if (!Validators.meets(rule, password)) _Check(text: Validators.ruleText(t, rule), color: context.palette.error),
      ],
    );
  }
}

/// One line: a small mark and a short text, in [color].
class _Check extends StatelessWidget {
  const _Check({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.close_rounded, size: 16, color: color),
        const SizedBox(width: 6),
        Flexible(child: Text(text, style: TextStyle(fontSize: 12.5, color: color))),
      ],
    );
  }
}
