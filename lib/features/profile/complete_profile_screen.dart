import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/i18n/languages.dart';
import '../../core/models/user_profile.dart';
import '../../core/settings/settings_controller.dart';
import '../../core/theme/weshape_palette.dart';
import '../../core/widgets/auth_layout.dart';
import '../../core/widgets/country_field.dart';
import '../../core/widgets/language_field.dart';
import '../../core/widgets/primary_button.dart';
import '../auth/validators.dart';
import 'profile_controller.dart';

/// "One more step": shown once after a first Google sign-in, which brings an
/// email and usually a name but never a country.
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  String? _country;
  late String _languageWeSet;
  bool _saving = false;
  ApiException? _error;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileController>().profile;
    _firstName = TextEditingController(text: profile?.firstName ?? '');
    _lastName = TextEditingController(text: profile?.lastName ?? '');
    _country = profile?.country;
    _languageWeSet = context.read<SettingsController>().languageCode;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  void _onCountry(String country) {
    setState(() => _country = country);
    if (context.read<SettingsController>().languageCode == _languageWeSet) {
      _languageWeSet = AppLanguages.forCountry(country);
      context.read<ProfileController>().changeLanguage(_languageWeSet);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final settings = context.read<SettingsController>();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<ProfileController>().completeProfile(ProfileDraft(
            firstName: _firstName.text,
            lastName: _lastName.text,
            country: _country!,
            preferredLanguage: settings.languageCode,
            themeMode: settings.themeMode,
          ));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final p = context.palette;
    final language = context.watch<SettingsController>().languageCode;
    final email = context.watch<ProfileController>().profile?.email ?? '';

    return AuthLayout(
      footer: Center(
        child: TextButton.icon(
          onPressed: () => context.read<AuthController>().signOut(),
          icon: const Icon(Icons.logout_rounded, size: 16),
          label: Text(t.signOut),
        ),
      ),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthHeading(title: t.completeProfileTitle, subtitle: t.completeProfileSubtitle),
            const SizedBox(height: 6),
            Text(email, style: TextStyle(fontSize: 13, color: p.muted)),
            const SizedBox(height: 18),
            LabeledField(
              label: t.firstName,
              child: TextFormField(
                controller: _firstName,
                textCapitalization: TextCapitalization.words,
                validator: (v) => Validators.required(t, v),
              ),
            ),
            const SizedBox(height: 14),
            LabeledField(
              label: t.lastName,
              child: TextFormField(
                controller: _lastName,
                textCapitalization: TextCapitalization.words,
                validator: (v) => Validators.required(t, v),
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
            if (_error != null) ...[const SizedBox(height: 12), ErrorBanner(_error!.message(t))],
            const SizedBox(height: 18),
            PrimaryButton(label: t.saveAndContinue, busy: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
