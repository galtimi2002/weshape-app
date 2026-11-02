import 'dart:ui';

/// The three river layers, as the backend names them.
enum HydroLayerId { potential, flow, head }

/// How one river layer is drawn: which value of the river tiles colours the lines, and its scale.
class HydroLayerInfo {
  const HydroLayerInfo({
    required this.id,
    required this.property,
    required this.unit,
    required this.min,
    required this.max,
    required this.logarithmic,
    required this.colors,
  });

  final HydroLayerId id;

  /// The value in the river tiles that colours the line ("p", "q" or "h").
  final String property;
  final String unit;
  final double min;
  final double max;
  final bool logarithmic;
  final List<Color> colors;

  /// The colour that marks this layer in the interface (the pin, the selected tile).
  Color get accent => colors[colors.length > 2 ? 2 : colors.length - 1];

  factory HydroLayerInfo.fromJson(Map<String, dynamic> json) => HydroLayerInfo(
        id: HydroLayerId.values.byName(json['id'] as String),
        property: json['property'] as String,
        unit: json['unit'] as String,
        min: (json['min'] as num).toDouble(),
        max: (json['max'] as num).toDouble(),
        logarithmic: json['scale'] == 'log',
        colors: [for (final c in json['colors'] as List) _hex(c as String)],
      );
}

/// The river map as the backend describes it.
class HydroLayers {
  const HydroLayers({
    required this.available,
    required this.bounds,
    required this.maxZoom,
    required this.tiles,
    required this.sourceLayer,
    required this.widthProperty,
    required this.attribution,
    required this.layers,
  });

  /// False until the river tiles are built (or while the backend cannot read them).
  final bool available;

  /// West, south, east, north in degrees.
  final List<double> bounds;
  final int maxZoom;

  /// Vector tile path on the backend with {z}/{x}/{y}.
  final String tiles;

  /// Layer name inside the vector tiles.
  final String sourceLayer;

  /// The tile value the line width follows (mean flow).
  final String widthProperty;

  /// HTML credit line for the map.
  final String attribution;
  final Map<HydroLayerId, HydroLayerInfo> layers;

  HydroLayerInfo operator [](HydroLayerId id) => layers[id]!;

  factory HydroLayers.fromJson(Map<String, dynamic> json) {
    final list = [for (final l in json['layers'] as List) HydroLayerInfo.fromJson(l as Map<String, dynamic>)];
    return HydroLayers(
      available: json['available'] as bool? ?? false,
      bounds: [for (final v in json['bounds'] as List) (v as num).toDouble()],
      maxZoom: (json['maxZoom'] as num?)?.toInt() ?? 10,
      tiles: json['tiles'] as String? ?? fallback.tiles,
      sourceLayer: json['sourceLayer'] as String? ?? fallback.sourceLayer,
      widthProperty: json['widthProperty'] as String? ?? fallback.widthProperty,
      attribution: json['attribution'] as String? ?? fallback.attribution,
      layers: {for (final l in list) l.id: l},
    );
  }

  static const _colors = [Color(0xFFDDF1F4), Color(0xFF7CC5D6), Color(0xFF2B8BA8), Color(0xFF145A73)];

  /// The same as the backend sends today, but closed (available: false) until its
  /// answer says the river tiles are there.
  static const HydroLayers fallback = HydroLayers(
    available: false,
    bounds: [-180, -60, 180, 84],
    maxZoom: 10,
    tiles: '/api/v1/hydro/tiles/{z}/{x}/{y}.pbf',
    sourceLayer: 'rivers',
    widthProperty: 'qa',
    attribution: 'River data: <a href="https://www.hydrosheds.org/hydroatlas" target="_blank" rel="noopener">RiverATLAS</a> '
        'v1.0, Linke et al. 2019 (CC BY 4.0)',
    layers: {
      HydroLayerId.potential: HydroLayerInfo(
          id: HydroLayerId.potential, property: 'p', unit: 'kW', min: 10, max: 10000, logarithmic: true, colors: _colors),
      HydroLayerId.flow: HydroLayerInfo(
          id: HydroLayerId.flow, property: 'q', unit: 'm³/s', min: 0.1, max: 5000, logarithmic: true, colors: _colors),
      HydroLayerId.head: HydroLayerInfo(
          id: HydroLayerId.head, property: 'h', unit: 'm', min: 1, max: 100, logarithmic: true, colors: _colors),
    },
  );
}

/// The river reach nearest to a place.
class HydroPoint {
  const HydroPoint({
    required this.lat,
    required this.lon,
    required this.distanceKm,
    required this.potentialKw,
    required this.availableFlow,
    required this.meanFlow,
    required this.driestMonthFlow,
    required this.wettestMonthFlow,
    required this.headM,
    required this.reachKm,
    required this.ecologicalShare,
    required this.source,
  });

  final double lat;
  final double lon;

  /// From the place to the river.
  final double distanceKm;

  /// 9.81 × available flow × head × efficiency, for the whole reach.
  final double potentialKw;

  /// Mean flow minus the share left in the river for nature (m³/s).
  final double availableFlow;
  final double meanFlow;
  final double driestMonthFlow;
  final double wettestMonthFlow;

  /// How far the water drops along the reach (m).
  final double headM;
  final double reachKm;

  /// Share of the mean flow left in the river (0.1 = 10 %).
  final double ecologicalShare;

  /// Where the numbers come from.
  final String source;

  factory HydroPoint.fromJson(Map<String, dynamic> json) {
    double n(String key) => (json[key] as num?)?.toDouble() ?? 0;
    return HydroPoint(
      lat: n('lat'),
      lon: n('lon'),
      distanceKm: n('distanceKm'),
      potentialKw: n('potentialKw'),
      availableFlow: n('availableFlow'),
      meanFlow: n('meanFlow'),
      driestMonthFlow: n('driestMonthFlow'),
      wettestMonthFlow: n('wettestMonthFlow'),
      headM: n('headM'),
      reachKm: n('reachKm'),
      ecologicalShare: n('ecologicalShare'),
      source: json['source'] as String? ?? '',
    );
  }
}

Color _hex(String s) => Color(0xFF000000 | int.parse(s.replaceFirst('#', ''), radix: 16));
