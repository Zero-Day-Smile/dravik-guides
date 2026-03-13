import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';

import '../models/nominatim_result.dart';

class SearchService {
  static const _baseUrl = 'https://nominatim.openstreetmap.org';

  Future<List<String>> fetchLocationSuggestions(
    String query, {
    String languageCode = 'en',
  }) async {
    if (query.isEmpty) return [];

    final uri = Uri.parse(
      '$_baseUrl/search?q=$query&format=json&limit=5&accept-language=$languageCode',
    );

    final response = await http.get(uri, headers: {
      'User-Agent': 'Dravik/1.0'
    }).timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data
          .map((e) => e['display_name'] as String?)
          .where((e) => e != null && e.isNotEmpty)
          .take(8)
          .cast<String>()
          .toList();
    }

    throw Exception('Failed to fetch suggestions: ${response.statusCode}');
  }

  Future<LatLngBounds?> fetchBoundsForPlace(
    String query, {
    String languageCode = 'en',
  }) async {
    if (query.isEmpty) return null;

    final cache = Hive.box('offline_data');
    final cacheKey = 'nominatim:$languageCode:$query';
    final cached = cache.get(cacheKey);
    if (cached != null) {
      try {
        return NominatimResult.fromJson(cached).toLatLngBounds();
      } catch (_) {}
    }

    final uri = Uri.parse(
      '$_baseUrl/search?q=$query&format=json&limit=1&accept-language=$languageCode',
    );

    final response = await http.get(uri, headers: {
      'User-Agent': 'Dravik/1.0'
    }).timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      if (data.isNotEmpty) {
        cache.put(cacheKey, data[0]);
        return NominatimResult.fromJson(data[0]).toLatLngBounds();
      }
    }

    throw Exception('Geocoding failed for query: $query');
  }

  Future<NominatimResult?> reverseGeocode(
    double lat,
    double lon, {
    String languageCode = 'en',
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/reverse?format=json&lat=$lat&lon=$lon&accept-language=$languageCode&zoom=14',
    );

    try {
      final response = await http.get(uri, headers: {
        'User-Agent': 'Dravik/1.0'
      }).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return NominatimResult.fromJson(data);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Reverse geocode failed: $e');
    }
    return null;
  }
}
