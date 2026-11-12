import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Who the assessment is for (question 1). Only [home] is open for now.
enum Audience { home, farm, business, community, village, site }

/// What the person wants to power (question 3, pick any).
enum Use { appliances, cooking, heating, hotWater, car, pumping }

enum BuildingType { house, flat }

enum BuildEra { before1960, from1960, from1990, from2010, unknown }

enum Renovation { walls, roof, windows, heating, none, unknown }

enum RenovationAge { recent, middle, old }

enum InsulationLevel { none, thin, medium, thick, unknown }

enum FloorInsulation { none, insulated, unknown }

enum WindowKind { single, doubleOld, doubleNew, triple, mix, unknown }

/// How the home gets energy today (question 5, pick any; [nothing] stands alone).
/// How the home gets its energy today. Equipment of its own is not asked: the bills are
/// what renewable energy would replace.
enum Source { mains, pipedGas, district, gasBottles, wood, generator, nothing }


enum GasUnit { m3, kwh }

/// Where there is free space (question 8, pick any; [nowhere] stands alone).
enum Space { roof, garden, land, balcony, notSure, nowhere }

/// [none]: only for the garden, when someone who was not sure has no garden or yard after all.
enum AreaSize { small, medium, large, none }

enum Facing { south, eastWest, north, flat }

enum Ownership { own, building, rent, shared }

enum Fixer { self, technician, installer, unknown }

enum HandsOn { none, little, regular }

enum Priority { upfront, running, environment, balanced }

enum Animals { few, herd, foodWaste, none }

enum RiverAccess { through, others, cannot, notSure }

/// The kind of firewood burnt (backend `Firewood.Kind`).
enum WoodKind { hardwood, softwood, mixed, unknown }

enum WindExposure { open, some, lots }

/// Parts of the place the person does not want anything on (question 13). Left and right
/// are as seen from the street.
enum Zone { roofFront, roofBack, roofLeft, roofRight, roofWhole, frontYard, backYard, sideLeft, sideRight }

/// The parts of the plot around the house, which can be missing at someone's place.
const groundZones = [Zone.frontYard, Zone.backYard, Zone.sideLeft, Zone.sideRight];

/// Something new on the plot that the map does not show yet.
enum NewThingKind { building, pool, trees, other }

/// Whether something could go on the new thing (on a building's roof, say): [unsure] when
/// it may not bear it (light, temporary).
enum NewUse { yes, no, unsure }

/// How tall the new trees are: what matters for their shade.
enum TreeHeight { low, medium, tall }

/// The roof's shape, as picked over the 3D drawing of question 13.
enum RoofShape { gable, hip, flat }

/// The parts of each roof shape that can be kept free.
const roofZones = {
  RoofShape.gable: [Zone.roofFront, Zone.roofBack],
  RoofShape.hip: [Zone.roofFront, Zone.roofBack, Zone.roofLeft, Zone.roofRight],
  RoofShape.flat: [Zone.roofWhole],
};

enum ExcludeReason { unsafe, reach, looks, rules, plans }

/// The place being assessed.
@immutable
class AssessmentPlace {
  const AssessmentPlace({required this.lat, required this.lon, this.title = '', this.detail = ''});

  final double lat;
  final double lon;

  /// What the place is called ("Strada Memorandumului 12"); empty when no name was found.
  final String title;
  final String detail;

  Map<String, Object?> toJson() => {'lat': lat, 'lon': lon, 'title': title, 'detail': detail};

  static AssessmentPlace? fromJson(Object? json) {
    if (json is! Map) return null;
    return AssessmentPlace(
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      title: json['title'] as String? ?? '',
      detail: json['detail'] as String? ?? '',
    );
  }
}

/// Size of one free place (question 8b): a size by comparison, or the exact area.
class SpaceSize {
  AreaSize? size;
  double? exactM2;

  Map<String, Object?> toJson() => {'size': size?.name, 'm2': exactM2};

