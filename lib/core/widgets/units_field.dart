import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/profile/profile_controller.dart';
import '../i18n/app_localizations.dart';
import '../settings/settings_controller.dart';
import '../theme/weshape_palette.dart';
import '../units/units.dart';

/// Metric or US units inside a form (registration, completing the profile). It shows the units
/// in use: the country's usual ones until the person picks other ones here.
class UnitsField extends StatelessWidget {
  const UnitsField({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.t;
    final value = context.watch<SettingsController>().unitSystem;
    return DropdownButtonFormField<UnitSystem>(
      // initialValue is read once; the key rebuilds the field when picking a country changes it.
      key: ValueKey(value),
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
      onChanged: (s) {
        if (s != null) context.read<ProfileController>().changeUnits(s);
      },
    );
  }
}
