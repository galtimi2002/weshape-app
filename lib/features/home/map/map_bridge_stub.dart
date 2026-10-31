import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'map_bridge.dart';

/// Outside the browser (tests, desktop runs) there is no MapLibre: a quiet
/// placeholder keeps the rest of the screen usable.
MapBridge createMapBridge() => _NoMap();

class _NoMap implements MapBridge {
  final _clicks = StreamController<MapPoint>.broadcast();
  final _error = ValueNotifier<String?>(null);

  @override
  Widget buildView({
    required bool dark,
    required String language,
    required List<double> bounds,
    required EdgeInsets padding,
    required String attribution,
  }) =>
      ColoredBox(color: dark ? const Color(0xFF121924) : const Color(0xFFE8ECF1));

  @override
  Stream<MapPoint> get clicks => _clicks.stream;

  @override
  ValueListenable<String?> get loadError => _error;

  @override
  void setDark(bool dark) {}
  @override
  void setLanguage(String languageCode) {}
  @override
  void setOverlay(String url, List<double> bounds, double opacity) {}
  @override
  void fitBounds(List<double> bounds, EdgeInsets padding, {bool animate = true}) {}
  @override
  void flyTo(double lat, double lon, {double zoom = 11, Offset offset = Offset.zero}) {}
  @override
  void setMarker(double lat, double lon, Color color) {}
  @override
  void clearMarker() {}
  @override
  void zoomIn() {}
  @override
  void zoomOut() {}
  @override
  void setBlockers(List<Rect> rects) {}
  @override
  void setAttributionBottom(double pixels) {}
  @override
  void setInteractive(bool interactive) {}

  @override
  void dispose() {
    _clicks.close();
    _error.dispose();
  }
}
