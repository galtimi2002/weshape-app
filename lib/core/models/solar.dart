import 'dart:ui';

/// The three solar layers. The names match the backend ids, which follow the
/// Global Solar Atlas: GTI, PVOUT and OPTA.
enum SolarLayerId { gti, pvout, opta }

/// How one layer is drawn: its unit and colour scale.
class SolarLayerInfo {
  const SolarLayerInfo({
    required this.id,
    required this.unit,
    required this.min,
    required this.max,
    required this.colors,
    required this.imagePath,
  });

  final SolarLayerId id;
  final String unit;
  final double min;
  final double max;
  final List<Color> colors;

  /// Path of the layer picture on the backend, e.g. /api/v1/solar/layers/pvout.png.
  final String imagePath;

  /// The colour that marks this layer in the interface (the pin, the selected tile).
  Color get accent => colors[colors.length > 2 ? 2 : colors.length - 1];

  factory SolarLayerInfo.fromJson(Map<String, dynamic> json) {
    final id = SolarLayerId.values.byName(json['id'] as String);
    return SolarLayerInfo(
      id: id,
      unit: json['unit'] as String,
      min: (json['min'] as num).toDouble(),
      max: (json['max'] as num).toDouble(),
      colors: [for (final c in json['colors'] as List) _hex(c as String)],
      imagePath: json['image'] as String,
    );
  }
}

/// Where the layers cover and how each is drawn, as the backend describes them.
class SolarLayers {
  const SolarLayers({required this.bounds, required this.layers, required this.example});

  /// West, south, east, north in degrees.
  final List<double> bounds;
  final Map<SolarLayerId, SolarLayerInfo> layers;

  /// True while the backend serves placeholder numbers.
  final bool example;

  SolarLayerInfo operator [](SolarLayerId id) => layers[id]!;

  factory SolarLayers.fromJson(Map<String, dynamic> json) {
    final list = [for (final l in json['layers'] as List) SolarLayerInfo.fromJson(l as Map<String, dynamic>)];
    return SolarLayers(
      bounds: [for (final v in json['bounds'] as List) (v as num).toDouble()],
      layers: {for (final l in list) l.id: l},
      example: json['example'] as bool? ?? false,
    );
  }

  /// The same as the backend sends today; used until its answer arrives.
  static const SolarLayers fallback = SolarLayers(
    bounds: [-180, -60, 180, 75],
    example: true,
    layers: {
      SolarLayerId.gti: SolarLayerInfo(
        id: SolarLayerId.gti,
        unit: 'kWh/m²',
        min: 1100,
        max: 2500,
        colors: [Color(0xFFF6EBC6), Color(0xFFEDBF5E), Color(0xFFD9892A), Color(0xFFB5651D)],
        imagePath: '/api/v1/solar/layers/gti.png',
      ),
      SolarLayerId.pvout: SolarLayerInfo(
        id: SolarLayerId.pvout,
        unit: 'kWh/kWp',
        min: 900,
        max: 2000,
        colors: [Color(0xFFE3F2E6), Color(0xFF7CC49A), Color(0xFF2E9E66), Color(0xFF1C6B44)],
        imagePath: '/api/v1/solar/layers/pvout.png',
      ),
      SolarLayerId.opta: SolarLayerInfo(
        id: SolarLayerId.opta,
        unit: '°',
        min: 5,
        max: 45,
        colors: [Color(0xFFEAF0F8), Color(0xFF9DB4DE), Color(0xFF3E64A8), Color(0xFF1E3A6E)],
        imagePath: '/api/v1/solar/layers/opta.png',
      ),
    },
  );
}

/// Solar values for one place.
class SolarPoint {
  const SolarPoint({
    required this.lat,
    required this.lon,
    required this.gti,
    required this.pvout,
    required this.opta,
    required this.gtiMonthly,
    required this.pvoutMonthly,
    required this.example,
    required this.source,
  });

  final double lat;
  final double lon;
  final double gti;
  final double pvout;
  final double opta;
  final List<double> gtiMonthly;
  final List<double> pvoutMonthly;
  final bool example;

  /// Where the numbers come from, e.g. "PVGIS (PVGIS-SARAH3)".
  final String source;

  double valueOf(SolarLayerId id) => switch (id) {
        SolarLayerId.gti => gti,
        SolarLayerId.pvout => pvout,
        SolarLayerId.opta => opta,
      };

  /// Monthly figures, January first; none for the tilt angle.
  List<double>? monthlyOf(SolarLayerId id) => switch (id) {
        SolarLayerId.gti => gtiMonthly,
        SolarLayerId.pvout => pvoutMonthly,
        SolarLayerId.opta => null,
      };

  factory SolarPoint.fromJson(Map<String, dynamic> json) {
    List<double> list(String key) => [for (final v in json[key] as List) (v as num).toDouble()];
    return SolarPoint(
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      gti: (json['gti'] as num).toDouble(),
      pvout: (json['pvout'] as num).toDouble(),
      opta: (json['opta'] as num).toDouble(),
      gtiMonthly: list('gtiMonthly'),
      pvoutMonthly: list('pvoutMonthly'),
      example: json['example'] as bool? ?? false,
      source: json['source'] as String? ?? '',
    );
  }
}

Color _hex(String s) => Color(0xFF000000 | int.parse(s.replaceFirst('#', ''), radix: 16));
