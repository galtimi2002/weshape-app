import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/app_localizations.dart';
import '../../core/settings/settings_controller.dart';
import '../../core/theme/weshape_palette.dart';
import '../../core/theme/weshape_theme.dart';
import '../../core/widgets/primary_button.dart';
import '../home/map/geocoder.dart';
import 'controls.dart';
import 'home_answers.dart';
import 'page_frame.dart';

/// The assessment tab: the start page (step 0) and the six questions of the home path.
/// The result is the next piece of work, so the last step's button is "Soon" for now.
class AssessmentFlow extends StatelessWidget {
  const AssessmentFlow({
    super.key,
    required this.answers,
    required this.countryCode,
    required this.onExplore,
    required this.onPickOnMap,
  });

  final HomeAnswers answers;
  final String? countryCode;
  final VoidCallback onExplore;

  /// Switches to the map, where the card's "Assess this place" brings a point back.
  final VoidCallback onPickOnMap;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: answers,
      builder: (context, _) {
        final step = answers.step;
        final Widget page = switch (step) {
          0 => _StartStep(onHome: () => answers.update((a) => a.step = 1), onExplore: onExplore),
          1 => _PlaceStep(answers: answers, countryCode: countryCode, onPickOnMap: onPickOnMap),
          2 => _BuildingStep(answers: answers),
          3 => _ConditionStep(answers: answers),
          4 => _HeatingStep(answers: answers),
          5 => _ElectricityStep(answers: answers),
          _ => _SpaceStep(answers: answers),
        };
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 380),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(begin: const Offset(0.03, 0), end: Offset.zero).animate(animation),
              child: child,
            ),
          ),
          layoutBuilder: (current, previous) => Stack(fit: StackFit.expand, children: [...previous, if (current != null) current]),
          child: KeyedSubtree(key: ValueKey(step), child: page),
        );
      },
    );
  }
}

TextStyle _mono(BuildContext context, double size) {
  final color = context.palette.muted;
  return WeShapeTheme.useGoogleFonts
      ? GoogleFonts.jetBrainsMono(fontSize: size, color: color)
      : TextStyle(fontFamily: 'monospace', fontSize: size, color: color);
}

/// 1,800 / 1.800 / 1 800, as each language writes thousands (as on the map card).
String _group(int v, String language) {
  const dot = {'de', 'nl', 'id', 'it', 'es', 'pt', 'tr', 'da', 'el', 'ro', 'hr', 'vi'};
  const space = {'hu', 'fr', 'pl', 'fi', 'sv', 'ru'};
  final sep = dot.contains(language) ? '.' : (space.contains(language) ? ' ' : ',');
  final digits = v.abs().toString();
  final out = StringBuffer(v < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(sep);
    out.write(digits[i]);
  }
  return out.toString();
}

