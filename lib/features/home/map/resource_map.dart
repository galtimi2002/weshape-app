import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/countries.dart';
import '../../../core/models/solar.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/weshape_palette.dart';
import '../../../core/theme/weshape_theme.dart';
import 'country_bounds.dart';
import 'geocoder.dart';
import 'map_bridge.dart';

/// The home screen's map: the person's country first, then any address or
/// any point they click, with the solar resource there.
///
/// Only solar works for now; the other resources are shown as coming soon.
class ResourceMap extends StatefulWidget {
  const ResourceMap({super.key, required this.countryCode});

  /// From the profile; the map opens on this country.
  final String? countryCode;

  @override
  State<ResourceMap> createState() => _ResourceMapState();
}

/// What the card shows: a place, and its values once they arrive.
class _Selection {
  const _Selection({required this.lat, required this.lon, this.title, this.detail, this.point, this.error});

  final double lat;
  final double lon;
  final String? title;
  final String? detail;
  final SolarPoint? point;
  final String? error;

  _Selection copyWith({String? title, String? detail, SolarPoint? point, String? error}) => _Selection(
        lat: lat,
        lon: lon,
        title: title ?? this.title,
        detail: detail ?? this.detail,
        point: point ?? this.point,
        error: error ?? this.error,
      );
}

// Below this the desktop dock no longer fits beside the zoom buttons.
const double _phoneWidth = 900;
const double _overlayOpacity = 0.66;

class _ResourceMapState extends State<ResourceMap> {
  final MapBridge _map = MapBridge();
  final Geocoder _geocoder = Geocoder();
  late final ApiClient _api = context.read<ApiClient>();

  SolarLayers _layers = SolarLayers.fallback;
  SolarLayerId _layer = SolarLayerId.pvout;
  List<double> _country = CountryBounds.europe;
  _Selection? _selection;
  Widget? _mapView;
  StreamSubscription<MapPoint>? _clicks;
  int _request = 0;
  bool _phone = false;

  bool? _dark;
  String? _language;
  bool _interactive = true;

  String? _toast;
  Timer? _toastTimer;

  // Flutter controls over the map; their areas are kept off the map (see _syncBlockers).
  final _stackKey = GlobalKey();
  final _searchKey = GlobalKey();
  final _cardKey = GlobalKey();
  final _zoomKey = GlobalKey();
  final _dockKey = GlobalKey();
  Timer? _blockerTimer;
  List<Rect> _blockers = const [];
  double _attributionLift = 0;

  @override
  void initState() {
    super.initState();
    _country = CountryBounds.of(widget.countryCode) ?? CountryBounds.europe;
    _clicks = _map.clicks.listen((p) => _select(p.lat, p.lon));
    _showOverlay();
    _loadLayers();
    _lookUpCountryIfUnknown();
    // Controls change size on their own (suggestions open, the card animates in),
    // so their areas are re-measured a few times a second.
    _blockerTimer = Timer.periodic(const Duration(milliseconds: 250), (_) => _syncBlockers());
  }

  void _syncBlockers() {
    final stack = _stackKey.currentContext?.findRenderObject();
    if (!mounted || stack is! RenderBox || !stack.hasSize) return;
    final rects = <Rect>[];
    for (final key in [_searchKey, _cardKey, _zoomKey, _dockKey]) {
      final box = key.currentContext?.findRenderObject();
      if (box is RenderBox && box.hasSize && box.attached) {
        final topLeft = box.localToGlobal(Offset.zero, ancestor: stack);
        rects.add(topLeft & box.size);
      }
    }
    // Keep the attribution line readable: above the dock when the dock reaches the left edge.
    final dock = _dockKey.currentContext?.findRenderObject();
    if (dock is RenderBox && dock.hasSize && dock.attached) {
      final dockRect = dock.localToGlobal(Offset.zero, ancestor: stack) & dock.size;
      final lift = dockRect.left < 460 ? stack.size.height - dockRect.top + 6 : 0.0;
      if ((lift - _attributionLift).abs() > 0.5) {
        _attributionLift = lift;
        _map.setAttributionBottom(lift);
      }
    }
    if (_sameRects(rects, _blockers)) return;
    _blockers = rects;
    _map.setBlockers(rects);
  }

