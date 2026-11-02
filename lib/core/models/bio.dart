import 'dart:ui';

/// The three biomass layers, as the backend names them.
enum BioLayerId { density, resource, energy }

/// How one biomass layer is drawn: unit, colour scale and where its map tiles are.
class BioLayerInfo {
  const BioLayerInfo({
    required this.id,
    required this.unit,
    required this.min,
    required this.max,
    required this.colors,
    required this.tiles,
  });

  final BioLayerId id;
  final String unit;
  final double min;
  final double max;
  final List<Color> colors;

  /// Tile path on the backend with {z}/{x}/{y}.
  final String tiles;

  /// The colour that marks this layer in the interface (the pin, the selected tile).
  Color get accent => colors[colors.length > 2 ? 2 : colors.length - 1];

  factory BioLayerInfo.fromJson(Map<String, dynamic> json) => BioLayerInfo(
        id: BioLayerId.values.byName(json['id'] as String),
        unit: json['unit'] as String,
        min: (json['min'] as num).toDouble(),
        max: (json['max'] as num).toDouble(),
        colors: [for (final c in json['colors'] as List) _hex(c as String)],
        tiles: json['tiles'] as String,
      );
}

/// The biomass map as the backend describes it.
class BioLayers {
  const BioLayers({
    required this.available,
    required this.bounds,
    required this.maxZoom,
    required this.radiusKm,
    required this.attribution,
    required this.layers,
  });

  /// False until the biomass data is built (or while the backend cannot read it).
  final bool available;

  /// West, south, east, north in degrees.
  final List<double> bounds;
  final int maxZoom;

  /// The collection radius the resource and energy layers add up (km).
  final int radiusKm;

  /// HTML credit line for the map.
  final String attribution;
  final Map<BioLayerId, BioLayerInfo> layers;

  BioLayerInfo operator [](BioLayerId id) => layers[id]!;

  factory BioLayers.fromJson(Map<String, dynamic> json) {
    final list = [for (final l in json['layers'] as List) BioLayerInfo.fromJson(l as Map<String, dynamic>)];
    return BioLayers(
      available: json['available'] as bool? ?? false,
      bounds: [for (final v in json['bounds'] as List) (v as num).toDouble()],
      maxZoom: (json['maxZoom'] as num?)?.toInt() ?? 7,
      radiusKm: (json['radiusKm'] as num?)?.round() ?? 25,
      attribution: json['attribution'] as String? ?? fallback.attribution,
      layers: {for (final l in list) l.id: l},
    );
  }

  static const _colors = [Color(0xFFEAF4E0), Color(0xFFA9D48C), Color(0xFF5BAA5E), Color(0xFF2A6B3B)];

  /// The same as the backend sends, but closed (available: false) until its answer
  /// says the biomass data is there.
  static const BioLayers fallback = BioLayers(
    available: false,
    bounds: [-180, -60, 180, 84],
    maxZoom: 7,
    radiusKm: 25,
    attribution: 'Biomass data: <a href="https://doi.org/10.7910/DVN/SWPENT" target="_blank" rel="noopener">MapSPAM 2020</a> '
        '(IFPRI, CC BY 4.0), <a href="https://climate.esa.int/en/projects/biomass/" target="_blank" rel="noopener">ESA CCI '
        'Biomass</a>',
    layers: {
      BioLayerId.density: BioLayerInfo(
          id: BioLayerId.density, unit: 't/ha', min: 0, max: 3, colors: _colors, tiles: '/api/v1/bio/tiles/density/{z}/{x}/{y}.png'),
      BioLayerId.resource: BioLayerInfo(
          id: BioLayerId.resource, unit: 'kt', min: 0, max: 500, colors: _colors, tiles: '/api/v1/bio/tiles/resource/{z}/{x}/{y}.png'),
      BioLayerId.energy: BioLayerInfo(
          id: BioLayerId.energy, unit: 'GWh', min: 0, max: 2000, colors: _colors, tiles: '/api/v1/bio/tiles/energy/{z}/{x}/{y}.png'),
    },
  );
}

/// Biomass at one place.
class BioPoint {
  const BioPoint({
    required this.lat,
    required this.lon,
    required this.density,
    required this.cropKt,
    required this.forestKt,
    required this.resourceKt,
    required this.energyGwh,
    required this.homes,
    required this.radiusKm,
    required this.source,
  });

  final double lat;
  final double lon;

  /// Available biomass here, t/ha per year.
  final double density;

  /// Crop and forest residues within the radius, thousand t per year.
  final double cropKt;
  final double forestKt;
  final double resourceKt;

  /// Their heating value within the radius, GWh per year.
  final double energyGwh;

  /// Family homes that much heat would keep warm for a year.
  final int homes;
  final int radiusKm;
  final String source;

  factory BioPoint.fromJson(Map<String, dynamic> json) {
    double n(String key) => (json[key] as num?)?.toDouble() ?? 0;
    return BioPoint(
      lat: n('lat'),
      lon: n('lon'),
      density: n('density'),
      cropKt: n('cropKt'),
      forestKt: n('forestKt'),
      resourceKt: n('resourceKt'),
      energyGwh: n('energyGwh'),
      homes: (json['homes'] as num?)?.toInt() ?? 0,
      radiusKm: (json['radiusKm'] as num?)?.round() ?? 25,
      source: json['source'] as String? ?? '',
    );
  }
}

Color _hex(String s) => Color(0xFF000000 | int.parse(s.replaceFirst('#', ''), radix: 16));