  static SpaceSize fromJson(Object? json) {
    final s = SpaceSize();
    if (json is Map) {
      s.size = _enum(AreaSize.values, json['size']);
      s.exactM2 = (json['m2'] as num?)?.toDouble();
    }
    return s;
  }
}

T? _enum<T extends Enum>(List<T> values, Object? name) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return null;
}

Set<T> _enumSet<T extends Enum>(List<T> values, Object? names) => {
      if (names is List)
        for (final n in names)
          if (_enum(values, n) case final T v) v,
    };

List<double?> _doubles(Object? list, int length) => [
      for (var i = 0; i < length; i++)
        list is List && i < list.length ? (list[i] as num?)?.toDouble() : null,
    ];

/// The answers of the home assessment. Kept while the person moves between the tabs, and
/// saved on the device, so someone who leaves to find a bill continues where they stopped.
class HomeAnswers extends ChangeNotifier {
  HomeAnswers() {
    final now = DateTime.now();
    // The last three full months, oldest first.
    months = [for (var k = 3; k >= 1; k--) (now.month - 1 - k) % 12];
  }

  static const _storageKey = 'assessment.home.v2';

  /// Where the person is: the id of the current screen.
  String screen = 'audience';

  // Every question starts unanswered: nothing is picked for the person, so an answer is
  // always theirs (decided with the team). Null or empty means "not answered yet".
  Audience? audience;
  AssessmentPlace? place;

  Set<Use> uses = {};

  BuildingType? type;
  int? floors;
  int? people;
  int? area;
  bool areaSet = false;

  BuildEra? era;
  Set<Renovation> renovations = {};
  Map<Renovation, RenovationAge> renovationAge = {};
  InsulationLevel? wallInsulation;
  InsulationLevel? roofInsulation;
  FloorInsulation? floorInsulation;
  WindowKind? windows;

  Set<Source> sources = {};

  /// Month indexes 0–11 of the three months asked about.
  List<int> months = [0, 1, 2];
  bool useAverage = false;
  List<double?> electricityKwh = [null, null, null];
  double? electricityAverageKwh;
  List<double?> paid = [null, null, null];
  double? paidAverage;
  String? currency;

  GasUnit gasUnit = GasUnit.kwh;
  List<double?> gasAmount = [null, null, null];
  List<double?> gasPaid = [null, null, null];

  double? firewoodM3;
  WoodKind? firewoodKind;

  /// Price of 1 m³ of firewood, in [currency].
  double? firewoodPrice;
  double? pelletsTonnes;
  double? gasBottlesPerMonth;
  double? districtPerMonth;


  Set<Space> spaces = {};
  Map<Space, SpaceSize> sizes = {};
  Facing? facing;

  Ownership? ownership;
  Fixer? fixer;
  HandsOn? handsOn;
  Priority? priority;

  Animals? animals;
  RiverAccess? river;
  bool? brook;
  WindExposure? wind;

  bool? excludeSomewhere;
  /// Only shapes the drawing of the exclude question; a gable roof is drawn until picked.
  RoofShape? roofShape;
  RoofShape get roofDrawn => roofShape ?? RoofShape.gable;
  Set<Zone> zones = {};
  /// Parts of the plot that this place does not have (no front yard, the house on the boundary).
  Set<Zone> missing = {};
  /// Question 14: something new that the map does not show yet, where, and whether it can be used.
  bool? newThing;
  NewThingKind? newKind;
  /// Where the new thing is, tapped on the map: latitude, longitude.
  double? newLat;
  double? newLon;

  /// Its size: by comparison, as a number of m², or drawn round on the map ([newOutline],
  /// whose area then goes into [newAreaM2]). Trees are asked their height instead.
  AreaSize? newSize;
  double? newAreaM2;
  List<List<double>> newOutline = [];
  TreeHeight? newTreeHeight;

  /// The outline was drawn by the person; otherwise it is a square of the size given,
  /// around the point marked.
  bool newOutlineDrawn = false;

  /// How far the outline is turned round its middle, degrees (clockwise): [newOutline] is
  /// kept as drawn, [newShape] is what the map shows.
  double newRotation = 0;

