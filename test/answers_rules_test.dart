import 'package:flutter_test/flutter_test.dart';
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
      a.cropUnit = LandUnit.hectare;
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
      ..cropUnit = LandUnit.acre
      ..keeps = {Zone.roofFront: ZoneKeep()..reason = KeepReason.somethingThere..things = {KeepThing.chimney}};
    final json = a.toJson();
    expect(json['material'], 'wood');
    expect(json['animals'], containsAll(['few', 'crops']));
    expect((json['keeps'] as Map)['roofFront'], isA<Map>());
    a.dispose();
  });
}
