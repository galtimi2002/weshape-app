import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/profile/profile_controller.dart';
import '../i18n/app_localizations.dart';
import '../i18n/languages.dart';
import '../settings/settings_controller.dart';
import '../theme/weshape_palette.dart';

enum LanguageMenuStyle {
  /// Flag, language name and a chevron: roomy headers.
  full,

  /// Flag and EN/HU code: phone headers.
  compact,

  /// Just the flag: the tightest spots.
  flagOnly,
}

/// The language picker: every language under its own name, with its flag.
/// Picking one switches the whole app at once and, when signed in, saves it
/// to the profile.
class LanguageMenu extends StatelessWidget {
  const LanguageMenu({super.key, this.style = LanguageMenuStyle.full});

  final LanguageMenuStyle style;

  @override
  Widget build(BuildContext context) {
    final current = context.watch<SettingsController>().language;
    final p = context.palette;
    final t = context.t;

    return PopupMenuButton<String>(
      tooltip: t.language,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 6),
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 240),
      onSelected: (code) => context.read<ProfileController>().changeLanguage(code),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          height: 30,
          child: Text(t.language, style: TextStyle(fontSize: 12, color: p.muted)),
        ),
        for (final lang in AppLanguages.all)
          PopupMenuItem<String>(
            value: lang.code,
            height: 40,
            child: _LanguageRow(language: lang, selected: lang.code == current.code),
          ),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: style == LanguageMenuStyle.flagOnly ? 7 : 10, vertical: 6),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: p.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(current.flag, style: const TextStyle(fontSize: 16)),
            if (style != LanguageMenuStyle.flagOnly) ...[
              const SizedBox(width: 6),
              Text(
                style == LanguageMenuStyle.full ? current.nativeName : current.shortCode,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: p.text),
              ),
            ],
            if (style == LanguageMenuStyle.full) ...[
              const SizedBox(width: 2),
              Icon(Icons.expand_more_rounded, size: 18, color: p.muted),
            ],
          ],
        ),
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({required this.language, required this.selected});

  final AppLanguage language;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Text(language.flag, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            language.nativeName,
            style: TextStyle(fontSize: 14, color: p.text, fontWeight: selected ? FontWeight.w600 : FontWeight.w400),
          ),
        ),
        Text(language.shortCode, style: TextStyle(fontSize: 11, color: p.muted, letterSpacing: 0.5)),
        const SizedBox(width: 8),
        Icon(Icons.check_rounded, size: 16, color: selected ? p.primary : Colors.transparent),
      ],
    );
  }
}