  /// How far the outline was moved off the roads, [latitude, longitude] degrees.
  List<double> newShift = const [0, 0];

  /// The roads around the place (half width kept free, m; line [lat, lon]), from the map.
  /// Not saved: the map gives them again.
  List<(double, List<List<double>>)> roads = const [];

  /// Counts the changes ([update] calls), so a notice can go with the next one.
  int changes = 0;

  /// The change ([changes]) in which the outline was last moved off a road; 0: never.
  int roadPushAt = 0;

  /// The outline is being drawn on the map right now (press and drag, as often as needed,
  /// until "Done"). Not saved: a refresh ends the drawing.
  bool drawingNew = false;

  /// What the outline was before the drawing started, for "Cancel".
  ({List<List<double>> outline, double? area, AreaSize? size, bool drawn, double rotation, List<double> shift})?
      _beforeDrawing;
  NewUse? newUsable;

  /// Only for a building or something else: nothing goes on a pool or on trees.
  bool get asksNewUse => newKind == NewThingKind.building || newKind == NewThingKind.other;
  Set<ExcludeReason> reasons = {};

  SpaceSize sizeOf(Space s) => sizes.putIfAbsent(s, SpaceSize.new);

  /// Typical sizes of a new thing, m²: small, medium, large.
  static List<int> typicalNewM2(NewThingKind? kind) => switch (kind) {
        NewThingKind.building => const [15, 40, 80],
        NewThingKind.pool => const [15, 30, 50],
        _ => const [10, 25, 50],
      };

  /// The new thing's area, m²: typed, drawn, or the typical one of the size picked.
  double? get newAreaShown {
    if (newAreaM2 != null) return newAreaM2;
    final size = newSize;
    if (size == null || size == AreaSize.none) return null;
    return typicalNewM2(newKind)[size.index].toDouble();
  }

  /// Unless the person drew it, the outline is a square of the size given, centred on the
  /// point marked (call after the point, the kind or the size changed).
  void squareNew() {
    if (newOutlineDrawn) return;
    final area = newAreaShown, lat = newLat, lon = newLon;
    if (area == null || area <= 0 || lat == null || lon == null || newKind == NewThingKind.trees) {
      newOutline = [];
      return;
    }
    final half = math.sqrt(area) / 2;
    const r = 6371000.0;
    final dLat = half / r * 180 / math.pi;
    final dLon = dLat / math.cos(lat * math.pi / 180);
    newOutline = [
      [lat - dLat, lon - dLon],
      [lat - dLat, lon + dLon],
      [lat + dLat, lon + dLon],
      [lat + dLat, lon - dLon],
    ];
    fitNewToRoads();
  }

  /// A size picked by comparison: the outline becomes a square of it.
  void setNewSize(AreaSize size) {
    newSize = size;
    newAreaM2 = null;
    newOutlineDrawn = false;
    squareNew();
  }

  /// An area typed in: the outline becomes a square of it.
  void setNewArea(double? m2) {
    newAreaM2 = m2;
    if (m2 != null) newSize = null;
    newOutlineDrawn = false;
    squareNew();
  }

  /// "Draw it on the map": from now on a drag draws the outline, until [endDrawing].
  void startDrawing() {
    _beforeDrawing = (
      outline: newOutline,
      area: newAreaM2,
      size: newSize,
      drawn: newOutlineDrawn,
      rotation: newRotation,
      shift: newShift,
    );
    drawingNew = true;
  }

  /// "Done" keeps what was drawn; "Cancel" ([keep] false) brings back the outline before.
  void endDrawing({required bool keep}) {
    final before = _beforeDrawing;
    if (!keep && before != null) {
      newOutline = before.outline;
      newAreaM2 = before.area;
      newSize = before.size;
      newOutlineDrawn = before.drawn;
      newRotation = before.rotation;
      newShift = before.shift;
    }
    _beforeDrawing = null;
    drawingNew = false;
  }

