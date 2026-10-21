import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../i18n/app_localizations.dart';
import '../theme/weshape_palette.dart';
import 'language_menu.dart';
import 'theme_switch.dart';
import 'weshape_logo.dart';

/// Frame shared by login, registration and "one more step": language and
/// theme controls in the top corner, the logo, then a centred card.
///
/// On a phone the card dissolves into the page, since a box inside a box
/// only wastes the narrow width.
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.child, this.footer});

  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final width = MediaQuery.sizeOf(context).width;
    final phone = width < 600;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 12, phone ? 16 : 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  LanguageMenu(style: phone ? LanguageMenuStyle.compact : LanguageMenuStyle.full),
                  const SizedBox(width: 8),
                  const ThemeSwitch(),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(phone ? 20 : 24, 12, phone ? 20 : 24, 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(child: WeShapeLogo(width: phone ? 210 : 260)),
                        SizedBox(height: phone ? 20 : 24),
                        if (phone)
                          child
                        else
                          Container(
                            padding: const EdgeInsets.all(26),
                            decoration: BoxDecoration(
                              color: p.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: p.border),
                            ),
                            child: child,
                          ),
                        if (footer != null) ...[const SizedBox(height: 16), footer!],
                        if (AppConfig.isDemoAuth) ...[
                          const SizedBox(height: 16),
                          Text(
                            context.t.demoModeNotice,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: p.muted),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Title plus one muted line under it.
class AuthHeading extends StatelessWidget {
  const AuthHeading({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: p.text, letterSpacing: -0.2)),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 14, color: p.muted)),
      ],
    );
  }
}

/// A label above a field, like the sketch, instead of a floating label.
class LabeledField extends StatelessWidget {
  const LabeledField({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: p.text)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

/// A thin rule with a word in the middle: "or".
class OrDivider extends StatelessWidget {
  const OrDivider(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Expanded(child: Divider(color: p.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label, style: TextStyle(fontSize: 12, color: p.muted)),
        ),
        Expanded(child: Divider(color: p.border)),
      ],
    );
  }
}
