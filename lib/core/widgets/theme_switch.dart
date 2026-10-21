import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/profile/profile_controller.dart';
import '../i18n/app_localizations.dart';
import '../settings/settings_controller.dart';
import '../theme/weshape_palette.dart';

/// Light/dark toggle: just the icon, no frame. The icon itself morphs: the
/// pale sun's rays fold away while its disc grows and a crescent is bitten out
/// of it, leaving a white moon. Back again the other way.
///
/// It flips whatever is on screen, so on "follow system" the first tap pins
/// the opposite of what the device currently shows.
class ThemeSwitch extends StatefulWidget {
  const ThemeSwitch({super.key, this.size = 24});

  final double size;

  @override
  State<ThemeSwitch> createState() => _ThemeSwitchState();
}

class _ThemeSwitchState extends State<ThemeSwitch> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final p = context.palette;
    final t = context.t;
    final isDark = settings.effectiveBrightness(context) == Brightness.dark;
    final label = isDark ? t.switchToLight : t.switchToDark;

    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        toggled: isDark,
        label: label,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.read<ProfileController>().changeTheme(isDark ? ThemeMode.light : ThemeMode.dark),
            child: SizedBox(
              width: widget.size + 12,
              height: widget.size + 12,
              child: Center(
                child: AnimatedRotation(
                  turns: _hover ? -12 / 360 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: AnimatedScale(
                    scale: _hover ? 1.08 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(end: isDark ? 1 : 0),
                      duration: const Duration(milliseconds: 550),
                      curve: Curves.easeOutBack,
                      builder: (context, v, _) => CustomPaint(
                        size: Size.square(widget.size),
                        painter: SunMoonPainter(progress: v, palette: p),
                      ),
                    ),
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

/// [progress] 0 is the sun, 1 the moon; values slightly past either end
/// (from the overshooting curve) give the little bounce.
class SunMoonPainter extends CustomPainter {
  SunMoonPainter({required this.progress, required this.palette});

  final double progress;
  final WeShapePalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24; // drawn on a 24-unit grid
    final v = progress.clamp(-0.2, 1.2);
    final m = progress.clamp(0.0, 1.0);
    final center = Offset(12 * s, 12 * s);

    // Rays: rotate a quarter turn and shrink to nothing on the way to the moon.
    final rayScale = (1 - v).clamp(0.0, 1.2);
    if (rayScale > 0.01) {
      final ray = Paint()
        ..color = palette.sunRay.withValues(alpha: (1 - m).clamp(0.0, 1.0))
        ..strokeWidth = 2 * s
        ..strokeCap = StrokeCap.round;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(v * math.pi / 2);
      canvas.scale(rayScale);
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4;
        canvas.drawLine(
          Offset(math.cos(a) * 8.2 * s, math.sin(a) * 8.2 * s),
          Offset(math.cos(a) * 10.6 * s, math.sin(a) * 10.6 * s),
          ray,
        );
      }
      canvas.restore();
    }

    // Disc: grows from sun size to moon size; colour blends yellow to white.
    final radius = (5 + 4 * v) * s;
    final light = Color.lerp(palette.sunLight, palette.moonLight, m)!;
    final deep = Color.lerp(palette.sunDeep, palette.moonDeep, m)!;
    final discRect = Rect.fromCircle(center: center, radius: radius);

    canvas.saveLayer(Rect.fromLTWH(-4 * s, -4 * s, 32 * s, 32 * s), Paint());
    canvas.drawCircle(
      center,
      radius + 0.6 * s,
      Paint()
        ..color = const Color(0x260F192D)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1.2 * s),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.2, -0.3),
          colors: [light, deep],
        ).createShader(discRect),
    );
    // The bite that turns the disc into a crescent slides in from outside.
    final bite = Offset.lerp(Offset(30 * s, 0), Offset(18 * s, 6 * s), v)!;
    canvas.drawCircle(bite, 8 * s, Paint()..blendMode = BlendMode.clear);
    canvas.restore();
  }

  @override
  bool shouldRepaint(SunMoonPainter old) => old.progress != progress || old.palette != palette;
}