  /// A rectangle drawn on the map (corners [latitude, longitude]): its area replaces a size
  /// picked before. Drawing goes on until "Done".
  void setNewOutline(List<List<double>> corners) {
    newOutline = [for (final c in corners) List.of(c)];
    newAreaM2 = outlineArea(newOutline).roundToDouble();
    newSize = null;
    newOutlineDrawn = true;
    newRotation = 0;
    fitNewToRoads();
  }

  /// A new turn of the outline; it is moved off the roads again.
  void setNewRotation(double degrees) {
    newRotation = degrees;
    fitNewToRoads();
  }

  /// The roads around the place arrived from the map: the outline is moved off them.
  void setRoads(List<(double, List<List<double>>)> list) {
    roads = list;
    fitNewToRoads();
  }

  /// Moves the outline off the roads: nothing new stands on a road, so where the size given
  /// (or the drawing) would reach onto one, the outline is pushed back to the side of the
  /// road it is on, by as much as needed.
  void fitNewToRoads() {
    final before = newShift;
    final shape = _turned();
    if (shape.length < 3 || roads.isEmpty) {
      newShift = const [0, 0];
      return;
    }
    const r = 6371000.0;
    final lat0 = shape.first[0], lon0 = shape.first[1];
    final k = math.cos(lat0 * math.pi / 180);
    (double, double) local(List<double> c) =>
        ((c[1] - lon0) * math.pi / 180 * r * k, (c[0] - lat0) * math.pi / 180 * r);
    final pts = [for (final c in shape) local(c)];
    final segments = <((double, double), (double, double), double)>[
      for (final road in roads)
        for (var i = 0; i + 1 < road.$2.length; i++) (local(road.$2[i]), local(road.$2[i + 1]), road.$1),
    ];
    var sx = 0.0, sy = 0.0;
    const margin = 0.5;
    for (var round = 0; round < 8; round++) {
      var moved = false;
      for (final (a, b, half) in segments) {
        final dx = b.$1 - a.$1, dy = b.$2 - a.$2;
        final len = math.sqrt(dx * dx + dy * dy);
        if (len < 0.01) continue;
        final moving = [for (final p in pts) (p.$1 + sx, p.$2 + sy)];
        if (_distance(moving, a, b) >= half + margin) continue;
        // The side of the road the middle of the outline is on.
        var cx = 0.0, cy = 0.0;
        for (final p in moving) {
          cx += p.$1;
          cy += p.$2;
        }
        cx /= moving.length;
        cy /= moving.length;
        var nx = -dy / len, ny = dx / len;
        if ((cx - a.$1) * nx + (cy - a.$2) * ny < 0) {
          nx = -nx;
          ny = -ny;
        }
        var lowest = double.infinity;
        for (final p in moving) {
          lowest = math.min(lowest, (p.$1 - a.$1) * nx + (p.$2 - a.$2) * ny);
        }
        final push = half + margin - lowest;
        if (push > 0.01) {
          sx += nx * push;
          sy += ny * push;
          moved = true;
        }
      }
      if (!moved) break;
    }
    newShift = [sy / r * 180 / math.pi, sx / (r * k) * 180 / math.pi];
    // A new push (not the same one again, e.g. when the roads arrive for a saved outline).
    final moved = (newShift[0] - before[0]).abs() + (newShift[1] - before[1]).abs() > 1e-7;
    if (moved && sx * sx + sy * sy > 0.01) roadPushAt = changes;
  }

