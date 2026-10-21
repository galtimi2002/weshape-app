import 'package:flutter/material.dart';

import '../i18n/languages.dart';
import '../theme/weshape_palette.dart';

/// Language choice inside a form (registration), flags and native names.
class LanguageField extends StatelessWidget {
  const LanguageField({super.key, required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      icon: Icon(Icons.expand_more_rounded, color: p.muted),
      dropdownColor: p.surface,
      borderRadius: BorderRadius.circular(12),
      menuMaxHeight: 360,
      items: [
        for (final lang in AppLanguages.all)
          DropdownMenuItem(
            value: lang.code,
            child: Row(
              children: [
                Text(lang.flag, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(child: Text(lang.nativeName, style: TextStyle(fontSize: 14, color: p.text))),
                Text(lang.shortCode, style: TextStyle(fontSize: 11, color: p.muted)),
              ],
            ),
          ),
      ],
      onChanged: (code) {
        if (code != null) onChanged(code);
      },
    );
  }
}
