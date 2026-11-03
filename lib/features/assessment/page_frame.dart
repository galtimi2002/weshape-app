import 'package:flutter/material.dart';

import '../../core/theme/weshape_palette.dart';
import '../../core/widgets/stage_background.dart';

/// A full page inside the app: the stage gradient and a centred, scrolling column.
class PageFrame extends StatelessWidget {
  const PageFrame({super.key, required this.maxWidth, required this.children});

  final double maxWidth;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final phone = MediaQuery.sizeOf(context).width < 700;
    return StageBackground(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(phone ? 18 : 28, phone ? 22 : 40, phone ? 18 : 28, 32),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Big thin title, like the address search on the map.
class PageTitle extends StatelessWidget {
  const PageTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final phone = MediaQuery.sizeOf(context).width < 700;
    return Text(
      text,
      style: TextStyle(fontSize: phone ? 26 : 32, fontWeight: FontWeight.w300, letterSpacing: -0.5, height: 1.2, color: p.text),
    );
  }
}

/// Small framed "Soon" label for what is not built yet.
class SoonBadge extends StatelessWidget {
  const SoonBadge(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(border: Border.all(color: p.border), borderRadius: BorderRadius.circular(4)),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: p.muted),
      ),
    );
  }
}
