import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/auth_service.dart';
import '../config/app_config.dart';
import '../models/bio.dart';
import '../models/building.dart';
import '../models/geo.dart';
import '../models/hydro.dart';
import '../models/solar.dart';
import '../models/user_profile.dart';
import '../models/wind.dart';
import 'api_exception.dart';

/// Thin REST client for weshape-backend.
///
/// Attaches the current ID token to every call and retries once with a
/// refreshed token on 401, which covers a token expiring while the app is open.
class ApiClient {
  ApiClient({required AuthService authService, http.Client? httpClient, String? baseUrl})
      : _auth = authService,
        _http = httpClient ?? http.Client(),
        _baseUrl = (baseUrl ?? AppConfig.apiBaseUrl).replaceAll(RegExp(r'/+$'), '');

  final AuthService _auth;
  final http.Client _http;
  final String _baseUrl;

  /// Until the server has answered once it may still be booting, so calls get
  /// the cold-start budget instead of the normal one.
  bool _serverHasAnswered = false;

  Duration get _timeout => _serverHasAnswered ? AppConfig.requestTimeout : AppConfig.coldStartTimeout;

  Future<UserProfile> me() async =>
      UserProfile.fromJson(await _send('GET', '/api/v1/users/me') as Map<String, dynamic>);

  Future<UserProfile> completeProfile(ProfileDraft draft) async => UserProfile.fromJson(
      await _send('PUT', '/api/v1/users/me', body: draft.toJson()) as Map<String, dynamic>);

  Future<UserProfile> updatePreferences({String? language, String? themeMode}) async =>
      UserProfile.fromJson(await _send('PUT', '/api/v1/users/me/preferences', body: <String, dynamic>{
        if (language != null) 'preferredLanguage': language,
        if (themeMode != null) 'themeMode': themeMode,
      }) as Map<String, dynamic>);

  /// Irradiation, PV output and optimum tilt for one place.
  Future<SolarPoint> solarPoint(double lat, double lon) async => SolarPoint.fromJson(
      await _send('GET', '/api/v1/solar/point?lat=${lat.toStringAsFixed(5)}&lon=${lon.toStringAsFixed(5)}')
          as Map<String, dynamic>);

  /// How the solar map layers are drawn and where they cover.
  Future<SolarLayers> solarLayers() async =>
      SolarLayers.fromJson(await _send('GET', '/api/v1/solar/layers') as Map<String, dynamic>);

  /// Mean wind speed by height and power density for one place.
  Future<WindPoint> windPoint(double lat, double lon) async => WindPoint.fromJson(
      await _send('GET', '/api/v1/wind/point?lat=${lat.toStringAsFixed(5)}&lon=${lon.toStringAsFixed(5)}')
          as Map<String, dynamic>);

  /// How the wind map layers are drawn and where their tiles are.
  Future<WindLayers> windLayers() async =>
      WindLayers.fromJson(await _send('GET', '/api/v1/wind/layers') as Map<String, dynamic>);

  /// The nearest river reach to a place: potential, available flow, head. With [zoom],
  /// only among the rivers the map draws at that zoom (the one the person clicked on).
  Future<HydroPoint> hydroPoint(double lat, double lon, {double? zoom}) async => HydroPoint.fromJson(await _send(
          'GET',
          '/api/v1/hydro/point?lat=${lat.toStringAsFixed(5)}&lon=${lon.toStringAsFixed(5)}'
              '${zoom == null ? '' : '&zoom=${zoom.toStringAsFixed(1)}'}')
      as Map<String, dynamic>);

  /// The building at a place (or the nearest within 20 m) and the buildings within 50 m of it.
  Future<BuildingsAt> buildingsAt(double lat, double lon) async => BuildingsAt.fromJson(
      await _send('GET', '/api/v1/buildings/at?lat=${lat.toStringAsFixed(6)}&lon=${lon.toStringAsFixed(6)}')
          as Map<String, dynamic>);

  /// Ground temperature, heat flow and the estimated temperature at depth for one place.
  Future<GeoPoint> geoPoint(double lat, double lon) async => GeoPoint.fromJson(
      await _send('GET', '/api/v1/geo/point?lat=${lat.toStringAsFixed(5)}&lon=${lon.toStringAsFixed(5)}')
          as Map<String, dynamic>);

  /// Available biomass, crop and forest residues within 25 km and their energy for one place.
  Future<BioPoint> bioPoint(double lat, double lon) async => BioPoint.fromJson(
      await _send('GET', '/api/v1/bio/point?lat=${lat.toStringAsFixed(5)}&lon=${lon.toStringAsFixed(5)}')
          as Map<String, dynamic>);

  /// How the biomass map layers are drawn and where their tiles are.
  Future<BioLayers> bioLayers() async =>
      BioLayers.fromJson(await _send('GET', '/api/v1/bio/layers') as Map<String, dynamic>);

  /// How the geothermal map layers are drawn and where their tiles are.
  Future<GeoLayers> geoLayers() async =>
      GeoLayers.fromJson(await _send('GET', '/api/v1/geo/layers') as Map<String, dynamic>);

  /// How the river map layers are drawn and where their tiles are.
  Future<HydroLayers> hydroLayers() async =>
      HydroLayers.fromJson(await _send('GET', '/api/v1/hydro/layers') as Map<String, dynamic>);

  /// Full address of a backend path, for things the map loads by itself (layer pictures).
  String urlOf(String path) => '$_baseUrl$path';

  /// Wakes the backend early (fire and forget) so it is up by the time the
  /// person has typed their password.
  Future<void> warmUp() async {
    try {
      await _http.get(Uri.parse('$_baseUrl/api/v1/ping')).timeout(AppConfig.coldStartTimeout);
      _serverHasAnswered = true;
    } catch (_) {
      // Only a head start; the real calls report their own errors.
    }
  }

  Future<dynamic> _send(String method, String path, {Map<String, dynamic>? body, bool isRetry = false}) async {
    final token = await _auth.idToken(forceRefresh: isRetry);
    final request = http.Request(method, Uri.parse('$_baseUrl$path'))..headers['Accept'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.body = jsonEncode(body);
    }

    http.Response response;
    try {
      response = await http.Response.fromStream(await _http.send(request).timeout(_timeout));
      _serverHasAnswered = true;
    } catch (_) {
      // Socket errors, DNS failures, timeouts and CORS rejections all land here.
      throw const ApiException.network();
    }

    if (response.statusCode == 401 && !isRetry && token != null) {
      return _send(method, path, body: body, isRetry: true);
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.bodyBytes.isEmpty) return null;
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    throw _errorFrom(response);
  }

  ApiException _errorFrom(http.Response response) {
    String? message;
    var fieldErrors = const <String, String>{};
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        message = decoded['message'] as String?;
        final raw = decoded['fieldErrors'];
        if (raw is Map) fieldErrors = raw.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
    } catch (_) {
      // Not JSON; the status code alone will do.
    }
    return ApiException(statusCode: response.statusCode, serverMessage: message, fieldErrors: fieldErrors);
  }
}
