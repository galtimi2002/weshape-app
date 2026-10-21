import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/profile/profile_controller.dart';
import '../i18n/app_localizations.dart';
import '../settings/settings_controller.dart';
import '../theme/weshape_palette.dart';

/// Light/dark switch: a pale sun slides across to become a white moon.
///
/// It flips whatever is on screen, so on "follow system" the first tap pins
/// the opposite of what the device currently shows.
class ThemeSwitch extends StatelessWidget {
  const ThemeSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final p = context.palette;
    final t = context.t;
    final isDark = settings.effectiveBrightness(context) == Brightness.dark;

    return Tooltip(
      message: isDark ? t.switchToLight : t.switchToDark,
      child: Semantics(
        button: true,
        toggled: isDark,
        label: isDark ? t.switchToLight : t.switchToDark,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.read<ProfileController>().changeTheme(isDark ? ThemeMode.light : ThemeMode.dark),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 52,
            height: 30,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              gradient: p.switchTrack,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: p.border),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutBack,
              alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: p.switchKnob,
                  boxShadow: const [BoxShadow(color: Color(0x2E0F192D), blurRadius: 3, offset: Offset(0, 1))],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) => RotationTransition(
                    turns: Tween<double>(begin: 0.6, end: 1).animate(anim),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: Icon(
                    isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    key: ValueKey(isDark),
                    size: 14,
                    color: p.switchIcon,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
