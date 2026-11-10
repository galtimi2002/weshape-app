import 'dart:convert';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:weshape_app/core/models/building.dart';
import 'package:weshape_app/features/assessment/home_answers.dart';
import 'package:weshape_app/features/home/map/map_peek.dart';

/// The building at Florești as the backend returned it (one neighbour kept).
const _answer = '''
{"building":{"id":"a119","outline":[[23.4937676,46.7473194],[23.4936841,46.7473193],[23.4936847,46.7471071],
 [23.4937681,46.7471072],[23.4937676,46.7473194]],"areaM2":150.0,"perimeterM":59.9,"distanceM":0.0,"bearingDeg":53.0,
 "heightM":null,"floors":null,"roofShape":null,"roofDirectionDeg":null,"kind":null,
 "walls":[{"lengthM":6.4,"facingDeg":0.0},{"lengthM":23.6,"facingDeg":270.0},{"lengthM":6.4,"facingDeg":180.0},
 {"lengthM":23.6,"facingDeg":90.0}],"mainAxisDeg":0.0},
 "nearby":[{"id":"c695","outline":[[23.49366,46.7473884],[23.4936628,46.7473435],[23.4937324,46.7473455],
 [23.4937272,46.7474299],[23.49366,46.7473884]],"areaM2":43.0,"walls":null,"mainAxisDeg":null}],
 "release":"2026-10-21.0","attribution":"Overture"}''';

void main() {
  test('the backend answer reads, and the map gets the building at the place as main', () {
    final at = BuildingsAt.fromJson(jsonDecode(_answer) as Map<String, dynamic>);
    expect(at.building!.areaM2, 150);
    expect(at.building!.walls, hasLength(4));
    expect(at.nearby.single.walls, isEmpty);
    expect(at.building!.contains(46.7472, 23.4937), isTrue);
    expect(at.building!.contains(46.7472, 23.4940), isFalse);
    final geo = jsonDecode(at.toGeoJson()) as Map<String, dynamic>;
    final features = geo['features'] as List;
    expect(features, hasLength(2));
    expect((features.first as Map)['properties'], {'main': 1});
  });

  test('a tap on the map under the question turns into the point there, and back', () {
    const size = Size(1200, 800);
    const lat = 46.7472, lon = 23.4937;
    // The place itself sits at its spot below the question.
    expect(MapPeek.toScreen(size, lat, lon, lat, lon), MapPeek.placeAt(size));
    final (tLat, tLon) = MapPeek.toLatLon(size, lat, lon, MapPeek.placeAt(size) + const Offset(100, -50));
    expect(tLon, greaterThan(lon));
    expect(tLat, greaterThan(lat));
    final back = MapPeek.toScreen(size, lat, lon, tLat, tLon);
    expect((back - (MapPeek.placeAt(size) + const Offset(100, -50))).distance, lessThan(0.01));
    // About 0.2 m per pixel at zoom 18 here: 100 px east is some 20 m.
    expect((tLon - lon) * 111320 * 0.685, closeTo(20.5, 1));
  });

  test('an outline drawn corner by corner gives its area', () {
    // A 10 × 20 m rectangle near Florești.
    const lat = 46.7472, lon = 23.4937;
    const dLat = 10 / 111195.0, dLon = 20 / (111195.0 * 0.6853);
    final corners = [
      [lat, lon],
      [lat, lon + dLon],
      [lat + dLat, lon + dLon],
      [lat + dLat, lon],
    ];
    expect(HomeAnswers.outlineArea(corners), closeTo(200, 2));
    expect(HomeAnswers.outlineArea(corners.sublist(0, 2)), 0);
  });

  test('a size picked or typed becomes a square of that area around the point', () {
    final a = HomeAnswers()
      ..newLat = 46.7472
      ..newLon = 23.4937
      ..newKind = NewThingKind.building;
    a.setNewSize(AreaSize.medium);
    expect(HomeAnswers.outlineArea(a.newOutline), closeTo(40, 0.5));
    a.setNewArea(100);
    expect(HomeAnswers.outlineArea(a.newOutline), closeTo(100, 1));
    // Drawn by hand: kept, and "Cancel" brings back the square.
    a.startDrawing();
    a.setNewOutline([
      [46.7472, 23.4937],
      [46.7472, 23.4938],
      [46.7473, 23.4938],
    ]);
    expect(a.newOutlineDrawn, isTrue);
    a.endDrawing(keep: false);
    expect(a.newOutlineDrawn, isFalse);
    expect(HomeAnswers.outlineArea(a.newOutline), closeTo(100, 1));
    a.dispose();
  });

  test('turning the outline keeps its area', () {
    final a = HomeAnswers()
      ..newLat = 46.7472
      ..newLon = 23.4937
      ..newKind = NewThingKind.building;
    a.setNewArea(100);
    a.newRotation = 30;
    expect(HomeAnswers.outlineArea(a.newShape), closeTo(100, 1));
    expect(a.newShape.first, isNot(a.newOutline.first));
    a.dispose();
  });

  test('a square that would reach onto the road is pushed off it', () {
    const lat = 46.7472, lon = 23.4937;
    final a = HomeAnswers()
      ..newLat = lat + 2 / 111195.0 // 2 m north of the road's middle
      ..newLon = lon
      ..newKind = NewThingKind.building;
    a.setRoads([
      (
        4.0,
        [
          [lat, lon - 0.001],
          [lat, lon + 0.001],
        ],
      ),
    ]);
    a.setNewArea(100); // 10 × 10 m: would reach 3 m over the road's middle
    final south = a.newShape.map((c) => c[0]).reduce((x, y) => x < y ? x : y);
    // Its south side is now beyond the road's half width (4 m) and the margin.
    expect((south - lat) * 111195.0, closeTo(4.5, 0.05));
    expect(HomeAnswers.outlineArea(a.newShape), closeTo(100, 1));
    a.dispose();
  });
}
