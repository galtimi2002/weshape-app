import 'dart:math' as math;

import 'package:flutter/foundation.dart';

enum BuildingType { house, flat }

enum BuildEra { before1960, from1960, from1990, from2010 }

enum WallType { brick, panel, aerated, wood, stone }

enum Insulation { none, thin, thick }

enum Glazing { single, double, triple }

enum Heating { gas, wood, electric, district, heatPump }

enum Space { roof, garden, land, stream, balcony }

enum RoofSize { small, medium, large }

enum Facing { south, eastWest, north }

enum Aim { bills, independence, emissions }

/// The place being assessed.
@immutable
class AssessmentPlace {
  const AssessmentPlace({required this.lat, required this.lon, this.title = '', this.detail = ''});

  final double lat;
  final double lon;

  /// What the place is called ("Strada Memorandumului 12"); empty when no name was found.
  final String title;
  final String detail;
}

/// The answers of the home assessment, kept while the person moves between the tabs.
/// The starting values are a typical house, so every step can be skipped.
class HomeAnswers extends ChangeNotifier {
  /// 0 is the start page, 1–6 the questions.
  int step = 0;

  AssessmentPlace? place;

  BuildingType type = BuildingType.house;
  int floors = 2;
  int people = 4;
  int area = 120;

  /// The area was moved by hand, so floors no longer change it.
  bool areaSet = false;

  BuildEra era = BuildEra.from1960;
  WallType wall = WallType.brick;
  Insulation insulation = Insulation.none;
  Glazing glazing = Glazing.double;

  /// "I don't know": the condition is the typical house of the area.
  bool typicalBuilding = false;

  Heating heating = Heating.gas;

  /// kWh a month from a bill; Romania averages about 1,800 kWh a year per home (Odyssee-Mure).
  int monthlyKwh = 150;
  bool useKnown = true;

  Set<Space> spaces = {Space.roof, Space.garden};
  RoofSize roofSize = RoofSize.medium;
  Facing facing = Facing.south;
  Aim aim = Aim.bills;

  void update(void Function(HomeAnswers a) change) {
    change(this);
    notifyListeners();
  }

  /// Footprint × floors, until the person sets the area.
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

  void toggleSpace(Space s) => update((a) => a.spaces.contains(s) ? a.spaces.remove(s) : a.spaces.add(s));

  /// Yearly use when no bill is at hand: Romanian homes, about 2.6 people each.
  int get estimatedYearlyKwh => ((900 + 350 * math.min(people, 5)) / 100).round() * 100;

  int get yearlyKwh => useKnown ? monthlyKwh * 12 : estimatedYearlyKwh;
}
