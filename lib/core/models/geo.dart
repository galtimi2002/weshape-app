import 'dart:ui';

/// The three geothermal layers, as the backend names them.
enum GeoLayerId { ground, depth, heatflow }

/// How one geothermal layer is drawn: unit, colour scale and where its map tiles are.
class GeoLayerInfo {
  const GeoLayerInfo({
    required this.id,
    required this.unit,
    required this.min,
    required this.max,
    required this.colors,
    required this.tiles,
    this.ranges = const {},
  });

  final GeoLayerId id;
  final String unit;
  final double min;
  final double max;
  final List<Color> colors;

  /// Tile path on the backend with {z}/{x}/{y} (and {d} for the depth layer).
  final String tiles;

  /// The depth layer's colour scale per depth (km): (min, max).
  final Map<int, (double, double)> ranges;

  /// The colour that marks this layer in the interface (the pin, the selected tile).
  Color get accent => colors[colors.length > 2 ? 2 : colors.length - 1];

  /// The colour scale's range, per depth for the depth layer.
  (double, double) rangeAt(int depth) => ranges[depth] ?? (min, max);

  factory GeoLayerInfo.fromJson(Map<String, dynamic> json) {
    final raw = json['ranges'] as Map<String, dynamic>? ?? const {};
    return GeoLayerInfo(
      id: GeoLayerId.values.byName(json['id'] as String),
      unit: json['unit'] as String,
      min: (json['min'] as num).toDouble(),
      max: (json['max'] as num).toDouble(),
      colors: [for (final c in json['colors'] as List) _hex(c as String)],
      tiles: json['tiles'] as String,
      ranges: {
        for (final e in raw.entries)
          int.parse(e.key): (((e.value as List)[0] as num).toDouble(), ((e.value as List)[1] as num).toDouble()),
      },
    );
  }
}

/// The geothermal map as the backend describes it.
class GeoLayers {
  const GeoLayers({
    required this.available,
    required this.bounds,
    required this.maxZoom,
    required this.depths,
    required this.conductivity,
    required this.attribution,
    required this.layers,
  });

  /// False until the geothermal data is built (or while the backend cannot read it).
  final bool available;

  /// West, south, east, north in degrees.
  final List<double> bounds;
  final int maxZoom;

  /// Depths (km) of the temperature-at-depth layer.
  final List<int> depths;

  /// Rock thermal conductivity used for the estimate (W/m·K).
  final double conductivity;

  /// HTML credit line for the map.
  final String attribution;
  final Map<GeoLayerId, GeoLayerInfo> layers;

  GeoLayerInfo operator [](GeoLayerId id) => layers[id]!;

  factory GeoLayers.fromJson(Map<String, dynamic> json) {
    final list = [for (final l in json['layers'] as List) GeoLayerInfo.fromJson(l as Map<String, dynamic>)];
    return GeoLayers(
      available: json['available'] as bool? ?? false,
      bounds: [for (final v in json['bounds'] as List) (v as num).toDouble()],
      maxZoom: (json['maxZoom'] as num?)?.toInt() ?? 7,
      depths: [for (final v in json['depths'] as List? ?? fallback.depths) (v as num).toInt()],
      conductivity: (json['conductivity'] as num?)?.toDouble() ?? 2.5,
      attribution: json['attribution'] as String? ?? fallback.attribution,
      layers: {for (final l in list) l.id: l},
    );
  }

  static const _colors = [Color(0xFFFCEBDD), Color(0xFFF3A77A), Color(0xFFD45F35), Color(0xFF8C2A1B)];

  /// The same as the backend sends, but closed (available: false) until its answer
  /// says the geothermal data is there.
  static const GeoLayers fallback = GeoLayers(
    available: false,
    bounds: [-180, -60, 180, 84],
    maxZoom: 7,
    depths: [1, 2, 3, 5],
    conductivity: 2.5,
    attribution: 'Geothermal data: <a href="https://doi.org/10.5281/zenodo.4558732" target="_blank" rel="noopener">SoilTemp</a> '
        '(Lembrechts et al. 2022, CC BY 4.0), <a href="https://doi.org/10.5880/fidgeo.2024.014" target="_blank" '
        'rel="noopener">Global Heat Flow Database</a> 2024 (IHFC)',
    layers: {
      GeoLayerId.ground: GeoLayerInfo(
          id: GeoLayerId.ground, unit: '°C', min: 0, max: 20, colors: _colors, tiles: '/api/v1/geo/tiles/ground/{z}/{x}/{y}.png'),
      GeoLayerId.depth: GeoLayerInfo(
        id: GeoLayerId.depth,
        unit: '°C',
        min: 40,
        max: 120,
        colors: _colors,
        tiles: '/api/v1/geo/tiles/depth-{d}/{z}/{x}/{y}.png',
        ranges: {1: (20.0, 70.0), 2: (40.0, 120.0), 3: (60.0, 170.0), 5: (100.0, 260.0)},
      ),
      GeoLayerId.heatflow: GeoLayerInfo(
          id: GeoLayerId.heatflow, unit: 'mW/m²', min: 30, max: 120, colors: _colors, tiles: '/api/v1/geo/tiles/heatflow/{z}/{x}/{y}.png'),
    },
  );
}

/// Estimated temperature at one depth.
class GeoDepth {
  const GeoDepth(this.depthKm, this.temperature);

  final int depthKm;
  final double temperature;
}

/// Geothermal values at one place.
class GeoPoint {
  const GeoPoint({
    required this.lat,
    required this.lon,
    required this.groundTemperature,
    required this.heatFlow,
    required this.depths,
    required this.conductivity,
    required this.source,
  });

  final double lat;
  final double lon;

  /// Annual mean ground temperature near the surface (°C).
  final double groundTemperature;

  /// mW/m²; null where no heat flow measurement is near.
  final double? heatFlow;

  /// Estimated temperature at 1, 2, 3 and 5 km; empty without heat flow.
  final List<GeoDepth> depths;
  final double conductivity;
  final String source;

  /// Temperature at [depthKm], or null when it is not estimated here.
  double? temperatureAt(int depthKm) {
    for (final d in depths) {
      if (d.depthKm == depthKm) return d.temperature;
    }
    return null;
  }

  factory GeoPoint.fromJson(Map<String, dynamic> json) => GeoPoint(
        lat: (json['lat'] as num).toDouble(),
        lon: (json['lon'] as num).toDouble(),
        groundTemperature: (json['groundTemperature'] as num).toDouble(),
        heatFlow: (json['heatFlow'] as num?)?.toDouble(),
        depths: [
          for (final d in json['depths'] as List? ?? const [])
            GeoDepth(((d as Map<String, dynamic>)['depthKm'] as num).toInt(), (d['temperature'] as num).toDouble()),
        ],
        conductivity: (json['conductivity'] as num?)?.toDouble() ?? 2.5,
        source: json['source'] as String? ?? '',
      );
}

Color _hex(String s) => Color(0xFF000000 | int.parse(s.replaceFirst('#', ''), radix: 16));
