import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/auth/auth_failure.dart';
import '../../core/auth/credential_store.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/settings/settings_controller.dart';
import '../../core/theme/weshape_palette.dart';
import '../../core/widgets/auth_layout.dart';
import '../../core/widgets/primary_button.dart';
import 'masked_controller.dart';
import 'validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onRegister});

  final VoidCallback onRegister;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = MaskedController();

  /// The browser's chooser of saved passwords is offered once, on the first tap in the email field.
  bool _offeredSaved = false;

  /// The password field keeps the keyboard after the eye button and after a failed sign-in: on the
  /// web, switching between hidden and shown text while the field is not focused could leave it
  /// unable to take any more typing or deleting.
  final _passwordFocus = FocusNode();
  bool _remember = true;
  bool _obscure = true;
  AuthFailure? _failure;

  /// The failed address signs in with Google only: then the form gives way to the Google button.
  bool _useGoogle = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _failure = null;
      _useGoogle = false;
    });
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    final api = context.read<ApiClient>();
    // Kept here: once signed in, this page (and its fields) may already be gone.
    final email = _email.text;
    final password = _password.text;
    try {
      await auth.run(() => auth.service.signInWithEmail(email, password, remember: _remember));
      // Signed in: now, and only now, the browser may offer to save the email and password.
      await CredentialStore.save(email, password);
    } on AuthFailure catch (e) {
      final google = e.kind == AuthFailureKind.invalidCredentials && await api.signInHint(_email.text);
      if (!mounted) return;
      if (google) {
        // The password was not used: empty it and let go of the field before it leaves the page,
        // so the browser has nothing to offer to save.
        FocusManager.instance.primaryFocus?.unfocus();
        _password.clear();
      }
      setState(() {
        // For a Google account the Google button replaces the form; no "incorrect" message.
        _failure = google ? null : e;
        _useGoogle = google;
      });
      if (google) return;
      // Back in the password field with it selected, so a new try can be typed over it at once.
      _passwordFocus.requestFocus();
      _password.selection = TextSelection(baseOffset: 0, extentOffset: _password.text.length);
    }
  }

  /// On the first tap in an empty email field: the browser's chooser of saved email and password
  /// pairs, if it has any (Chrome, Edge).
  Future<void> _offerSaved() async {
    if (_offeredSaved || _email.text.isNotEmpty) return;
    _offeredSaved = true;
    final saved = await CredentialStore.pick();
    if (saved == null || !mounted) return;
    setState(() {
      _email.text = saved.email;
      _password.text = saved.password;
    });
  }

  /// From the Google button back to the email and password form; the email stays, the password goes.
  void _backToForm() {
    setState(() {
      _useGoogle = false;
      _failure = null;
      _password.clear();
    });
  }

  /// Shows or hides the password, and keeps the cursor in the field where it was.
  void _toggleObscure() {
    final selection = _password.selection;
    setState(() {
      _obscure = !_obscure;
      _password.obscure = _obscure;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _passwordFocus.requestFocus();
      final end = _password.text.length;
      _password.selection = selection.isValid && selection.end <= end
          ? selection
          : TextSelection.collapsed(offset: end);
    });
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

  Future<void> _forgotPassword() async {
    final t = context.t;
    final controller = TextEditingController(text: _email.text);
    final formKey = GlobalKey<FormState>();
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.resetPasswordTitle),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.resetPasswordBody, style: TextStyle(color: context.palette.muted, fontSize: 14)),
              const SizedBox(height: 14),
              TextFormField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: t.email),
                validator: (v) => Validators.email(t, v),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(context, controller.text.trim());
            },
            child: Text(t.send),
          ),
        ],
      ),
    );
    controller.dispose();
    if (email == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final language = context.read<SettingsController>().languageCode;
    try {
      await context.read<AuthController>().service.sendPasswordReset(email, languageCode: language);
    } on AuthFailure {
      // Same answer either way, so the form does not reveal which emails have accounts.
    }
    messenger.showSnackBar(SnackBar(content: Text(t.resetPasswordSent)));
  }

  /// "Don't have an account? Create account".
  Widget _registerRow(AppStrings t, WeShapePalette p, bool busy) => Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(t.noAccount, style: TextStyle(color: p.muted, fontSize: 12.5)),
          TextButton(onPressed: busy ? null : widget.onRegister, child: Text(t.createAccount)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final p = context.palette;
    final busy = context.watch<AuthController>().busy;

    return AuthLayout(
      // Leaving this page (to registration, or the Google button) must not make the browser offer to
      // save the password: only a sign-in that worked does that (see _signIn).
      child: AutofillGroup(
        onDisposeAction: AutofillContextAction.cancel,
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _useGoogle
                ? [
                    // This address signs in with Google: only the Google button, a little larger.
                    AuthHeading(title: t.signInSubtitle),
                    const SizedBox(height: 20),
                    GoogleButton(label: t.continueWithGoogle, onPressed: busy ? null : _google, large: true),
                    if (_failure != null) ...[const SizedBox(height: 12), ErrorBanner(_failure!.message(t))],
                    const SizedBox(height: 10),
                    // Mistyped the email, or wants the form after all: back to it, email kept.
                    Center(
                      child: TextButton.icon(
                        onPressed: busy ? null : _backToForm,
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: Text(t.backToSignIn),
                      ),
                    ),
                    _registerRow(t, p, busy),
                  ]
                : [
              AuthHeading(title: t.signInSubtitle),
              const SizedBox(height: 16),
              LabeledField(
                label: t.email,
                child: TextFormField(
                  controller: _email,
                  onTap: _offerSaved,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  validator: (v) => Validators.email(t, v),
                ),
              ),
              const SizedBox(height: 12),
              LabeledField(
                label: t.password,
                child: TextFormField(
                  controller: _password,
                  focusNode: _passwordFocus,
                  // Not a browser password field (see MaskedController); the controller draws dots.
                  enableSuggestions: false,
                  autocorrect: false,
                  enableIMEPersonalizedLearning: false,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _signIn(),
                  decoration: InputDecoration(
                    // The button never takes the focus away from the field.
                    suffixIcon: ExcludeFocus(
                      child: IconButton(
                      tooltip: t.password,
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 20, color: p.muted),
                      onPressed: _toggleObscure,
                    ),
                    ),
                  ),
                  validator: (v) => Validators.required(t, v),
                ),
              ),
              if (_failure != null) ...[const SizedBox(height: 12), ErrorBanner(_failure!.message(t))],
              const SizedBox(height: 4),
              Row(
                children: [
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: Checkbox(value: _remember, onChanged: (v) => setState(() => _remember = v ?? true)),
                  ),
                  Flexible(
                    child: GestureDetector(
                      onTap: () => setState(() => _remember = !_remember),
                      child: Text(t.rememberMe, style: TextStyle(fontSize: 13, color: p.muted)),
                    ),
                  ),
                  const Spacer(),
                  TextButton(onPressed: busy ? null : _forgotPassword, child: Text(t.forgotPassword)),
                ],
              ),
              const SizedBox(height: 6),
              PrimaryButton(label: t.signIn, busy: busy, onPressed: _signIn),
              const SizedBox(height: 12),
              OrDivider(t.orDivider),
              const SizedBox(height: 12),
              GoogleButton(label: t.continueWithGoogle, onPressed: busy ? null : _google),
              const SizedBox(height: 6),
              _registerRow(t, p, busy),
            ],
          ),
        ),
      ),
    );
  }
}
