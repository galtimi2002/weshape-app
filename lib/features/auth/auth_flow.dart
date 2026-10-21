import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'register_screen.dart';

/// Login and registration, switched in place rather than pushed as routes, so
/// the moment sign-in succeeds the app's root takes over without a stale page
/// left behind on the navigator.
class AuthFlow extends StatefulWidget {
  const AuthFlow({super.key});

  @override
  State<AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<AuthFlow> {
  bool _registering = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: _registering
          ? RegisterScreen(key: const ValueKey('register'), onSignIn: () => setState(() => _registering = false))
          : LoginScreen(key: const ValueKey('login'), onRegister: () => setState(() => _registering = true)),
    );
  }
}
