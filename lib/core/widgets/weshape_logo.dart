import 'package:flutter/material.dart';

/// The full WeShape Energy logo, in the version made for the current
/// background: the navy wordmark on light, the white one on dark.
class WeShapeLogo extends StatelessWidget {
  const WeShapeLogo({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Image.asset(
      dark ? 'assets/brand/logo-dark.png' : 'assets/brand/logo-light.png',
      width: width,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'WeShape Energy',
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
    return Image.asset(
      dark ? 'assets/brand/icon-dark.png' : 'assets/brand/icon-light.png',
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'WeShape Energy',
    );
  }
}