  static bool _sameRects(List<Rect> a, List<Rect> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if ((a[i].left - b[i].left).abs() > 0.5 ||
          (a[i].top - b[i].top).abs() > 0.5 ||
          (a[i].width - b[i].width).abs() > 0.5 ||
          (a[i].height - b[i].height).abs() > 0.5) {
        return false;
      }
    }
    return true;
  }

  @override
  void dispose() {
    _clicks?.cancel();
    _toastTimer?.cancel();
    _blockerTimer?.cancel();
    _map.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (_dark != null && dark != _dark) _map.setDark(dark);
    _dark = dark;

    _language ??= context.read<SettingsController>().languageCode;

    // A menu or dialog above the map: clicks on it must not also land on the map.
    final interactive = ModalRoute.of(context)?.isCurrent ?? true;
    if (interactive != _interactive) {
      _interactive = interactive;
      _map.setInteractive(interactive);
    }
  }

  // ------------------------------------------------------------------ data

  Future<void> _loadLayers() async {
    try {
      final layers = await _api.solarLayers();
      if (!mounted) return;
      setState(() => _layers = layers);
      _showOverlay();
    } on ApiException {
      // The built-in description matches the backend; the pictures still load from it.
    }
  }

  String? _overlayUrl;

  void _showOverlay() {
    final url = _api.urlOf(_layers[_layer].imagePath);
    if (url == _overlayUrl) return;
    _overlayUrl = url;
    _map.setOverlay(url, _layers.bounds, _overlayOpacity);
  }

  Future<void> _lookUpCountryIfUnknown() async {
    final code = widget.countryCode;
    if (code == null || CountryBounds.of(code) != null) return;
    try {
      final bounds = await _geocoder.countryBounds(Countries.nameOf(code, 'en'));
      if (bounds == null || !mounted) return;
      _country = bounds;
      if (_selection == null) _map.fitBounds(bounds, _fitPadding(_phone));
    } catch (_) {
      // Europe stays in view.
    }
  }

  Future<void> _select(double lat, double lon, {Place? place}) async {
    final request = ++_request;
    final t = context.t;
    setState(() => _selection = _Selection(lat: lat, lon: lon, title: place?.title, detail: place?.detail));
    _map.setMarker(lat, lon, _layers[_layer].accent);
    if (place != null) {
      _map.flyTo(lat, lon, zoom: 12, offset: _phone ? const Offset(0, -110) : const Offset(-170, 0));
    } else {
      _geocoder.reverse(lat, lon, language: _language ?? 'en').then((found) {
        if (!mounted || request != _request) return;
        setState(() => _selection = _selection?.copyWith(
              title: found?.title ?? t.selectedPoint,
              detail: found?.detail ?? '',
            ));
      }, onError: (Object _) {
        if (!mounted || request != _request) return;
        setState(() => _selection = _selection?.copyWith(title: t.selectedPoint, detail: ''));
      });
    }
    try {
      final point = await _api.solarPoint(lat, lon);
      if (!mounted || request != _request) return;
      setState(() => _selection = _selection?.copyWith(point: point));
    } on ApiException catch (e) {
      if (!mounted || request != _request) return;
      setState(() => _selection = _selection?.copyWith(error: e.statusCode == 404 ? t.noSolarDataHere : e.message(t)));
    }
  }

  void _closeCard() {
    _request++;
    setState(() => _selection = null);
    _map.clearMarker();
    _map.fitBounds(_country, _fitPadding(_phone));
  }

  void _setLayer(SolarLayerId layer) {
    if (layer == _layer) return;
    setState(() => _layer = layer);
    _showOverlay();
    final s = _selection;
    if (s != null) _map.setMarker(s.lat, s.lon, _layers[layer].accent);
  }

  void _showToast(String message) {
    _toastTimer?.cancel();
    setState(() => _toast = message);
    _toastTimer = Timer(const Duration(milliseconds: 1900), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  static EdgeInsets _fitPadding(bool phone) => phone
      ? const EdgeInsets.fromLTRB(20, 110, 20, 190)
      : const EdgeInsets.fromLTRB(60, 120, 60, 140);

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final p = context.palette;
    final language = context.watch<SettingsController>().languageCode;
    if (language != _language) {
      _language = language;
      _map.setLanguage(language);
    }

    return LayoutBuilder(builder: (context, constraints) {
      final phone = constraints.maxWidth < _phoneWidth;
      _phone = phone;
      _mapView ??= _map.buildView(
        dark: _dark ?? false,
        language: language,
        bounds: _country,
        padding: _fitPadding(phone),
        // The wording PVGIS asks for in its usage conditions, linked to its home page.
        attribution: 'Solar data: <a href="https://joint-research-centre.ec.europa.eu/photovoltaic-geographical-information-system-pvgis_en" '
            'target="_blank" rel="noopener">PVGIS</a>, European Commission Joint Research Centre',
      );
      final info = _layers[_layer];
      final countryName = widget.countryCode == null ? null : Countries.nameOf(widget.countryCode!, language);
      final hint = _selection != null || countryName == null ? t.mapClickHint : t.mapCountryHintFor(countryName);

      WidgetsBinding.instance.addPostFrameCallback((_) => _syncBlockers());
      return Stack(
        key: _stackKey,
        // Fill the space given; without this the map would take the width of
        // its smallest unpositioned child, which is zero.
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: _mapView!),
          // Fades the map into the header so the search reads as part of it.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 150,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [p.surface, p.surface.withValues(alpha: 0.7), p.surface.withValues(alpha: 0)],
                    stops: const [0, 0.43, 1],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: ValueListenableBuilder<String?>(
            valueListenable: _map.loadError,
            builder: (context, error, _) => error == null
                ? const SizedBox.shrink()
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(t.mapLoadFailed, textAlign: TextAlign.center, style: TextStyle(color: p.muted)),
                    ),
                  ),
            ),
          ),
          Positioned(
            top: phone ? 6 : 8,
            left: phone ? 16 : 24,
            width: math.min(470.0, constraints.maxWidth - (phone ? 32 : 48)),
            child: KeyedSubtree(
              key: _searchKey,
              child: _SearchBox(
                geocoder: _geocoder,
                countryCode: widget.countryCode,
                near: CountryBounds.centerOf(_country),
                language: language,
                hint: hint,
                phone: phone,
                onPlace: (place) => _select(place.lat, place.lon, place: place),
                onNothingFound: () => _showToast(t.noPlaceFound),
              ),
            ),
          ),
          if (_selection != null)
            Positioned(
              right: phone ? 10 : 16,
              left: phone ? 10 : null,
              top: phone ? null : 70,
              bottom: phone ? 150 : null,
              width: phone ? null : 310,
              child: KeyedSubtree(
                key: _cardKey,
                child: _ResultCard(
                  key: ValueKey('${_selection!.lat},${_selection!.lon}'),
                  selection: _selection!,
                  layers: _layers,
                  layer: _layer,
                  phone: phone,
                  language: language,
                  onLayer: _setLayer,
                  onClose: _closeCard,
                ),
              ),
            ),
          Positioned(
            right: phone ? 10 : 16,
            bottom: phone ? null : 16,
            // On narrow screens the dock fills the bottom, so the buttons sit on the right side.
            top: phone ? constraints.maxHeight * 0.36 : null,
            child: KeyedSubtree(key: _zoomKey, child: _ZoomButtons(onIn: _map.zoomIn, onOut: _map.zoomOut)),
          ),
          Positioned(
            left: phone ? 10 : 0,
            right: phone ? 10 : 0,
            bottom: phone ? 10 : 16,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: KeyedSubtree(
                key: _dockKey,
                child: _Dock(
                  phone: phone,
                  layer: _layer,
                  info: info,
                  language: language,
                  onLayer: _setLayer,
                  onComingSoon: (name) => _showToast(t.comingSoonFor(name)),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: phone ? 160 : 130,
            child: IgnorePointer(
              child: Center(
                child: AnimatedOpacity(
                  opacity: _toast == null ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: p.text, borderRadius: BorderRadius.circular(8)),
                    child: Text(_toast ?? '', style: TextStyle(color: p.background, fontSize: 12.5)),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

// ==================================================================== search

class _SearchBox extends StatefulWidget {
  const _SearchBox({
    required this.geocoder,
    required this.countryCode,
    required this.near,
    required this.language,
    required this.hint,
    required this.phone,
    required this.onPlace,
    required this.onNothingFound,
  });

  final Geocoder geocoder;
  final String? countryCode;
  final (double, double) near;
  final String language;
  final String hint;
  final bool phone;
  final ValueChanged<Place> onPlace;
  final VoidCallback onNothingFound;

  @override
  State<_SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<_SearchBox> {
  final _controller = TextEditingController();
  late final _focus = FocusNode(onKeyEvent: _onKey);
  Timer? _debounce;
  List<Place> _results = const [];
  int _active = -1;
  int _query = 0;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) {
        // Let a click on a suggestion land first.
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && !_focus.hasFocus) setState(() => _open = false);
        });
      } else if (_results.isNotEmpty) {
        setState(() => _open = true);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    if (text.trim().length < 2) {
      setState(() {
        _results = const [];
        _open = false;
        _active = -1;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 250), () => _search(text));
  }

  Future<List<Place>> _search(String text) async {
    final query = ++_query;
    try {
      final results = await widget.geocoder.search(
        text,
        countryCode: widget.countryCode,
        near: widget.near,
        language: widget.language,
      );
      if (mounted && query == _query) {
        setState(() {
          _results = results;
          _active = -1;
          _open = results.isNotEmpty && _focus.hasFocus;
        });
      }
      return results;
    } catch (_) {
      return const [];
    }
  }

  void _choose(Place place) {
    _controller.text = place.fullName;
    setState(() {
      _open = false;
      _results = const [];
    });
    _focus.unfocus();
    widget.onPlace(place);
  }

  Future<void> _submit() async {
    if (_open && _results.isNotEmpty) {
      _choose(_results[_active >= 0 ? _active : 0]);
      return;
    }
    _debounce?.cancel();
    final results = await _search(_controller.text);
    if (!mounted) return;
    if (results.isEmpty) {
      widget.onNothingFound();
    } else {
      _choose(results.first);
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!_open || _results.isEmpty || event is KeyUpEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() => _active = (_active + 1) % _results.length);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() => _active = (_active - 1 + _results.length) % _results.length);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      setState(() => _open = false);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final p = context.palette;
    final phone = widget.phone;
    final underline = p.text.withValues(alpha: 0.22);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.search_rounded, size: 22, color: p.text.withValues(alpha: 0.55)),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  onChanged: _onChanged,
                  onSubmitted: (_) => _submit(),
                  textInputAction: TextInputAction.search,
                  style: TextStyle(fontSize: phone ? 19 : 24, fontWeight: FontWeight.w300, color: p.text, letterSpacing: -0.2),
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
            const SizedBox(width: 12),
            _GradientButton(
              size: phone ? 36 : 40,
              tooltip: t.searchAddress,
              onTap: _submit,
              child: Icon(Icons.arrow_forward_rounded, size: 18, color: p.onPrimary),
            ),
          ],
        ),
        if (_open && _results.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: phone ? 0 : 32, right: phone ? 0 : 52, top: 6),
            child: _Suggestions(
              results: _results,
              active: _active,
              query: _controller.text,
              phone: phone,
              onTap: _choose,
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(left: 32, top: 8),
            child: Text(widget.hint, style: TextStyle(fontSize: phone ? 11.5 : 12.5, color: p.muted)),
          ),
      ],
    );
  }
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({
    required this.results,
    required this.active,
    required this.query,
    required this.phone,
    required this.onTap,
  });

  final List<Place> results;
  final int active;
  final String query;
  final bool phone;
  final ValueChanged<Place> onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.surface,
      elevation: 0,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: p.border),
          boxShadow: const [BoxShadow(color: Color(0x40102040), blurRadius: 30, offset: Offset(0, 14), spreadRadius: -16)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < results.length; i++)
              InkWell(
                borderRadius: BorderRadius.circular(7),
                onTap: () => onTap(results[i]),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: i == active ? p.selected : null,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.place_outlined, size: 17, color: i == active ? p.primary : p.muted),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text.rich(
                          TextSpan(children: [
                            ..._highlight(results[i].title, query),
                            if (results[i].detail.isNotEmpty)
                              TextSpan(text: '  ${results[i].detail}', style: TextStyle(color: p.muted, fontSize: 12)),
                          ]),
                          maxLines: phone ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13.5, color: p.text),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// The typed part in bold, matched without case or accents.
  static List<TextSpan> _highlight(String text, String query) {
    String fold(String s) => Countries.fold(s);
    final q = fold(query.trim().split(',').first.trim());
    final i = q.isEmpty ? -1 : fold(text).indexOf(q);
    if (i < 0) return [TextSpan(text: text)];
    return [
      TextSpan(text: text.substring(0, i)),
      TextSpan(text: text.substring(i, i + q.length), style: const TextStyle(fontWeight: FontWeight.w700)),
      TextSpan(text: text.substring(i + q.length)),
    ];
  }
}

