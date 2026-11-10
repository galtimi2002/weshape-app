import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/i18n/countries.dart';
import '../../core/models/user_profile.dart';
import '../../core/theme/weshape_palette.dart';
import '../../core/widgets/language_menu.dart';
import '../../core/widgets/theme_switch.dart';
import '../../core/widgets/weshape_logo.dart';
import '../profile/profile_controller.dart';
import '../assessment/assessment_flow.dart';
import '../assessment/home_answers.dart';
import '../assessment/saved_assessments_page.dart';
import 'map/resource_map.dart';
import 'nav_tabs.dart';

/// The signed-in home: the header with the three tabs (map, assessment, saved
/// assessments) and under it the resource map. The other two are full pages that slide
/// in over the map; the map stays alive underneath, so it keeps its place and selection.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomeTab _tab = HomeTab.map;

  /// The home assessment's answers live here, so they survive switching tabs.
  final _answers = HomeAnswers();

  /// The open tab is kept on the device, so a page refresh stays on the assessment (at the
  /// same question) or on the saved assessments, instead of jumping back to the map.
  static const _tabKey = 'home.tab';

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    // Someone who left to find a bill continues where they stopped.
    await _answers.restore();
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_tabKey);
      final tab = HomeTab.values.where((t) => t.name == name).firstOrNull;
      if (tab != null && mounted) setState(() => _tab = tab);
    } catch (_) {
      // Storage can be off (private window): start on the map.
    }
  }

  Future<void> _saveTab(HomeTab tab) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tabKey, tab.name);
    } catch (_) {
      // Not kept: a refresh opens the map.
    }
  }

  @override
  void dispose() {
    _answers.dispose();
    super.dispose();
  }

  /// The assessment's place step sent the person to the map to click a point.
  bool _picking = false;

  void _go(HomeTab tab) {
    if (tab != _tab || _picking) {
      setState(() {
        _tab = tab;
        _picking = false;
      });
      _saveTab(tab);
    }
  }

  /// "Assess this place" on the map card: the place becomes the assessment's, and the
  /// assessment opens at the place step so the person sees it and continues from there.
  void _assess(AssessmentPlace place) {
    _answers.update((a) {
      a.place = place;
      if (a.screen == 'audience') a.screen = 'place';
    });
    _go(HomeTab.assessment);
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>().profile!;
    final width = MediaQuery.sizeOf(context).width;
    final phone = width < 700;
    // The tabs go in the header when they fit next to the language, theme and log-out
    // controls; otherwise they get a strip of their own under it.
    final inHeader = !phone && width >= HeaderTabs.widthFor(context) + 640;

    final Widget page = switch (_tab) {
      HomeTab.map => const SizedBox.shrink(key: ValueKey('map')),
      HomeTab.assessment => AssessmentFlow(
          key: const ValueKey('assessment'),
          answers: _answers,
          countryCode: profile.country,
          // While picking on the map, a refresh still comes back to the assessment.
          onPickOnMap: () => setState(() {
            _tab = HomeTab.map;
            _picking = true;
          }),
        ),
      HomeTab.saved => SavedAssessmentsPage(key: const ValueKey('saved'), onNew: () => _go(HomeTab.assessment)),
    };

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              profile: profile,
              phone: phone,
              tabs: inHeader ? HeaderTabs(current: _tab, onSelect: _go) : null,
            ),
            if (!inHeader)
              Container(
                color: context.palette.surface,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                alignment: Alignment.center,
                child: StripTabs(current: _tab, onSelect: _go),
              ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ListenableBuilder(
                      listenable: _answers,
                      builder: (context, _) => ResourceMap(
                        countryCode: profile.country,
                        active: _tab == HomeTab.map,
                        onAssess: _assess,
                        picking: _picking,
                        onCancelPick: () => _go(HomeTab.assessment),
                        // The question about something new shows the map under its page.
                        peek: _tab == HomeTab.assessment && _answers.screen == 'newThing' ? _answers.place : null,
                        peekMark: _answers.newThing == true && _answers.newLat != null && _answers.newLon != null
                            ? (_answers.newLat!, _answers.newLon!)
                            : null,
                        peekShape: _answers.newThing == true ? _answers.newOutlineGeoJson : null,
                        peekDrawing: _answers.newThing == true && _answers.drawingNew,
                        // A double click marks where the new thing is, once the answer is "yes".
                        onPeekMark: (lat, lon) {
                          if (_answers.newThing != true || _answers.drawingNew) return;
                          _answers.update((x) {
                            x.newLat = lat;
                            x.newLon = lon;
                            x.squareNew();
                          });
                        },
                        // Its outline, drawn as a rectangle by dragging.
                        onPeekDrawn: (corners) => _answers.update((x) => x.setNewOutline(corners)),
                        onPeekRoads: (roads) => _answers.update((x) => x.setRoads(roads)),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 450),
                      reverseDuration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween(begin: const Offset(0, 0.025), end: Offset.zero).animate(animation),
                          child: child,
                        ),
                      ),
                      layoutBuilder: (current, previous) => Stack(
                        fit: StackFit.expand,
                        children: [...previous, if (current != null) current],
                      ),
                      child: page,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile, required this.phone, this.tabs});

  final UserProfile profile;
  final bool phone;

  /// The tabs, when they fit in the header (left of the language menu).
  final Widget? tabs;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.t;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: phone ? 12 : 20, vertical: 10),
      color: p.surface,
      child: Row(
        children: [
          if (phone) const WeShapeMark(size: 36) else const WeShapeLogo(height: 40, withSlogan: false),
          const Spacer(),
          if (tabs != null) ...[tabs!, const SizedBox(width: 26)],
          LanguageMenu(style: phone ? LanguageMenuStyle.flagOnly : LanguageMenuStyle.compact),
          const SizedBox(width: 8),
          const ThemeSwitch(),
          const SizedBox(width: 8),
          if (phone)
            IconButton(
              tooltip: t.signOut,
              onPressed: () => context.read<AuthController>().signOut(),
              icon: Icon(Icons.logout_rounded, size: 20, color: p.text),
            )
          else
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 34), padding: const EdgeInsets.symmetric(horizontal: 12)),
              onPressed: () => context.read<AuthController>().signOut(),
              icon: const Icon(Icons.logout_rounded, size: 16),
              label: Text(t.signOut, style: const TextStyle(fontSize: 13)),
            ),
          const SizedBox(width: 10),
          _AccountButton(profile: profile),
        ],
      ),
    );
  }
}

/// Initials with a green "online" dot; opens a card with the person's details.
class _AccountButton extends StatelessWidget {
  const _AccountButton({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Tooltip(
      message: profile.displayName,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => showDialog<void>(context: context, builder: (_) => _AccountDialog(profile: profile)),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: p.primaryGradient),
                alignment: Alignment.center,
                child: Text(
                  profile.initials,
                  style: TextStyle(color: p.onPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: p.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: p.surface, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountDialog extends StatelessWidget {
  const _AccountDialog({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.t;
    final language = Localizations.localeOf(context).languageCode;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(profile.displayName, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: p.text)),
              const SizedBox(height: 2),
              Text(profile.email, style: TextStyle(fontSize: 13, color: p.muted)),
              if (profile.country != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${Country(profile.country!, '').flag}  ${Countries.nameOf(profile.country!, language)}',
                  style: TextStyle(fontSize: 14, color: p.text),
                ),
              ],
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () {
                  final auth = context.read<AuthController>();
                  Navigator.of(context).pop();
                  auth.signOut();
                },
                icon: const Icon(Icons.logout_rounded, size: 16),
                label: Text(t.signOut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
