import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'map_bridge_stub.dart' if (dart.library.js_interop) 'map_bridge_web.dart' as impl;

/// A point on the map.
@immutable
class MapPoint {
  const MapPoint(this.lat, this.lon);

  final double lat;
  final double lon;
}

/// The interactive map, drawn by MapLibre GL JS in the browser.
///
/// Flutter draws everything on top of it (search, card, resource switch);
/// this class only moves the map, changes its look and reports clicks.
abstract class MapBridge {
  factory MapBridge() => impl.createMapBridge();

  /// The map itself. Build it once; [bounds] is west, south, east, north.
  Widget buildView({
    required bool dark,
    required String language,
    required List<double> bounds,
    required EdgeInsets padding,
    required String attribution,
  });

  /// Clicks on the map (not on Flutter content above it).
  Stream<MapPoint> get clicks;

  /// Set when the map library or the base map could not load.
  ValueListenable<String?> get loadError;

  void setDark(bool dark);
  void setLanguage(String languageCode);

  /// A picture laid over the land, rows in Web Mercator; [bounds] is west, south, east, north.
  void setOverlay(String url, List<double> bounds, double opacity);

  void fitBounds(List<double> bounds, EdgeInsets padding, {bool animate = true});

  /// [offset] shifts the target away from the centre, in pixels, to leave room for the card.
  void flyTo(double lat, double lon, {double zoom = 11, Offset offset = Offset.zero});

  void setMarker(double lat, double lon, Color color);
  void clearMarker();
  void zoomIn();
  void zoomOut();

  /// Where Flutter draws controls over the map, in the map's own coordinates.
  /// Clicks and drags there go to Flutter only.
  void setBlockers(List<Rect> rects);

  /// Moves the map's attribution line up by [pixels] so nothing covers it.
  void setAttributionBottom(double pixels);

  /// False while a menu or dialog covers the map.
  void setInteractive(bool interactive);

  void dispose();
}

String cssColor(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
