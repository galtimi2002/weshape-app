import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

/// On a phone, or on a screen taller than wide, longer answers go one under another;
/// on a laptop they sit side by side. Short ones (1, 2, 3+, Yes / No) always stay in a row.
bool _stacked(BuildContext context, Iterable<String> labels) {
  final size = MediaQuery.sizeOf(context);
  final roomBelow = size.width < 700 || size.height > size.width;
  return roomBelow && labels.any((l) => l.length > 12);
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
    final stacked = _stacked(context, values.map(label));
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final v in values)
          SizedBox(
            width: stacked ? double.infinity : null,
            child: Semantics(
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

  /// Null until a value is picked: the number shows as a dash.
  final int? value;
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
              TextSpan(
                  text: value == null ? '–' : '$value',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: value == null ? p.muted : p.text, letterSpacing: -0.5)),
              TextSpan(text: '  $unit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: p.muted)),
              if (note != null) TextSpan(text: '  ·  $note', style: TextStyle(fontSize: 13, color: p.muted)),
            ]),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: p.primary,
              inactiveTrackColor: p.border,
              // No value yet: the thumb waits at the start, faint.
              thumbColor: value == null ? p.border : p.primary,
              overlayColor: p.primary.withValues(alpha: 0.12),
              trackHeight: 3,
            ),
            child: Slider(
              value: (value ?? min).clamp(min, max).toDouble(),
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
  const CheckRow({super.key, required this.title, required this.checked, required this.onTap, this.detail});

  final String title;
  final String? detail;
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
                    if (detail != null) ...[
                      const SizedBox(height: 2),
                      Text(detail!, style: TextStyle(fontSize: 13, color: p.muted)),
                    ],
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

/// Several choices out of a few (pick any), as chips with a tick.
class MultiChips<T> extends StatelessWidget {
  const MultiChips({super.key, required this.values, required this.label, required this.selected, required this.onToggle, this.icon});

  final List<T> values;
  final String Function(T) label;
  final IconData? Function(T)? icon;
  final Set<T> selected;
  final ValueChanged<T> onToggle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final stacked = _stacked(context, values.map(label));
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final v in values)
          SizedBox(
            width: stacked ? double.infinity : null,
            child: Semantics(
            checked: selected.contains(v),
            button: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(9),
              onTap: () => onToggle(v),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: selected.contains(v) ? p.selected : p.fieldFill,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: selected.contains(v) ? p.primary : p.border, width: selected.contains(v) ? 1.5 : 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon?.call(v) case final IconData i) ...[Icon(i, size: 17, color: p.primary), const SizedBox(width: 7)],
                    Flexible(child: Text(label(v), style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: p.text))),
                    if (selected.contains(v)) ...[const SizedBox(width: 6), Icon(Icons.check_rounded, size: 15, color: p.primary)],
                  ],
                ),
              ),
            ),
          ),
          ),
      ],
    );
  }
}

/// A number typed by the person; empty means "not given". Keeps its own text while typing.
class NumberField extends StatefulWidget {
  const NumberField({
    super.key,
    required this.value,
    required this.onChanged,
    this.suffix,
    this.width = 140,
    this.hint,
    this.money = false,
  });

  /// An amount of money: a dot or a comma both start the cents (bani, fillér),
  /// at most two digits after it.
  final bool money;

  /// The largest number that can be typed: kWh, m³ and m² of a home fit in five digits,
  /// so a key held down by mistake cannot become a huge number. Money only has a length
  /// limit, as currencies differ so much (300 lei is about 1,500,000 dong).
  double get max => money ? 999999999.99 : 99999.99;

  final double? value;
  final ValueChanged<double?> onChanged;
  final String? suffix;
  final String? hint;
  final double width;

  @override
  State<NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<NumberField> {
  late final TextEditingController _controller = TextEditingController(text: _format(widget.value));

  static String _format(double? v) => v == null ? '' : (v == v.roundToDouble() ? v.toInt().toString() : v.toString());

  @override
  void didUpdateWidget(NumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final parsed = double.tryParse(_controller.text.replaceAll(',', '.').replaceAll(' ', ''));
    if (parsed != widget.value) _controller.text = _format(widget.value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      width: widget.width,
      child: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        // Digits and one decimal mark (dot or comma) only; nothing else can be typed or pasted.
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          TextInputFormatter.withFunction(
            (old, value) {
              final shape = RegExp(widget.money ? r'^\d*([.,]\d{0,2})?$' : r'^\d*[.,]?\d*$').hasMatch(value.text);
              final number = double.tryParse(value.text.replaceAll(',', '.')) ?? 0;
              return shape && number <= widget.max ? value : old;
            },
          ),
        ],
        style: TextStyle(fontSize: 15, color: p.text),
        decoration: InputDecoration(
          isDense: true,
          hintText: widget.hint,
          // A suffix icon, unlike suffixText, shows the unit before the field is touched.
          suffixIcon: widget.suffix == null
              ? null
              : Padding(
                  padding: const EdgeInsetsDirectional.only(end: 12, start: 6),
                  child: Text(widget.suffix!, style: TextStyle(fontSize: 12.5, color: p.muted)),
                ),
          suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        ),
        onChanged: (text) {
          final t = text.replaceAll(',', '.').replaceAll(' ', '');
          widget.onChanged(t.isEmpty ? null : double.tryParse(t));
        },
      ),
    );
  }
}

/// A short drop-down (months, units).
class SmallDropdown<T> extends StatelessWidget {
  const SmallDropdown({super.key, required this.value, required this.values, required this.label, required this.onChanged, this.width = 150});

  final T value;
  final List<T> values;
  final String Function(T) label;
  final ValueChanged<T> onChanged;
  final double width;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: p.fieldFill, borderRadius: BorderRadius.circular(10), border: Border.all(color: p.fieldBorder)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(10),
          style: TextStyle(fontSize: 14.5, color: p.text),
          items: [for (final v in values) DropdownMenuItem(value: v, child: Text(label(v)))],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

/// Question with an optional helper line, used inside a step for second questions.
class SubQuestion extends StatelessWidget {
  const SubQuestion(this.text, {super.key, this.helper});

  final String text;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: p.text)),
          if (helper != null) Text(helper!, style: TextStyle(fontSize: 13, color: p.muted)),
        ],
      ),
    );
  }
}

/// A warning under a field ("This is very high for a home").
class FieldWarning extends StatelessWidget {
  const FieldWarning(this.text, {super.key, this.action, this.onAction});

  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: p.sunDeep),
          const SizedBox(width: 6),
          Flexible(child: Text(text, style: TextStyle(fontSize: 12.5, color: p.text))),
          if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
        ],
      ),
    );
  }
}
