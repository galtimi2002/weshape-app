import 'package:flutter/material.dart';

/// The WeShape Energy logo, in the version made for the current background:
/// navy wordmark on light, white on dark. The two cross-fade when the theme
/// changes instead of jumping.
///
/// [withSlogan] keeps the "We care about the future of green energy." line;
/// it belongs on the sign-in pages only, the app header shows the plain mark.
class WeShapeLogo extends StatelessWidget {
  const WeShapeLogo({super.key, this.width, this.height, this.withSlogan = true});

  final double? width;
  final double? height;
  final bool withSlogan;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final name = withSlogan ? 'logo' : 'wordmark';
    return _CrossFade(
      dark: dark,
      child: Image.asset(
        'assets/brand/$name-${dark ? 'dark' : 'light'}.png',
        key: ValueKey('$name-$dark'),
        width: width,
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        semanticLabel: 'WeShape Energy',
      ),
    );
  }
}

/// Just the globe, for tight spaces such as the phone header.
class WeShapeMark extends StatelessWidget {
  const WeShapeMark({super.key, this.size = 34});

  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return _CrossFade(
      dark: dark,
      child: Image.asset(
        dark ? 'assets/brand/icon-dark.png' : 'assets/brand/icon-light.png',
        key: ValueKey('mark-$dark'),
        width: size,
        height: size,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        semanticLabel: 'WeShape Energy',
      ),
    );
  }
}

class _CrossFade extends StatelessWidget {
  const _CrossFade({required this.dark, required this.child});

  final bool dark;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        layoutBuilder: (current, previous) => Stack(alignment: Alignment.center, children: [...previous, if (current != null) current]),
        child: child,
      );
}
