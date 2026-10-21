import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/auth/auth_failure.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/settings/settings_controller.dart';
import '../../core/theme/weshape_palette.dart';
import '../../core/widgets/auth_layout.dart';
import '../../core/widgets/primary_button.dart';
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
  final _password = TextEditingController();
  bool _remember = true;
  bool _obscure = true;
  AuthFailure? _failure;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() => _failure = null);
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    try {
      await auth.run(() => auth.service.signInWithEmail(_email.text, _password.text, remember: _remember));
    } on AuthFailure catch (e) {
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
                decoration: InputDecoration(hintText: 'name@company.com', labelText: t.email),
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

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final p = context.palette;
    final busy = context.watch<AuthController>().busy;

    return AuthLayout(
      child: AutofillGroup(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthHeading(title: t.signInSubtitle),
              const SizedBox(height: 16),
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
              const SizedBox(height: 12),
              LabeledField(
                label: t.password,
                child: TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _signIn(),
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                      tooltip: t.password,
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 20, color: p.muted),
                      onPressed: () => setState(() => _obscure = !_obscure),
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
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(t.noAccount, style: TextStyle(color: p.muted, fontSize: 12.5)),
                  TextButton(onPressed: busy ? null : widget.onRegister, child: Text(t.createAccount)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
