import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';

class OverpassService {
  static const String _endpoint = 'https://overpass-api.de/api/interpreter';

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0; // km
    double toRad(double d) => d * pi / 180.0;
    final dLat = toRad(lat2 - lat1);
    final dLon = toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(toRad(lat1)) * cos(toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  Future<List<Map<String, dynamic>>> queryAerodromes(double lat, double lon,
      {int radiusMeters = 100000, int limit = 5}) async {
    final q = '''[out:json][timeout:25];
(
  node["aeroway"="aerodrome"](around:$radiusMeters,$lat,$lon);
  way["aeroway"="aerodrome"](around:$radiusMeters,$lat,$lon);
  relation["aeroway"="aerodrome"](around:$radiusMeters,$lat,$lon);
);
out center tags $limit;''';

    final resp = await http.post(Uri.parse(_endpoint), body: {'data': q});
    if (resp.statusCode != 200) return [];
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final elements = (json['elements'] as List?) ?? [];
    final results = <Map<String, dynamic>>[];
    for (final e in elements) {
      final tags = (e['tags'] as Map?)?.cast<String, dynamic>() ?? {};
      final center = (e['center'] as Map?)?.cast<String, dynamic>();
      final nlat = (e['lat'] ?? center?['lat'])?.toDouble();
      final nlon = (e['lon'] ?? center?['lon'])?.toDouble();
      if (nlat is double && nlon is double) {
        final dist = _haversine(lat, lon, nlat, nlon);
        results.add({
          'name': tags['name'] ?? 'Unnamed Aerodrome',
          'iata': tags['iata'],
          'icao': tags['icao'],
          'distanceKm': dist,
        });
      }
    }
    results.sort((a, b) =>
        (a['distanceKm'] as double).compareTo(b['distanceKm'] as double));
    return results.take(limit).toList();
  }

  Future<List<Map<String, dynamic>>> queryTrainStations(double lat, double lon,
      {int radiusMeters = 50000, int limit = 5}) async {
    final q = '''[out:json][timeout:25];
(
  node["railway"="station"](around:$radiusMeters,$lat,$lon);
  way["railway"="station"](around:$radiusMeters,$lat,$lon);
);
out center tags $limit;''';

    final resp = await http.post(Uri.parse(_endpoint), body: {'data': q});
    if (resp.statusCode != 200) return [];
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final elements = (json['elements'] as List?) ?? [];
    final results = <Map<String, dynamic>>[];
    for (final e in elements) {
      final tags = (e['tags'] as Map?)?.cast<String, dynamic>() ?? {};
      final center = (e['center'] as Map?)?.cast<String, dynamic>();
      final nlat = (e['lat'] ?? center?['lat'])?.toDouble();
      final nlon = (e['lon'] ?? center?['lon'])?.toDouble();
      if (nlat is double && nlon is double) {
        final dist = _haversine(lat, lon, nlat, nlon);
        results.add({
          'name': tags['name'] ?? 'Train Station',
          'type': 'train',
          'distanceKm': dist,
        });
      }
    }
    results.sort((a, b) =>
        (a['distanceKm'] as double).compareTo(b['distanceKm'] as double));
    return results.take(limit).toList();
  }

  Future<List<Map<String, dynamic>>> queryTransportStops(double lat, double lon,
      {int radiusMeters = 5000, int limitPerType = 5}) async {
    final q = '''[out:json][timeout:25];
(
  node["public_transport"="station"](around:$radiusMeters,$lat,$lon);
  node["railway"="subway_entrance"](around:$radiusMeters,$lat,$lon);
  node["highway"="bus_stop"](around:$radiusMeters,$lat,$lon);
);
out tags geom;''';

    final resp = await http.post(Uri.parse(_endpoint), body: {'data': q});
    if (resp.statusCode != 200) return [];
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final elements = (json['elements'] as List?) ?? [];
    final results = <Map<String, dynamic>>[];
    for (final e in elements) {
      final tags = (e['tags'] as Map?)?.cast<String, dynamic>() ?? {};
      final nlat = (e['lat'] as num?)?.toDouble();
      final nlon = (e['lon'] as num?)?.toDouble();
      if (nlat is double && nlon is double) {
        final dist = _haversine(lat, lon, nlat, nlon);
        String type = 'transport';
        if (tags['railway'] == 'station') type = 'train';
        if (tags['railway'] == 'subway_entrance') type = 'subway';
        if (tags['highway'] == 'bus_stop') type = 'bus';
        if (tags['public_transport'] == 'station') type = 'station';
        results.add({
          'name': tags['name'] ?? 'Unnamed',
          'type': type,
          'distanceKm': dist,
        });
      }
    }
    results.sort((a, b) =>
        (a['distanceKm'] as double).compareTo(b['distanceKm'] as double));

    // enforce a small per-type limit for balance
    final byType = <String, int>{};
    final capped = <Map<String, dynamic>>[];
    for (final r in results) {
      final t = r['type'] as String;
      final count = byType[t] ?? 0;
      if (count < limitPerType) {
        byType[t] = count + 1;
        capped.add(r);
      }
    }
    return capped;
  }

  Future<List<Map<String, dynamic>>> fetchTrails({
    required LatLng southwest,
    required LatLng northeast,
    String? trailName,
  }) async {
    final bbox = _bbox(southwest, northeast);
    final nameFilter = (trailName != null && trailName.isNotEmpty)
        ? "[\"name\"~\"$trailName\",i]"
        : '';
    final query = '''
      [out:json][timeout:15];
      way["highway"~"path|footway|bridleway"]$nameFilter
      ($bbox);
      out geom;
    ''';
    final data = await _run(query);
    return data
        .map<Map<String, dynamic>>((e) => {
              'type': 'Feature',
              'properties': {
                'id': e['id'].toString(),
                'name': e['tags']?['name'] ?? 'Unnamed Trail',
                'difficulty': e['tags']?['sac_scale'] ?? 'hiking',
                'surface': e['tags']?['surface'] ?? 'unknown',
              },
              'geometry': {
                'type': 'LineString',
                'coordinates': (e['geometry'] as List)
                    .map((g) => [g['lon'], g['lat']])
                    .toList(),
              },
            })
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchShelters({
    required LatLng southwest,
    required LatLng northeast,
  }) async {
    final bbox = _bbox(southwest, northeast);
    const filter = '["tourism"="alpine_hut"],["amenity"="shelter"]';
    final query = '''
      [out:json][timeout:15];
      (
        node$filter($bbox);
        way$filter($bbox);
        relation$filter($bbox);
      );
      out center;
    ''';
    final data = await _run(query);
    return _pointsFromElements(data, defaultName: 'Shelter');
  }

  Future<List<Map<String, dynamic>>> fetchWaterSources({
    required LatLng southwest,
    required LatLng northeast,
  }) async {
    final bbox = _bbox(southwest, northeast);
    const filter = '["natural"="spring"],["amenity"="drinking_water"]';
    final query = '''
      [out:json][timeout:15];
      (
        node$filter($bbox);
        way$filter($bbox);
      );
      out center;
    ''';
    final data = await _run(query);
    return _pointsFromElements(data, defaultName: 'Water Source');
  }

  Future<List<Map<String, dynamic>>> fetchPOIs({
    required LatLng southwest,
    required LatLng northeast,
    required String key,
    required List<String> values,
    String? label,
  }) async {
    final bbox = _bbox(southwest, northeast);

    final query = '''
      [out:json][timeout:15];
      (
        node[$key]["$key"~"${values.join('|')}"]($bbox);
        way[$key]["$key"~"${values.join('|')}"]($bbox);
      );
      out center 100;
    ''';
    final data = await _run(query);
    return data.take(100).map<Map<String, dynamic>>((e) {
      final props = e['tags'] ?? {};
      final name = props['name'] ?? label ?? 'POI';
      final center =
          e['type'] == 'way' ? (e['center'] ?? e['geometry']?[0]) : e;
      final lon = center['lon'] ?? 0.0;
      final lat = center['lat'] ?? 0.0;
      return {
        'type': 'Feature',
        'properties': {
          'id': e['id'].toString(),
          'name': name,
          'category': label ?? key,
        },
        'geometry': {
          'type': 'Point',
          'coordinates': [lon, lat],
        },
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> fetchCompositePOIs({
    required LatLng southwest,
    required LatLng northeast,
    required List<Map<String, dynamic>> filters,
    String defaultLabel = 'POI',
  }) async {
    final bbox = _bbox(southwest, northeast);
    final buffer = filters.map((f) {
      final key = f['key'] as String;
      final values = (f['values'] as List).join('|');
      return '''
        node["$key"~"$values"]($bbox);
        way["$key"~"$values"]($bbox);
      ''';
    }).join();

    final query = '''
      [out:json][timeout:20];
      (
        $buffer
      );
      out center 100;
    ''';

    final data = await _run(query);
    return data.take(100).map<Map<String, dynamic>>((e) {
      final props = e['tags'] ?? {};
      final name = props['name'] ?? defaultLabel;
      final center =
          e['type'] == 'way' ? (e['center'] ?? e['geometry']?[0]) : e;
      final lon = center['lon'] ?? 0.0;
      final lat = center['lat'] ?? 0.0;
      return {
        'type': 'Feature',
        'properties': {
          'id': e['id'].toString(),
          'name': name,
          'category': defaultLabel,
        },
        'geometry': {
          'type': 'Point',
          'coordinates': [lon, lat],
        },
      };
    }).toList();
  }

  // Helpers
  Future<List<dynamic>> _run(String query) async {
    final response = await http
        .post(Uri.parse(_endpoint), body: query)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['elements'] as List?) ?? [];
    }
    throw Exception('Overpass error: ${response.statusCode}');
  }

  List<Map<String, dynamic>> _pointsFromElements(List elements,
      {required String defaultName}) {
    return elements.map<Map<String, dynamic>>((e) {
      final center =
          e['type'] == 'way' ? (e['center'] ?? e['geometry']?[0]) : e;
      final lon = center['lon'] ?? 0.0;
      final lat = center['lat'] ?? 0.0;
      return {
        'type': 'Feature',
        'properties': {
          'id': e['id'].toString(),
          'name': e['tags']?['name'] ?? defaultName,
        },
        'geometry': {
          'type': 'Point',
          'coordinates': [lon, lat],
        },
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> fetchLandcover({
    required LatLng southwest,
    required LatLng northeast,
  }) async {
    final bbox = _bbox(southwest, northeast);
    final query = '''
      [out:json][timeout:20];
      (
        way["natural"~"wood|forest|scrub|grassland|sand|wetland"]($bbox);
        relation["natural"~"wood|forest|scrub|grassland|sand|wetland"]($bbox);
        way["landuse"~"forest|meadow|grass|wetland"]($bbox);
        relation["landuse"~"forest|meadow|grass|wetland"]($bbox);
      );
      out geom;
    ''';
    final data = await _run(query);
    return data
        .map<Map<String, dynamic>>((e) {
          final tags = e['tags'] ?? {};
          final type = tags['natural'] ?? tags['landuse'] ?? 'unknown';
          String color = '#90EE90'; // default green
          if (type.contains('forest') || type.contains('wood')) {
            color = '#228B22';
          } else if (type.contains('grass') || type.contains('meadow')) {
            color = '#7CFC00';
          } else if (type.contains('sand')) {
            color = '#F4A460';
          } else if (type.contains('wetland')) {
            color = '#4682B4';
          } else if (type.contains('scrub')) {
            color = '#556B2F';
          }

          final geometry = e['geometry'] ?? e['members'];
          List<List<double>> coordinates = [];
          if (e['type'] == 'way' && geometry != null) {
            coordinates = (geometry as List)
                .map((g) => [g['lon'] as double, g['lat'] as double])
                .toList();
          }

          return {
            'type': 'Feature',
            'properties': {
              'id': e['id'].toString(),
              'landcover': type,
              'color': color,
            },
            'geometry': {
              'type': 'Polygon',
              'coordinates': coordinates.isNotEmpty ? [coordinates] : [],
            },
          };
        })
        .where((f) => (f['geometry']['coordinates'] as List).isNotEmpty)
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchProtectedAreas({
    required LatLng southwest,
    required LatLng northeast,
  }) async {
    final bbox = _bbox(southwest, northeast);
    final query = '''
      [out:json][timeout:20];
      (
        way["boundary"="protected_area"]($bbox);
        relation["boundary"="protected_area"]($bbox);
        way["boundary"="national_park"]($bbox);
        relation["boundary"="national_park"]($bbox);
        way["leisure"="nature_reserve"]($bbox);
        relation["leisure"="nature_reserve"]($bbox);
      );
      out geom;
    ''';
    final data = await _run(query);
    return data
        .map<Map<String, dynamic>>((e) {
          final tags = e['tags'] ?? {};
          final name = tags['name'] ?? 'Protected Area';
          final protectClass = tags['protect_class'] ?? 'unknown';

          final geometry = e['geometry'] ?? e['members'];
          List<List<double>> coordinates = [];
          if (e['type'] == 'way' && geometry != null) {
            coordinates = (geometry as List)
                .map((g) => [g['lon'] as double, g['lat'] as double])
                .toList();
          }

          return {
            'type': 'Feature',
            'properties': {
              'id': e['id'].toString(),
              'name': name,
              'protect_class': protectClass,
            },
            'geometry': {
              'type': 'Polygon',
              'coordinates': coordinates.isNotEmpty ? [coordinates] : [],
            },
          };
        })
        .where((f) => (f['geometry']['coordinates'] as List).isNotEmpty)
        .toList();
  }

  String _bbox(LatLng sw, LatLng ne) =>
      '${sw.latitude},${sw.longitude},${ne.latitude},${ne.longitude}';
}
