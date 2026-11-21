import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/profile/profile_controller.dart';
import '../i18n/app_localizations.dart';
import '../settings/settings_controller.dart';
import '../theme/weshape_palette.dart';
import '../units/units.dart';

/// Metric or US units inside a form (registration, completing the profile). It shows the units
/// in use: the country's usual ones until the person picks other ones here.
class UnitsField extends StatefulWidget {
  const UnitsField({super.key, this.beforeChange});

  /// Asked before switching (an assessment under way must start again); false keeps the units.
  final Future<bool> Function(UnitSystem to)? beforeChange;

  @override
  State<UnitsField> createState() => _UnitsFieldState();
}

class _UnitsFieldState extends State<UnitsField> {
  /// Bumped when a switch is called off, so the field shows the units still in use.
  int _calledOff = 0;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.t;
    final value = context.watch<SettingsController>().unitSystem;
    return DropdownButtonFormField<UnitSystem>(
      // initialValue is read once; the key rebuilds the field when picking a country changes it.
      key: ValueKey('$value $_calledOff'),
      initialValue: value,
      isExpanded: true,
      icon: Icon(Icons.expand_more_rounded, color: p.muted),
      dropdownColor: p.surface,
      borderRadius: BorderRadius.circular(12),
      items: [
        for (final s in UnitSystem.values)
          DropdownMenuItem(
            value: s,
            child: Text(s == UnitSystem.metric ? t.unitsMetric : t.unitsUs, style: TextStyle(fontSize: 14, color: p.text)),
          ),
      ],
      onChanged: (s) async {
        if (s == null || s == value) return;
        final profile = context.read<ProfileController>();
        final go = await widget.beforeChange?.call(s) ?? true;
        if (!mounted) return;
        if (go) {
          await profile.changeUnits(s);
        } else {
          setState(() => _calledOff++);
        }
      },
    );
  }
}
