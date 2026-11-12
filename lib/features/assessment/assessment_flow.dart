import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/settings/settings_controller.dart';
import '../../core/theme/weshape_palette.dart';
import '../../core/theme/weshape_theme.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/stage_background.dart';
import '../home/map/geocoder.dart';
import '../home/map/map_peek.dart';
import 'controls.dart';
import 'currencies.dart';
import 'home_answers.dart';
import 'page_frame.dart';

/// The assessment tab: the questions of the home path, one screen at a time. Which screens
/// appear depends on the answers (no gas questions without piped gas, and so on), so the
/// order is worked out again after every answer. The result comes next: its button is "Soon".
class AssessmentFlow extends StatefulWidget {
  const AssessmentFlow({super.key, required this.answers, required this.countryCode, required this.onPickOnMap});

  final HomeAnswers answers;
  final String? countryCode;

  /// Switches to the map, where the person clicks a point and confirms it.
  final VoidCallback onPickOnMap;

  @override
  State<AssessmentFlow> createState() => _AssessmentFlowState();
}

/// What our maps know about the chosen place, for the follow-up questions.
class _PlaceFacts {
  _PlaceFacts(this.place);

  final AssessmentPlace place;
  bool loading = true;

  /// Distance to the nearest river reach, when the river map has one.
  double? riverKm;

  /// Mean wind speed at 20 m, from the 10 m and 50 m values of the wind map.
  double? wind20;
}

/// Rivers further than this are not worth asking about for a home.
const _riverNearKm = 0.5;

/// Below this mean speed at 20 m a small turbine makes little power: no question.
const _windUseful = 3.0;

class _AssessmentFlowState extends State<AssessmentFlow> {
  _PlaceFacts? _facts;

  /// "Just one more question": shown for a moment before the last question.
  bool _oneMore = false;
  Timer? _oneMoreTimer;

  HomeAnswers get _a => widget.answers;

  @override
  void initState() {
    super.initState();
    _a.addListener(_checkPlace);
    _checkPlace();
  }

  @override
  void dispose() {
    _a.removeListener(_checkPlace);
    _oneMoreTimer?.cancel();
    super.dispose();
  }

  /// A new place: ask the river and wind maps about it, in the background.
  void _checkPlace() {
    final place = _a.place;
    if (place == null) {
      _facts = null;
      return;
    }
    final known = _facts?.place;
    if (known != null && known.lat == place.lat && known.lon == place.lon) return;
    final facts = _facts = _PlaceFacts(place);
    final api = context.read<ApiClient>();
    Future.wait<double>([
      api.hydroPoint(place.lat, place.lon).then((h) => facts.riverKm = h.distanceKm).catchError((Object _) => 99.0),
      api.windPoint(place.lat, place.lon).then((w) {
        final s10 = w.speeds.where((s) => s.height == 10).firstOrNull?.speed;
        final s50 = w.speeds.where((s) => s.height == 50).firstOrNull?.speed;
        if (s10 != null && s50 != null && s10 > 0) {
          // Log-law between the two heights the map has.
          facts.wind20 = s10 * math.pow(s50 / s10, math.log(2) / math.log(5)).toDouble();
        }
        return 0.0;
      }).catchError((Object _) => 0.0),
    ]).whenComplete(() {
      facts.loading = false;
      if (mounted && identical(facts, _facts)) setState(() {});
    });
  }

  /// Next screen; the last question is announced first ("Just one more question").
  void _next(List<String> steps, int index) {
    final next = steps[index + 1];
    if (next != steps.last) {
      _a.update((a) => a.screen = next);
      return;
    }
    setState(() => _oneMore = true);
    _oneMoreTimer?.cancel();
    _oneMoreTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _oneMore = false);
      _a.update((a) => a.screen = next);
    });
  }

  Future<void> _confirmReset() async {
    final t = context.t;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.resetTitle),
        content: Text(t.resetBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(t.resetConfirm)),
        ],
      ),
    );
    if (ok ?? false) _a.reset();
  }

  bool get _land => _a.spaces.contains(Space.garden) || _a.spaces.contains(Space.land) || _a.spaces.contains(Space.notSure);

  bool get _askAnimals => _land;
  bool get _askRiver => (_facts?.riverKm ?? 99) <= _riverNearKm;
  bool get _askBrook => !_askRiver && _land;
  bool get _askWind =>
      (_facts?.wind20 ?? 0) >= _windUseful && _a.type == BuildingType.house && (_land || _a.spaces.contains(Space.roof));
  bool get _askFollowUps => (_facts?.loading ?? false) || _askAnimals || _askRiver || _askBrook || _askWind;

  /// The screens to show, in order, for the answers so far.
  List<String> _steps() {
    final a = _a;
    final mains = a.sources.contains(Source.mains);
    return [
      'audience',
      'place',
      'uses',
      if (a.uses.contains(Use.heating)) ...[
        'building',
        'era',
        if (a.oldBuilding) 'renovation',
        'insulation',
        'windows',
      ],
      'sources',
      if (mains) ...['electricity', 'paid'],
      if (a.sources.contains(Source.pipedGas)) 'gas',
      if (a.hasFuels) 'fuels',
      'spaces',
      if (a.hasPlaces) 'sizes',
      'ownership',
      'upkeep',
      'priority',
      if (_askFollowUps) 'followUps',
      'exclude',
      // Something new at the place that the map does not show yet: asked of everyone,
      // over the map of the place.
      'newThing',
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _a,
      builder: (context, _) {
        final steps = _steps();
        var index = steps.indexOf(_a.screen);
        if (index < 0) index = _a.screen == 'followUps' ? steps.length - 2 : 0;
        final id = steps[index];
        final nav = _Nav(
          index: index,
          total: steps.length,
          onBack: index == 0 ? null : () => _a.update((a) => a.screen = steps[index - 1]),
          onNext: index == steps.length - 1 ? null : () => _next(steps, index),
          onFirst: index == 0 ? null : () => _a.update((a) => a.screen = steps.first),
          onReset: _confirmReset,
        );
        final a = _a;
        final Widget page = _oneMore ? const _OneMoreStep() : switch (id) {
          'audience' => _AudienceStep(answers: a, nav: nav),
          'place' => _PlaceStep(answers: a, nav: nav, countryCode: widget.countryCode, onPickOnMap: widget.onPickOnMap),
          'uses' => _UsesStep(answers: a, nav: nav),
          'building' => _BuildingStep(answers: a, nav: nav),
          'era' => _EraStep(answers: a, nav: nav),
          'renovation' => _RenovationStep(answers: a, nav: nav),
          'insulation' => _InsulationStep(answers: a, nav: nav),
          'windows' => _WindowsStep(answers: a, nav: nav),
          'sources' => _SourcesStep(answers: a, nav: nav),
          'electricity' => _ElectricityStep(answers: a, nav: nav),
          'paid' => _PaidStep(answers: a, nav: nav, countryCode: widget.countryCode),
          'gas' => _GasStep(answers: a, nav: nav, countryCode: widget.countryCode),
          'fuels' => _FuelsStep(answers: a, nav: nav, countryCode: widget.countryCode),
          'spaces' => _SpacesStep(answers: a, nav: nav),
          'sizes' => _SizesStep(answers: a, nav: nav),
          'ownership' => _OwnershipStep(answers: a, nav: nav),
          'upkeep' => _UpkeepStep(answers: a, nav: nav),
          'priority' => _PriorityStep(answers: a, nav: nav),
          'followUps' => _FollowUpsStep(
              answers: a,
              nav: nav,
              facts: _facts,
              animals: _askAnimals,
              river: _askRiver,
              brook: _askBrook,
              wind: _askWind,
            ),
          'exclude' => _ExcludeStep(answers: a, nav: nav),
          _ => _NewThingStep(answers: a, nav: nav),
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
          child: KeyedSubtree(key: ValueKey(_oneMore ? 'oneMore' : id), child: page),
        );
      },
    );
  }
}

/// Where a screen is in the flow, and how to leave it.
class _Nav {
  const _Nav({
    required this.index,
    required this.total,
    required this.onBack,
    required this.onNext,
    required this.onFirst,
    required this.onReset,
  });

  final int index;
  final int total;
  final VoidCallback? onBack;

  /// Back to the first question, keeping the answers; null on the first one.
  final VoidCallback? onFirst;

  /// "I made a mistake": asks, then deletes every answer and goes back to the first question.
  final VoidCallback onReset;

  /// Null on the last screen: the result comes next.
  final VoidCallback? onNext;

  bool get last => onNext == null;
}

// ---------------------------------------------------------------- shared pieces

TextStyle _mono(BuildContext context, double size) {
  final color = context.palette.muted;
  return WeShapeTheme.useGoogleFonts
      ? GoogleFonts.jetBrainsMono(fontSize: size, color: color)
      : TextStyle(fontFamily: 'monospace', fontSize: size, color: color);
}

const _commaLanguages = {'hu', 'ro', 'de', 'fr', 'es', 'it', 'pt', 'nl', 'pl', 'hr', 'fi', 'ru', 'tr', 'sv', 'da', 'el', 'id', 'vi'};

/// 4.2 / 4,2, as each language writes decimals.
String _decimal(double v, String language) {
  final s = v.toStringAsFixed(1);
  return _commaLanguages.contains(language) ? s.replaceAll('.', ',') : s;
}

List<String> _monthNames(AppStrings t) => [for (final m in t.monthNames.split(',')) m.trim()];

/// Progress line on top of every page: "Step 2 of 14" with the bar filling up.
class _Progress extends StatelessWidget {
  const _Progress({required this.nav});

  final _Nav nav;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Text(context.t.stepOfTotalFor(nav.index + 1, nav.total), style: _mono(context, 11.5)),
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
                    tween: Tween(end: (nav.index + 1) / nav.total),
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

/// Title, optional helper line, the screen's content, and Back / Continue at the bottom.
class _StepPage extends StatelessWidget {
  const _StepPage({
    required this.nav,
    required this.title,
    required this.children,
    this.hint,
    this.note,
    this.canContinue = true,
    this.wide,
  });

  final _Nav nav;
  final String title;
  final String? hint;

  /// One line on what we take into account with this answer, so the user sees how carefully we
  /// calculate (docs/decisions/2026-11-12-question-notes-and-climate-grid.md in the backend).
  final String? note;
  final List<Widget> children;
  final bool canContinue;