// ==================================================================== card

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    super.key,
    required this.selection,
    required this.layers,
    required this.layer,
    required this.phone,
    required this.language,
    required this.onLayer,
    required this.onClose,
  });

  final _Selection selection;
  final SolarLayers layers;
  final SolarLayerId layer;
  final bool phone;
  final String language;
  final ValueChanged<SolarLayerId> onLayer;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final p = context.palette;
    final s = selection;
    final point = s.point;
    final info = layers[layer];
    final accent = info.accent;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: phone ? Offset(0, 20 * (1 - v)) : Offset(24 * (1 - v), 0), child: child),
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 14, 10, phone ? 12 : 14),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: p.border),
          boxShadow: const [BoxShadow(color: Color(0x50102040), blurRadius: 40, offset: Offset(0, 18), spreadRadius: -20)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.title ?? '…',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: p.text),
                      ),
                      if ((s.detail ?? '').isNotEmpty)
                        Text(s.detail!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: p.muted)),
                      const SizedBox(height: 3),
                      Text(_coordinates(s.lat, s.lon), style: _mono(10.5, p.muted)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: t.close,
                  onPressed: onClose,
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  icon: Icon(Icons.close_rounded, color: p.muted),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _body(context, t, p, point, info, accent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, AppStrings t, WeShapePalette p, SolarPoint? point, SolarLayerInfo info, Color accent) {
    if (selection.error != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(selection.error!, style: TextStyle(color: p.error, fontSize: 13)),
      );
    }
    if (point == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 10),
        child: LinearProgressIndicator(minHeight: 2, color: accent, backgroundColor: p.border),
      );
    }
    final value = point.valueOf(layer);
    final monthly = point.monthlyOf(layer);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(_title(t, layer), style: TextStyle(fontSize: 12, color: p.muted)),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 6,
          children: [
            Text(
              _format(value, layer, language),
              style: TextStyle(fontSize: phone ? 28 : 32, fontWeight: FontWeight.w700, letterSpacing: -0.8, color: p.text, height: 1.15),
            ),
            if (layer != SolarLayerId.opta)
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(info.unit, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.text)),
              ),
            if (layer != SolarLayerId.opta)
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(t.perYear, style: TextStyle(fontSize: 12, color: p.muted)),
              ),
          ],
        ),
        if (!phone) ...[
          const SizedBox(height: 8),
          if (monthly != null) _MonthlyBars(values: monthly, color: accent) else _TiltFigure(angle: value, color: accent, south: t.south),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            for (final id in SolarLayerId.values) ...[
              if (id != SolarLayerId.gti) const SizedBox(width: 6),
              Expanded(
                child: _MetricTile(
                  label: _short(t, id),
                  value: _format(point.valueOf(id), id, language),
                  unit: id == SolarLayerId.opta ? '' : layers[id].unit,
                  selected: id == layer,
                  accent: layers[id].accent,
                  onTap: () => onLayer(id),
                ),
              ),
            ],
          ],
        ),
        if (!phone) ...[
          const SizedBox(height: 10),
          Text(
            point.example ? t.exampleValuesNote : '${point.source} · European Commission JRC',
            style: TextStyle(fontSize: 10.5, color: p.muted),
          ),
        ],
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final String value;
  final String unit;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: 0.14) : p.text.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? accent : Colors.transparent),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: p.muted)),
              const SizedBox(height: 1),
              Text(value, maxLines: 1, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: p.text)),
              Text(unit.isEmpty ? ' ' : unit, maxLines: 1, style: TextStyle(fontSize: 9.5, color: p.muted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthlyBars extends StatelessWidget {
  const _MonthlyBars({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final max = values.fold<double>(0, math.max);
    return Column(
      children: [
        SizedBox(
          height: 34,
          child: TweenAnimationBuilder<double>(
            key: ValueKey(values.first),
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, grow, _) => Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < values.length; i++) ...[
                  if (i > 0) const SizedBox(width: 3),
                  Expanded(
                    child: Container(
                      height: 34 * (0.12 + 0.88 * values[i] / (max == 0 ? 1 : max)) * grow,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [color, color.withValues(alpha: 0.35)],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text('J', style: _mono(9, p.muted)), Text('D', style: _mono(9, p.muted))],
        ),
      ],
    );
  }
}

class _TiltFigure extends StatelessWidget {
  const _TiltFigure({required this.angle, required this.color, required this.south});

  final double angle;
  final Color color;
  final String south;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: angle),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        builder: (context, a, _) => CustomPaint(
          painter: _TiltPainter(angle: a, color: color, line: p.muted, text: p.text, south: south),
        ),
      ),
    );
  }
}

