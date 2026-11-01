import 'dart:ui';

/// The three wind layers, as the backend names them.
enum WindLayerId { speed, power, height }

/// How one wind layer is drawn: unit, fixed colour scale and where its map tiles are.
class WindLayerInfo {
  const WindLayerInfo({
    required this.id,
    required this.unit,
    required this.min,
    required this.max,
    required this.logarithmic,
    required this.colors,
    required this.tiles,
  });

  final WindLayerId id;
  final String unit;
  final double min;
  final double max;
  final bool logarithmic;
  final List<Color> colors;

  /// Tile path on the backend with {z}/{x}/{y} (and {h} for the height layer).
  final String tiles;

  /// The colour that marks this layer in the interface (the pin, the selected tile).
  Color get accent => colors[colors.length > 2 ? 2 : colors.length - 1];

  factory WindLayerInfo.fromJson(Map<String, dynamic> json) => WindLayerInfo(
        id: WindLayerId.values.byName(json['id'] as String),
        unit: json['unit'] as String,
        min: (json['min'] as num).toDouble(),
        max: (json['max'] as num).toDouble(),
        logarithmic: json['scale'] == 'log',
        colors: [for (final c in json['colors'] as List) _hex(c as String)],
        tiles: json['tiles'] as String,
      );
}

/// The wind map as the backend describes it.
class WindLayers {
  const WindLayers({
    required this.available,
    required this.bounds,
    required this.maxZoom,
    required this.heights,
    required this.attribution,
    required this.layers,
  });

  /// False while the backend cannot read the wind files.
  final bool available;

  /// West, south, east, north in degrees.
  final List<double> bounds;
  final int maxZoom;
  final List<int> heights;

  /// HTML credit line for the map.
  final String attribution;
  final Map<WindLayerId, WindLayerInfo> layers;

  WindLayerInfo operator [](WindLayerId id) => layers[id]!;

  factory WindLayers.fromJson(Map<String, dynamic> json) {
    final list = [for (final l in json['layers'] as List) WindLayerInfo.fromJson(l as Map<String, dynamic>)];
    return WindLayers(
      available: json['available'] as bool? ?? false,
      bounds: [for (final v in json['bounds'] as List) (v as num).toDouble()],
      maxZoom: (json['maxZoom'] as num?)?.toInt() ?? 10,
      heights: [for (final v in json['heights'] as List) (v as num).toInt()],
      attribution: json['attribution'] as String? ?? fallback.attribution,
      layers: {for (final l in list) l.id: l},
    );
  }

  /// The same as the backend sends today; used until its answer arrives.
  static const WindLayers fallback = WindLayers(
    available: true,
    bounds: [-180, -64, 180, 80],
    maxZoom: 10,
    heights: [10, 50, 100, 150, 200],
    attribution: 'Wind data: <a href="https://globalwindatlas.info" target="_blank" rel="noopener">Global Wind Atlas</a> 4.0, '
        'DTU and World Bank Group (CC BY 4.0)',
    layers: {
      WindLayerId.speed: WindLayerInfo(
        id: WindLayerId.speed,
        unit: 'm/s',
        min: 3,
        max: 9,
        logarithmic: false,
        colors: [Color(0xFFE3EEF8), Color(0xFF7FB2E0), Color(0xFF2F6DB0), Color(0xFF163E78)],
        tiles: '/api/v1/wind/tiles/speed/{z}/{x}/{y}.png',
      ),
      WindLayerId.power: WindLayerInfo(
        id: WindLayerId.power,
        unit: 'W/m²',
        min: 50,
        max: 800,
        logarithmic: true,
        colors: [Color(0xFFEEE8F6), Color(0xFFB39BDA), Color(0xFF7552B5), Color(0xFF46297F)],
        tiles: '/api/v1/wind/tiles/power/{z}/{x}/{y}.png',
      ),
      WindLayerId.height: WindLayerInfo(
        id: WindLayerId.height,
        unit: 'm/s',
        min: 2,
        max: 10,
        logarithmic: false,
        colors: [Color(0xFFE0F2F5), Color(0xFF7CC5D6), Color(0xFF2B8BA8), Color(0xFF145A73)],
        tiles: '/api/v1/wind/tiles/height-{h}/{z}/{x}/{y}.png',
      ),
    },
  );
}

/// Mean wind speed at one height.
class WindSpeedAt {
  const WindSpeedAt(this.height, this.speed);

  final int height;
  final double speed;
}

/// The wind at one place.
class WindPoint {
  const WindPoint({
    required this.lat,
    required this.lon,
    required this.speeds,
    required this.speed100,
    required this.powerDensity100,
    required this.source,
  });

  final double lat;
  final double lon;

  /// Mean speed at 10, 50, 100, 150 and 200 m (those the atlas has here).
  final List<WindSpeedAt> speeds;
  final double speed100;

  /// W/m² at 100 m; null where the atlas has no value.
  final double? powerDensity100;

  /// Where the numbers come from, e.g. "Global Wind Atlas 4.0 (DTU, World Bank Group)".
  final String source;

  /// Speed at [height], or null when the atlas has none there.
  double? speedAt(int height) {
    for (final s in speeds) {
      if (s.height == height) return s.speed;
    }
    return null;
  }

  factory WindPoint.fromJson(Map<String, dynamic> json) => WindPoint(
        lat: (json['lat'] as num).toDouble(),
        lon: (json['lon'] as num).toDouble(),
        speeds: [
          for (final s in json['speeds'] as List)
            WindSpeedAt(((s as Map<String, dynamic>)['height'] as num).toInt(), (s['speed'] as num).toDouble()),
        ],
        speed100: (json['speed100'] as num).toDouble(),
        powerDensity100: (json['powerDensity100'] as num?)?.toDouble(),
        source: json['source'] as String? ?? '',
      );
}

Color _hex(String s) => Color(0xFF000000 | int.parse(s.replaceFirst('#', ''), radix: 16));