  /// On a large screen, two columns side by side instead of [children], so the page fits
  /// without scrolling.
  final (List<Widget>, List<Widget>)? wide;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final columns = MediaQuery.sizeOf(context).width >= 1000 ? wide : null;
    return PageFrame(
      maxWidth: columns == null ? 680 : 1160,
      children: [
        _Progress(nav: nav),
        const SizedBox(height: 18),
        PageTitle(title),
        if (hint != null) ...[
          const SizedBox(height: 6),
          Text(hint!, style: TextStyle(fontSize: 14, color: p.muted)),
        ],
        if (note != null) ...[
          const SizedBox(height: 10),
          _NoteLine(note!),
        ],
        const SizedBox(height: 22),
        if (columns == null)
          ...children
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: columns.$1)),
              const SizedBox(width: 48),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: columns.$2)),
            ],
          ),
        const SizedBox(height: 28),
        _StepButtons(nav: nav, canContinue: canContinue),
      ],
    );
  }
}

/// What we take into account with the answer: a small sparkle and one line.
class _NoteLine extends StatelessWidget {
  const _NoteLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(Icons.auto_awesome, size: 16, color: p.green),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontSize: 13.5, height: 1.35, color: p.text))),
      ],
    );
  }
}

/// Continue (or "See the result" on the last screen), then Back, Back to the first question
/// and "I made a mistake".
class _StepButtons extends StatelessWidget {
  const _StepButtons({required this.nav, required this.canContinue});

  final _Nav nav;
  final bool canContinue;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: SizedBox(
            width: nav.last ? 230 : 200,
            child: PrimaryButton(
              label: nav.last ? t.seeResult : t.assessContinue,
              onPressed: !canContinue ? null : (nav.last ? () => _confirmResult(context) : nav.onNext),
            ),
          ),
        ),
        if (nav.last) ...[
          const SizedBox(height: 10),
          Center(
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
        if (nav.onBack != null) ...[
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            runSpacing: 2,
            children: [
              TextButton.icon(
                onPressed: nav.onBack,
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: Text(t.back),
                style: TextButton.styleFrom(foregroundColor: p.muted),
              ),
              if (nav.onFirst != null && nav.index > 1)
                TextButton.icon(
                  onPressed: nav.onFirst,
                  icon: const Icon(Icons.first_page_rounded, size: 18),
                  label: Text(t.toFirst),
                  style: TextButton.styleFrom(foregroundColor: p.muted),
                ),
              TextButton.icon(
                onPressed: nav.onReset,
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: Text(t.resetAnswers),
                style: TextButton.styleFrom(foregroundColor: p.error),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// "Is everything filled in correctly?" before the result. The result itself is the
/// next piece of work, so for now a confirmed answer only says it is coming.
Future<void> _confirmResult(BuildContext context) async {
  final t = context.t;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(t.confirmTitle),
      content: Text(t.confirmBody),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.confirmCheck)),
        TextButton(onPressed: () => Navigator.pop(context, true), child: Text(t.confirmGo)),
      ],
    ),
  );
  if ((ok ?? false) && context.mounted) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(t.resultSoon)));
  }
}

/// "Just one more question", for a moment before the last question.
class _OneMoreStep extends StatelessWidget {
  const _OneMoreStep();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return StageBackground(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 30, height: 30, child: CircularProgressIndicator(strokeWidth: 2.5, color: p.primary)),
            const SizedBox(height: 18),
            PageTitle(context.t.oneMore),
          ],
        ),
      ),
    );
  }
}

/// Spacing between the groups of a screen.
const _gap = SizedBox(height: 22);

/// One answer out of a list, as rows with a round mark and an optional description.
class _Options<T> extends StatelessWidget {
  const _Options({required this.values, required this.title, required this.selected, required this.onSelect, this.detail});

  final List<T> values;
  final String Function(T) title;
  final String? Function(T)? detail;
  final T? selected;
  final ValueChanged<T> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      children: [
        Container(height: 1, color: p.border),
        for (final v in values)
          _OptionRow(title: title(v), detail: detail?.call(v), selected: v == selected, onTap: () => onSelect(v)),
      ],
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.title, required this.selected, required this.onTap, this.detail});

  final String title;
  final String? detail;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label: title,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
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
                    border: Border.all(color: selected ? p.primary : p.muted, width: 1.5),
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

/// Several answers out of a list, one under the other, with a square tick and an icon.
class _CheckOptions<T> extends StatelessWidget {
  const _CheckOptions({required this.values, required this.title, required this.selected, required this.onToggle, this.icon});

  final List<T> values;
  final String Function(T) title;
  final IconData Function(T)? icon;
  final Set<T> selected;
  final ValueChanged<T> onToggle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      children: [
        Container(height: 1, color: p.border),
        for (final v in values)
          Semantics(
            checked: selected.contains(v),
            label: title(v),
            child: InkWell(
              onTap: () => onToggle(v),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.border))),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: selected.contains(v) ? p.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: selected.contains(v) ? p.primary : p.muted, width: 1.5),
                      ),
                      child: selected.contains(v) ? Icon(Icons.check_rounded, size: 14, color: p.onPrimary) : null,
                    ),
                    const SizedBox(width: 14),
                    if (icon != null) ...[
                      Icon(icon!(v), size: 20, color: p.primary),
                      const SizedBox(width: 10),
                    ],
                    Expanded(child: Text(title(v), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: p.text))),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Something that is coming: shown, greyed, with the "Soon" badge, and not clickable.
class _SoonAction extends StatelessWidget {
  const _SoonAction({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: p.muted.withValues(alpha: 0.7)),
        const SizedBox(width: 6),
        Flexible(child: Text(label, style: TextStyle(fontSize: 13.5, color: p.muted.withValues(alpha: 0.8)))),
        const SizedBox(width: 8),
        SoonBadge(context.t.comingSoon),
      ],
    );
  }
}

/// "Help me check" (opens short tips on what to look at) and "Take a photo" (soon).
class _HelpCheck extends StatefulWidget {
  const _HelpCheck({required this.tips});

  final List<String> tips;

  @override
  State<_HelpCheck> createState() => _HelpCheckState();
}

class _HelpCheckState extends State<_HelpCheck> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 18,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TextButton.icon(
              onPressed: () => setState(() => _open = !_open),
              icon: Icon(_open ? Icons.expand_less_rounded : Icons.help_outline_rounded, size: 18),
              label: Text(t.helpCheck),
            ),
            _SoonAction(icon: Icons.photo_camera_outlined, label: t.takePhoto),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: !_open
              ? const SizedBox(width: double.infinity)
              : Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: p.fieldFill, borderRadius: BorderRadius.circular(12), border: Border.all(color: p.border)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final tip in widget.tips)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Icon(Icons.search_rounded, size: 16, color: p.primary),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(tip, style: TextStyle(fontSize: 13.5, color: p.text, height: 1.4))),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- 1: who is it for

class _AudienceStep extends StatelessWidget {
  const _AudienceStep({required this.answers, required this.nav});