  /// Distance between a polygon (local metres) and a segment: 0 when they cross.
  static double _distance(List<(double, double)> poly, (double, double) a, (double, double) b) {
    double seg((double, double) p, (double, double) q, (double, double) x) {
      final dx = q.$1 - p.$1, dy = q.$2 - p.$2;
      final l2 = dx * dx + dy * dy;
      final t = l2 == 0 ? 0.0 : (((x.$1 - p.$1) * dx + (x.$2 - p.$2) * dy) / l2).clamp(0.0, 1.0);
      final ex = p.$1 + t * dx - x.$1, ey = p.$2 + t * dy - x.$2;
      return math.sqrt(ex * ex + ey * ey);
    }

    double cross((double, double) o, (double, double) p, (double, double) q) =>
        (p.$1 - o.$1) * (q.$2 - o.$2) - (p.$2 - o.$2) * (q.$1 - o.$1);
    var best = double.infinity;
    var inside = false;
    for (var i = 0; i < poly.length; i++) {
      final p = poly[i], q = poly[(i + 1) % poly.length];
      final d1 = cross(a, b, p), d2 = cross(a, b, q), d3 = cross(p, q, a), d4 = cross(p, q, b);
      if (((d1 > 0) != (d2 > 0)) && ((d3 > 0) != (d4 > 0))) return 0;
      best = math.min(best, math.min(seg(p, q, a), seg(p, q, b)));
      best = math.min(best, math.min(seg(a, b, p), seg(a, b, q)));
      // Point a inside the polygon (ray to the east).
      if ((p.$2 > a.$2) != (q.$2 > a.$2) && a.$1 < (q.$1 - p.$1) * (a.$2 - p.$2) / (q.$2 - p.$2) + p.$1) inside = !inside;
    }
    return inside ? 0 : best;
  }

  /// [newOutline] turned by [newRotation] round its middle and moved off the roads by
  /// [newShift]: what the map shows.
  List<List<double>> get newShape => [
        for (final c in _turned()) [c[0] + newShift[0], c[1] + newShift[1]],
      ];

  List<List<double>> _turned() {
    if (newRotation == 0 || newOutline.length < 3) return newOutline;
    var cLat = 0.0, cLon = 0.0;
    for (final c in newOutline) {
      cLat += c[0];
      cLon += c[1];
    }
    cLat /= newOutline.length;
    cLon /= newOutline.length;
    final k = math.cos(cLat * math.pi / 180);
    // Clockwise on the map: east goes south.
    final a = -newRotation * math.pi / 180;
    return [
      for (final c in newOutline)
        () {
          final x = (c[1] - cLon) * k, y = c[0] - cLat;
          final rx = x * math.cos(a) - y * math.sin(a), ry = x * math.sin(a) + y * math.cos(a);
          return [cLat + ry, cLon + rx / k];
        }(),
    ];
  }

  /// Area of an outline of [latitude, longitude] corners, m² (flat sums, fine for a plot).
  static double outlineArea(List<List<double>> corners) {
    if (corners.length < 3) return 0;
    const r = 6371000.0;
    final lat0 = corners.first[0] * math.pi / 180;
    final pts = [
      for (final c in corners)
        (r * (c[1] - corners.first[1]) * math.pi / 180 * math.cos(lat0), r * (c[0] - corners.first[0]) * math.pi / 180),
    ];
    var sum = 0.0;
    for (var i = 0; i < pts.length; i++) {
      final a = pts[i], b = pts[(i + 1) % pts.length];
      sum += a.$1 * b.$2 - b.$1 * a.$2;
    }
    return sum.abs() / 2;
  }

  /// The outline being drawn, as GeoJSON for the map (corners, the line, the area); null
  /// when there is none.
  String? get newOutlineGeoJson {
    if (newOutline.isEmpty) return null;
    final ring = [for (final c in newShape) [c[1], c[0]]];
    return jsonEncode({
      'type': 'FeatureCollection',
      'features': [
        if (ring.length >= 3)
          {
            'type': 'Feature',
            'properties': <String, Object?>{},
            'geometry': {
              'type': 'Polygon',
              'coordinates': [
                [...ring, ring.first],
              ],
            },
          }
        else if (ring.length == 2)
          {
            'type': 'Feature',
            'properties': <String, Object?>{},
            'geometry': {'type': 'LineString', 'coordinates': ring},
          },
        for (final c in ring)
          {
            'type': 'Feature',
            'properties': <String, Object?>{},
            'geometry': {'type': 'Point', 'coordinates': c},
          },
      ],
    });
  }

  void update(void Function(HomeAnswers a) change) {
    changes++;
    change(this);
    notifyListeners();
    _scheduleSave();
  }