class _TiltPainter extends CustomPainter {
  _TiltPainter({required this.angle, required this.color, required this.line, required this.text, required this.south});

  final double angle;
  final Color color;
  final Color line;
  final Color text;
  final String south;

  @override
  void paint(Canvas canvas, Size size) {
    final ground = size.height - 6;
    final x0 = size.width * 0.09;
    // Dashed ground line.
    final dash = Paint()
      ..color = line
      ..strokeWidth = 1.5;
    for (var x = x0; x < size.width * 0.9; x += 6) {
      canvas.drawLine(Offset(x, ground), Offset(math.min(x + 3, size.width * 0.9), ground), dash);
    }
    final rad = angle * math.pi / 180;
    final len = size.width * 0.55;
    // Angle arc.
    canvas.drawArc(
      Rect.fromCircle(center: Offset(x0, ground), radius: 42),
      -rad,
      rad,
      false,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    // The panel.
    canvas.drawLine(
      Offset(x0, ground),
      Offset(x0 + len * math.cos(rad), ground - len * math.sin(rad)),
      Paint()
        ..color = color
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    _text(canvas, '${angle.round()}°', Offset(x0 + 52, ground - 20), TextStyle(color: text, fontSize: 13, fontWeight: FontWeight.w600));
    _text(canvas, '$south →', Offset(size.width * 0.9, 0), TextStyle(color: line, fontSize: 10, fontWeight: FontWeight.w600), alignRight: true);
  }

  void _text(Canvas canvas, String s, Offset at, TextStyle style, {bool alignRight = false}) {
    final tp = TextPainter(text: TextSpan(text: s, style: style), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, alignRight ? at - Offset(tp.width, 0) : at);
  }

  @override
  bool shouldRepaint(_TiltPainter old) =>
      old.angle != angle || old.color != color || old.line != line || old.text != text || old.south != south;
}

// ==================================================================== dock

enum _Resource { solar, wind, hydro, geothermal, biomass }

class _Dock extends StatelessWidget {
  const _Dock({
    required this.phone,
    required this.layer,
    required this.info,
    required this.language,
    required this.onLayer,
    required this.onComingSoon,
  });

  final bool phone;
  final SolarLayerId layer;
  final SolarLayerInfo info;
  final String language;
  final ValueChanged<SolarLayerId> onLayer;
  final ValueChanged<String> onComingSoon;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final p = context.palette;

    final resources = [
      for (final r in _Resource.values)
        _ResourceButton(
          icon: _icon(r),
          label: _resourceName(t, r),
          soon: r == _Resource.solar ? null : t.comingSoon,
          selected: r == _Resource.solar,
          phone: phone,
          onTap: r == _Resource.solar ? null : () => onComingSoon(_resourceName(t, r)),
        ),
    ];

    final dock = Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.border),
        boxShadow: const [BoxShadow(color: Color(0x50102040), blurRadius: 40, offset: Offset(0, 18), spreadRadius: -20)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (phone)
            Row(children: [for (final b in resources) Expanded(child: b)])
          else
            Row(mainAxisSize: MainAxisSize.min, children: [
              for (var i = 0; i < resources.length; i++) ...[if (i > 0) const SizedBox(width: 2), resources[i]],
            ]),
          const SizedBox(height: 6),
          Container(height: 1, color: p.border),
          const SizedBox(height: 5),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 2,
            children: [
              for (final id in SolarLayerId.values)
                _LayerChip(label: _short(t, id), selected: id == layer, accent: info.accent, onTap: () => onLayer(id)),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 2, 10, 4),
            child: Row(
              mainAxisSize: phone ? MainAxisSize.max : MainAxisSize.min,
              children: [
                if (!phone) ...[
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Text(_legend(t, layer), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10.5, color: p.muted)),
                  ),
                  const SizedBox(width: 10),
                ],
                Text(_legendNumber(info.min, layer, language), style: _mono(10, p.muted)),
                const SizedBox(width: 8),
                SizedBox(
                  width: phone ? null : 180,
                  child: phone ? null : _LegendBar(colors: info.colors),
                ),
                if (phone) Expanded(child: _LegendBar(colors: info.colors)),
                const SizedBox(width: 8),
                Text(_legendNumber(info.max, layer, language), style: _mono(10, p.muted)),
              ],
            ),
          ),
        ],
      ),
    );
    return phone ? dock : IntrinsicWidth(child: dock);
  }

  static IconData _icon(_Resource r) => switch (r) {
        _Resource.solar => Icons.wb_sunny_outlined,
        _Resource.wind => Icons.air_rounded,
        _Resource.hydro => Icons.water_drop_outlined,
        _Resource.geothermal => Icons.thermostat_outlined,
        _Resource.biomass => Icons.eco_outlined,
      };

  static String _resourceName(AppStrings t, _Resource r) => switch (r) {
        _Resource.solar => t.resourceSolar,
        _Resource.wind => t.resourceWind,
        _Resource.hydro => t.resourceHydro,
        _Resource.geothermal => t.resourceGeothermal,
        _Resource.biomass => t.resourceBiomass,
      };
}

