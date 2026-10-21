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
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _country;
  bool _obscure = true;
  AuthFailure? _failure;

  /// The language the app had when this page opened, or the last one this
  /// page set from a country. Anything else on screen means the person chose.
  late String _languageWeSet;

  @override
  void initState() {
    super.initState();
    _languageWeSet = context.read<SettingsController>().languageCode;
  }

  @override
  void dispose() {
    for (final c in [_firstName, _lastName, _email, _password, _confirm]) {
      c.dispose();
    }
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
    if (!_form.currentState!.validate()) return;

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
    final wide = MediaQuery.sizeOf(context).width >= 600;

    final firstName = LabeledField(
      label: t.firstName,
      child: TextFormField(
        controller: _firstName,
        textCapitalization: TextCapitalization.words,
        autofillHints: const [AutofillHints.givenName],
        textInputAction: TextInputAction.next,
        validator: (v) => Validators.required(t, v),
      ),
    );
    final lastName = LabeledField(
      label: t.lastName,
      child: TextFormField(
        controller: _lastName,
        textCapitalization: TextCapitalization.words,
        autofillHints: const [AutofillHints.familyName],
        textInputAction: TextInputAction.next,
        validator: (v) => Validators.required(t, v),
      ),
    );

    return AuthLayout(
      footer: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(t.haveAccount, style: TextStyle(color: p.muted, fontSize: 13)),
          TextButton(onPressed: busy ? null : widget.onSignIn, child: Text(t.signIn)),
        ],
      ),
      child: AutofillGroup(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthHeading(title: t.createAccountTitle, subtitle: t.signUpSubtitle),
              const SizedBox(height: 20),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: firstName),
                    const SizedBox(width: 12),
                    Expanded(child: lastName),
                  ],
                )
              else ...[
                firstName,
                const SizedBox(height: 14),
                lastName,
              ],
              const SizedBox(height: 14),
              LabeledField(
                label: t.email,
                child: TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(hintText: 'name@company.com'),
                  validator: (v) => Validators.email(t, v),
                ),
              ),
              const SizedBox(height: 14),
              LabeledField(
                label: t.country,
                child: CountryField(
                  initialValue: _country,
                  onChanged: _onCountry,
                  validator: (v) => v == null ? t.fieldRequired : null,
                ),
              ),
              const SizedBox(height: 14),
              LabeledField(
                label: t.language,
                child: LanguageField(
                  value: language,
                  onChanged: (code) => context.read<ProfileController>().changeLanguage(code),
                ),
              ),
              const SizedBox(height: 6),
              Text(t.languageHint, style: TextStyle(fontSize: 12, color: p.muted)),
              const SizedBox(height: 14),
              LabeledField(
                label: t.password,
                child: TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    helperText: t.passwordHint,
                    helperStyle: TextStyle(color: p.muted, fontSize: 12),
                    suffixIcon: IconButton(
                      tooltip: t.password,
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 20, color: p.muted),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => Validators.newPassword(t, v),
                ),
              ),
              const SizedBox(height: 14),
              LabeledField(
                label: t.confirmPassword,
                child: TextFormField(
                  controller: _confirm,
                  obscureText: _obscure,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _register(),
                  validator: (v) => v != _password.text ? t.passwordsDoNotMatch : null,
                ),
              ),
              if (_failure != null) ...[const SizedBox(height: 12), ErrorBanner(_failure!.message(t))],
              const SizedBox(height: 18),
              PrimaryButton(label: t.createAccount, busy: busy, onPressed: _register),
              const SizedBox(height: 16),
              OrDivider(t.orDivider),
              const SizedBox(height: 16),
              GoogleButton(label: t.continueWithGoogle, onPressed: busy ? null : _google),
            ],
          ),
        ),
      ),
    );
  }
}
