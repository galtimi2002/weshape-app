import 'package:flutter/material.dart';

import '../../core/theme/weshape_palette.dart';

/// Small grey label over a group of choices.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: context.palette.muted)),
      );
}

/// One choice out of a few, as a row of chips that wrap.
class ChoiceChips<T> extends StatelessWidget {
  const ChoiceChips({super.key, required this.values, required this.label, required this.selected, required this.onSelect, this.sublabel});

  final List<T> values;
  final String Function(T) label;
  final String? Function(T)? sublabel;
  final T? selected;
  final ValueChanged<T> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final v in values)
          Semantics(
            inMutuallyExclusiveGroup: true,
            checked: v == selected,
            button: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(9),
              onTap: () => onSelect(v),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                decoration: BoxDecoration(
                  color: v == selected ? p.selected : p.fieldFill,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: v == selected ? p.primary : p.border, width: v == selected ? 1.5 : 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label(v), style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: p.text)),
                    if (sublabel?.call(v) case final String s) Text(s, style: TextStyle(fontSize: 11, color: p.muted)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A big number with a slider under it.
class NumberSlider extends StatelessWidget {
  const NumberSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.unit,
    required this.onChanged,
    this.note,
    this.enabled = true,
  });

  final int value;
  final int min;
  final int max;
  final int step;
  final String unit;
  final String? note;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1 : 0.4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(children: [
              TextSpan(text: '$value', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: p.text, letterSpacing: -0.5)),
              TextSpan(text: '  $unit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: p.muted)),
              if (note != null) TextSpan(text: '  ·  $note', style: TextStyle(fontSize: 13, color: p.muted)),
            ]),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: p.primary,
              inactiveTrackColor: p.border,
              thumbColor: p.primary,
              overlayColor: p.primary.withValues(alpha: 0.12),
              trackHeight: 3,
            ),
            child: Slider(
              value: value.clamp(min, max).toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: (max - min) ~/ step,
              onChanged: enabled ? (v) => onChanged(v.round()) : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// A row that can be ticked, with a short explanation.
class CheckRow extends StatelessWidget {
  const CheckRow({super.key, required this.title, required this.detail, required this.checked, required this.onTap});

  final String title;
  final String detail;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      checked: checked,
      label: title,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.border))),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 18,
                height: 18,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: checked ? p.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: checked ? p.primary : p.muted, width: 1.5),
                ),
                child: checked ? Icon(Icons.check_rounded, size: 14, color: p.onPrimary) : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: p.text)),
                    const SizedBox(height: 2),
                    Text(detail, style: TextStyle(fontSize: 13, color: p.muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Underlined link-like button ("I don't know: …").
class LinkButton extends StatelessWidget {
  const LinkButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            label,
            style: TextStyle(fontSize: 13.5, color: p.primary, decoration: TextDecoration.underline, decorationColor: p.primary.withValues(alpha: 0.5)),
          ),
        ),
      ),
    );
  }
}
