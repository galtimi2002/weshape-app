import 'package:flutter/material.dart';

import '../theme/weshape_palette.dart';

/// The one filled button per screen: navy gradient in light mode, soft blue
/// in dark. Shows a spinner instead of its label while [busy].
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.busy = false});

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onPressed != null && !busy;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: onPressed == null ? 0.6 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: p.primaryGradient,
            borderRadius: BorderRadius.circular(11),
            boxShadow: [BoxShadow(color: p.buttonShadow, blurRadius: 22, offset: const Offset(0, 8), spreadRadius: -10)],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(11),
              onTap: enabled ? onPressed : null,
              child: SizedBox(
                height: 44,
                child: Center(
                  child: busy
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: p.onPrimary),
                        )
                      : Text(
                          label,
                          style: TextStyle(
                            color: p.onPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            letterSpacing: 0.1,
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

/// "Continue with Google", outlined, with the four-colour G.
class GoogleButton extends StatelessWidget {
  const GoogleButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 18, height: 18, child: CustomPaint(painter: _GoogleGPainter())),
          const SizedBox(width: 10),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  const _GoogleGPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = s * 0.2;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, s - stroke, s - stroke);
    Paint arc(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    const deg = 3.1415926535 / 180;
    canvas.drawArc(rect, -40 * deg, -100 * deg, false, arc(const Color(0xFFEA4335)));
    canvas.drawArc(rect, -140 * deg, -90 * deg, false, arc(const Color(0xFFFBBC05)));
    canvas.drawArc(rect, 130 * deg, -90 * deg, false, arc(const Color(0xFF34A853)));
    canvas.drawArc(rect, 40 * deg, -40 * deg, false, arc(const Color(0xFF4285F4)));
    canvas.drawRect(
      Rect.fromLTWH(s * 0.5, s * 0.5 - stroke / 2, s * 0.5 - stroke * 0.05, stroke),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Inline error under a form: muted terracotta, never alarm red.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(color: p.errorBackground, borderRadius: BorderRadius.circular(8)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(Icons.info_outline_rounded, size: 16, color: p.error),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: TextStyle(color: p.error, fontSize: 13, height: 1.35))),
          ],
        ),
      ),
    );
  }
}
