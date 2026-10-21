import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/theme/weshape_palette.dart';
import '../../core/widgets/weshape_logo.dart';

/// Startup screen. A normal start is a blink. When the free-tier backend is
/// asleep the wait can reach a minute, so after a few seconds the screen says
/// what it is waiting for instead of looking frozen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _hintTimer;
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    _hintTimer = Timer(AppConfig.coldStartHintDelay, () {
      if (mounted) setState(() => _showHint = true);
    });
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final p = context.palette;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const WeShapeLogo(width: 240),
                const SizedBox(height: 36),
                const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4)),
                // Space is reserved so the logo does not jump when the hint appears.
                SizedBox(
                  height: 90,
                  child: AnimatedOpacity(
                    opacity: _showHint ? 1 : 0,
                    duration: const Duration(milliseconds: 400),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 22),
                      child: Column(
                        children: [
                          Text(t.serverWakingUp,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w600, color: p.text)),
                          const SizedBox(height: 6),
                          Text(t.serverWakingUpHint,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, height: 1.35, color: p.muted)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
