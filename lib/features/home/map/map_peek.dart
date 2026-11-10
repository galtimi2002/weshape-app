import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

/// The assessment's last question ("Is there something new at your place?") shows the map
/// under the page: the place close up, with the building outlines, and none of the map's
/// controls. It can be moved and zoomed; a double click marks where the new thing is.
///
/// The place opens in the middle of the strip of map left between the question (top) and
/// the buttons (bottom), or right of the question on a laptop: the page measures it and sets
/// [place], and its panels as
/// [blockers]; the map follows. [toScreen] and [toLatLon] are the map's own Web Mercator sums
/// for that opening view.
class MapPeek {
  MapPeek._();

  /// Close enough to tell one house from the next.
  static const double zoom = 18;

  /// Where the place opens, as shares of the map's width and height.
  static final ValueNotifier<Offset> place = ValueNotifier(const Offset(0.5, 0.55));

  /// Where the page draws over the map (its question and its buttons), in the map's
  /// pixels: clicks and drags there are the page's, not the map's.
  static final ValueNotifier<List<Rect>> blockers = ValueNotifier(const []);

  /// MapLibre draws the world 512 pixels wide at zoom 0.
  static const double _tile = 512;

  /// How far the place is moved from the middle of a map of [size] (for flyTo).
  static Offset offsetFor(Size size) => Offset((place.value.dx - 0.5) * size.width, (place.value.dy - 0.5) * size.height);

  /// Where the place itself is drawn on a map of [size].
  static Offset placeAt(Size size) => Offset(place.value.dx * size.width, place.value.dy * size.height);

  static Offset _world(double lat, double lon) {
    final scale = _tile * math.pow(2, zoom);
    final s = math.sin(lat.clamp(-85.0, 85.0) * math.pi / 180);
    return Offset(
      (lon + 180) / 360 * scale,
      (0.5 - math.log((1 + s) / (1 - s)) / (4 * math.pi)) * scale,
    );
  }

  /// Where [lat], [lon] is drawn on a map of [size] centred on the place [placeLat], [placeLon].
  static Offset toScreen(Size size, double placeLat, double placeLon, double lat, double lon) =>
      placeAt(size) + (_world(lat, lon) - _world(placeLat, placeLon));

  /// The point under [screen] on a map of [size] centred on the place: (latitude, longitude).
  static (double, double) toLatLon(Size size, double placeLat, double placeLon, Offset screen) {
    final scale = _tile * math.pow(2, zoom);
    final w = _world(placeLat, placeLon) + (screen - placeAt(size));
    final lon = w.dx / scale * 360 - 180;
    final n = math.pi - 2 * math.pi * w.dy / scale;
    final lat = 180 / math.pi * math.atan(0.5 * (math.exp(n) - math.exp(-n)));
    return (lat, lon);
  }
}
