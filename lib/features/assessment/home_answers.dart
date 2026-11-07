import 'dart:async';
import 'dart:convert';

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
enum Source { mains, pipedGas, district, gasBottles, wood, generator, nothing, solarPanels, solarWater, heatPump, battery, smallWind, other }

const outsideSources = [Source.mains, Source.pipedGas, Source.district, Source.gasBottles, Source.wood, Source.generator, Source.nothing];
const ownSources = [Source.solarPanels, Source.solarWater, Source.heatPump, Source.battery, Source.smallWind, Source.other];

enum PowerCuts { never, hardlyEver, monthly, mostDays }

enum GasUnit { m3, kwh }

/// Where there is free space (question 8, pick any; [nowhere] stands alone).
enum Space { roof, garden, land, balcony, notSure, nowhere }

/// [none]: only for the garden, when someone who was not sure has no garden or yard after all.
enum AreaSize { small, medium, large, none }

enum Facing { south, eastWest, north, flat }

enum Ownership { own, building, rent, shared }

enum Fixer { self, technician, installer, unknown }

enum HandsOn { none, little, regular }

enum Priority { upfront, running, reliable, environment, balanced }

enum Animals { few, herd, foodWaste, none }

enum RiverAccess { through, others, cannot, notSure }

enum WindExposure { open, some, lots }

/// Parts of the place the person does not want anything on (question 13). Left and right
/// are as seen from the street.
enum Zone { roofFront, roofBack, roofLeft, roofRight, roofWhole, frontYard, backYard, sideLeft, sideRight }

/// The parts of the plot around the house, which can be missing at someone's place.
const groundZones = [Zone.frontYard, Zone.backYard, Zone.sideLeft, Zone.sideRight];