  // ------------------------------------------------------------- rules

  bool get heats => uses.contains(Use.heating) || uses.contains(Use.hotWater);
  bool get oldBuilding => era == BuildEra.before1960 || era == BuildEra.from1960 || era == BuildEra.unknown;
  bool get hasFuels =>
      sources.contains(Source.wood) || sources.contains(Source.gasBottles) || sources.contains(Source.district);
  /// Marks a part as kept free, or (with [isMissing]) as not there; a part is never both.
  void markZone(Zone z, {required bool isMissing}) => update((a) {
        final target = isMissing ? a.missing : a.zones;
        final other = isMissing ? a.zones : a.missing;
        if (isMissing && !groundZones.contains(z)) return;
        target.contains(z) ? target.remove(z) : target.add(z);
        other.remove(z);
      });

  /// A new roof shape drops the marks on roof parts it does not have.
  void setRoofShape(RoofShape shape) => update((a) {
        a.roofShape = shape;
        a.zones.removeWhere((z) => roofZones.values.any((l) => l.contains(z)) && !roofZones[shape]!.contains(z));
      });

  /// Whether there is a yard or land around the building: open land, or a garden that is
  /// not "I don't have a garden or yard". Without one, the last questions show no yard.
  bool get hasYard =>
      type != BuildingType.flat &&
      (spaces.contains(Space.land) ||
          ((spaces.contains(Space.garden) || spaces.contains(Space.notSure)) && sizes[Space.garden]?.size != AreaSize.none));

  bool get hasPlaces => spaces.isNotEmpty && !spaces.contains(Space.nowhere);

  void setFloors(int value) => update((a) => a.floors = value);

  /// A house and a flat have different places: the places picked go with the type.
  void setType(BuildingType value) => update((a) {
        if (a.type != value) a.spaces = {};
        a.type = value;
      });

  /// "Nothing yet" and "Nowhere" exclude every other answer, and the other way round.
  void toggleSource(Source s) => update((a) {
        if (s == Source.nothing) {
          a.sources = a.sources.contains(s) ? {} : {s};
        } else {
          a.sources.remove(Source.nothing);
          a.sources.contains(s) ? a.sources.remove(s) : a.sources.add(s);
        }
      });

  void toggleSpace(Space s) => update((a) {
        if (s == Space.nowhere) {
          a.spaces = a.spaces.contains(s) ? {} : {s};
        } else {
          a.spaces.remove(Space.nowhere);
          a.spaces.contains(s) ? a.spaces.remove(s) : a.spaces.add(s);
        }
      });

  void toggleRenovation(Renovation r) => update((a) {
        if (r == Renovation.none || r == Renovation.unknown) {
          a.renovations = a.renovations.contains(r) ? {} : {r};
        } else {
          a.renovations.remove(Renovation.none);
          a.renovations.remove(Renovation.unknown);
          if (a.renovations.contains(r)) {
            a.renovations.remove(r);
          } else {
            a.renovations.add(r);
            // A renovated wall or roof is insulated: an earlier "not insulated" is asked again.
            if (r == Renovation.walls && a.wallInsulation == InsulationLevel.none) a.wallInsulation = null;
            if (r == Renovation.roof && a.roofInsulation == InsulationLevel.none) a.roofInsulation = null;
          }
        }
      });

  // ------------------------------------------------------------- saving

  Timer? _save;

