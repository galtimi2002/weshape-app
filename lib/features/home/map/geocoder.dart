import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

/// A place found by the address search.
class Place {
  const Place({required this.title, required this.detail, required this.lat, required this.lon, this.countryCode});

  /// What the person would call it: "Strada Memorandumului 12" or "Cluj-Napoca".
  final String title;

  /// Where it is: "Cluj-Napoca, Romania".
  final String detail;
  final double lat;
  final double lon;

  /// ISO 3166-1 alpha-2, upper case, when known.
  final String? countryCode;

  /// Title and detail together, without repeating the same name.
  String get fullName => detail.isEmpty ? title : '$title, $detail';
}

/// Address search and place names, from OpenStreetMap data through Photon
/// (photon.komoot.io).
///
/// The public Photon server is free and fine for development and testing. It
/// has no guaranteed capacity, so before launch this should move to a hosted
/// or self-run geocoder; only this class changes when it does.
class Geocoder {
  Geocoder({http.Client? client}) : _http = client ?? http.Client();

  final http.Client _http;
  static const _base = 'https://photon.komoot.io';

  /// Photon translates place names into these languages only.
  static const _languages = {'en', 'de', 'fr', 'it'};

  /// Matches for [query], places in [countryCode] first, at most [limit].
  /// [near] is a (lat, lon) the results should lean towards.
  Future<List<Place>> search(
    String query, {
    String? countryCode,
    (double, double)? near,
    String language = 'en',
    int limit = 5,
  }) async {
    final q = query.trim();
    if (q.length < 2) return const [];
    final params = <String, String>{
      'q': q,
      'limit': '12',
      if (_languages.contains(language)) 'lang': language,
      if (near != null) 'lat': near.$1.toStringAsFixed(4),
      if (near != null) 'lon': near.$2.toStringAsFixed(4),
    };
    final features = await _get('/api/', params);
    final places = features.map(_place).whereType<Place>().toList();
    final code = countryCode?.toUpperCase();
    if (code != null) {
      // Stable sort: the person's own country first, Photon's order otherwise.
      final mine = places.where((p) => p.countryCode == code);
      final others = places.where((p) => p.countryCode != code);
      return [...mine, ...others].take(limit).toList();
    }
    return places.take(limit).toList();
  }

  /// The name of what is at a point, or null when nothing useful is there.
  Future<Place?> reverse(double lat, double lon, {String language = 'en'}) async {
    final features = await _get('/reverse', {
      'lat': lat.toStringAsFixed(5),
      'lon': lon.toStringAsFixed(5),
      'limit': '5',
      if (_languages.contains(language)) 'lang': language,
    });
    // Photon answers with the nearest named things, which can be a church far off, or a
    // stream or road whose box covers half the valley. A name is used only when the point
    // is on that thing (or right by it); otherwise the place is named after the nearest
    // village or town.
    for (final feature in features) {
      final props = feature['properties'] as Map<String, dynamic>? ?? const {};
      if (const {'waterway', 'natural', 'landuse', 'boundary', 'place'}.contains(props['osm_key'])) continue;
      if (_isAt(feature, lat, lon)) return _place(feature);
    }
    final near = await _settlements(lat, lon, language);
    if (near.isEmpty) return null;
    final place = _place(near.first);
    if (place == null) return null;
    return Place(title: place.title, detail: place.detail, lat: lat, lon: lon, countryCode: place.countryCode);
  }

