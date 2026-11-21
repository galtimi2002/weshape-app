import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weshape_app/core/units/units.dart';
import 'package:weshape_app/features/assessment/home_answers.dart';

void main() {
  group('full independence (docs/decisions/2026-11-19-question-changes.md)', () {
    test('asked for every answer but most days for hours or longer', () {
      final a = HomeAnswers();
      expect(a.asksIndependence, isFalse); // nothing answered yet
      a.cuts = PowerCuts.never;
      expect(a.asksIndependence, isTrue);
      for (final cuts in [PowerCuts.hardlyEver, PowerCuts.monthly]) {
        a.cuts = cuts;
        a.cutLength = null;
        expect(a.asksIndependence, isFalse, reason: 'length first');
        for (final length in CutLength.values) {
          a.cutLength = length;
          expect(a.asksIndependence, isTrue, reason: '$cuts $length');
        }
      }
      a.cuts = PowerCuts.mostDays;
      a.cutLength = CutLength.underHour;
      expect(a.asksIndependence, isTrue);
      a.cutLength = CutLength.hours;
      expect(a.asksIndependence, isFalse);
      a.cutLength = CutLength.overDay;
      expect(a.asksIndependence, isFalse);
      a.dispose();
    });
  });

  group('animals, food waste and crop residue', () {
    test('"None" stands alone; each answer needs its numbers', () {
      final a = HomeAnswers();
      expect(a.animalsComplete, isFalse);
      a.toggleAnimals(Animals.none);
      expect(a.animalsComplete, isTrue);
      a.toggleAnimals(Animals.few);
      expect(a.animals, {Animals.few});
      expect(a.animalsComplete, isFalse);
      a.animalCounts[AnimalKind.cattle] = 2;
      expect(a.animalsComplete, isTrue);
      a.toggleAnimals(Animals.foodWaste);
      expect(a.animalsComplete, isFalse);
      a.foodWastePerWeek = 5;
      a.foodWasteUnit = MassUnit.kg;
      expect(a.animalsComplete, isTrue);
      a.toggleAnimals(Animals.crops);
      a.cropArea[CropKind.maize] = null;
      expect(a.animalsComplete, isFalse);
      a.cropArea[CropKind.maize] = 2;
      expect(a.animalsComplete, isFalse, reason: 'unit missing');
      a.cropUnit = AreaUnit.hectare;
      expect(a.animalsComplete, isTrue);
      a.toggleAnimals(Animals.none);
      expect(a.animals, {Animals.none});
      a.dispose();
    });
  });

  group('parts kept free', () {
    test('a reason; with something there what it is and the sizes asked', () {
      final k = ZoneKeep();
      expect(k.complete, isFalse);
      k.reason = KeepReason.rules;
      expect(k.complete, isTrue);
      k.reason = KeepReason.somethingThere;
      expect(k.complete, isFalse);
      k.things.add(KeepThing.chimney);
      expect(k.complete, isTrue, reason: 'a chimney needs no size');
      k.things.add(KeepThing.window);
      expect(k.complete, isFalse);
      k.windowW = 1;
      k.windowH = 1.2;
      expect(k.complete, isTrue);
    });
  });

  test('people are asked only with hot water', () {
    final a = HomeAnswers();
    a.uses = {Use.heating};
    expect(a.asksPeople, isFalse);
    a.uses = {Use.hotWater};
    expect(a.asksPeople, isTrue);
    a.dispose();
  });

  test('the new answers go into the save', () {
    final a = HomeAnswers()
      ..material = BuildMaterial.wood
      ..bottleSize = 26
      ..bottleUnit = BottleUnit.litre
      ..animals = {Animals.few, Animals.crops}
      ..animalCounts = {AnimalKind.pigs: 3}
      ..cropArea = {CropKind.wheatBarley: 1.5}
      ..cropUnit = AreaUnit.acre
      ..keeps = {Zone.roofFront: ZoneKeep()..reason = KeepReason.somethingThere..things = {KeepThing.chimney}};
    final json = a.toJson();
    expect(json['material'], 'wood');
    expect(json['animals'], containsAll(['few', 'crops']));
    expect((json['keeps'] as Map)['roofFront'], isA<Map>());
    a.dispose();
  });

  test('firewood saved before units could be picked comes back as stacked m³', () async {
    SharedPreferences.setMockInitialValues({
      'assessment.home.v2': jsonEncode({'firewoodM3': 8, 'firewoodPrice': 300}),
    });
    final a = HomeAnswers();
    await a.restore();
    expect(a.firewoodAmount, 8);
    expect(a.firewoodUnit, WoodUnit.stacked);
    expect(a.firewoodPrice, 300);
    a.dispose();
  });

  test('the units picked go into the save and come back', () async {
    final a = HomeAnswers()
      ..firewoodAmount = 40
      ..firewoodUnit = WoodUnit.quintal
      ..bottleSize = 21
      ..bottleUnit = BottleUnit.litre
      ..bottleLitres = BottleLitres.gas
      ..gasUnit = GasUnit.mj
      ..cropUnit = AreaUnit.hold;
    SharedPreferences.setMockInitialValues({'assessment.home.v2': jsonEncode(a.toJson())});
    final b = HomeAnswers();
    await b.restore();
    expect(b.firewoodAmount, 40);
    expect(b.firewoodUnit, WoodUnit.quintal);
    expect(b.bottleLitres, BottleLitres.gas);
    expect(b.gasUnit, GasUnit.mj);
    expect(b.cropUnit, AreaUnit.hold);
    a.dispose();
    b.dispose();
  });

  test('pellets: saved as tonnes before come back as tonnes; bags and their weight are saved', () async {
    SharedPreferences.setMockInitialValues({'assessment.home.v2': jsonEncode({'pelletsTonnes': 2})});
    final a = HomeAnswers();
    await a.restore();
    expect(a.pelletsAmount, 2);
    expect(a.pelletsUnit, PelletUnit.tonne);

    a
      ..pelletsAmount = 120
      ..pelletsUnit = PelletUnit.bag
      ..pelletBagKg = 25;
    SharedPreferences.setMockInitialValues({'assessment.home.v2': jsonEncode(a.toJson())});
    final b = HomeAnswers();
    await b.restore();
    expect(b.pelletsAmount, 120);
    expect(b.pelletsUnit, PelletUnit.bag);
    expect(b.pelletBagKg, 25);
    a.dispose();
    b.dispose();
  });

  test('an assessment keeps the units it was started in; starting again forgets them', () async {
    final a = HomeAnswers();
    expect(a.started, isFalse);
    a
      ..unitSystem = UnitSystem.us
      ..audience = Audience.home;
    expect(a.started, isTrue);
    SharedPreferences.setMockInitialValues({'assessment.home.v2': jsonEncode(a.toJson())});
    final b = HomeAnswers();
    await b.restore();
    expect(b.unitSystem, UnitSystem.us);
    b.reset();
    expect(b.unitSystem, isNull);
    expect(b.started, isFalse);
    a.dispose();
    b.dispose();
  });

  test('the gas bill unit starts on m³ and keeps what the person picks', () async {
    final a = HomeAnswers();
    expect(a.gasUnit, GasUnit.m3);
    a.gasUnit = GasUnit.kwh;
    SharedPreferences.setMockInitialValues({'assessment.home.v2': jsonEncode(a.toJson())});
    final b = HomeAnswers();
    await b.restore();
    expect(b.gasUnit, GasUnit.kwh);
    a.dispose();
    b.dispose();
  });

  test('pellets are a source of their own; old saves with pellets under firewood get it', () async {
    SharedPreferences.setMockInitialValues({
      'assessment.home.v2': jsonEncode({'sources': ['wood'], 'pelletsTonnes': 2, 'firewoodM3': 0}),
    });
    final a = HomeAnswers();
    await a.restore();
    expect(a.sources, containsAll([Source.wood, Source.pellets]));

    SharedPreferences.setMockInitialValues({'assessment.home.v2': jsonEncode({'sources': ['wood'], 'firewoodM3': 8})});
    final b = HomeAnswers();
    await b.restore();
    expect(b.sources, {Source.wood});
    a.dispose();
    b.dispose();
  });

  test('the roof is in play when it is picked as a free space, or the person is not sure', () {
    final a = HomeAnswers();
    expect(a.roofInPlay, isFalse);
    a.spaces = {Space.garden};
    expect(a.roofInPlay, isFalse);
    a.spaces = {Space.roof};
    expect(a.roofInPlay, isTrue);
    a.spaces = {Space.notSure};
    expect(a.roofInPlay, isTrue);
    a.dispose();
  });

  test('yearly totals, and district heat with its unit, are saved and come back', () async {
    final a = HomeAnswers()
      ..useYear = true
      ..electricityYearKwh = 3200
      ..paidYear = 2400
      ..gasUseYear = true
      ..gasYearAmount = 1100
      ..gasYearPaid = 3000
      ..districtHeatAmount = 1.2
      ..districtUnit = DistrictUnit.gcal;
    SharedPreferences.setMockInitialValues({'assessment.home.v2': jsonEncode(a.toJson())});
    final b = HomeAnswers();
    await b.restore();
    expect(b.useYear, isTrue);
    expect(b.electricityYearKwh, 3200);
    expect(b.paidYear, 2400);
    expect(b.gasUseYear, isTrue);
    expect(b.gasYearAmount, 1100);
    expect(b.gasYearPaid, 3000);
    expect(b.districtHeatAmount, 1.2);
    expect(b.districtUnit, DistrictUnit.gcal);
    expect(b.districtNotOnBill, isFalse);
    a.dispose();
    b.dispose();
  });
}
