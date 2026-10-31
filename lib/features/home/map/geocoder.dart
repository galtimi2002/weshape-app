import 'dart:convert';

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
      if (_languages.contains(language)) 'lang': language,
    });
    return features.isEmpty ? null : _place(features.first);
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
    final city = s('city') ?? s('town') ?? s('village') ?? s('district');
    final region = s('county') ?? s('state');
    final country = s('country');

    final title = name ?? (street != null ? [street, if (number != null) number].join(' ') : null) ?? city ?? region;
    if (title == null) return null;
    final detail = <String>[];
    for (final part in [if (name != null && street != null) [street, if (number != null) number].join(' '), city, region, country]) {
      if (part != null && part != title && !detail.contains(part)) detail.add(part);
    }
    // Keep it short: the nearest two levels and the country.
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
