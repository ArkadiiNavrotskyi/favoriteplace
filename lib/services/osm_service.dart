import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// OpenStreetMap helper — Nominatim (geocoding) + OSMDroid-style reverse geocode.
class OsmService {
  static const String _base = 'https://nominatim.openstreetmap.org';
  static const String _userAgent = 'favorite-places-app/1.0 (assignment)';

  /// Get current GPS position. Throws on denial.
  Future<Position> getCurrentPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw 'Location services are disabled.';
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Location permission denied.';
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw 'Location permission permanently denied. Enable in settings.';
    }
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Reverse geocode: coordinates → human-readable address.
  Future<String?> reverseGeocode(double lat, double lon) async {
    try {
      final uri = Uri.parse(
        '$_base/reverse?format=jsonv2&lat=$lat&lon=$lon&zoom=18',
      );
      final resp = await http.get(uri, headers: {'User-Agent': _userAgent});
      if (resp.statusCode != 200) return null;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return data['display_name'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Forward geocode: query → list of (lat, lon, displayName).
  Future<List<GeocodeResult>> search(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final uri = Uri.parse(
        '$_base/search?format=jsonv2&q=${Uri.encodeComponent(query)}&limit=5',
      );
      final resp = await http.get(uri, headers: {'User-Agent': _userAgent});
      if (resp.statusCode != 200) return [];
      final list = jsonDecode(resp.body) as List<dynamic>;
      return list.map((e) {
        final m = e as Map<String, dynamic>;
        return GeocodeResult(
          latitude: double.parse(m['lat'] as String),
          longitude: double.parse(m['lon'] as String),
          displayName: m['display_name'] as String,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}

class GeocodeResult {
  final double latitude;
  final double longitude;
  final String displayName;
  GeocodeResult({
    required this.latitude,
    required this.longitude,
    required this.displayName,
  });
}