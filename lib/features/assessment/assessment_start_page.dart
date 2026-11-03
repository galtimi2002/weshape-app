import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/i18n/app_localizations.dart';
import '../../core/theme/weshape_palette.dart';
import '../../core/theme/weshape_theme.dart';
import '../../core/widgets/primary_button.dart';
import 'page_frame.dart';

enum _Start { home, business, community, explore }

/// The assessment's first page: what would you like to plan. Only "just looking around"
/// leads anywhere yet (back to the map); the home questions come next, the business and
/// community paths later, so those are shown but cannot be chosen.
class AssessmentStartPage extends StatefulWidget {
  const AssessmentStartPage({super.key, required this.onExplore});

  final VoidCallback onExplore;

  @override
  State<AssessmentStartPage> createState() => _AssessmentStartPageState();
}

class _AssessmentStartPageState extends State<AssessmentStartPage> {
  _Start _choice = _Start.home;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final p = context.palette;
    final phone = MediaQuery.sizeOf(context).width < 700;

    Widget option(_Start value, String title, String detail, {bool soon = false}) => _Option(
          title: title,
          detail: phone ? null : detail,
          selected: _choice == value,
          soon: soon ? t.comingSoon : null,
          onTap: soon ? null : () => setState(() => _choice = value),
        );

    final ready = _choice == _Start.explore;
    return PageFrame(
      maxWidth: 640,
      children: [
        Row(
          children: [
            Text(
              t.assessStep,
              style: WeShapeTheme.useGoogleFonts
                  ? GoogleFonts.jetBrainsMono(fontSize: 11.5, color: p.muted)
                  : TextStyle(fontFamily: 'monospace', fontSize: 11.5, color: p.muted),
            ),
            const SizedBox(width: 10),
            Expanded(child: Container(height: 3, decoration: BoxDecoration(color: p.border, borderRadius: BorderRadius.circular(2)))),
          ],
        ),
        const SizedBox(height: 18),
        PageTitle(t.assessTitle),
        const SizedBox(height: 6),
        Text(t.assessHint, style: TextStyle(fontSize: 14, color: p.muted)),
        const SizedBox(height: 18),
        Container(height: 1, color: p.border),
        option(_Start.home, t.assessHome, t.assessHomeDesc),
        option(_Start.business, t.assessBusiness, t.assessBusinessDesc, soon: true),
        option(_Start.community, t.assessCommunity, t.assessCommunityDesc, soon: true),
        option(_Start.explore, t.assessExplore, t.assessExploreDesc),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 12,
          spacing: 16,
          children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: ready ? 0 : 1,
              child: Text(t.assessStepsSoon, style: TextStyle(fontSize: 13, color: p.muted)),
            ),
            SizedBox(
              width: 150,
              child: PrimaryButton(label: t.assessContinue, onPressed: ready ? widget.onExplore : null),
            ),
          ],
        ),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({required this.title, required this.detail, required this.selected, required this.soon, required this.onTap});

  final String title;
  final String? detail;
  final bool selected;
  final String? soon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onTap != null;
    final color = enabled ? p.text : p.muted;

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      enabled: enabled,
      label: title,
      child: InkWell(
        onTap: onTap,
        mouseCursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 4),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.border))),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: selected ? p.primary : (enabled ? p.muted : p.border), width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 200),
                    scale: selected ? 1 : 0,
                    child: Container(width: 8, height: 8, decoration: BoxDecoration(color: p.primary, shape: BoxShape.circle)),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color)),
                    if (detail != null) ...[
                      const SizedBox(height: 2),
                      Text(detail!, style: TextStyle(fontSize: 13, color: p.muted)),
                    ],
                  ],
                ),
              ),
              if (soon != null) ...[const SizedBox(width: 10), Padding(padding: const EdgeInsets.only(top: 2), child: SoonBadge(soon!))],
            ],
          ),
        ),
      ),
    );
  }
}