class _LegendBar extends StatelessWidget {
  const _LegendBar({required this.colors});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        height: 6,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(3), gradient: LinearGradient(colors: colors)),
      );
}

class _ResourceButton extends StatelessWidget {
  const _ResourceButton({
    required this.icon,
    required this.label,
    required this.soon,
    required this.selected,
    required this.phone,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? soon;
  final bool selected;
  final bool phone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = selected ? p.onPrimary : (soon != null ? p.muted.withValues(alpha: 0.6) : p.muted);
    final badge = soon == null
        ? null
        : Container(
            padding: EdgeInsets.symmetric(horizontal: phone ? 3 : 4, vertical: 1),
            decoration: BoxDecoration(border: Border.all(color: p.border), borderRadius: BorderRadius.circular(4)),
            child: Text(
              soon!.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: phone ? 7 : 8.5, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: p.muted),
            ),
          );
    final text = Text(label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: phone ? 10 : 13, fontWeight: FontWeight.w600, color: color));

    final content = phone
        ? Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 19, color: color),
            const SizedBox(height: 3),
            text,
            if (badge != null) ...[const SizedBox(height: 2), badge],
          ])
        : Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 7),
            text,
            if (badge != null) ...[const SizedBox(width: 6), badge],
          ]);

    return Tooltip(
      message: soon ?? '',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          mouseCursor: onTap == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(8),
          child: Ink(
            padding: phone ? const EdgeInsets.fromLTRB(2, 8, 2, 7) : const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              gradient: selected ? p.primaryGradient : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

class _LayerChip extends StatelessWidget {
  const _LayerChip({required this.label, required this.selected, required this.accent, required this.onTap});

  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: 0.22) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: selected ? p.text : p.muted),
          ),
        ),
      ),
    );
  }
}

