import 'dart:convert';
import 'dart:math' as math;

/// One straight wall of a building and the compass bearing it faces (0 north, 90 east).
class Wall {
  const Wall(this.lengthM, this.facingDeg);

  final double lengthM;
  final double facingDeg;

  Map<String, Object?> toJson() => {'lengthM': lengthM, 'facingDeg': facingDeg};

  factory Wall.fromJson(Map<String, dynamic> j) =>
      Wall((j['lengthM'] as num).toDouble(), (j['facingDeg'] as num).toDouble());
}

/// A building from the map (Overture Maps): its outline and what is known about it.
class BuildingShape {
  const BuildingShape({
    required this.id,
    required this.outline,
    required this.areaM2,
    this.heightM,
    this.floors,
    this.roofShape,
    this.walls = const [],
    this.mainAxisDeg,
  });

  final String id;

  /// Outer outline as [longitude, latitude] points, closed.
  final List<List<double>> outline;

  /// Ground area, m².
  final double areaM2;
  final double? heightM;
  final int? floors;

  /// Overture's roof shape (flat, gabled, hipped ...), when known.
  final String? roofShape;

  /// Only for the building at the place itself.
  final List<Wall> walls;

  /// Direction of the longest wall, 0–180 (0 north–south, 90 east–west).
  final double? mainAxisDeg;

  /// True when the point is inside the outline.
  bool contains(double lat, double lon) {
    var inside = false;
    for (var i = 0, j = outline.length - 1; i < outline.length; j = i++) {
      final a = outline[i], b = outline[j];
      if ((a[1] > lat) != (b[1] > lat) && lon < (b[0] - a[0]) * (lat - a[1]) / (b[1] - a[1]) + a[0]) {
        inside = !inside;
      }
    }
    return inside;
  }

  /// [west, south, east, north].
  List<double> get bounds {
    var w = 180.0, s = 90.0, e = -180.0, n = -90.0;
    for (final p in outline) {
      w = math.min(w, p[0]);
      e = math.max(e, p[0]);
      s = math.min(s, p[1]);
      n = math.max(n, p[1]);
    }
    return [w, s, e, n];
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'outline': outline,
        'areaM2': areaM2,
        'heightM': heightM,
        'floors': floors,
        'roofShape': roofShape,
        'walls': [for (final w in walls) w.toJson()],
        'mainAxisDeg': mainAxisDeg,
      };

  factory BuildingShape.fromJson(Map<String, dynamic> j) => BuildingShape(
        id: j['id'] as String? ?? '',
        outline: [
          for (final p in j['outline'] as List) [for (final v in p as List) (v as num).toDouble()],
        ],
        areaM2: (j['areaM2'] as num).toDouble(),
        heightM: (j['heightM'] as num?)?.toDouble(),
        floors: (j['floors'] as num?)?.toInt(),
        roofShape: j['roofShape'] as String?,
        walls: [for (final w in (j['walls'] as List?) ?? const []) Wall.fromJson(w as Map<String, dynamic>)],
        mainAxisDeg: (j['mainAxisDeg'] as num?)?.toDouble(),
      );
}

/// The building at a place and the ones within 50 m of it.
class BuildingsAt {
  const BuildingsAt({required this.building, required this.nearby, required this.attribution});

  /// Null when there is no building at or right next to the place.
  final BuildingShape? building;
  final List<BuildingShape> nearby;
  final String attribution;

  factory BuildingsAt.fromJson(Map<String, dynamic> j) => BuildingsAt(
        building: j['building'] == null ? null : BuildingShape.fromJson(j['building'] as Map<String, dynamic>),
        nearby: [for (final b in (j['nearby'] as List?) ?? const []) BuildingShape.fromJson(b as Map<String, dynamic>)],
        attribution: j['attribution'] as String? ?? '',
      );

  /// GeoJSON for the map: the building with `main: 1`, the others with `main: 0`, and
  /// the place itself as a point when given.
  String toGeoJson({double? pointLat, double? pointLon}) => jsonEncode({
        'type': 'FeatureCollection',
        'features': [
          if (building != null) _feature(building!, 1),
          for (final b in nearby) _feature(b, 0),
          if (pointLat != null && pointLon != null) pointFeature(pointLat, pointLon),
        ],
      });

  /// Only the place, as a point (when the buildings could not be read).
  static String pointGeoJson(double lat, double lon) => jsonEncode({
        'type': 'FeatureCollection',
        'features': [pointFeature(lat, lon)],
      });

  static Map<String, Object?> pointFeature(double lat, double lon) => {
        'type': 'Feature',
        'properties': {'place': 1},
        'geometry': {
          'type': 'Point',
          'coordinates': [lon, lat],
        },
      };

  static Map<String, Object?> _feature(BuildingShape b, int main) => {
        'type': 'Feature',
        'properties': {'main': main},
        'geometry': {
          'type': 'Polygon',
          'coordinates': [b.outline],
        },
      };
}