  final HomeAnswers answers;
  final _Nav nav;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final cards = [
      (Audience.home, Icons.home_outlined, t.audHome, t.audHomeDesc),
      (Audience.farm, Icons.agriculture_outlined, t.audFarm, t.audFarmDesc),
      (Audience.business, Icons.storefront_outlined, t.audBusiness, t.audBusinessDesc),
      (Audience.community, Icons.groups_outlined, t.audCommunity, t.audCommunityDesc),
      (Audience.village, Icons.location_city_outlined, t.audVillage, t.audVillageDesc),
      (Audience.site, Icons.landscape_outlined, t.audSite, t.audSiteDesc),
    ];
    return _StepPage(
      nav: nav,
      title: t.audTitle,
      note: t.noteAudience,
      hint: t.assessIntro,
      canContinue: answers.audience != null,
      children: [
        LayoutBuilder(
          builder: (context, box) {
            final columns = box.maxWidth >= 600 ? 3 : (box.maxWidth >= 340 ? 2 : 1);
            const gap = 10.0;
            final width = (box.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final (value, icon, title, detail) in cards)
                  SizedBox(
                    width: width,
                    child: _AudienceCard(
                      icon: icon,
                      title: title,
                      detail: detail,
                      selected: answers.audience == value,
                      // Only the home path has its questions so far.
                      onTap: value == Audience.home ? () => answers.update((a) => a.audience = value) : null,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _AudienceCard extends StatelessWidget {
  const _AudienceCard({required this.icon, required this.title, required this.detail, required this.selected, required this.onTap});

  final IconData icon;
  final String title;
  final String detail;
  final bool selected;
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
        borderRadius: BorderRadius.circular(14),
        mouseCursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minHeight: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? p.selected : p.fieldFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? p.primary : p.border, width: selected ? 1.5 : 1),
          ),
          child: Opacity(
            opacity: enabled ? 1 : 0.55,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(color: p.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                      child: Icon(icon, color: p.primary, size: 22),
                    ),
                    const Spacer(),
                    if (!enabled) SoonBadge(context.t.comingSoon),
                  ],
                ),
                const SizedBox(height: 12),
                Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: p.text)),
                const SizedBox(height: 3),
                Text(detail, style: TextStyle(fontSize: 12.5, color: p.muted, height: 1.35)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- 2: place

class _PlaceStep extends StatefulWidget {
  const _PlaceStep({required this.answers, required this.nav, required this.countryCode, required this.onPickOnMap});

  final HomeAnswers answers;
  final _Nav nav;
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
      nav: widget.nav,
      title: t.placeTitle,
      note: t.notePlace,
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

// ---------------------------------------------------------------- 3: what to power

class _UsesStep extends StatelessWidget {
  const _UsesStep({required this.answers, required this.nav});

  final HomeAnswers answers;
  final _Nav nav;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final a = answers;
    return _StepPage(
      nav: nav,
      title: t.usesTitle,
      note: t.noteUses,
      canContinue: a.uses.isNotEmpty,
      children: [
        _CheckOptions<Use>(
          values: Use.values,
          selected: a.uses,
          title: (v) => switch (v) {
            Use.appliances => t.useAppliances,
            Use.cooking => t.useCooking,
            Use.heating => t.useHeating,
            Use.hotWater => t.useHotWater,
            Use.car => t.useCar,
            Use.pumping => t.usePumping,
          },
          icon: (v) => switch (v) {
            Use.appliances => Icons.lightbulb_outline_rounded,
            Use.cooking => Icons.soup_kitchen_outlined,
            Use.heating => Icons.thermostat_rounded,
            Use.hotWater => Icons.shower_outlined,
            Use.car => Icons.ev_station_outlined,
            Use.pumping => Icons.water_drop_outlined,
          },
          onToggle: (v) => a.update((x) => x.uses.contains(v) ? x.uses.remove(v) : x.uses.add(v)),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- 4: the building

class _BuildingStep extends StatelessWidget {
  const _BuildingStep({required this.answers, required this.nav});

  final HomeAnswers answers;
  final _Nav nav;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final a = answers;
    return _StepPage(
      nav: nav,
      title: t.buildingTitle,
      note: t.noteBuilding,
      hint: t.buildingHint,
      canContinue: a.type != null && a.area != null && a.people != null && (a.type == BuildingType.flat || a.floors != null),
      children: [
        FieldLabel(t.typeLabel),
        ChoiceChips<BuildingType>(
          values: BuildingType.values,
          label: (v) => v == BuildingType.house ? t.typeHouse : t.typeFlat,
          selected: a.type,
          onSelect: a.setType,
        ),
        _gap,
        FieldLabel(t.areaLabel),
        NumberSlider(
          value: a.area,
          min: 20,
          max: 400,
          step: 5,
          unit: 'm²',
          onChanged: (v) => a.update((x) {
            x.area = v;
            x.areaSet = true;
          }),
        ),
        if (a.type == BuildingType.house) ...[
          _gap,
          FieldLabel(t.floorsLabel),
          ChoiceChips<int>(values: const [1, 2, 3], label: (v) => v == 3 ? '3+' : '$v', selected: a.floors, onSelect: a.setFloors),
        ],
        _gap,
        FieldLabel(t.peopleLabel),
        ChoiceChips<int>(
          values: const [1, 2, 3, 4, 5],
          label: (v) => v == 5 ? '5+' : '$v',
          selected: a.people,
          onSelect: (v) => a.update((x) => x.people = v),
        ),
      ],
    );
  }
}

class _EraStep extends StatelessWidget {
  const _EraStep({required this.answers, required this.nav});

  final HomeAnswers answers;
  final _Nav nav;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final a = answers;
    return _StepPage(
      nav: nav,
      title: a.type == BuildingType.flat ? t.eraTitleFlat : t.eraTitle,
      note: t.noteEra,
      canContinue: a.era != null,
      children: [
        _Options<BuildEra>(
          values: BuildEra.values,
          title: (v) => switch (v) {
            BuildEra.before1960 => t.eraBefore1960,
            BuildEra.from1960 => t.era1960,
            BuildEra.from1990 => t.era1990,
            BuildEra.from2010 => t.era2010,
            BuildEra.unknown => t.dontKnow,
          },
          selected: a.era,
          onSelect: (v) => a.update((x) => x.era = v),
        ),
        if (a.era == BuildEra.unknown) _Unsure('${t.unsureLead} ${t.tipEra}'),
      ],
    );
  }
}

class _RenovationStep extends StatelessWidget {
  const _RenovationStep({required this.answers, required this.nav});

  final HomeAnswers answers;
  final _Nav nav;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final a = answers;
    String label(Renovation r) => switch (r) {
          Renovation.walls => t.renoWalls,
          Renovation.roof => t.renoRoof,
          Renovation.windows => t.renoWindows,
          Renovation.heating => t.renoHeating,
          Renovation.none => t.renoNone,
          Renovation.unknown => t.dontKnow,
        };
    final parts = [
      for (final r in Renovation.values)
        if (r != Renovation.none && r != Renovation.unknown && a.renovations.contains(r)) r,
    ];
    return _StepPage(
      nav: nav,
      title: t.renoTitle,
      note: t.noteReno,
      canContinue: a.renovations.isNotEmpty && parts.every(a.renovationAge.containsKey),
      children: [
        MultiChips<Renovation>(values: Renovation.values, label: label, selected: a.renovations, onToggle: a.toggleRenovation),
        if (a.renovations.contains(Renovation.unknown)) _Unsure('${t.unsureLead} ${t.tipReno}'),
        if (parts.isNotEmpty) ...[
          _gap,
          SubQuestion(t.renoWhen),
          for (final r in parts) ...[
            FieldLabel(label(r)),
            ChoiceChips<RenovationAge>(
              values: RenovationAge.values,
              label: (v) => switch (v) {
                RenovationAge.recent => t.ageRecent,
                RenovationAge.middle => t.ageMiddle,
                RenovationAge.old => t.ageOld,
              },
              selected: a.renovationAge[r],
              onSelect: (v) => a.update((x) => x.renovationAge[r] = v),
            ),
            const SizedBox(height: 14),
          ],
        ],
      ],
    );
  }
}

class _InsulationStep extends StatelessWidget {
  const _InsulationStep({required this.answers, required this.nav});

  final HomeAnswers answers;
  final _Nav nav;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final a = answers;
    String level(InsulationLevel v) => switch (v) {
          InsulationLevel.none => t.insNone,
          InsulationLevel.thin => t.insThin,
          InsulationLevel.medium => t.insMedium,
          InsulationLevel.thick => t.insThick,
          InsulationLevel.unknown => t.dontKnow,
        };
    // A renovated wall or roof is insulated: only how thick is left to choose.
    List<InsulationLevel> levels(Renovation part) => [
          for (final v in InsulationLevel.values)
            if (v != InsulationLevel.none || !a.renovations.contains(part)) v,
        ];
    return _StepPage(
      nav: nav,
      title: t.insTitle,
      note: t.noteIns,
      canContinue: a.wallInsulation != null && a.roofInsulation != null && a.floorInsulation != null,
      children: [
        FieldLabel(t.insWalls),
        ChoiceChips<InsulationLevel>(
          values: levels(Renovation.walls),
          label: level,
          selected: a.wallInsulation,
          onSelect: (v) => a.update((x) => x.wallInsulation = v),
        ),
        _gap,
        FieldLabel(t.insRoof),
        ChoiceChips<InsulationLevel>(
          values: levels(Renovation.roof),
          label: level,
          selected: a.roofInsulation,
          onSelect: (v) => a.update((x) => x.roofInsulation = v),
        ),
        _gap,
        FieldLabel(t.insFloor),
        ChoiceChips<FloorInsulation>(
          values: FloorInsulation.values,
          label: (v) => switch (v) {
            FloorInsulation.none => t.insNone,
            FloorInsulation.insulated => t.insInsulated,
            FloorInsulation.unknown => t.dontKnow,
          },
          selected: a.floorInsulation,
          onSelect: (v) => a.update((x) => x.floorInsulation = v),
        ),
        if (a.wallInsulation == InsulationLevel.unknown ||
            a.roofInsulation == InsulationLevel.unknown ||
            a.floorInsulation == FloorInsulation.unknown)
          _Unsure('${t.unsureLead} ${t.tipIns}'),
        const SizedBox(height: 16),
        _HelpCheck(tips: [t.insHelpWalls, t.insHelpRoof, t.insHelpFloor]),
      ],
    );
  }
}

class _WindowsStep extends StatelessWidget {
  const _WindowsStep({required this.answers, required this.nav});

  final HomeAnswers answers;
  final _Nav nav;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final a = answers;
    return _StepPage(
      nav: nav,
      title: t.winTitle,
      note: t.noteWin,
      canContinue: a.windows != null,
      children: [
        _Options<WindowKind>(
          values: WindowKind.values,
          title: (v) => switch (v) {
            WindowKind.single => t.winSingle,
            WindowKind.doubleOld => t.winDoubleOld,
            WindowKind.doubleNew => t.winDoubleNew,
            WindowKind.triple => t.winTriple,
            WindowKind.mix => t.winMix,
            WindowKind.unknown => t.dontKnow,
          },
          selected: a.windows,
          onSelect: (v) => a.update((x) => x.windows = v),
        ),
        if (a.windows == WindowKind.unknown) _Unsure('${t.unsureLead} ${t.tipWin}'),
        const SizedBox(height: 12),
        _HelpCheck(tips: [t.winHelpPanes, t.winHelpDate]),
      ],
    );
  }
}

// ---------------------------------------------------------------- 5–6: energy today

class _SourcesStep extends StatelessWidget {
  const _SourcesStep({required this.answers, required this.nav});

  final HomeAnswers answers;
  final _Nav nav;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final a = answers;
    String label(Source s) => switch (s) {
          Source.mains => t.srcMains,
          Source.pipedGas => t.srcPipedGas,
          Source.district => t.srcDistrict,
          Source.gasBottles => t.srcBottles,
          Source.wood => t.srcWood,
          Source.generator => t.srcGenerator,
          Source.nothing => t.srcNothing,
        };
    return _StepPage(
      nav: nav,
      title: t.srcTitle,
      note: t.noteSrc,
      canContinue: a.sources.isNotEmpty,
      children: [
        MultiChips<Source>(values: Source.values, label: label, selected: a.sources, onToggle: a.toggleSource),
      ],
    );
  }
}

// ---------------------------------------------------------------- 7: use and cost

/// More than this in a month is unusual for a home: ask whether it is right.
const _highKwhMonth = 3000.0;

bool _twice(List<int> months) => months.toSet().length < months.length;

/// The three month rows: the month (a drop-down, or fixed text) and one or two number fields.
class _MonthRows extends StatelessWidget {
  const _MonthRows({required this.answers, required this.fields, this.monthsEditable = true});

  final HomeAnswers answers;

  /// The fields of each row, built for the row's index.
  final List<Widget> Function(int row) fields;
  final bool monthsEditable;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final p = context.palette;
    final names = _monthNames(t);
    final a = answers;
    String name(int m) => names.length == 12 ? names[m] : '${m + 1}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (monthsEditable)
                  SmallDropdown<int>(
                    value: a.months[i],
                    values: List.generate(12, (m) => m),
                    label: name,
                    onChanged: (m) => a.update((x) => x.months[i] = m),
                  )
                else
                  SizedBox(
                    width: 150,
                    child: Text(name(a.months[i]), style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: p.text)),
                  ),
                ...fields(i),
              ],
            ),
          ),
      ],
    );
  }
}

class _BillPhotoSoon extends StatelessWidget {
  const _BillPhotoSoon();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 14),
        child: _SoonAction(icon: Icons.receipt_long_outlined, label: context.t.billPhoto),
      );
}

class _ElectricityStep extends StatelessWidget {
  const _ElectricityStep({required this.answers, required this.nav});

