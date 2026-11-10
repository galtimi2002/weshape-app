import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

import 'map_bridge.dart';

MapBridge createMapBridge() => _WebMapBridge();

/// window.WeShapeMap, defined by assets/map/weshape_map.js.
@JS('WeShapeMap')
external _WeShapeMapJs? get _weShapeMap;

extension type _WeShapeMapJs._(JSObject _) implements JSObject {
  external int? get version;
  external void mount(web.HTMLElement element, JSAny? options, JSFunction onClick, JSFunction onError);
  external void setDark(bool dark);
  external void setLanguage(String code);
  external void setOverlay(String url, JSArray<JSNumber> bounds, double opacity);
  external void setTileOverlay(String url, JSArray<JSNumber> bounds, double opacity, int maxZoom);
  external void setRiverOverlay(String url, JSArray<JSNumber> bounds, double opacity, int maxZoom, String style);
  external void setAttribution(String html);
  external void playBreeze();
  external void fitBounds(JSArray<JSNumber> bounds, double top, double right, double bottom, double left, bool animate);
  external void flyTo(double lon, double lat, double zoom, double offsetX, double offsetY);
  external void setPeek(bool on);
  external void jumpTo(double lon, double lat, double zoom, double offsetX, double offsetY);
  external void setMarker(double lon, double lat, String color);
  external void clearMarker();
  external void setBuildings(String geojson, String color);
  external void setOverlayVisible(bool visible);
  external void setDrawing(String geojson, String color);
  external void setDrawMode(bool on);
  external void setOnDraw(JSFunction fn);
  external void setOnRoads(JSFunction fn);
  external void requestRoads(double lon, double lat, double metres);
  external void zoomIn();
  external void zoomOut();
  external void setInteractive(bool on);
  external void setBlockers(JSArray<JSNumber> flat);
  external void setAttributionBottom(double px);
  external void destroy();
}

/// Raise together with VERSION in assets/map/weshape_map.js whenever that file changes.
const _bridgeVersion = 21;

Future<void>? _scriptLoading;

/// Adds the bridge script to the page once.
Future<void> _loadScript() {
  if (_weShapeMap?.version == _bridgeVersion) return Future.value();
  return _scriptLoading ??= () {
    final done = Completer<void>();
    // The version keeps browsers from running an older cached copy after an update.
    final script = web.HTMLScriptElement()
      ..src = '${ui_web.assetManager.getAssetUrl('assets/map/weshape_map.js')}?v=$_bridgeVersion';
    script.addEventListener('load', ((web.Event _) => done.complete()).toJS);
    script.addEventListener(
      'error',
      ((web.Event _) {
        _scriptLoading = null;
        done.completeError(StateError('map script did not load'));
      }).toJS,
    );
    web.document.head!.appendChild(script);
    return done.future;
  }();
}

JSArray<JSNumber> _numbers(List<double> values) => [for (final v in values) v.toJS].toJS;

class _WebMapBridge implements MapBridge {
  final _clicks = StreamController<MapPoint>.broadcast();
  final _drawn = StreamController<List<List<double>>>.broadcast();
  final _roads = StreamController<List<(double, List<List<double>>)>>.broadcast();
  final _error = ValueNotifier<String?>(null);
  late final Future<void> _ready = _loadScript();
  bool _disposed = false;

  /// Runs [action] once the bridge script is there, in call order.
  void _run(void Function(_WeShapeMapJs map) action) {
    _ready.then((_) {
      final map = _weShapeMap;
      if (!_disposed && map != null) action(map);
    }, onError: (Object e) {
      if (!_disposed) _error.value ??= '$e';
    });
  }

