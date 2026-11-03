import 'package:flutter/material.dart';

import '../../core/i18n/app_localizations.dart';
import '../../core/theme/weshape_palette.dart';
import 'page_frame.dart';

/// Saved assessments. Saving comes with the assessment itself, so for now the page shows
/// how it will work, a way to start one, and comparing as "Soon".
class SavedAssessmentsPage extends StatelessWidget {
  const SavedAssessmentsPage({super.key, required this.onNew});

  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final p = context.palette;

    return PageFrame(
      maxWidth: 880,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.end,
          runSpacing: 14,
          spacing: 16,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                PageTitle(t.savedTitle),
                const SizedBox(height: 6),
                Text(t.savedHint, style: TextStyle(fontSize: 14, color: p.muted)),
              ],
            ),
            _NewButton(label: t.savedNew, onTap: onNew),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          decoration: BoxDecoration(
            color: p.fieldFill,
            border: Border.all(color: p.fieldBorder),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: p.selected, shape: BoxShape.circle),
                child: Icon(Icons.bookmark_border_rounded, color: p.primary, size: 26),
              ),
              const SizedBox(height: 14),
              Text(t.savedEmpty, textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: p.text)),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Text(t.savedEmptyHint, textAlign: TextAlign.center, style: TextStyle(fontSize: 13.5, height: 1.45, color: p.muted)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            border: Border.all(color: p.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Text(t.savedCompare, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.muted)),
              const SizedBox(width: 10),
              Expanded(child: Text(t.savedCompareHint, style: TextStyle(fontSize: 12.5, color: p.muted))),
              const SizedBox(width: 10),
              SoonBadge(t.comingSoon),
            ],
          ),
        ),
      ],
    );
  }
}

class _NewButton extends StatelessWidget {
  const _NewButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: p.primaryGradient,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: p.buttonShadow, blurRadius: 18, offset: const Offset(0, 6), spreadRadius: -10)],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, size: 18, color: p.onPrimary),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(color: p.onPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