/// Progress line on top of every page: "Start", or "Step 2 of 6" with the bar filling up.
class _Progress extends StatelessWidget {
  const _Progress({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final p = context.palette;
    return Row(
      children: [
        Text(step == 0 ? t.assessStep : t.stepOfN(step), style: _mono(context, 11.5)),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 3,
              child: Stack(
                children: [
                  Positioned.fill(child: ColoredBox(color: p.border)),
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: step / 6),
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => FractionallySizedBox(widthFactor: v, child: ColoredBox(color: p.primary)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Title, hint, the step's content, and Back / Continue at the bottom.
class _StepPage extends StatelessWidget {
  const _StepPage({
    required this.answers,
    required this.title,
    required this.hint,
    required this.children,
    this.canContinue = true,
  });

  final HomeAnswers answers;
  final String title;
  final String hint;
  final List<Widget> children;
  final bool canContinue;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final p = context.palette;
    final last = answers.step == 6;
    return PageFrame(
      maxWidth: 680,
      children: [
        _Progress(step: answers.step),
        const SizedBox(height: 18),
        PageTitle(title),
        const SizedBox(height: 6),
        Text(hint, style: TextStyle(fontSize: 14, color: p.muted)),
        const SizedBox(height: 22),
        ...children,
        const SizedBox(height: 26),
        Row(
          children: [
            TextButton.icon(
              onPressed: () => answers.update((a) => a.step -= 1),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: Text(t.back),
              style: TextButton.styleFrom(foregroundColor: p.muted),
            ),
            const Spacer(),
            SizedBox(
              width: last ? 210 : 150,
              child: PrimaryButton(
                label: last ? t.seeResult : t.assessContinue,
                // The result is not built yet: the button stays, but cannot be pressed.
                onPressed: last || !canContinue ? null : () => answers.update((a) => a.step += 1),
              ),
            ),
          ],
        ),
        if (last) ...[
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SoonBadge(t.comingSoon),
                const SizedBox(width: 8),
                Flexible(child: Text(t.resultSoon, style: TextStyle(fontSize: 12.5, color: p.muted))),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Spacing between the groups of a step.
const _gap = SizedBox(height: 22);

// ---------------------------------------------------------------- 0: start

enum _Start { home, business, community, explore }

class _StartStep extends StatefulWidget {
  const _StartStep({required this.onHome, required this.onExplore});

  final VoidCallback onHome;
  final VoidCallback onExplore;

  @override
  State<_StartStep> createState() => _StartStepState();
}

class _StartStepState extends State<_StartStep> {
  _Start _choice = _Start.home;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final p = context.palette;
    final phone = MediaQuery.sizeOf(context).width < 700;

    Widget option(_Start value, String title, String detail, {bool soon = false}) => _StartOption(
          title: title,
          detail: phone ? null : detail,
          selected: _choice == value,
          soon: soon ? t.comingSoon : null,
          onTap: soon ? null : () => setState(() => _choice = value),
        );

    return PageFrame(
      maxWidth: 640,
      children: [
        const _Progress(step: 0),
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
        const SizedBox(height: 22),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: SizedBox(
            width: 150,
            child: PrimaryButton(
              label: t.assessContinue,
              onPressed: _choice == _Start.explore ? widget.onExplore : widget.onHome,
            ),
          ),
        ),
      ],
    );
  }
}

class _StartOption extends StatelessWidget {
  const _StartOption({required this.title, required this.detail, required this.selected, required this.soon, required this.onTap});

  final String title;
  final String? detail;
  final bool selected;
  final String? soon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onTap != null;
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
                    Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: enabled ? p.text : p.muted)),
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

// ---------------------------------------------------------------- 1: place

class _PlaceStep extends StatefulWidget {
  const _PlaceStep({required this.answers, required this.countryCode, required this.onPickOnMap});

  final HomeAnswers answers;
  final String? countryCode;
  final VoidCallback onPickOnMap;

  @override
  State<_PlaceStep> createState() => _PlaceStepState();
}

class _PlaceStepState extends State<_PlaceStep> {
  final _geocoder = Geocoder();
  final _controller = TextEditingController();
  Timer? _debounce;
  List<Place> _results = const [];
  int _request = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _nameIfNeeded());
  }

  @override
  void didUpdateWidget(_PlaceStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _nameIfNeeded());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// A point clicked on the map arrives without a name: look it up, as the map card does.
  AssessmentPlace? _naming;
  Future<void> _nameIfNeeded() async {
    final place = widget.answers.place;
    if (!mounted || place == null || place.title.isNotEmpty || identical(place, _naming)) return;
    _naming = place;
    try {
      final found = await _geocoder.reverse(place.lat, place.lon, language: context.read<SettingsController>().languageCode);
      if (!mounted || found == null || !identical(widget.answers.place, place)) return;
      widget.answers.update((a) => a.place = AssessmentPlace(lat: place.lat, lon: place.lon, title: found.title, detail: found.detail));
    } catch (_) {
      // No name: the card says "Selected point".
    }
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(text));
  }

  Future<void> _search(String text) async {
    final request = ++_request;
    final language = context.read<SettingsController>().languageCode;
    try {
      final found = await _geocoder.search(text, countryCode: widget.countryCode, language: language);
      if (!mounted || request != _request) return;
      setState(() => _results = found);
    } catch (_) {
      if (mounted && request == _request) setState(() => _results = const []);
    }
  }

  void _choose(Place place) {
    widget.answers.update((a) => a.place = AssessmentPlace(lat: place.lat, lon: place.lon, title: place.title, detail: place.detail));
    setState(() {
      _results = const [];
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final p = context.palette;
    final phone = MediaQuery.sizeOf(context).width < 700;
    final place = widget.answers.place;
    final underline = p.text.withValues(alpha: 0.18);

    return _StepPage(
      answers: widget.answers,
      title: t.placeTitle,
      hint: t.placeHint,
      canContinue: place != null,
      children: [
        Row(
          children: [
            Icon(Icons.search_rounded, size: 22, color: p.text.withValues(alpha: 0.55)),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _controller,
                onChanged: _onChanged,
                onSubmitted: _search,
                textInputAction: TextInputAction.search,
                style: TextStyle(fontSize: phone ? 19 : 22, fontWeight: FontWeight.w300, color: p.text, letterSpacing: -0.2),
                cursorColor: p.primary,
                decoration: InputDecoration(
                  isDense: true,
                  filled: false,
                  hintText: t.searchAddress,
                  hintStyle: TextStyle(color: p.text.withValues(alpha: 0.4), fontWeight: FontWeight.w300),
                  contentPadding: const EdgeInsets.only(top: 6, bottom: 10),
                  border: UnderlineInputBorder(borderSide: BorderSide(color: underline, width: 1.5)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: underline, width: 1.5)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: p.primary, width: 1.5)),
                ),
              ),
            ),
          ],
        ),
        if (_results.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: p.border)),
            child: Column(
              children: [
                for (final r in _results)
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.place_outlined, size: 18, color: p.muted),
                    title: Text(r.title, style: TextStyle(fontSize: 14, color: p.text)),
                    subtitle: r.detail.isEmpty ? null : Text(r.detail, style: TextStyle(fontSize: 12, color: p.muted)),
                    onTap: () => _choose(r),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 14),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            onPressed: widget.onPickOnMap,
            icon: const Icon(Icons.map_outlined, size: 18),
            label: Text(t.placePickOnMap),
          ),
        ),
        if (place != null) ...[
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.fieldFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.primary.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.place_rounded, color: p.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.placeChosen, style: TextStyle(fontSize: 11.5, color: p.muted)),
                      Text(place.title.isEmpty ? t.selectedPoint : place.title,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: p.text)),
                      if (place.detail.isNotEmpty) Text(place.detail, style: TextStyle(fontSize: 12.5, color: p.muted)),
                      Text(
                        '${place.lat.abs().toStringAsFixed(2)}° ${place.lat >= 0 ? 'N' : 'S'} · ${place.lon.abs().toStringAsFixed(2)}° ${place.lon >= 0 ? 'E' : 'W'}',
                        style: _mono(context, 10.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------- 2: building

class _BuildingStep extends StatelessWidget {
  const _BuildingStep({required this.answers});

  final HomeAnswers answers;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final a = answers;
    return _StepPage(
      answers: a,
      title: t.buildingTitle,
      hint: t.buildingHint,
      children: [
        FieldLabel(t.typeLabel),
        ChoiceChips<BuildingType>(
          values: BuildingType.values,
          label: (v) => v == BuildingType.house ? t.typeHouse : t.typeFlat,
          selected: a.type,
          onSelect: a.setType,
        ),
        _gap,
        FieldLabel(t.floorsLabel),
        ChoiceChips<int>(values: const [1, 2, 3], label: (v) => v == 3 ? '3+' : '$v', selected: a.floors, onSelect: a.setFloors),
        _gap,
        FieldLabel(t.peopleLabel),
        ChoiceChips<int>(
          values: const [1, 2, 3, 4, 5],
          label: (v) => v == 5 ? '5+' : '$v',
          selected: a.people,
          onSelect: (v) => a.update((x) => x.people = v),
        ),
        _gap,
        FieldLabel(t.areaLabel),
        NumberSlider(
          value: a.area,
          min: 30,
          max: 400,
          step: 5,
          unit: 'm²',
          onChanged: (v) => a.update((x) {
            x.area = v;
            x.areaSet = true;
          }),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- 3: condition

class _ConditionStep extends StatelessWidget {
  const _ConditionStep({required this.answers});

  final HomeAnswers answers;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final a = answers;
    void set(void Function(HomeAnswers) change) => a.update((x) {
          change(x);
          x.typicalBuilding = false;
        });

    return _StepPage(
      answers: a,
      title: t.condTitle,
      hint: t.condHint,
      children: [
        FieldLabel(t.builtLabel),
        ChoiceChips<BuildEra>(
          values: BuildEra.values,
          label: (v) => switch (v) {
            BuildEra.before1960 => t.eraBefore1960,
            BuildEra.from1960 => t.era1960,
            BuildEra.from1990 => t.era1990,
            BuildEra.from2010 => t.era2010,
          },
          selected: a.era,
          onSelect: (v) => set((x) => x.era = v),
        ),
        _gap,
        FieldLabel(t.wallsLabel),
        ChoiceChips<WallType>(
          values: WallType.values,
          label: (v) => switch (v) {
            WallType.brick => t.wallBrick,
            WallType.panel => t.wallPanel,
            WallType.aerated => t.wallAerated,
            WallType.wood => t.wallWood,
            WallType.stone => t.wallStone,
          },
          selected: a.wall,
          onSelect: (v) => set((x) => x.wall = v),
        ),
        _gap,
        FieldLabel(t.insLabel),
        ChoiceChips<Insulation>(
          values: Insulation.values,
          label: (v) => switch (v) {
            Insulation.none => t.insNone,
            Insulation.thin => t.insThin,
            Insulation.thick => t.insThick,
          },
          selected: a.insulation,
          onSelect: (v) => set((x) => x.insulation = v),
        ),
        _gap,
        FieldLabel(t.windowsLabel),
        ChoiceChips<Glazing>(
          values: Glazing.values,
          label: (v) => switch (v) {
            Glazing.single => t.winSingle,
            Glazing.double => t.winDouble,
            Glazing.triple => t.winTriple,
          },
          selected: a.glazing,
          onSelect: (v) => set((x) => x.glazing = v),
        ),
        const SizedBox(height: 16),
        LinkButton(
          label: t.condUnknown,
          onTap: () => a.update((x) {
            x
              ..era = BuildEra.from1960
              ..wall = WallType.brick
              ..insulation = Insulation.none
              ..glazing = Glazing.double
              ..typicalBuilding = true
              ..step += 1;
          }),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- 4: heating

class _HeatingStep extends StatelessWidget {
  const _HeatingStep({required this.answers});

  final HomeAnswers answers;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return _StepPage(
      answers: answers,
      title: t.heatTitle,
      hint: t.heatHint,
      children: [
        ChoiceChips<Heating>(
          values: Heating.values,
          label: (v) => switch (v) {
            Heating.gas => t.heatGas,
            Heating.wood => t.heatWood,
            Heating.electric => t.heatElectric,
            Heating.district => t.heatDistrict,
            Heating.heatPump => t.heatPump,
          },
          selected: answers.heating,
          onSelect: (v) => answers.update((x) => x.heating = v),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- 5: electricity

class _ElectricityStep extends StatelessWidget {
  const _ElectricityStep({required this.answers});

  final HomeAnswers answers;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final p = context.palette;
    final a = answers;
    final language = Localizations.localeOf(context).languageCode;
    return _StepPage(
      answers: a,
      title: t.elecTitle,
      hint: t.elecHint,
      children: [
        NumberSlider(
          value: a.monthlyKwh,
          min: 50,
          max: 1500,
          step: 10,
          unit: t.kwhPerMonth,
          note: t.kwhPerYearAboutN(_group((a.monthlyKwh * 12 / 100).round() * 100, language)),
          enabled: a.useKnown,
          onChanged: (v) => a.update((x) => x.monthlyKwh = v),
        ),
        const SizedBox(height: 8),
        LinkButton(
          label: a.useKnown ? t.elecUnknown : t.elecKnown,
          onTap: () => a.update((x) => x.useKnown = !x.useKnown),
        ),
        if (!a.useKnown) ...[
          const SizedBox(height: 8),
          Text(t.elecEstimatedFor(a.people, _group(a.estimatedYearlyKwh, language)),
              style: TextStyle(fontSize: 13.5, color: p.muted)),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------- 6: space and goal

class _SpaceStep extends StatelessWidget {
  const _SpaceStep({required this.answers});

  final HomeAnswers answers;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final p = context.palette;
    final a = answers;
    final flat = a.type == BuildingType.flat;
    Widget row(Space s, String title, String detail) =>
        CheckRow(title: title, detail: detail, checked: a.spaces.contains(s), onTap: () => a.toggleSpace(s));

    return _StepPage(
      answers: a,
      title: t.spaceTitle,
      hint: t.spaceHint,
      children: [
        Container(height: 1, color: p.border),
        if (flat) row(Space.balcony, t.hasBalcony, t.hasBalconyDesc) else ...[
          row(Space.roof, t.hasRoof, t.hasRoofDesc),
          row(Space.garden, t.hasGarden, t.hasGardenDesc),
          row(Space.land, t.hasLand, t.hasLandDesc),
        ],
        row(Space.stream, t.hasStream, t.hasStreamDesc),
        if (!flat && a.spaces.contains(Space.roof)) ...[
          _gap,
          Wrap(
            spacing: 32,
            runSpacing: 18,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FieldLabel(t.roofSizeLabel),
                  ChoiceChips<RoofSize>(
                    values: RoofSize.values,
                    label: (v) => switch (v) {
                      RoofSize.small => t.roofSmall,
                      RoofSize.medium => t.roofMedium,
                      RoofSize.large => t.roofLarge,
                    },
                    sublabel: (v) => switch (v) {
                      RoofSize.small => '~3 kWp',
                      RoofSize.medium => '~6 kWp',
                      RoofSize.large => '~10 kWp',
                    },
                    selected: a.roofSize,
                    onSelect: (v) => a.update((x) => x.roofSize = v),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FieldLabel(t.facingLabel),
                  ChoiceChips<Facing>(
                    values: Facing.values,
                    label: (v) => switch (v) {
                      Facing.south => t.faceSouth,
                      Facing.eastWest => t.faceEastWest,
                      Facing.north => t.faceNorth,
                    },
                    selected: a.facing,
                    onSelect: (v) => a.update((x) => x.facing = v),
                  ),
                ],
              ),
            ],
          ),
        ],
        _gap,
        FieldLabel(t.aimLabel),
        ChoiceChips<Aim>(
          values: Aim.values,
          label: (v) => switch (v) {
            Aim.bills => t.aimBills,
            Aim.independence => t.aimIndep,
            Aim.emissions => t.aimCo2,
          },
          selected: a.aim,
          onSelect: (v) => a.update((x) => x.aim = v),
        ),
      ],
    );
  }
}