  final HomeAnswers answers;
  final _Nav nav;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final p = context.palette;
    final a = answers;
    const unit = 'kWh';
    final values = a.useAverage ? [a.electricityAverageKwh] : a.electricityKwh;
    final high = values.any((v) => (v ?? 0) > _highKwhMonth);
    return _StepPage(
      nav: nav,
      title: t.elecUseTitle,
      note: t.noteElec,
      canContinue: a.useAverage ? a.electricityAverageKwh != null : a.electricityKwh.every((v) => v != null),
      children: [
        if (!a.useAverage) ...[
          _MonthRows(
            answers: a,
            fields: (i) => [
              NumberField(
                value: a.electricityKwh[i],
                suffix: unit,
                width: 190,
                onChanged: (v) => a.update((x) => x.electricityKwh[i] = v),
              ),
            ],
          ),
          if (_twice(a.months)) FieldWarning(t.sameMonthTwice),
          if (high) FieldWarning(t.tooHigh),
          const SizedBox(height: 8),
          LinkButton(label: t.dontKnowExact, onTap: () => a.update((x) => x.useAverage = true)),
        ] else ...[
          SubQuestion(t.avgElecQuestion),
          NumberField(
            value: a.electricityAverageKwh,
            suffix: unit,
            width: 190,
            onChanged: (v) => a.update((x) => x.electricityAverageKwh = v),
          ),
          if (high) FieldWarning(t.tooHigh),
          const SizedBox(height: 10),
          Text(t.avgNote, style: TextStyle(fontSize: 12.5, color: p.muted)),
          const SizedBox(height: 8),
          LinkButton(label: t.knowExact, onTap: () => a.update((x) => x.useAverage = false)),
        ],
        const _BillPhotoSoon(),
      ],
    );
  }
}

/// The currency of all the amounts: the country's by default, any other searchable.
class _CurrencyPicker extends StatelessWidget {
  const _CurrencyPicker({required this.answers, required this.countryCode});

  final HomeAnswers answers;
  final String? countryCode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(context.t.currencyLabel),
        DropdownMenu<String>(
          initialSelection: answers.currency ?? currencyOf(countryCode),
          width: 190,
          enableFilter: true,
          requestFocusOnTap: true,
          menuHeight: 320,
          dropdownMenuEntries: [for (final c in allCurrencies) DropdownMenuEntry(value: c, label: currencyLabel(c))],
          onSelected: (c) {
            if (c != null) answers.update((a) => a.currency = c);
          },
        ),
      ],
    );
  }
}

class _PaidStep extends StatelessWidget {
  const _PaidStep({required this.answers, required this.nav, required this.countryCode});

  final HomeAnswers answers;
  final _Nav nav;
  final String? countryCode;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final p = context.palette;
    final a = answers;
    final currency = a.currency ?? currencyOf(countryCode);
    return _StepPage(
      nav: nav,
      title: t.paidTitle,
      canContinue: a.useAverage ? a.paidAverage != null : a.paid.every((v) => v != null),
      children: [
        _CurrencyPicker(answers: a, countryCode: countryCode),
        _gap,
        if (!a.useAverage)
          _MonthRows(
            answers: a,
            monthsEditable: false,
            fields: (i) => [
              NumberField(value: a.paid[i], suffix: currency, width: 170, money: true, onChanged: (v) => a.update((x) => x.paid[i] = v)),
            ],
          )
        else ...[
          SubQuestion(t.avgPaidQuestion),
          NumberField(value: a.paidAverage, suffix: currency, width: 170, money: true, onChanged: (v) => a.update((x) => x.paidAverage = v)),
          const SizedBox(height: 10),
          Text(t.avgNote, style: TextStyle(fontSize: 12.5, color: p.muted)),
        ],
        const _BillPhotoSoon(),
      ],
    );
  }
}

/// Countries whose gas bills count cubic metres; elsewhere kWh.
const _gasInM3 = {'HU', 'UA', 'MD', 'RS', 'BA', 'MK', 'ME', 'RU', 'BY', 'GE', 'AM', 'AZ', 'KZ', 'UZ', 'KG', 'TR'};

class _GasStep extends StatefulWidget {
  const _GasStep({required this.answers, required this.nav, required this.countryCode});

  final HomeAnswers answers;
  final _Nav nav;
  final String? countryCode;

  @override
  State<_GasStep> createState() => _GasStepState();
}

class _GasStepState extends State<_GasStep> {
  @override
  void initState() {
    super.initState();
    // Nothing typed yet: start with the unit the country's bills use.
    final a = widget.answers;
    if (a.gasAmount.every((v) => v == null)) {
      final unit = _gasInM3.contains(widget.countryCode?.toUpperCase()) ? GasUnit.m3 : GasUnit.kwh;
      if (unit != a.gasUnit) WidgetsBinding.instance.addPostFrameCallback((_) => a.update((x) => x.gasUnit = unit));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final a = widget.answers;
    final currency = a.currency ?? currencyOf(widget.countryCode);
    final unit = a.gasUnit == GasUnit.m3 ? 'm³' : 'kWh';
    // About 10.5 kWh in a cubic metre: a number in the wrong unit is off about tenfold.
    final amounts = a.gasAmount.whereType<double>();
    final looksKwh = a.gasUnit == GasUnit.m3 && amounts.any((v) => v > 1200);
    final looksM3 = a.gasUnit == GasUnit.kwh && amounts.isNotEmpty && amounts.every((v) => v > 0 && v < 40);
    final high = a.gasUnit == GasUnit.m3 ? amounts.any((v) => v > 12000) : amounts.any((v) => v > 120000);
    return _StepPage(
      nav: widget.nav,
      title: t.gasTitle,
      note: t.noteGas,
      children: [
        _CurrencyPicker(answers: a, countryCode: widget.countryCode),
        _gap,
        FieldLabel(t.gasUnitLabel),
        ChoiceChips<GasUnit>(
          values: GasUnit.values,
          label: (v) => v == GasUnit.m3 ? 'm³' : 'kWh',
          selected: a.gasUnit,
          onSelect: (v) => a.update((x) => x.gasUnit = v),
        ),
        _gap,
        _MonthRows(
          answers: a,
          // The months can be changed here too (shared with the electricity questions).
          monthsEditable: true,
          fields: (i) => [
            NumberField(
              value: a.gasAmount[i],
              suffix: unit,
              width: 150,
              hint: t.gasUsed,
              onChanged: (v) => a.update((x) => x.gasAmount[i] = v),
            ),
            NumberField(
              value: a.gasPaid[i],
              suffix: currency,
              money: true,
              width: 150,
              hint: t.gasPaid,
              onChanged: (v) => a.update((x) => x.gasPaid[i] = v),
            ),
          ],
        ),
        if (looksKwh)
          FieldWarning(t.unitLooksKwh, action: t.yes, onAction: () => a.update((x) => x.gasUnit = GasUnit.kwh))
        else if (looksM3)
          FieldWarning(t.unitLooksM3, action: t.yes, onAction: () => a.update((x) => x.gasUnit = GasUnit.m3))
        else if (high)
          FieldWarning(t.tooHigh),
        const _BillPhotoSoon(),
      ],
    );
  }
}

class _FuelsStep extends StatefulWidget {
  const _FuelsStep({required this.answers, required this.nav, required this.countryCode});

  final HomeAnswers answers;
  final _Nav nav;
  final String? countryCode;

  @override
  State<_FuelsStep> createState() => _FuelsStepState();
}

class _FuelsStepState extends State<_FuelsStep> {
  /// "Continue" was pressed once with firewood data missing: the yellow notes show, and the next
  /// press goes on (docs/decisions/2026-11-12-firewood-and-missing-data.md in the backend).
  bool _warned = false;

  bool get _woodMissing {
    final a = widget.answers;
    if (!a.sources.contains(Source.wood)) return false;
    if (a.firewoodM3 == null) return true;
    return a.firewoodKind == null || a.firewoodPrice == null;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final a = widget.answers;
    final nav = widget.nav;
    final currency = a.currency ?? currencyOf(widget.countryCode);
    final wood = a.sources.contains(Source.wood);
    final hasWood = wood && (a.firewoodM3 ?? 0) > 0;
    final next = nav.onNext;
    final guarded = _Nav(
      index: nav.index,
      total: nav.total,
      onBack: nav.onBack,
      onFirst: nav.onFirst,
      onReset: nav.onReset,
      onNext: next == null
          ? null
          : () {
              if (!_warned && _woodMissing) {
                setState(() => _warned = true);
              } else {
                next();
              }
            },
    );
    Widget field(double? value, String? suffix, ValueChanged<double?> onChanged, {bool money = false}) =>
        NumberField(value: value, suffix: suffix, width: 200, money: money, onChanged: onChanged);
    Widget row(String question, double? value, String? suffix, ValueChanged<double?> onChanged, {bool money = false}) => Padding(
          padding: const EdgeInsets.only(bottom: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SubQuestion(question),
              field(value, suffix, onChanged, money: money),
            ],
          ),
        );
    return _StepPage(
      nav: guarded,
      title: t.fuelsTitle,
      note: t.noteFuels,
      hint: t.fuelsHint,
      children: [
        if (a.sources.contains(Source.district) || hasWood) ...[
          _CurrencyPicker(answers: a, countryCode: widget.countryCode),
          _gap,
        ],
        if (wood) ...[
          SubQuestion(t.fuelFirewood),
          field(a.firewoodM3, 'm³', (v) => a.update((x) => x.firewoodM3 = v)),
          const SizedBox(height: 6),
          Text(t.woodM3Note, style: TextStyle(fontSize: 13, color: context.palette.muted)),
          if (_warned && a.firewoodM3 == null) _Unsure('${t.unsureLead} ${t.unsureAmount}'),
          const SizedBox(height: 22),
          if (hasWood) ...[
            SubQuestion(t.woodKindQ),
            ChoiceChips<WoodKind>(
              values: WoodKind.values,
              label: (v) => switch (v) {
                WoodKind.hardwood => t.woodHard,
                WoodKind.softwood => t.woodSoft,
                WoodKind.mixed => t.woodMixed,
                WoodKind.unknown => t.dontKnow,
              },
              selected: a.firewoodKind,
              onSelect: (v) => a.update((x) => x.firewoodKind = v),
            ),
            if (a.firewoodKind == WoodKind.unknown || (_warned && a.firewoodKind == null))
              _Unsure('${t.unsureLead} ${t.unsureWood}'),
            const SizedBox(height: 22),
            SubQuestion(t.woodPriceQ),
            field(a.firewoodPrice, currency, (v) => a.update((x) => x.firewoodPrice = v), money: true),
            if (_warned && a.firewoodPrice == null) _Unsure('${t.unsureLead} ${t.unsurePrice}'),
            const SizedBox(height: 22),
          ],
          row(t.fuelPellets, a.pelletsTonnes, 't', (v) => a.update((x) => x.pelletsTonnes = v)),
        ],
        if (a.sources.contains(Source.gasBottles))
          row(t.fuelBottles, a.gasBottlesPerMonth, null, (v) => a.update((x) => x.gasBottlesPerMonth = v)),
        if (a.sources.contains(Source.district))
          row(t.fuelDistrict, a.districtPerMonth, currency, (v) => a.update((x) => x.districtPerMonth = v), money: true),
      ],
    );
  }
}

