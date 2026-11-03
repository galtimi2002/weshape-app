import 'package:flutter/material.dart';

import '../../core/i18n/app_localizations.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/theme/weshape_palette.dart';

/// The three places of the signed-in app.
enum HomeTab { map, assessment, saved }

const _duration = Duration(milliseconds: 450);
const _curve = Curves.easeOutCubic;

/// Header tabs on wide screens: thin text like the address search, and a 1.5 px line
/// (like the search's underline) that slides under the active tab.
class HeaderTabs extends StatefulWidget {
  const HeaderTabs({super.key, required this.current, required this.onSelect});

  final HomeTab current;
  final ValueChanged<HomeTab> onSelect;

  static const _gap = 22.0;
  static const _style = TextStyle(fontSize: 17, fontWeight: FontWeight.w300, letterSpacing: -0.2, height: 1.2);

  static List<String> labels(AppStrings t) => [t.navMap, t.navAssessment, t.navSaved];

  /// Width the tabs need, for deciding whether they fit in the header.
  static double widthFor(BuildContext context) {
    final widths = _widths(context, labels(context.t));
    return widths.fold<double>(0, (a, b) => a + b) + _gap * (widths.length - 1);
  }

  static List<double> _widths(BuildContext context, List<String> texts) => [
        for (final s in texts)
          (TextPainter(
            text: TextSpan(text: s, style: DefaultTextStyle.of(context).style.merge(_style)),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
            maxLines: 1,
          )..layout())
              .width
              .ceilToDouble(),
      ];

  @override
  State<HeaderTabs> createState() => _HeaderTabsState();
}

/// Rebuilds when a font finishes loading: the tab widths, and so the line, change with it.
mixin _FontsChange<T extends StatefulWidget> on State<T> {
  void _fontsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    PaintingBinding.instance.systemFonts.addListener(_fontsChanged);
  }

  @override
  void dispose() {
    PaintingBinding.instance.systemFonts.removeListener(_fontsChanged);
    super.dispose();
  }
}

class _HeaderTabsState extends State<HeaderTabs> with _FontsChange {
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final texts = HeaderTabs.labels(context.t);
    final widths = HeaderTabs._widths(context, texts);
    final i = widget.current.index;
    const gap = HeaderTabs._gap;
    const style = HeaderTabs._style;
    final onSelect = widget.onSelect;
    final start = widths.take(i).fold<double>(0, (a, b) => a + b) + gap * i;

    return Semantics(
      container: true,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var k = 0; k < texts.length; k++) ...[
                  if (k > 0) const SizedBox(width: gap),
                  _TabText(
                    label: texts[k],
                    style: style,
                    active: k == i,
                    onTap: () => onSelect(HomeTab.values[k]),
                  ),
                ],
              ],
            ),
          ),
          AnimatedPositionedDirectional(
            duration: _duration,
            curve: _curve,
            start: start,
            width: widths[i],
            bottom: 0,
            height: 1.5,
            child: DecoratedBox(
              decoration: BoxDecoration(color: p.primary, borderRadius: BorderRadius.circular(1)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabText extends StatefulWidget {
  const _TabText({required this.label, required this.style, required this.active, required this.onTap});

  final String label;
  final TextStyle style;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_TabText> createState() => _TabTextState();
}

class _TabTextState extends State<_TabText> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final alpha = widget.active ? 1.0 : (_hover ? 0.8 : 0.5);
    return Semantics(
      button: true,
      selected: widget.active,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            style: DefaultTextStyle.of(context).style.merge(widget.style).copyWith(color: p.text.withValues(alpha: alpha)),
            child: Text(widget.label, maxLines: 1),
          ),
        ),
      ),
    );
  }
}

/// On narrow screens the tabs sit in a strip under the header: icon and short name,
/// with a white pill sliding behind the active one. Very narrow screens keep the icons only.
class StripTabs extends StatefulWidget {
  const StripTabs({super.key, required this.current, required this.onSelect});

  final HomeTab current;
  final ValueChanged<HomeTab> onSelect;

  @override
  State<StripTabs> createState() => _StripTabsState();
}

class _StripTabsState extends State<StripTabs> with _FontsChange {
  static const _icons = [Icons.map_outlined, Icons.assignment_outlined, Icons.bookmark_border_rounded];
  static const _style = TextStyle(fontSize: 14, fontWeight: FontWeight.w300, letterSpacing: -0.1, height: 1.2);
  static const _pad = 10.0;
  static const _icon = 16.0;
  static const _iconGap = 6.0;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.t;
    final labels = [t.navMap, t.navAssessment, t.navSavedShort];
    final iconsOnly = MediaQuery.sizeOf(context).width < 340;
    final widths = [
      for (final s in labels)
        _pad * 2 +
            _icon +
            (iconsOnly
                ? 6
                : _iconGap +
                    (TextPainter(
                      text: TextSpan(text: s, style: DefaultTextStyle.of(context).style.merge(_style)),
                      textDirection: Directionality.of(context),
                      textScaler: MediaQuery.textScalerOf(context),
                      maxLines: 1,
                    )..layout())
                        .width
                        .ceilToDouble()),
    ];
    final i = widget.current.index;
    final onSelect = widget.onSelect;
    final start = widths.take(i).fold<double>(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: p.selected.withValues(alpha: 0.95),
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Stack(
        children: [
          AnimatedPositionedDirectional(
            duration: _duration,
            curve: _curve,
            start: start,
            width: widths[i],
            top: 0,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [BoxShadow(color: Color(0x26102040), blurRadius: 3, offset: Offset(0, 1))],
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var k = 0; k < labels.length; k++)
                Semantics(
                  button: true,
                  selected: k == i,
                  label: labels[k],
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => onSelect(HomeTab.values[k]),
                    child: SizedBox(
                      width: widths[k],
                      height: 32,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_icons[k], size: _icon, color: p.text.withValues(alpha: k == i ? 1 : 0.55)),
                          if (!iconsOnly) ...[
                            const SizedBox(width: _iconGap),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 250),
                              style: DefaultTextStyle.of(context).style.merge(_style).copyWith(color: p.text.withValues(alpha: k == i ? 1 : 0.55)),
                              child: Text(labels[k], maxLines: 1),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
