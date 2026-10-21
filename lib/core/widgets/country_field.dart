import 'package:flutter/material.dart';

import '../i18n/app_localizations.dart';
import '../i18n/countries.dart';
import '../theme/weshape_palette.dart';

/// Country picker as a form field: shows the chosen country with its flag and
/// opens a searchable list, named in the current interface language.
class CountryField extends FormField<String> {
  CountryField({
    super.key,
    super.initialValue,
    required ValueChanged<String> onChanged,
    super.validator,
  }) : super(
          builder: (state) {
            final context = state.context;
            final p = context.palette;
            final t = context.t;
            final language = Localizations.localeOf(context).languageCode;
            final code = state.value;

            Future<void> open() async {
              final picked = await showCountryPicker(context, selected: code);
              if (picked != null) {
                state.didChange(picked);
                onChanged(picked);
              }
            }

            return InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: open,
              child: InputDecorator(
                isEmpty: code == null,
                decoration: InputDecoration(
                  hintText: t.selectCountry,
                  errorText: state.errorText,
                  suffixIcon: Icon(Icons.expand_more_rounded, color: p.muted),
                ),
                child: code == null
                    ? null
                    : Row(
                        children: [
                          Text(Country(code, '').flag, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              Countries.nameOf(code, language),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 14, color: p.text),
                            ),
                          ),
                        ],
                      ),
              ),
            );
          },
        );
}

/// Searchable country list. A bottom sheet on phones, a dialog elsewhere.
Future<String?> showCountryPicker(BuildContext context, {String? selected}) {
  final phone = MediaQuery.sizeOf(context).width < 600;
  const picker = _CountryPicker();
  if (phone) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => FractionallySizedBox(heightFactor: 0.85, child: _withSelected(picker, selected)),
    );
  }
  return showDialog<String>(
    context: context,
    builder: (_) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
        child: _withSelected(picker, selected),
      ),
    ),
  );
}

Widget _withSelected(Widget child, String? selected) => _SelectedCountry(selected: selected, child: child);

class _SelectedCountry extends InheritedWidget {
  const _SelectedCountry({required this.selected, required super.child});

  final String? selected;

  @override
  bool updateShouldNotify(_SelectedCountry oldWidget) => selected != oldWidget.selected;
}

class _CountryPicker extends StatefulWidget {
  const _CountryPicker();

  @override
  State<_CountryPicker> createState() => _CountryPickerState();
}

class _CountryPickerState extends State<_CountryPicker> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.t;
    final language = Localizations.localeOf(context).languageCode;
    final selected = context.dependOnInheritedWidgetOfExactType<_SelectedCountry>()?.selected;
    final countries = Countries.sorted(language).where((c) => Countries.matches(c, _query)).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          TextField(
            controller: _search,
            autofocus: MediaQuery.sizeOf(context).width >= 600,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: t.searchCountry,
              prefixIcon: Icon(Icons.search_rounded, color: p.muted, size: 20),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: countries.isEmpty
                ? Center(child: Text(t.noResults, style: TextStyle(color: p.muted)))
                : ListView.builder(
                    itemCount: countries.length,
                    itemBuilder: (context, i) {
                      final c = countries[i];
                      final isSelected = c.code == selected;
                      return ListTile(
                        dense: true,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        selected: isSelected,
                        selectedTileColor: p.selected,
                        leading: Text(c.flag, style: const TextStyle(fontSize: 20)),
                        title: Text(c.name, style: TextStyle(fontSize: 14, color: p.text)),
                        trailing: isSelected
                            ? Icon(Icons.check_rounded, size: 18, color: p.primary)
                            : Text(c.code, style: TextStyle(fontSize: 11, color: p.muted)),
                        onTap: () => Navigator.of(context).pop(c.code),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
