import 'dart:async';
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
  external void mount(web.HTMLElement element, JSAny? options, JSFunction onClick, JSFunction onError);
  external void setDark(bool dark);
  external void setLanguage(String code);
  external void setOverlay(String url, JSArray<JSNumber> bounds, double opacity);
  external void fitBounds(JSArray<JSNumber> bounds, double top, double right, double bottom, double left, bool animate);
  external void flyTo(double lon, double lat, double zoom, double offsetX, double offsetY);
  external void setMarker(double lon, double lat, String color);
  external void clearMarker();
  external void zoomIn();
  external void zoomOut();
  external void setInteractive(bool on);
  external void setBlockers(JSArray<JSNumber> flat);
  external void setAttributionBottom(double px);
  external void destroy();
}

/// Raise when assets/map/weshape_map.js changes.
const _bridgeVersion = 6;

Future<void>? _scriptLoading;

/// Adds the bridge script to the page once.
Future<void> _loadScript() {
  if (_weShapeMap != null) return Future.value();
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
        _run((map) => map.mount(
              element,
              options,
              ((JSNumber lon, JSNumber lat) {
                if (!_clicks.isClosed) _clicks.add(MapPoint(lat.toDartDouble, lon.toDartDouble));
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
  void fitBounds(List<double> bounds, EdgeInsets padding, {bool animate = true}) =>
      _run((m) => m.fitBounds(_numbers(bounds), padding.top, padding.right, padding.bottom, padding.left, animate));

  @override
  void flyTo(double lat, double lon, {double zoom = 11, Offset offset = Offset.zero}) =>
      _run((m) => m.flyTo(lon, lat, zoom, offset.dx, offset.dy));

  @override
  void setMarker(double lat, double lon, Color color) => _run((m) => m.setMarker(lon, lat, cssColor(color)));

  @override
  void clearMarker() => _run((m) => m.clearMarker());

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
    _error.dispose();
  }
}