/// The soft yellow note after "Don't know" or an empty field: the result will be less precise.
class _Unsure extends StatelessWidget {
  const _Unsure(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF5B83D).withValues(alpha: 0.14),
          border: Border.all(color: const Color(0xFFF5B83D).withValues(alpha: 0.55)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(Icons.info_outline_rounded, size: 17, color: Color(0xFFD99A1E)),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: TextStyle(fontSize: 13.5, height: 1.35, color: p.text))),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- 8: free space

class _SpacesStep extends StatelessWidget {
  const _SpacesStep({required this.answers, required this.nav});

  final HomeAnswers answers;
  final _Nav nav;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final a = answers;
    return _StepPage(
      nav: nav,
      title: t.spacesTitle,
      note: t.noteSpaces,
      hint: t.spacesHint,
      canContinue: a.spaces.isNotEmpty,
      children: [
        MultiChips<Space>(
          values: Space.values,
          selected: a.spaces,
          label: (v) => switch (v) {
            Space.roof => t.spRoof,
            Space.garden => t.spGarden,
            Space.land => t.spLand,
            Space.balcony => t.spBalcony,
            Space.notSure => t.spNotSure,
            Space.nowhere => t.spNowhere,
          },
          icon: (v) => switch (v) {
            Space.roof => Icons.roofing_rounded,
            Space.garden => Icons.yard_outlined,
            Space.land => Icons.landscape_outlined,
            Space.balcony => Icons.balcony_outlined,
            Space.notSure => Icons.travel_explore_rounded,
            Space.nowhere => Icons.block_rounded,
          },
          onToggle: a.toggleSpace,
        ),
      ],
    );
  }
}

class _SizesStep extends StatelessWidget {
  const _SizesStep({required this.answers, required this.nav});

  final HomeAnswers answers;
  final _Nav nav;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final p = context.palette;
    final a = answers;
    final notSure = a.spaces.contains(Space.notSure);

    // Picking a size clears the exact area, and typing an area clears the size.
    Widget exact(Space s) => Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Wrap(
            spacing: 10,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(t.exactSize, style: TextStyle(fontSize: 13, color: p.muted)),
              NumberField(
                value: a.sizeOf(s).exactM2,
                suffix: 'm²',
                width: 130,
                onChanged: (v) => a.update((x) {
                  final size = x.sizeOf(s);
                  size.exactM2 = v;
                  if (v != null) size.size = null;
                }),
              ),
            ],
          ),
        );

    Widget sizes(Space s, List<AreaSize> values, String Function(AreaSize) label, {String? Function(AreaSize)? sublabel}) =>
        ChoiceChips<AreaSize>(
          values: values,
          label: label,
          sublabel: sublabel,
          selected: a.sizeOf(s).size,
          onSelect: (v) => a.update((x) {
            x.sizeOf(s)
              ..size = v
              ..exactM2 = null;
          }),
        );

    String land(AreaSize v) => switch (v) {
          AreaSize.small => t.landSmall,
          AreaSize.medium => t.landMedium,
          AreaSize.large => t.landLarge,
          AreaSize.none => t.noGarden,
        };

    const measured = [AreaSize.small, AreaSize.medium, AreaSize.large];

    // The garden also offers "I don't have a garden or yard" (asked when someone was not
    // sure where there is room); then there is nothing to measure.
    Widget landSection(Space s, String title, {bool canBeNone = false}) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SubQuestion(title),
            sizes(s, [...measured, if (canBeNone) AreaSize.none], land),
            if (a.sizeOf(s).size != AreaSize.none) ...[
              exact(s),
              const SizedBox(height: 10),
              _SoonAction(icon: Icons.draw_outlined, label: t.drawOnMap),
            ],
            _gap,
          ],
        );

    final roofPart = [
      if (a.spaces.contains(Space.roof) || notSure) ...[
        SubQuestion(t.sizeRoofLabel),
        sizes(
          Space.roof,
          measured,
          (v) => switch (v) {
            AreaSize.small => t.roofSmall,
            AreaSize.medium => t.roofMedium,
            AreaSize.large || AreaSize.none => t.roofLarge,
          },
          sublabel: (v) => t.aboutM2For(switch (v) {
            AreaSize.small => 30,
            AreaSize.medium => 60,
            AreaSize.large || AreaSize.none => 100,
          }),
        ),
        exact(Space.roof),
        const SizedBox(height: 18),
        FieldLabel(t.facingQuestion),
        ChoiceChips<Facing>(
          values: Facing.values,
          label: (v) => switch (v) {
            Facing.south => t.faceSouth,
            Facing.eastWest => t.faceEastWest,
            Facing.north => t.faceNorth,
            Facing.flat => t.faceFlat,
          },
          selected: a.facing,
          onSelect: (v) => a.update((x) => x.facing = v),
        ),
        _gap,
      ],
    ];
    final groundPart = [
      if (a.spaces.contains(Space.garden) || notSure) landSection(Space.garden, t.sizeGardenLabel, canBeNone: true),
      if (a.spaces.contains(Space.land)) landSection(Space.land, t.sizeLandLabel),
      if (a.spaces.contains(Space.balcony)) ...[
        SubQuestion(t.sizeBalconyLabel),
        sizes(Space.balcony, const [AreaSize.small, AreaSize.large], (v) => v == AreaSize.small ? t.balconySmall : t.balconyLarge),
      ],
    ];
    final note = [
      if (notSure) ...[
        Text(t.notSureNote, style: TextStyle(fontSize: 13.5, color: p.muted)),
        _gap,
      ],
    ];
    // Every place shown needs a size: one of the choices, or the exact area.
    final shown = [
      if (a.spaces.contains(Space.roof) || notSure) Space.roof,
      if (a.spaces.contains(Space.garden) || notSure) Space.garden,
      if (a.spaces.contains(Space.land)) Space.land,
      if (a.spaces.contains(Space.balcony)) Space.balcony,
    ];
    final complete = shown.every((s) => a.sizeOf(s).size != null || (a.sizeOf(s).exactM2 ?? 0) > 0) &&
        (!shown.contains(Space.roof) || a.facing != null);
    return _StepPage(
      nav: nav,
      title: t.sizesTitle,
      note: t.noteSizes,
      canContinue: complete,
      // Large screens: the roof on the left, the ground on the right.
      wide: roofPart.isNotEmpty && groundPart.isNotEmpty ? ([...note, ...roofPart], groundPart) : null,
      children: [...note, ...roofPart, ...groundPart],
    );
  }
}

// ---------------------------------------------------------------- 9–11: owner, upkeep, priority

class _OwnershipStep extends StatelessWidget {
  const _OwnershipStep({required this.answers, required this.nav});

  final HomeAnswers answers;
  final _Nav nav;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final a = answers;
    return _StepPage(
      nav: nav,
      title: t.ownTitle,
      note: t.noteOwn,
      canContinue: a.ownership != null,
      hint: t.ownHint,
      children: [
        _Options<Ownership>(
          values: Ownership.values,
          title: (v) => switch (v) {
            Ownership.own => t.ownYes,
            Ownership.building => t.ownBuilding,
            Ownership.rent => t.ownRent,
            Ownership.shared => t.ownShared,
          },
          selected: a.ownership,
          onSelect: (v) => a.update((x) => x.ownership = v),
        ),
      ],
    );
  }
}

class _UpkeepStep extends StatelessWidget {
  const _UpkeepStep({required this.answers, required this.nav});

  final HomeAnswers answers;
  final _Nav nav;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final a = answers;
    final fixer = _Options<Fixer>(
      values: Fixer.values,
      title: (v) => switch (v) {
        Fixer.self => t.fixSelf,
        Fixer.technician => t.fixTech,
        Fixer.installer => t.fixInstaller,
        Fixer.unknown => t.fixUnknown,
      },
      selected: a.fixer,
      onSelect: (v) => a.update((x) => x.fixer = v),
    );
    final hands = _Options<HandsOn>(
      values: HandsOn.values,
      title: (v) => switch (v) {
        HandsOn.none => t.handsNone,
        HandsOn.little => t.handsLittle,
        HandsOn.regular => t.handsRegular,
      },
      selected: a.handsOn,
      onSelect: (v) => a.update((x) => x.handsOn = v),
    );
    return _StepPage(
      nav: nav,
      title: t.fixTitle,
      note: t.noteUpkeep,
      canContinue: a.fixer != null && a.handsOn != null,
      hint: t.fixHint,
      wide: ([fixer], [SubQuestion(t.handsTitle), hands]),
      children: [
        fixer,
        const SizedBox(height: 30),
        SubQuestion(t.handsTitle),
        hands,
      ],
    );
  }
}

class _PriorityStep extends StatelessWidget {
  const _PriorityStep({required this.answers, required this.nav});

