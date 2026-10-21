import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../i18n/app_localizations.dart';
import '../theme/weshape_palette.dart';
import 'language_menu.dart';
import 'theme_switch.dart';
import 'weshape_logo.dart';

/// Frame shared by login, registration and "one more step".
///
/// No card: the form sits straight on a soft gradient, centred on every
/// screen size, with language and theme in the top-right corner. Sized to fit
/// one screen; it only scrolls on a display too short for the form.
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.child, this.footer, this.maxWidth = 340});

  final Widget child;
  final Widget? footer;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final phone = MediaQuery.sizeOf(context).width < 600;

    return Scaffold(
      backgroundColor: p.stageBottom,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: p.stageGradient),
        child: Stack(
          children: [
            Positioned.fill(child: _Glow(palette: p)),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(phone ? 22 : 24, phone ? 52 : 40, phone ? 22 : 24, 20),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(child: WeShapeLogo(width: phone ? 176 : 230)),
                              SizedBox(height: phone ? 16 : 20),
                              child,
                              if (footer != null) ...[const SizedBox(height: 12), footer!],
                              if (AppConfig.isDemoAuth) ...[
                                const SizedBox(height: 10),
                                Text(
                                  context.t.demoModeNotice,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 11, color: p.muted),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, phone ? 8 : 14, phone ? 12 : 18, 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LanguageMenu(style: phone ? LanguageMenuStyle.compact : LanguageMenuStyle.full),
                      const SizedBox(width: 6),
                      const ThemeSwitch(),
                    ],
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

/// Faint blue light behind the logo and a breath of green in the far corner.
class _Glow extends StatelessWidget {
  const _Glow({required this.palette});

  final WeShapePalette palette;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.45),
                  radius: 0.75,
                  colors: [palette.glowBlue, palette.glowBlue.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.8, 1),
                  radius: 0.6,
                  colors: [palette.glowGreen, palette.glowGreen.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Centred page title, with an optional muted line under it.
class AuthHeading extends StatelessWidget {
  const AuthHeading({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: p.text, letterSpacing: -0.3),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: p.muted)),
        ],
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
        const SizedBox(height: 5),
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