  /// The villages, towns and cities nearest to a point (Photon's layers can repeat in
  /// a query, which a map of parameters cannot hold).
  Future<List<Map<String, dynamic>>> _settlements(double lat, double lon, String language) async {
    final query = [
      'lat=${lat.toStringAsFixed(5)}',
      'lon=${lon.toStringAsFixed(5)}',
      'radius=15',
      'limit=1',
      'layer=city',
      'layer=district',
      'layer=locality',
      if (_languages.contains(language)) 'lang=$language',
    ].join('&');
    final response = await _http.get(Uri.parse('$_base/reverse?$query')).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) throw http.ClientException('geocoder ${response.statusCode}');
    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return [for (final f in body['features'] as List? ?? const []) f as Map<String, dynamic>];
  }

  /// Within about 40 m of the feature: inside its box when that is small (a building, a
  /// short street), otherwise near its point.
  static bool _isAt(Map<String, dynamic> feature, double lat, double lon) {
    const metres = 40.0;
    const dLat = metres / 111195;
    final dLon = dLat / math.max(0.05, math.cos(lat * math.pi / 180));
    final extent = (feature['properties'] as Map<String, dynamic>?)?['extent'];
    if (extent is List && extent.length == 4) {
      // Photon gives [minLon, maxLat, maxLon, minLat].
      final e = [for (final v in extent) (v as num).toDouble()];
      final small = (e[1] - e[3]) < 8 * dLat && (e[2] - e[0]) < 8 * dLon;
      if (small) return lon >= e[0] - dLon && lon <= e[2] + dLon && lat >= e[3] - dLat && lat <= e[1] + dLat;
    }
    final coords = (feature['geometry'] as Map<String, dynamic>?)?['coordinates'];
    if (coords is! List || coords.length < 2) return false;
    return ((coords[1] as num).toDouble() - lat).abs() <= dLat && ((coords[0] as num).toDouble() - lon).abs() <= dLon;
  }

  /// A country's extent as west, south, east, north, looked up by name.
  Future<List<double>?> countryBounds(String countryName) async {
    final features = await _get('/api/', {'q': countryName, 'osm_tag': 'place:country', 'limit': '1'});
    if (features.isEmpty) return null;
    final extent = (features.first['properties'] as Map<String, dynamic>?)?['extent'];
    if (extent is! List || extent.length != 4) return null;
    // Photon gives [minLon, maxLat, maxLon, minLat].
    final e = [for (final v in extent) (v as num).toDouble()];
    return [e[0], e[3], e[2], e[1]];
  }

  Future<List<Map<String, dynamic>>> _get(String path, Map<String, String> params) async {
    final response = await _http.get(Uri.parse('$_base$path').replace(queryParameters: params)).timeout(
          const Duration(seconds: 8),
        );
    if (response.statusCode != 200) throw http.ClientException('geocoder ${response.statusCode}');
    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return [for (final f in body['features'] as List? ?? const []) f as Map<String, dynamic>];
  }

  static Place? _place(Map<String, dynamic> feature) {
    final coords = (feature['geometry'] as Map<String, dynamic>?)?['coordinates'];
    final props = feature['properties'] as Map<String, dynamic>? ?? const {};
    if (coords is! List || coords.length < 2) return null;
    String? s(String key) {
      final v = props[key];
      return v is String && v.trim().isNotEmpty ? v.trim() : null;
    }

    final street = s('street');
    final number = s('housenumber');
    final name = s('name');
    // A village that belongs to a commune comes as the district, the commune as the city
    // (Sfăraș in Almașu): the village is where the place is, so it goes first.
    final village = s('district');
    final city = s('city') ?? s('town') ?? s('village');
    final region = s('county') ?? s('state');
    final country = s('country');

    final title =
        name ?? (street != null ? [street, if (number != null) number].join(' ') : null) ?? village ?? city ?? region;
    if (title == null) return null;
    final detail = <String>[];
    for (final part in [
      if (name != null && street != null) [street, if (number != null) number].join(' '),
      village,
      city,
      region,
      country,
    ]) {
      if (part != null && part != title && !detail.contains(part)) detail.add(part);
    }
    // Keep it short: the nearest levels and the country.
    final short = detail.length > 3 ? [detail[0], detail[1], detail.last] : detail;
    return Place(
      title: title,
      detail: short.join(', '),
      lat: (coords[1] as num).toDouble(),
      lon: (coords[0] as num).toDouble(),
      countryCode: s('countrycode')?.toUpperCase(),
    );
  }
}