  final HomeAnswers answers;
  final _Nav nav;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final a = answers;
    return _StepPage(
      nav: nav,
      title: t.prioTitle,
      note: t.notePrio,
      canContinue: a.priority != null,
      children: [
        _Options<Priority>(
          values: Priority.values,
          title: (v) => switch (v) {
            Priority.upfront => t.prioUpfront,
            Priority.running => t.prioRunning,
            Priority.environment => t.prioEnv,
            Priority.balanced => t.prioBalanced,
          },
          detail: (v) => switch (v) {
            Priority.upfront => t.prioUpfrontDesc,
            Priority.running => t.prioRunningDesc,
            Priority.environment => t.prioEnvDesc,
            Priority.balanced => t.prioBalancedDesc,
          },
          selected: a.priority,
          onSelect: (v) => a.update((x) => x.priority = v),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- 12: follow-ups

class _FollowUpsStep extends StatelessWidget {
  const _FollowUpsStep({
    required this.answers,
    required this.nav,
    required this.facts,
    required this.animals,
    required this.river,
    required this.brook,
    required this.wind,
  });

  final HomeAnswers answers;
  final _Nav nav;
  final _PlaceFacts? facts;
  final bool animals;
  final bool river;
  final bool brook;
  final bool wind;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final p = context.palette;
    final a = answers;
    final loading = facts?.loading ?? false;
    final language = Localizations.localeOf(context).languageCode;
    final metres = math.max(10, ((facts?.riverKm ?? 0) * 100).round() * 10);
    // Every question shown here needs an answer ("None", "No" count), and the map
    // check has to finish first.
    final answered = !loading &&
        (!animals || a.animals != null) &&
        (!river || a.river != null) &&
        (!brook || a.brook != null) &&
        (!(wind && facts?.wind20 != null) || a.wind != null);
    return _StepPage(
      nav: nav,
      title: t.followTitle,
      note: t.noteFollow,
      canContinue: answered,
      children: [
        if (animals) ...[
          SubQuestion(t.animalsQ),
          _Options<Animals>(
            values: Animals.values,
            title: (v) => switch (v) {
              Animals.few => t.animFew,
              Animals.herd => t.animHerd,
              Animals.foodWaste => t.animWaste,
              Animals.none => t.animNone,
            },
            selected: a.animals,
            onSelect: (v) => a.update((x) => x.animals = v),
          ),
          _gap,
        ],
        if (loading)
          Row(
            children: [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: p.primary)),
              const SizedBox(width: 10),
              Text(t.checkingMap, style: TextStyle(fontSize: 13.5, color: p.muted)),
            ],
          )
        else ...[
          if (river) ...[
            _MapFound(text: t.riverFoundFor(metres)),
            const SizedBox(height: 8),
            _Options<RiverAccess>(
              values: RiverAccess.values,
              title: (v) => switch (v) {
                RiverAccess.through => t.riverThrough,
                RiverAccess.others => t.riverOthers,
                RiverAccess.cannot => t.riverCannot,
                RiverAccess.notSure => t.riverNotSure,
              },
              selected: a.river,
              onSelect: (v) => a.update((x) => x.river = v),
            ),
            if (a.river == RiverAccess.notSure) _Unsure('${t.unsureLead} ${t.tipRiver}'),
            _gap,
          ],
          if (brook) ...[
            SubQuestion(t.brookQ),
            ChoiceChips<bool>(
              values: const [true, false],
              label: (v) => v ? t.yes : t.no,
              selected: a.brook,
              onSelect: (v) => a.update((x) => x.brook = v),
            ),
            _gap,
          ],
          if (wind && facts?.wind20 != null) ...[
            _MapFound(text: t.windFoundFor(_decimal(facts!.wind20!, language))),
            const SizedBox(height: 8),
            _Options<WindExposure>(
              values: WindExposure.values,
              title: (v) => switch (v) {
                WindExposure.open => t.windOpen,
                WindExposure.some => t.windSome,
                WindExposure.lots => t.windLots,
              },
              selected: a.wind,
              onSelect: (v) => a.update((x) => x.wind = v),
            ),
          ],
          if (!animals && !river && !brook && !wind) Text(t.nothingMore, style: TextStyle(fontSize: 13.5, color: p.muted)),
        ],
      ],
    );
  }
}

/// "We found … on our map": the question starts from what the map shows.
class _MapFound extends StatelessWidget {
  const _MapFound({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(top: 2), child: Icon(Icons.map_outlined, size: 18, color: p.primary)),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: p.text, height: 1.35))),
      ],
    );
  }
}

// ---------------------------------------------------------------- 13: places to keep free

class _ExcludeStep extends StatefulWidget {
  const _ExcludeStep({required this.answers, required this.nav});

  final HomeAnswers answers;
  final _Nav nav;

  @override
  State<_ExcludeStep> createState() => _ExcludeStepState();
}

class _ExcludeStepState extends State<_ExcludeStep> {
  /// What a tap on the drawing or the list marks: a part to keep free, or one that is not there.
  bool _missingMode = false;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final p = context.palette;
    final a = widget.answers;
    final yard = a.hasYard;
    final missingMode = _missingMode && yard;
    void tap(Zone z) {
      if (yard || !groundZones.contains(z)) a.markZone(z, isMissing: missingMode);
    }

    final marking = a.excludeSomewhere ?? false;
    // Without a yard only the roof can be marked, and nothing can be "not there".
    final available = [...roofZones[a.roofDrawn]!, if (yard) ...groundZones];
    final kept = [for (final z in available) if (a.zones.contains(z)) z];
    final gone = [if (yard) for (final z in groundZones) if (a.missing.contains(z)) z];