  @override
  Widget buildView({
    required bool dark,
    required String language,
    required List<double> bounds,
    required EdgeInsets padding,
    required String attribution,
  }) {
    return HtmlElementView.fromTagName(
      tagName: 'div',
      onElementCreated: (Object created) {
        final element = created as web.HTMLElement;
        element.style
          ..width = '100%'
          ..height = '100%';
        final options = <String, Object>{
          'dark': dark,
          'language': language,
          'bounds': bounds,
          'padding': [padding.top, padding.right, padding.bottom, padding.left],
          'attribution': attribution,
        }.jsify();
        _run((map) => map.setOnDraw(((JSString json) {
              if (_drawn.isClosed) return;
              final corners = jsonDecode(json.toDart) as List;
              _drawn.add([
                for (final c in corners) [((c as List)[0] as num).toDouble(), (c[1] as num).toDouble()],
              ]);
            }).toJS));
        _run((map) => map.setOnRoads(((JSString json) {
              if (_roads.isClosed) return;
              _roads.add([
                for (final r in jsonDecode(json.toDart) as List)
                  (
                    ((r as Map)['w'] as num).toDouble(),
                    [for (final c in r['c'] as List) [((c as List)[0] as num).toDouble(), (c[1] as num).toDouble()]],
                  ),
              ]);
            }).toJS));
        _run((map) => map.mount(
              element,
              options,
              ((JSNumber lon, JSNumber lat, JSNumber? zoom, JSBoolean? doubleClick) {
                if (!_clicks.isClosed) {
                  _clicks.add(MapPoint(lat.toDartDouble, lon.toDartDouble,
                      zoom: zoom?.toDartDouble, doubleClick: doubleClick?.toDart ?? false));
                }
              }).toJS,
              ((JSString message) {
                if (!_disposed) _error.value ??= message.toDart;
              }).toJS,
            ));
      },
    );
  }

  @override
  Stream<MapPoint> get clicks => _clicks.stream;

  @override
  ValueListenable<String?> get loadError => _error;

  @override
  void setDark(bool dark) => _run((m) => m.setDark(dark));

  @override
  void setLanguage(String languageCode) => _run((m) => m.setLanguage(languageCode));

  @override
  void setOverlay(String url, List<double> bounds, double opacity) =>
      _run((m) => m.setOverlay(url, _numbers(bounds), opacity));

  @override
  void setTileOverlay(String urlTemplate, List<double> bounds, double opacity, {int maxZoom = 10}) =>
      _run((m) => m.setTileOverlay(urlTemplate, _numbers(bounds), opacity, maxZoom));

  @override
  void setRiverOverlay(String urlTemplate, List<double> bounds, double opacity, RiverStyle style, {int maxZoom = 10}) =>
      _run((m) => m.setRiverOverlay(urlTemplate, _numbers(bounds), opacity, maxZoom, jsonEncode(style.toJson())));

  @override
  void setAttribution(String html) => _run((m) => m.setAttribution(html));

  @override
  void playBreeze() => _run((m) => m.playBreeze());

  @override
  void fitBounds(List<double> bounds, EdgeInsets padding, {bool animate = true}) =>
      _run((m) => m.fitBounds(_numbers(bounds), padding.top, padding.right, padding.bottom, padding.left, animate));

  @override
  void flyTo(double lat, double lon, {double zoom = 11, Offset offset = Offset.zero}) =>
      _run((m) => m.flyTo(lon, lat, zoom, offset.dx, offset.dy));

  @override
  void setPeek(bool on) => _run((m) => m.setPeek(on));

  @override
  void jumpTo(double lat, double lon, {double zoom = 11, Offset offset = Offset.zero}) =>
      _run((m) => m.jumpTo(lon, lat, zoom, offset.dx, offset.dy));

  @override
  void setMarker(double lat, double lon, Color color) => _run((m) => m.setMarker(lon, lat, cssColor(color)));

  @override
  void clearMarker() => _run((m) => m.clearMarker());

  @override
  void setBuildings(String geoJson, Color color) => _run((m) => m.setBuildings(geoJson, cssColor(color)));

  @override
  void setDrawMode(bool on) => _run((m) => m.setDrawMode(on));

  @override
  Stream<List<List<double>>> get drawn => _drawn.stream;

  @override
  void requestRoads(double lat, double lon, double metres) => _run((m) => m.requestRoads(lon, lat, metres));

  @override
  Stream<List<(double, List<List<double>>)>> get roads => _roads.stream;

  @override
  void setDrawing(String geoJson, Color color) => _run((m) => m.setDrawing(geoJson, cssColor(color)));

  @override
  void setOverlayVisible(bool visible) => _run((m) => m.setOverlayVisible(visible));

  @override
  void zoomIn() => _run((m) => m.zoomIn());

  @override
  void zoomOut() => _run((m) => m.zoomOut());

  @override
  void setBlockers(List<Rect> rects) =>
      _run((m) => m.setBlockers(_numbers([for (final r in rects) ...[r.left, r.top, r.width, r.height]])));

  @override
  void setAttributionBottom(double pixels) => _run((m) => m.setAttributionBottom(pixels));

  @override
  void setInteractive(bool interactive) => _run((m) => m.setInteractive(interactive));

  @override
  void dispose() {
    _disposed = true;
    _weShapeMap?.destroy();
    _clicks.close();
    _drawn.close();
    _roads.close();
    _error.dispose();
  }
}