  void _scheduleSave() {
    _save?.cancel();
    _save = Timer(const Duration(milliseconds: 600), () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_storageKey, jsonEncode(toJson()));
      } catch (_) {
        // Storage can be off (private window): the answers still live for this visit.
      }
    });
  }

  /// "I made a mistake": every answer back to its starting value, and the first question.
  void reset() {
    final fresh = HomeAnswers();
    _fromJson(jsonDecode(jsonEncode(fresh.toJson())) as Map<String, dynamic>);
    fresh.dispose();
    notifyListeners();
    _scheduleSave();
  }

  /// Brings back the answers saved on this device, if any.
  Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null) return;
      _fromJson(jsonDecode(raw) as Map<String, dynamic>);
      notifyListeners();
    } catch (_) {
      // A broken or older save: start fresh.
    }
  }

  @override
  void dispose() {
    _save?.cancel();
    super.dispose();
  }

  Map<String, Object?> toJson() => {
        'screen': screen,
        'audience': audience?.name,
        'place': place?.toJson(),
        'uses': [for (final u in uses) u.name],
        'type': type?.name,
        'floors': floors,
        'people': people,
        'area': area,
        'areaSet': areaSet,
        'era': era?.name,
        'renovations': [for (final r in renovations) r.name],
        'renovationAge': {for (final e in renovationAge.entries) e.key.name: e.value.name},
        'wallInsulation': wallInsulation?.name,
        'roofInsulation': roofInsulation?.name,
        'floorInsulation': floorInsulation?.name,
        'windows': windows?.name,
        'sources': [for (final s in sources) s.name],
        'months': months,
        'useAverage': useAverage,
        'electricityKwh': electricityKwh,
        'electricityAverageKwh': electricityAverageKwh,
        'paid': paid,
        'paidAverage': paidAverage,
        'currency': currency,
        'gasUnit': gasUnit.name,
        'gasAmount': gasAmount,
        'gasPaid': gasPaid,
        'firewoodM3': firewoodM3,
        'firewoodKind': firewoodKind?.name,
        'firewoodPrice': firewoodPrice,
        'pelletsTonnes': pelletsTonnes,
        'gasBottlesPerMonth': gasBottlesPerMonth,
        'districtPerMonth': districtPerMonth,
        'spaces': [for (final s in spaces) s.name],
        'sizes': {for (final e in sizes.entries) e.key.name: e.value.toJson()},
        'facing': facing?.name,
        'ownership': ownership?.name,
        'fixer': fixer?.name,
        'handsOn': handsOn?.name,
        'priority': priority?.name,
        'animals': animals?.name,
        'river': river?.name,
        'brook': brook,
        'wind': wind?.name,
        'excludeSomewhere': excludeSomewhere,
        'roofShape': roofShape?.name,
        'zones': [for (final z in zones) z.name],
        'missing': [for (final z in missing) z.name],
        'newThing': newThing,
        'newKind': newKind?.name,
        'newUsable': newUsable?.name,
        'newLat': newLat,
        'newLon': newLon,
        'newSize': (_beforeDrawing == null ? newSize : _beforeDrawing!.size)?.name,
        'newAreaM2': _beforeDrawing == null ? newAreaM2 : _beforeDrawing!.area,
        // While drawing, what was there before is kept: a drawing counts once "Done".
        'newOutline': _beforeDrawing?.outline ?? newOutline,
        'newOutlineDrawn': _beforeDrawing?.drawn ?? newOutlineDrawn,
        'newRotation': _beforeDrawing?.rotation ?? newRotation,
        'newShift': _beforeDrawing?.shift ?? newShift,
        'newTreeHeight': newTreeHeight?.name,
        'reasons': [for (final r in reasons) r.name],
      };

  void _fromJson(Map<String, dynamic> j) {
    screen = j['screen'] as String? ?? screen;
    audience = _enum(Audience.values, j['audience']);
    place = AssessmentPlace.fromJson(j['place']);
    uses = _enumSet(Use.values, j['uses']);
    type = _enum(BuildingType.values, j['type']);
    floors = j['floors'] as int?;
    people = j['people'] as int?;
    area = j['area'] as int?;
    areaSet = j['areaSet'] as bool? ?? areaSet;
    era = _enum(BuildEra.values, j['era']);
    renovations = _enumSet(Renovation.values, j['renovations']);
    renovationAge = {
      if (j['renovationAge'] is Map)
        for (final e in (j['renovationAge'] as Map).entries)
          if ((_enum(Renovation.values, e.key), _enum(RenovationAge.values, e.value)) case (final Renovation r, final RenovationAge a)) r: a,
    };
    wallInsulation = _enum(InsulationLevel.values, j['wallInsulation']);
    roofInsulation = _enum(InsulationLevel.values, j['roofInsulation']);
    floorInsulation = _enum(FloorInsulation.values, j['floorInsulation']);
    windows = _enum(WindowKind.values, j['windows']);
    sources = _enumSet(Source.values, j['sources']);
    if (j['months'] is List && (j['months'] as List).length == 3) months = [for (final m in j['months'] as List) (m as num).toInt()];
    useAverage = j['useAverage'] as bool? ?? useAverage;
    electricityKwh = _doubles(j['electricityKwh'], 3);
    electricityAverageKwh = (j['electricityAverageKwh'] as num?)?.toDouble();
    paid = _doubles(j['paid'], 3);
    paidAverage = (j['paidAverage'] as num?)?.toDouble();
    currency = j['currency'] as String?;
    gasUnit = _enum(GasUnit.values, j['gasUnit']) ?? gasUnit;
    gasAmount = _doubles(j['gasAmount'], 3);
    gasPaid = _doubles(j['gasPaid'], 3);
    firewoodM3 = (j['firewoodM3'] as num?)?.toDouble();
    firewoodKind = _enum(WoodKind.values, j['firewoodKind']);
    firewoodPrice = (j['firewoodPrice'] as num?)?.toDouble();
    pelletsTonnes = (j['pelletsTonnes'] as num?)?.toDouble();
    gasBottlesPerMonth = (j['gasBottlesPerMonth'] as num?)?.toDouble();
    districtPerMonth = (j['districtPerMonth'] as num?)?.toDouble();
    spaces = _enumSet(Space.values, j['spaces']);
    sizes = {
      if (j['sizes'] is Map)
        for (final e in (j['sizes'] as Map).entries)
          if (_enum(Space.values, e.key) case final Space s) s: SpaceSize.fromJson(e.value),
    };
    facing = _enum(Facing.values, j['facing']);
    ownership = _enum(Ownership.values, j['ownership']);
    fixer = _enum(Fixer.values, j['fixer']);
    handsOn = _enum(HandsOn.values, j['handsOn']);
    priority = _enum(Priority.values, j['priority']);
    animals = _enum(Animals.values, j['animals']);
    river = _enum(RiverAccess.values, j['river']);
    brook = j['brook'] as bool?;
    wind = _enum(WindExposure.values, j['wind']);
    excludeSomewhere = j['excludeSomewhere'] as bool?;
    roofShape = _enum(RoofShape.values, j['roofShape']);
    zones = _enumSet(Zone.values, j['zones']);
    missing = _enumSet(Zone.values, j['missing']);
    newThing = j['newThing'] as bool?;
    newKind = _enum(NewThingKind.values, j['newKind']);
    newUsable = switch (j['newUsable']) {
      true => NewUse.yes,
      false => NewUse.no,
      final Object? v => _enum(NewUse.values, v),
    };
    newLat = (j['newLat'] as num?)?.toDouble();
    newLon = (j['newLon'] as num?)?.toDouble();
    newSize = _enum(AreaSize.values, j['newSize']);
    newAreaM2 = (j['newAreaM2'] as num?)?.toDouble();
    newOutline = [
      if (j['newOutline'] is List)
        for (final c in j['newOutline'] as List)
          if (c is List && c.length == 2) [(c[0] as num).toDouble(), (c[1] as num).toDouble()],
    ];
    newTreeHeight = _enum(TreeHeight.values, j['newTreeHeight']);
    newOutlineDrawn = j['newOutlineDrawn'] as bool? ?? false;
    newRotation = (j['newRotation'] as num?)?.toDouble() ?? 0;
    newShift = j['newShift'] is List && (j['newShift'] as List).length == 2
        ? [for (final v in j['newShift'] as List) (v as num).toDouble()]
        : const [0, 0];
    drawingNew = false;
    _beforeDrawing = null;
    reasons = _enumSet(ExcludeReason.values, j['reasons']);
  }
}