    final choice = _Options<bool>(
      values: const [false, true],
      title: (v) => v ? t.exclYes : t.exclNo,
      selected: a.excludeSomewhere,
      onSelect: (v) => a.update((x) => x.excludeSomewhere = v),
    );
    final roof = [
      FieldLabel(t.roofShapeLabel),
      ChoiceChips<RoofShape>(
        values: RoofShape.values,
        label: (v) => switch (v) {
          RoofShape.gable => t.roofGable,
          RoofShape.hip => t.roofHip,
          RoofShape.flat => t.faceFlat,
        },
        selected: a.roofShape,
        onSelect: a.setRoofShape,
      ),
    ];
    final mode = [
      if (yard) ...[
      FieldLabel(t.markModeLabel),
      ChoiceChips<bool>(
        values: const [false, true],
        label: (v) => v ? t.markMissing : t.markKeepFree,
        selected: _missingMode,
        onSelect: (v) => setState(() => _missingMode = v),
      ),
      const SizedBox(height: 14),
      ],
    ];
    final drawing = [
      Text(t.exclTapHint, style: TextStyle(fontSize: 13.5, color: p.muted)),
      const SizedBox(height: 8),
      _House3D(shape: a.roofDrawn, selected: a.zones, missing: a.missing, onToggle: tap, yard: yard),
      const SizedBox(height: 8),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 1), child: Icon(Icons.info_outline_rounded, size: 16, color: p.muted)),
          const SizedBox(width: 6),
          Expanded(child: Text(yard ? t.exclSketchNote : t.exclSketchNoteHouse, style: TextStyle(fontSize: 12.5, color: p.muted))),
        ],
      ),
    ];
    Widget summary(String label, List<Zone> zones, Color color) => Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: '$label: ', style: TextStyle(fontWeight: FontWeight.w600, color: color)),
              TextSpan(text: zones.map((z) => _zoneLabel(t, z)).join(', '), style: TextStyle(color: p.text)),
            ]),
            style: const TextStyle(fontSize: 13),
          ),
        );
    final parts = [
      MultiChips<Zone>(
        values: missingMode ? groundZones : available,
        selected: missingMode ? a.missing : a.zones,
        label: (z) => _zoneLabel(t, z),
        onToggle: tap,
      ),
      if (kept.isNotEmpty) summary(t.keepFreeList, kept, p.error),
      if (gone.isNotEmpty) summary(t.missingList, gone, p.muted),
      const SizedBox(height: 10),
      _SoonAction(icon: Icons.edit_location_alt_outlined, label: t.markOnMap),
      // "Why?" is about the parts kept free; a part that is not there needs no reason.
      if (kept.isNotEmpty) ...[
        _gap,
        SubQuestion(t.whyLabel),
        MultiChips<ExcludeReason>(
          values: ExcludeReason.values,
          selected: a.reasons,
          label: (r) => switch (r) {
            ExcludeReason.unsafe => t.whyUnsafe,
            ExcludeReason.reach => t.whyReach,
            ExcludeReason.looks => t.whyLooks,
            ExcludeReason.rules => t.whyRules,
            ExcludeReason.plans => t.whyPlans,
          },
          onToggle: (r) => a.update((x) => x.reasons.contains(r) ? x.reasons.remove(r) : x.reasons.add(r)),
        ),
      ],
    ];
    return _StepPage(
      nav: widget.nav,
      title: t.exclTitle,
      canContinue: a.excludeSomewhere != null,
      // Large screens: the house on the left, the choices on the right.
      wide: marking ? ([...mode, ...drawing], [choice, _gap, ...roof, _gap, ...parts]) : null,
      children: [
        choice,
        if (marking) ...[
          _gap,
          ...roof,
          const SizedBox(height: 18),
          ...mode,
          ...drawing,
          const SizedBox(height: 12),
          ...parts,
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------- 14: something new

/// Something new at the place that the map does not show yet (a garage, a pool). The map of
/// the place shows through the middle of the page (see MapPeek), between the question at the
/// top and the buttons at the bottom: with "Yes", a tap on it marks where the new thing is,
/// and the questions about it follow in the bottom part.
class _NewThingStep extends StatefulWidget {
  const _NewThingStep({required this.answers, required this.nav});

  final HomeAnswers answers;
  final _Nav nav;

  @override
  State<_NewThingStep> createState() => _NewThingStepState();
}

class _NewThingStepState extends State<_NewThingStep> {
  /// A mark further than this from the place belongs to an earlier place: asked again.
  static const _markRangeM = 600.0;
  static const _fade = 36.0;

  /// From this width the question sits on the left and the map on the right.
  static const _sideBySide = 1000.0;

  final _first = GlobalKey();
  final _second = GlobalKey();

  /// "The road cannot be part of the area": shown for the change that moved the outline off
  /// a road, until the next change or for 4 seconds.
  int _noticeFor = 0;
  bool _noticeTimedOut = false;
  Timer? _noticeTimer;

  /// Puts the place in the middle of the map left free by the panels, and tells the map
  /// where the panels are (their clicks are the page's).
  void _measure() {
    if (!mounted) return;
    final page = context.findRenderObject();
    if (page is! RenderBox || !page.hasSize || page.size.isEmpty) return;
    final boxes = [
      for (final key in [_first, _second])
        if (key.currentContext?.findRenderObject() case final RenderBox box when box.hasSize) box,
    ];
    if (boxes.isEmpty) return;
    final rects = [for (final box in boxes) box.localToGlobal(Offset.zero, ancestor: page) & box.size];
    final size = page.size;
    final Rect free;
    if (size.width >= _sideBySide) {
      free = Rect.fromLTRB(rects.first.right + _fade, 0, size.width, size.height);
    } else {
      final top = rects.first.bottom + _fade;
      final bottom = rects.length > 1 ? rects[1].top - _fade : size.height;
      free = Rect.fromLTRB(0, top, size.width, math.max(top + 1, bottom));
    }
    final share = Offset(
      (free.center.dx / size.width).clamp(0.2, 0.85),
      (free.center.dy / size.height).clamp(0.25, 0.85),
    );
    if ((share - MapPeek.place.value).distance * size.shortestSide > 2) MapPeek.place.value = share;
    if (!listEquals(MapPeek.blockers.value, rects)) MapPeek.blockers.value = rects;
  }

  @override
  void dispose() {
    _noticeTimer?.cancel();
    MapPeek.blockers.value = const [];
    super.dispose();
  }

  /// Whether the notice about the road shows now (starts its 4 seconds on a new push).
  bool _roadNotice(HomeAnswers a) {
    if (a.roadPushAt == 0) return false;
    if (a.roadPushAt != _noticeFor) {
      _noticeFor = a.roadPushAt;
      _noticeTimedOut = false;
      _noticeTimer?.cancel();
      _noticeTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _noticeTimedOut = true);
      });
    }
    return !_noticeTimedOut && a.changes == a.roadPushAt;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final p = context.palette;
    final a = widget.answers;
    final nav = widget.nav;
    final place = a.place;
    final yes = a.newThing ?? false;
    final phone = MediaQuery.sizeOf(context).width < 700;

    final markLat = a.newLat, markLon = a.newLon;
    final marked = place != null &&
        markLat != null &&
        markLon != null &&
        _metres(place.lat, place.lon, markLat, markLon) <= _markRangeM;

    final question = <Widget>[
      _Progress(nav: nav),
      SizedBox(height: phone ? 12 : 18),
      PageTitle(t.newTitle),
      if (place != null) ...[
        const SizedBox(height: 6),
        Text(t.newMapNote, style: TextStyle(fontSize: 14, color: p.muted)),
      ],
      const SizedBox(height: 10),
      _NoteLine(t.noteNew),
      SizedBox(height: phone ? 12 : 18),
      _Options<bool>(
        values: const [false, true],
        title: (v) => v ? t.newYes : t.newNo,
        selected: a.newThing,
        onSelect: (v) => a.update((x) => x.newThing = v),
      ),
      if (yes) ...[
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(marked ? Icons.check_circle_rounded : Icons.touch_app_outlined, size: 18, color: p.primary),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(a.drawingNew ? t.newDrawHint : (marked ? t.newMarked : t.newWhereHint),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.text)),
            ),
          ],
        ),
      ],
      if (yes && marked) ...[
        const SizedBox(height: 18),
        FieldLabel(t.newKindQ),
        ChoiceChips<NewThingKind>(
          values: NewThingKind.values,
          label: (k) => switch (k) {
            NewThingKind.building => t.newBuilding,
            NewThingKind.pool => t.newPool,
            NewThingKind.trees => t.newTrees,
            NewThingKind.other => t.newOther,
          },
          selected: a.newKind,
          onSelect: (k) => a.update((x) {
            x.newKind = k;
            x.squareNew();
          }),
        ),
        if (a.newKind != null) ...[
          const SizedBox(height: 14),
          ..._newSize(context, a),
        ],
        if (a.asksNewUse) ...[
          const SizedBox(height: 14),
          SubQuestion(t.newUseQ),
          ChoiceChips<NewUse>(
            values: NewUse.values,
            label: (v) => switch (v) {
              NewUse.yes => t.yes,
              NewUse.no => t.newUseNo,
              NewUse.unsure => t.newUseUnsure,
            },
            selected: a.newUsable,
            onSelect: (v) => a.update((x) => x.newUsable = v),
          ),
        ],
      ],
    ];
    final buttons = _StepButtons(
      nav: nav,
      canContinue: a.newThing == false ||
          (yes &&
              marked &&
              !a.drawingNew &&
              a.newKind != null &&
              (!a.asksNewUse || a.newUsable != null) &&
              (a.newKind == NewThingKind.trees ? a.newTreeHeight != null : a.newSize != null || (a.newAreaM2 ?? 0) > 0)),
    );

    Widget panel(Key key, List<Widget> children, EdgeInsets padding, {double maxWidth = 680}) => DecoratedBox(
          key: key,
          decoration: BoxDecoration(gradient: p.stageGradient),
          child: SingleChildScrollView(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Padding(
                  padding: padding,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
                ),
              ),
            ),
          ),
        );
    Widget fade(Alignment from, {double? width, double? height}) => IgnorePointer(
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: from,
                end: -from,
                colors: [p.stageMiddle, p.stageMiddle.withValues(alpha: 0)],
              ),
            ),
          ),
        );
    final side = phone ? 18.0 : 28.0;

    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest;
      // Wherever the panels leave room, the page is empty: the map under it is moved,
      // zoomed and double-clicked directly.
      if (size.width >= _sideBySide) {
        // Laptop: the question (and everything about it) on the left, the map on the right.
        final width = math.min(600.0, size.width * 0.45);
        return Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: width,
              child: panel(_first, [...question, const SizedBox(height: 28), buttons],
                  const EdgeInsets.fromLTRB(40, 36, 32, 24)),
            ),
            Positioned(left: width, top: 0, bottom: 0, child: fade(Alignment.centerLeft, width: _fade)),
          ],
        );
      }
      // Phone and narrow windows: the question on top, the buttons at the bottom, the map
      // between them.
      return Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: size.height * 0.48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Flexible(child: panel(_first, question, EdgeInsets.fromLTRB(side, phone ? 14 : 28, side, 6))),
                  fade(Alignment.topCenter, height: _fade),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                fade(Alignment.bottomCenter, height: _fade),
                panel(_second, [buttons], EdgeInsets.fromLTRB(side, 2, side, phone ? 8 : 14)),
              ],
            ),
          ),
        ],
      );
    });
  }

  /// How big the new thing is: a size by comparison or in m², or drawn round on the map;
  /// for trees, how tall they are.
  List<Widget> _newSize(BuildContext context, HomeAnswers a) {
    final t = context.t;
    final p = context.palette;
    final kind = a.newKind!;
    final typical = HomeAnswers.typicalNewM2(kind);
    const sizes = [AreaSize.small, AreaSize.medium, AreaSize.large];
    final drawnArea = a.newOutlineDrawn && a.newOutline.length >= 3 ? a.newAreaM2 : null;
    return [
      if (kind == NewThingKind.trees) ...[
        FieldLabel(t.newTreeQ),
        ChoiceChips<TreeHeight>(
          values: TreeHeight.values,
          label: (h) => switch (h) {
            TreeHeight.low => t.treeLow,
            TreeHeight.medium => t.treeMedium,
            TreeHeight.tall => t.treeTall,
          },
          selected: a.newTreeHeight,
          onSelect: (h) => a.update((x) => x.newTreeHeight = h),
        ),
      ] else ...[
        FieldLabel(t.newSizeQ),
        ChoiceChips<AreaSize>(
          values: sizes,
          label: (v) => switch (v) {
            AreaSize.small => t.newSizeSmall,
            AreaSize.medium => t.newSizeMedium,
            _ => t.newSizeLarge,
          },
          sublabel: (v) => t.aboutM2For(typical[sizes.indexOf(v)]),
          selected: a.newSize,
          onSelect: (v) => a.update((x) => x.setNewSize(v)),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(t.exactSize, style: TextStyle(fontSize: 13, color: p.muted)),
            NumberField(
              // A drawn area shows below, not here.
              value: drawnArea == null ? a.newAreaM2 : null,
              suffix: 'm²',
              width: 130,
              onChanged: (v) => a.update((x) => x.setNewArea(v)),
            ),
          ],
        ),
      ],
      const SizedBox(height: 12),
      // Or drawn on the map: press and drag from one corner to the opposite one, as often as
      // needed; "Done" keeps it.
      Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (!a.drawingNew)
            OutlinedButton.icon(
              onPressed: () => a.update((x) => x.startDrawing()),
              icon: const Icon(Icons.crop_square_rounded, size: 18),
              label: Text(t.newDraw),
            )
          else ...[
            FilledButton.icon(
              onPressed: a.newOutlineDrawn ? () => a.update((x) => x.endDrawing(keep: true)) : null,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text(t.newDrawDone),
            ),
            TextButton(
              onPressed: () => a.update((x) => x.endDrawing(keep: false)),
              style: TextButton.styleFrom(foregroundColor: p.muted),
              child: Text(t.cancel),
            ),
          ],
        ],
      ),
      if (drawnArea != null) ...[
        const SizedBox(height: 8),
        Text(t.newDrawAreaFor(drawnArea.round()),
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: p.text)),
      ],
      AnimatedSize(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.topCenter,
        child: !_roadNotice(a)
            ? const SizedBox(width: double.infinity)
            : Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: p.errorBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.add_road_rounded, size: 18, color: p.error),
                    const SizedBox(width: 8),
                    Expanded(child: Text(t.newRoadPushed, style: TextStyle(fontSize: 13, color: p.text))),
                  ],
                ),
              ),
      ),
      // Turning the outline (drawn or the square of the size), for one that stands askew.
      if (a.newOutline.length >= 3) ...[
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.rotate_right_rounded, size: 18, color: p.muted),
            const SizedBox(width: 6),
            Text('${t.newRotate}: ${a.newRotation.round()}°', style: TextStyle(fontSize: 13.5, color: p.text)),
          ],
        ),
        Slider(
          value: a.newRotation.clamp(-90, 90),
          min: -90,
          max: 90,
          divisions: 36,
          label: '${a.newRotation.round()}°',
          onChanged: (v) => a.update((x) => x.setNewRotation(v)),
        ),
      ],
    ];
  }

  /// Rough distance between two points, m (fine for a few hundred metres).
  static double _metres(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final x = (lon2 - lon1) * math.pi / 180 * math.cos((lat1 + lat2) / 2 * math.pi / 180);
    final y = (lat2 - lat1) * math.pi / 180;
    return r * math.sqrt(x * x + y * y);
  }
}

String _zoneLabel(AppStrings t, Zone z) => switch (z) {
      Zone.roofFront => t.zoneRoofFront,
      Zone.roofBack => t.zoneRoofBack,
      Zone.roofLeft => t.zoneRoofLeft,
      Zone.roofRight => t.zoneRoofRight,
      Zone.roofWhole => t.zoneRoofWhole,
      Zone.frontYard => t.zoneFrontYard,
      Zone.backYard => t.zoneBackYard,
      Zone.sideLeft => t.zoneSideLeft,
      Zone.sideRight => t.zoneSideRight,
    };

/// A point of the 3D house: x along the street, y from the back (0) to the front (8),
/// z up. Metres, roughly: a 10 × 8 m house on its plot.
class _P3 {
  const _P3(this.x, this.y, [this.z = 0]);

  final double x;
  final double y;
  final double z;
}

/// One face of the drawing: its corners, the zone it marks (null for walls and the
/// street), and whether it lies on the ground.
class _Face {
  const _Face(this.points, {this.zone, this.ground = false, this.street = false});

  final List<_P3> points;
  final Zone? zone;
  final bool ground;
  final bool street;
}