/// Something new on the plot that the map does not show yet.
enum NewThingKind { building, pool, trees, other }

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

  Audience audience = Audience.home;
  AssessmentPlace? place;

  Set<Use> uses = {Use.appliances};

  BuildingType type = BuildingType.house;
  int floors = 2;
  int people = 4;
  int area = 120;
  bool areaSet = false;

  BuildEra era = BuildEra.from1960;
  Set<Renovation> renovations = {};
  Map<Renovation, RenovationAge> renovationAge = {};
  InsulationLevel wallInsulation = InsulationLevel.none;
  InsulationLevel roofInsulation = InsulationLevel.none;
  FloorInsulation floorInsulation = FloorInsulation.none;
  WindowKind windows = WindowKind.doubleOld;

  Set<Source> sources = {Source.mains};
  PowerCuts cuts = PowerCuts.hardlyEver;

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
  double? pelletsTonnes;
  double? gasBottlesPerMonth;
  double? districtPerMonth;

  bool? dayNightTariff;
  double? exportedKwh;

  Set<Space> spaces = {Space.roof, Space.garden};
  Map<Space, SpaceSize> sizes = {};
  Facing facing = Facing.south;

  Ownership ownership = Ownership.own;
  Fixer fixer = Fixer.technician;
  HandsOn handsOn = HandsOn.little;
  Priority priority = Priority.balanced;

  Animals? animals;
  RiverAccess? river;
  bool? brook;
  WindExposure? wind;

  bool? excludeSomewhere;
  RoofShape roofShape = RoofShape.gable;
  Set<Zone> zones = {};
  /// Parts of the plot that this place does not have (no front yard, the house on the boundary).
  Set<Zone> missing = {};
  /// Question 14: something new that the map does not show yet, where, and whether it can be used.
  bool? newThing;
  NewThingKind? newKind;
  Zone? newWhere;
  bool? newUsable;
  Set<ExcludeReason> reasons = {};

  SpaceSize sizeOf(Space s) => sizes.putIfAbsent(s, SpaceSize.new);

  void update(void Function(HomeAnswers a) change) {
    change(this);
    notifyListeners();
    _scheduleSave();
  }

  // ------------------------------------------------------------- rules

  bool get heats => uses.contains(Use.heating) || uses.contains(Use.hotWater);
  bool get oldBuilding => era == BuildEra.before1960 || era == BuildEra.from1960 || era == BuildEra.unknown;
  bool get hasGrid => sources.contains(Source.mains) || sources.contains(Source.generator);
  bool get hasSolar => sources.contains(Source.solarPanels);
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

  void setFloors(int value) => update((a) {
        final perFloor = a.area / a.floors;
        a.floors = value;
        if (!a.areaSet && a.type == BuildingType.house) a.area = (perFloor * value / 5).round() * 5;
      });

  void setType(BuildingType value) => update((a) {
        a.type = value;
        a.spaces = value == BuildingType.flat ? {Space.balcony} : {Space.roof, Space.garden};
        if (!a.areaSet) a.area = value == BuildingType.flat ? 60 : 120;
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
            a.renovationAge.putIfAbsent(r, () => RenovationAge.middle);
            // A renovated wall or roof starts as insulated: only the thickness is left to ask.
            if (r == Renovation.walls && a.wallInsulation == InsulationLevel.none) a.wallInsulation = InsulationLevel.thin;
            if (r == Renovation.roof && a.roofInsulation == InsulationLevel.none) a.roofInsulation = InsulationLevel.thin;
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
        'audience': audience.name,
        'place': place?.toJson(),
        'uses': [for (final u in uses) u.name],
        'type': type.name,
        'floors': floors,
        'people': people,
        'area': area,
        'areaSet': areaSet,
        'era': era.name,
        'renovations': [for (final r in renovations) r.name],
        'renovationAge': {for (final e in renovationAge.entries) e.key.name: e.value.name},
        'wallInsulation': wallInsulation.name,
        'roofInsulation': roofInsulation.name,
        'floorInsulation': floorInsulation.name,
        'windows': windows.name,
        'sources': [for (final s in sources) s.name],
        'cuts': cuts.name,
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
        'pelletsTonnes': pelletsTonnes,
        'gasBottlesPerMonth': gasBottlesPerMonth,
        'districtPerMonth': districtPerMonth,
        'dayNightTariff': dayNightTariff,
        'exportedKwh': exportedKwh,
        'spaces': [for (final s in spaces) s.name],
        'sizes': {for (final e in sizes.entries) e.key.name: e.value.toJson()},
        'facing': facing.name,
        'ownership': ownership.name,
        'fixer': fixer.name,
        'handsOn': handsOn.name,
        'priority': priority.name,
        'animals': animals?.name,
        'river': river?.name,
        'brook': brook,
        'wind': wind?.name,
        'excludeSomewhere': excludeSomewhere,
        'roofShape': roofShape.name,
        'zones': [for (final z in zones) z.name],
        'missing': [for (final z in missing) z.name],
        'newThing': newThing,
        'newKind': newKind?.name,
        'newUsable': newUsable,
        'newWhere': newWhere?.name,
        'reasons': [for (final r in reasons) r.name],
      };

  void _fromJson(Map<String, dynamic> j) {
    screen = j['screen'] as String? ?? screen;
    audience = _enum(Audience.values, j['audience']) ?? audience;
    place = AssessmentPlace.fromJson(j['place']);
    uses = _enumSet(Use.values, j['uses']);
    type = _enum(BuildingType.values, j['type']) ?? type;
    floors = j['floors'] as int? ?? floors;
    people = j['people'] as int? ?? people;
    area = j['area'] as int? ?? area;
    areaSet = j['areaSet'] as bool? ?? areaSet;
    era = _enum(BuildEra.values, j['era']) ?? era;
    renovations = _enumSet(Renovation.values, j['renovations']);
    renovationAge = {
      if (j['renovationAge'] is Map)
        for (final e in (j['renovationAge'] as Map).entries)
          if ((_enum(Renovation.values, e.key), _enum(RenovationAge.values, e.value)) case (final Renovation r, final RenovationAge a)) r: a,
    };
    wallInsulation = _enum(InsulationLevel.values, j['wallInsulation']) ?? wallInsulation;
    roofInsulation = _enum(InsulationLevel.values, j['roofInsulation']) ?? roofInsulation;
    floorInsulation = _enum(FloorInsulation.values, j['floorInsulation']) ?? floorInsulation;
    windows = _enum(WindowKind.values, j['windows']) ?? windows;
    sources = _enumSet(Source.values, j['sources']);
    cuts = _enum(PowerCuts.values, j['cuts']) ?? cuts;
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
    pelletsTonnes = (j['pelletsTonnes'] as num?)?.toDouble();
    gasBottlesPerMonth = (j['gasBottlesPerMonth'] as num?)?.toDouble();
    districtPerMonth = (j['districtPerMonth'] as num?)?.toDouble();
    dayNightTariff = j['dayNightTariff'] as bool?;
    exportedKwh = (j['exportedKwh'] as num?)?.toDouble();
    spaces = _enumSet(Space.values, j['spaces']);
    sizes = {
      if (j['sizes'] is Map)
        for (final e in (j['sizes'] as Map).entries)
          if (_enum(Space.values, e.key) case final Space s) s: SpaceSize.fromJson(e.value),
    };
    facing = _enum(Facing.values, j['facing']) ?? facing;
    ownership = _enum(Ownership.values, j['ownership']) ?? ownership;
    fixer = _enum(Fixer.values, j['fixer']) ?? fixer;
    handsOn = _enum(HandsOn.values, j['handsOn']) ?? handsOn;
    priority = _enum(Priority.values, j['priority']) ?? priority;
    animals = _enum(Animals.values, j['animals']);
    river = _enum(RiverAccess.values, j['river']);
    brook = j['brook'] as bool?;
    wind = _enum(WindExposure.values, j['wind']);
    excludeSomewhere = j['excludeSomewhere'] as bool?;
    roofShape = _enum(RoofShape.values, j['roofShape']) ?? roofShape;
    zones = _enumSet(Zone.values, j['zones']);
    missing = _enumSet(Zone.values, j['missing']);
    newThing = j['newThing'] as bool?;
    newKind = _enum(NewThingKind.values, j['newKind']);
    newUsable = j['newUsable'] as bool?;
    newWhere = _enum(Zone.values, j['newWhere']);
    reasons = _enumSet(ExcludeReason.values, j['reasons']);
  }
}
