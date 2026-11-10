import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'map_bridge_stub.dart' if (dart.library.js_interop) 'map_bridge_web.dart' as impl;

/// A point on the map.
@immutable
class MapPoint {
  const MapPoint(this.lat, this.lon, {this.zoom, this.doubleClick = false});

  final double lat;
  final double lon;

  /// The map's zoom when it was clicked.
  final double? zoom;

  /// The second click of a double click (or tap).
  final bool doubleClick;
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

  /// Map tiles laid over the land instead of a single picture: [urlTemplate] has
  /// {z}/{x}/{y}; [bounds] is west, south, east, north; tiles exist up to [maxZoom].
  void setTileOverlay(String urlTemplate, List<double> bounds, double opacity, {int maxZoom = 10});

  /// River lines from vector tiles ([urlTemplate] has {z}/{x}/{y}) instead of a picture.
  /// [style] says which tile value colours the lines and how: see [RiverStyle].
  void setRiverOverlay(String urlTemplate, List<double> bounds, double opacity, RiverStyle style, {int maxZoom = 10});

  /// Replaces the data credit in the map's attribution line (HTML).
  void setAttribution(String html);

  /// A short breeze across the map (soft gusts, a few leaves, a turbine), when
  /// the person switches to wind. Skipped when the system asks for reduced motion.
  void playBreeze();

  void fitBounds(List<double> bounds, EdgeInsets padding, {bool animate = true});

  /// [offset] shifts the target away from the centre, in pixels, to leave room for the card.
  void flyTo(double lat, double lon, {double zoom = 11, Offset offset = Offset.zero});

  /// On: a double click is reported as a [MapPoint.doubleClick] instead of zooming in.
  void setPeek(bool on);

  /// Like [flyTo], without the flight.
  void jumpTo(double lat, double lon, {double zoom = 11, Offset offset = Offset.zero});

  void setMarker(double lat, double lon, Color color);
  void clearMarker();

  /// Building outlines on top of the map: [geoJson] is a FeatureCollection whose picked
  /// building has `main: 1`, drawn in [color]; the others grey. An empty string clears them.
  void setBuildings(String geoJson, Color color);

  /// On: pressing and dragging on the map draws a rectangle (reported on [drawn]) instead
  /// of moving the map.
  void setDrawMode(bool on);

  /// The corners [latitude, longitude] of each rectangle drawn in draw mode.
  Stream<List<List<double>>> get drawn;

  /// Asks for the roads within [metres] of a place; they arrive on [roads] once the map
  /// has its tiles there.
  void requestRoads(double lat, double lon, double metres);

  /// Roads near a place: each with the half width kept free (m) and its line [lat, lon].
  Stream<List<(double, List<List<double>>)>> get roads;

  /// Something the person draws on the map (the outline of a new thing): a FeatureCollection
  /// of its area, line and corners, in [color]. An empty string clears it.
  void setDrawing(String geoJson, Color color);

  /// Hides the resource layer (solar, wind ...) or shows it again.
  void setOverlayVisible(bool visible);
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

/// How the river lines are drawn: [property] (a value in the tiles' [sourceLayer])
/// picks the colour on the [min]–[max] scale, [widthProperty] (mean flow) the width.
@immutable
class RiverStyle {
  const RiverStyle({
    required this.sourceLayer,
    required this.property,
    required this.min,
    required this.max,
    required this.logarithmic,
    required this.colors,
    required this.widthProperty,
  });

  final String sourceLayer;
  final String property;
  final double min;
  final double max;
  final bool logarithmic;
  final List<Color> colors;
  final String widthProperty;

  Map<String, Object> toJson() => {
        'sourceLayer': sourceLayer,
        'property': property,
        'min': min,
        'max': max,
        'log': logarithmic,
        'colors': [for (final c in colors) cssColor(c)],
        'widthProperty': widthProperty,
      };
}

String cssColor(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