const _wallH = 3.0;
const _ridgeH = 6.0;
const _centre = _P3(5, 4, _wallH / 2);

List<_Face> _houseFaces(RoofShape shape) {
  final eave = shape == RoofShape.flat ? _wallH + 0.3 : _wallH;
  _P3 p(double x, double y, [double z = 0]) => _P3(x, y, z);
  return [
    _Face([p(-4, 14), p(14, 14), p(14, 17), p(-4, 17)], ground: true, street: true),
    _Face([p(-4, 8), p(14, 8), p(14, 14), p(-4, 14)], zone: Zone.frontYard, ground: true),
    _Face([p(-4, -6), p(14, -6), p(14, 0), p(-4, 0)], zone: Zone.backYard, ground: true),
    _Face([p(-4, 0), p(0, 0), p(0, 8), p(-4, 8)], zone: Zone.sideLeft, ground: true),
    _Face([p(10, 0), p(14, 0), p(14, 8), p(10, 8)], zone: Zone.sideRight, ground: true),
    // Walls.
    _Face([p(0, 8), p(10, 8), p(10, 8, eave), p(0, 8, eave)]),
    _Face([p(0, 0), p(10, 0), p(10, 0, eave), p(0, 0, eave)]),
    _Face([p(0, 0), p(0, 8), p(0, 8, eave), p(0, 0, eave)]),
    _Face([p(10, 0), p(10, 8), p(10, 8, eave), p(10, 0, eave)]),
    ...switch (shape) {
      RoofShape.gable => [
          _Face([p(0, 0, _wallH), p(0, 8, _wallH), p(0, 4, _ridgeH)]),
          _Face([p(10, 0, _wallH), p(10, 8, _wallH), p(10, 4, _ridgeH)]),
          _Face([p(0, 8, _wallH), p(10, 8, _wallH), p(10, 4, _ridgeH), p(0, 4, _ridgeH)], zone: Zone.roofFront),
          _Face([p(0, 0, _wallH), p(10, 0, _wallH), p(10, 4, _ridgeH), p(0, 4, _ridgeH)], zone: Zone.roofBack),
        ],
      RoofShape.hip => [
          _Face([p(0, 8, _wallH), p(10, 8, _wallH), p(6.5, 4, _ridgeH), p(3.5, 4, _ridgeH)], zone: Zone.roofFront),
          _Face([p(0, 0, _wallH), p(10, 0, _wallH), p(6.5, 4, _ridgeH), p(3.5, 4, _ridgeH)], zone: Zone.roofBack),
          _Face([p(0, 0, _wallH), p(0, 8, _wallH), p(3.5, 4, _ridgeH)], zone: Zone.roofLeft),
          _Face([p(10, 0, _wallH), p(10, 8, _wallH), p(6.5, 4, _ridgeH)], zone: Zone.roofRight),
        ],
      RoofShape.flat => [
          _Face([p(0, 0, eave), p(10, 0, eave), p(10, 8, eave), p(0, 8, eave)], zone: Zone.roofWhole),
        ],
    },
  ];
}

/// The house turned by [quarter] quarter turns around its middle, then drawn in isometric
/// view: faces turned away from the viewer are left out, so no depth sorting is needed.
class _Projection {
  _Projection(this.size, this.quarter) : scale = size.width / 36;

  final Size size;
  final int quarter;
  final double scale;

  _P3 turn(_P3 p) {
    final a = quarter * math.pi / 2;
    final x = p.x - _centre.x;
    final y = p.y - _centre.y;
    return _P3(x * math.cos(a) - y * math.sin(a), x * math.sin(a) + y * math.cos(a), p.z);
  }

  Offset project(_P3 p) {
    final r = turn(p);
    return Offset(size.width / 2 + (r.x - r.y) * 0.866 * scale, size.height * 0.56 + (r.x + r.y) * 0.5 * scale - r.z * scale);
  }

  Path path(_Face f) => Path()..addPolygon([for (final p in f.points) project(p)], true);

  /// Whether the face points towards the viewer (up, and towards +x +y after turning).
  bool facesViewer(_Face f) {
    if (f.ground) return true;
    final r = [for (final p in f.points) turn(p)];
    final u = [r[1].x - r[0].x, r[1].y - r[0].y, r[1].z - r[0].z];
    final v = [r[2].x - r[0].x, r[2].y - r[0].y, r[2].z - r[0].z];
    var n = [u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0]];
    final c = [
      r.map((p) => p.x).reduce((a, b) => a + b) / r.length,
      r.map((p) => p.y).reduce((a, b) => a + b) / r.length,
      r.map((p) => p.z).reduce((a, b) => a + b) / r.length - _centre.z,
    ];
    // Point the normal outwards, away from the middle of the house.
    if (n[0] * c[0] + n[1] * c[1] + n[2] * c[2] < 0) n = [-n[0], -n[1], -n[2]];
    return n[0] + n[1] + n[2] > 1e-6;
  }

  /// The faces in drawing order: the ground first, then the walls, then the roof.
  List<_Face> visible(List<_Face> faces) => [
        ...faces.where((f) => f.ground),
        ...faces.where((f) => !f.ground && f.zone == null && facesViewer(f)),
        ...faces.where((f) => !f.ground && f.zone != null && facesViewer(f)),
      ];
}

/// The house and its plot in 3D: the roof's sides and the parts of the yard can be tapped
/// to keep them free, and the arrows turn the house to reach the sides behind it.
class _House3D extends StatefulWidget {
  const _House3D({
    required this.shape,
    required this.selected,
    required this.missing,
    required this.onToggle,
    this.yard = true,
  });

  final RoofShape shape;
  final Set<Zone> selected;
  final Set<Zone> missing;
  final ValueChanged<Zone> onToggle;

  /// False when the place has no yard: only the house and the street are drawn.
  final bool yard;

  @override
  State<_House3D> createState() => _House3DState();
}

class _House3DState extends State<_House3D> {
  int _quarter = 0;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final p = context.palette;
    final faces = [
      for (final f in _houseFaces(widget.shape))
        if (widget.yard || !groundZones.contains(f.zone)) f,
    ];
    return LayoutBuilder(
      builder: (context, box) {
        final width = math.min(box.maxWidth, 440.0);
        final size = Size(width, width * 0.78);
        final projection = _Projection(size, _quarter);
        final shown = projection.visible(faces);
        final hidden = faces.any((f) => f.zone != null && !f.ground && !projection.facesViewer(f));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: SizedBox(
                width: width,
                child: Stack(
                  children: [
                    GestureDetector(
                      onTapUp: (d) {
                        // The top-most face under the finger: roof before walls before ground.
                        for (final f in shown.reversed) {
                          if (projection.path(f).contains(d.localPosition)) {
                            if (f.zone != null) widget.onToggle(f.zone!);
                            return;
                          }
                        }
                      },
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: CustomPaint(
                          size: size,
                          painter: _HousePainter(
                            projection: projection,
                            faces: shown,
                            selected: {...widget.selected},
                            missing: {...widget.missing},
                            street: t.dirFront,
                            labels: {
                              Zone.frontYard: t.zoneFrontYard,
                              Zone.backYard: t.zoneBackYard,
                            },
                            ground: p.green.withValues(alpha: 0.16),
                            streetFill: p.muted.withValues(alpha: 0.22),
                            wall: Color.alphaBlend(p.text.withValues(alpha: 0.06), p.surface),
                            roof: Color.alphaBlend(p.primary.withValues(alpha: 0.28), p.surface),
                            mark: p.error.withValues(alpha: 0.45),
                            line: p.text.withValues(alpha: 0.45),
                            text: p.muted,
                          ),
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      top: 0,
                      end: 0,
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: t.rotateLeft,
                            onPressed: () => setState(() => _quarter = (_quarter + 3) % 4),
                            icon: const Icon(Icons.rotate_left_rounded),
                          ),
                          IconButton(
                            tooltip: t.rotateRight,
                            onPressed: () => setState(() => _quarter = (_quarter + 1) % 4),
                            icon: const Icon(Icons.rotate_right_rounded),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (hidden)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(padding: const EdgeInsets.only(top: 1), child: Icon(Icons.threesixty_rounded, size: 16, color: p.primary)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(t.roofHidden, style: TextStyle(fontSize: 12.5, color: p.text))),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _HousePainter extends CustomPainter {
  _HousePainter({
    required this.projection,
    required this.faces,
    required this.selected,
    required this.missing,
    required this.street,
    required this.labels,
    required this.ground,
    required this.streetFill,
    required this.wall,
    required this.roof,
    required this.mark,
    required this.line,
    required this.text,
  });

  final _Projection projection;
  final List<_Face> faces;
  final Set<Zone> selected;
  final Set<Zone> missing;
  final String street;
  final Map<Zone, String> labels;
  final Color ground;
  final Color streetFill;
  final Color wall;
  final Color roof;
  final Color mark;
  final Color line;
  final Color text;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 1
      ..color = line;
    for (final f in faces) {
      final base = f.street
          ? streetFill
          : f.ground
              ? ground
              : f.zone == null
                  ? wall
                  : roof;
      final fill = f.zone != null && selected.contains(f.zone) ? Color.alphaBlend(mark, base) : base;
      final path = projection.path(f);
      final gone = f.zone != null && missing.contains(f.zone);
      canvas.drawPath(path, Paint()..color = gone ? line.withValues(alpha: 0.08) : fill);
      if (gone) {
        // A part that is not there: grey, crossed with thin lines.
        canvas.save();
        canvas.clipPath(path);
        final b = path.getBounds();
        final hatch = Paint()
          ..strokeWidth = 1
          ..color = line.withValues(alpha: 0.35);
        for (var x = b.left - b.height; x < b.right; x += 8) {
          canvas.drawLine(Offset(x, b.bottom), Offset(x + b.height, b.top), hatch);
        }
        canvas.restore();
      }
      canvas.drawPath(path, stroke..color = f.ground ? line.withValues(alpha: 0.25) : line);

      final name = f.street ? street : labels[f.zone];
      if (name != null) {
        final c = Offset(
          f.points.map((p) => projection.project(p).dx).reduce((a, b) => a + b) / f.points.length,
          f.points.map((p) => projection.project(p).dy).reduce((a, b) => a + b) / f.points.length,
        );
        final tp = TextPainter(
          text: TextSpan(text: name, style: TextStyle(fontSize: 10.5, color: text, fontWeight: FontWeight.w600)),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        )..layout(maxWidth: size.width / 3);
        tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(_HousePainter old) => true;
}