class _ZoomButtons extends StatelessWidget {
  const _ZoomButtons({required this.onIn, required this.onOut});

  final VoidCallback onIn;
  final VoidCallback onOut;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final p = context.palette;
    Widget button(String label, String tip, VoidCallback onTap) => Tooltip(
          message: tip,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 36,
              height: 36,
              child: Center(child: Text(label, style: TextStyle(fontSize: 18, color: p.text))),
            ),
          ),
        );
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: p.border), borderRadius: BorderRadius.circular(10)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            button('+', t.zoomIn, onIn),
            Container(height: 1, width: 36, color: p.border),
            button('−', t.zoomOut, onOut),
          ],
        ),
      ),
    );
  }
}

// ==================================================================== helpers

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.size, required this.tooltip, required this.onTap, required this.child});

  final double size;
  final String tooltip;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Ink(
            width: size,
            height: size,
            decoration: BoxDecoration(gradient: p.primaryGradient, borderRadius: BorderRadius.circular(8)),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

String _title(AppStrings t, SolarLayerId id) => switch (id) {
      SolarLayerId.gti => t.irradiationTitle,
      SolarLayerId.pvout => t.pvProductionTitle,
      SolarLayerId.opta => t.optimumTiltTitle,
    };

String _short(AppStrings t, SolarLayerId id) => switch (id) {
      SolarLayerId.gti => t.layerIrradiation,
      SolarLayerId.pvout => t.layerPvProduction,
      SolarLayerId.opta => t.layerOptimumTilt,
    };

String _legend(AppStrings t, SolarLayerId id) => switch (id) {
      SolarLayerId.gti => t.legendIrradiation,
      SolarLayerId.pvout => t.legendPvProduction,
      SolarLayerId.opta => t.legendOptimumTilt,
    };

String _format(double v, SolarLayerId id, String language) =>
    id == SolarLayerId.opta ? '${v.round()}°' : _group((v / 5).round() * 5, language);

String _legendNumber(double v, SolarLayerId id, String language) =>
    id == SolarLayerId.opta ? '${v.round()}°' : _group(v.round(), language);

/// 1,276 / 1.276 / 1 276, as each language writes thousands.
String _group(int v, String language) {
  const dot = {'de', 'nl', 'id', 'it', 'es', 'pt', 'tr', 'da', 'el', 'ro', 'hr', 'vi'};
  const space = {'hu', 'fr', 'pl', 'fi', 'sv', 'ru'};
  final sep = dot.contains(language) ? '.' : (space.contains(language) ? ' ' : ',');
  final digits = v.abs().toString();
  final out = StringBuffer(v < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(sep);
    out.write(digits[i]);
  }
  return out.toString();
}

String _coordinates(double lat, double lon) =>
    '${lat.abs().toStringAsFixed(2)}° ${lat >= 0 ? 'N' : 'S'} · ${lon.abs().toStringAsFixed(2)}° ${lon >= 0 ? 'E' : 'W'}';

TextStyle _mono(double size, Color color) => WeShapeTheme.useGoogleFonts
    ? GoogleFonts.jetBrainsMono(fontSize: size, color: color)
    : TextStyle(fontFamily: 'monospace', fontSize: size, color: color);
