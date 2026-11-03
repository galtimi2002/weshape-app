import 'package:flutter/material.dart';

import '../theme/weshape_palette.dart';

/// The sign-in pages' soft diagonal gradient with a faint blue light at the top and a
/// breath of green in the corner, for full pages inside the app (the assessment, the
/// saved assessments).
class StageBackground extends StatelessWidget {
  const StageBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(gradient: p.stageGradient),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.75, -1),
                    radius: 0.9,
                    colors: [p.glowBlue, p.glowBlue.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.9, 1),
                    radius: 0.7,
                    colors: [p.glowGreen, p.glowGreen.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}
