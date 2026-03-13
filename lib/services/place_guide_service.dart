import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:hive/hive.dart';

import '../models/place_guide.dart';
import 'overpass_service.dart';
import 'search_service.dart';

class PlaceGuideService {
  final _overpass = OverpassService();
  final _search = SearchService();
  static const String _cacheBoxName = 'place_guides_cache';

  Future<Box> _cacheBox() async => await Hive.openBox(_cacheBoxName);

  String _cacheKey(String place, int month) =>
      '${place.toLowerCase().trim()}_$month';

  Future<PlaceGuide?> getCached(String placeQuery, int month) async {
    try {
      final box = await _cacheBox();
      final key = _cacheKey(placeQuery, month);
      final data = box.get(key);
      if (data != null) {
        final guide =
            PlaceGuide.fromJson(Map<String, dynamic>.from(data as Map));
        // Cache valid for 7 days
        if (DateTime.now().difference(guide.generatedAt).inDays < 7) {
          return guide;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _saveCache(
      String placeQuery, int month, PlaceGuide guide) async {
    try {
      final box = await _cacheBox();
      final key = _cacheKey(placeQuery, month);
      await box.put(key, guide.toJson());
    } catch (_) {}
  }

  Future<List<PlaceGuide>> getAllCached() async {
    try {
      final box = await _cacheBox();
      return box.values
          .map((v) => PlaceGuide.fromJson(Map<String, dynamic>.from(v as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<(LatLng, String)> _resolvePlace(String query) async {
    final bounds = await _search.fetchBoundsForPlace(query);
    if (bounds == null) {
      throw Exception('Failed to locate place: $query');
    }
    // approximate center
    final lat = (bounds.northeast.latitude + bounds.southwest.latitude) / 2;
    final lon = (bounds.northeast.longitude + bounds.southwest.longitude) / 2;
    return (LatLng(lat, lon), query);
  }

  Future<PlaceClimateSummary> _fetchMonthlyClimate(
      double lat, double lon, int month) async {
    final m = month.clamp(1, 12);
    final uri = Uri.parse(
        'https://climate-api.open-meteo.com/v1/climate?latitude=$lat&longitude=$lon&start_year=1991&end_year=2020&models=ERA5&month=$m&temperature_2m_mean=1&precipitation_sum=1');
    try {
      final resp = await http.get(uri).timeout(const Duration(seconds: 12));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final monthly = (data['monthly'] as Map<String, dynamic>?);
        double? t;
        double? p;
        if (monthly != null) {
          final temps = (monthly['temperature_2m_mean'] as List?)?.cast<num>();
          final prec = (monthly['precipitation_sum'] as List?)?.cast<num>();
          // For single-month query, API returns single values in arrays
          if (temps != null && temps.isNotEmpty) t = temps.first.toDouble();
          if (prec != null && prec.isNotEmpty) p = prec.first.toDouble();
        }
        return PlaceClimateSummary(
            month: m, temperatureMeanC: t, precipitationMm: p);
      }
    } catch (_) {}
    return PlaceClimateSummary(
        month: m, temperatureMeanC: null, precipitationMm: null);
  }

  String climateDescription(PlaceClimateSummary c) {
    final monthName = DateFormat.MMMM().format(DateTime(2000, c.month));
    if (c.temperatureMeanC == null && c.precipitationMm == null) {
      return 'Typical $monthName climate data unavailable for this location.';
    }
    final parts = <String>[];
    if (c.temperatureMeanC != null) {
      parts.add('avg temp ~${c.temperatureMeanC!.toStringAsFixed(1)}°C');
    }
    if (c.precipitationMm != null) {
      parts.add('precip ${c.precipitationMm!.toStringAsFixed(0)} mm');
    }
    return '$monthName climate: ${parts.join(', ')}.';
  }

  Future<PlaceGuide> generate({
    required String placeQuery,
    required int month,
    bool useCache = true,
  }) async {
    // Check cache first
    if (useCache) {
      final cached = await getCached(placeQuery, month);
      if (cached != null) return cached;
    }

    final (center, name) = await _resolvePlace(placeQuery);
    final climate =
        await _fetchMonthlyClimate(center.latitude, center.longitude, month);

    // Expanded airport search (200km radius)
    final airportsRaw = await _overpass.queryAerodromes(
      center.latitude,
      center.longitude,
      radiusMeters: 200000,
      limit: 5,
    );
    final airports = airportsRaw
        .map((e) => PlaceGuideAirport(
              name: (e['name'] as String?) ?? 'Airport',
              iata: e['iata'] as String?,
              icao: e['icao'] as String?,
              distanceKm: (e['distanceKm'] as num).toDouble(),
            ))
        .toList();

    // Add train stations (50km search)
    final trainsRaw = await _overpass.queryTrainStations(
      center.latitude,
      center.longitude,
      radiusMeters: 50000,
      limit: 3,
    );

    final transportRaw =
        await _overpass.queryTransportStops(center.latitude, center.longitude);
    final allTransport = [...trainsRaw, ...transportRaw];
    final transport = allTransport
        .map((e) => PlaceGuideTransportStop(
              name: (e['name'] as String?)?.trim().isEmpty == true
                  ? 'Stop'
                  : (e['name'] as String? ?? 'Stop'),
              type: (e['type'] as String?) ?? 'transport',
              distanceKm: (e['distanceKm'] as num).toDouble(),
            ))
        .toList();
    transport.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    // Generate solo traveler safety info
    final safetyInfo = await _generateSafetyInfo(placeQuery, center);

    final guide = PlaceGuide(
      placeName: name,
      latitude: center.latitude,
      longitude: center.longitude,
      climate: climate,
      nearestAirports: airports,
      nearbyTransport: transport.take(15).toList(),
      safetyInfo: safetyInfo,
    );

    // Save to cache
    await _saveCache(placeQuery, month, guide);

    return guide;
  }

  Future<SoloTravelSafety> _generateSafetyInfo(
      String placeQuery, LatLng center) async {
    // Try to get country info from reverse geocode
    final countryInfo = await _search.reverseGeocode(
      center.latitude,
      center.longitude,
    );
    final country = countryInfo?.country?.toLowerCase() ?? '';

    // Country-specific emergency numbers
    String? emergency, police, ambulance;
    String? currency, language;
    final safetyTips = <String>[];
    final phrases = <Map<String, String>>[];
    final customs = <String>[];

    // Common worldwide safety tips for solo travelers
    safetyTips.addAll([
      'Share your itinerary with someone back home',
      'Keep copies of important documents separately',
      'Stay in well-lit, populated areas at night',
      'Trust your instincts - if something feels wrong, leave',
      'Use official transportation services',
      'Keep valuables concealed and secured',
    ]);

    // Country-specific data
    if (country.contains('united states') || country.contains('usa')) {
      emergency = '911';
      police = '911';
      ambulance = '911';
      currency = 'USD';
      language = 'English';
      safetyTips.add('Tip 15-20% at restaurants');
      customs.addAll([
        'Tipping is expected in restaurants and taxis',
        'Personal space is important - keep arms length',
        'Punctuality is valued',
      ]);
      phrases.addAll([
        {'english': 'Emergency', 'local': 'Emergency'},
        {'english': 'Help', 'local': 'Help'},
        {'english': 'Hospital', 'local': 'Hospital'},
      ]);
    } else if (country.contains('japan')) {
      emergency = '110 (Police) / 119 (Fire/Ambulance)';
      police = '110';
      ambulance = '119';
      currency = 'JPY (Yen)';
      language = 'Japanese';
      safetyTips.addAll([
        'Crime rate is very low, but stay alert',
        'Learn basic Japanese phrases - English limited outside cities',
        'Carry cash - many places do not accept cards',
      ]);
      customs.addAll([
        'Bow when greeting',
        'Remove shoes indoors',
        'No tipping - it can be considered rude',
        'Be quiet on public transport',
      ]);
      phrases.addAll([
        {'english': 'Help', 'local': 'Tasukete (助けて)'},
        {'english': 'Emergency', 'local': 'Kinkyū (緊急)'},
        {'english': 'Hospital', 'local': 'Byōin (病院)'},
        {'english': 'Police', 'local': 'Keisatsu (警察)'},
      ]);
    } else if (country.contains('france')) {
      emergency = '112';
      police = '17';
      ambulance = '15';
      currency = 'EUR (Euro)';
      language = 'French';
      safetyTips.addAll([
        'Beware of pickpockets in tourist areas',
        'Learn basic French - locals appreciate the effort',
      ]);
      customs.addAll([
        'Greet with "Bonjour" before asking questions',
        'Tipping not required but rounding up is polite',
        'Dress modestly when visiting churches',
      ]);
      phrases.addAll([
        {'english': 'Help', 'local': 'Au secours'},
        {'english': 'Emergency', 'local': 'Urgence'},
        {'english': 'Hospital', 'local': 'Hôpital'},
      ]);
    } else if (country.contains('india')) {
      emergency = '112';
      police = '100';
      ambulance = '102';
      currency = 'INR (Rupee)';
      language = 'Hindi/English';
      safetyTips.addAll([
        'Dress modestly, especially for women',
        'Avoid drinking tap water - stick to bottled',
        'Be cautious with street food if you have a sensitive stomach',
        'Female travelers: avoid isolated areas after dark',
      ]);
      customs.addAll([
        'Remove shoes before entering temples and homes',
        'Use right hand for eating and greeting',
        'Haggling is expected in markets',
      ]);
      phrases.addAll([
        {'english': 'Help', 'local': 'Madad (मदद)'},
        {'english': 'Emergency', 'local': 'Āpātakāl (आपातकाल)'},
        {'english': 'Hospital', 'local': 'Aspatal (अस्पताल)'},
      ]);
    } else if (country.contains('spain')) {
      emergency = '112';
      police = '091';
      ambulance = '061';
      currency = 'EUR (Euro)';
      language = 'Spanish';
      safetyTips.add('Watch for pickpockets in Barcelona and Madrid');
      customs.addAll([
        'Late meal times: lunch 2-4pm, dinner 9-11pm',
        'Siesta time: many shops close 2-5pm',
        'Greet with two kisses on cheeks',
      ]);
      phrases.addAll([
        {'english': 'Help', 'local': 'Ayuda'},
        {'english': 'Emergency', 'local': 'Emergencia'},
        {'english': 'Hospital', 'local': 'Hospital'},
      ]);
    } else if (country.contains('germany')) {
      emergency = '112';
      police = '110';
      ambulance = '112';
      currency = 'EUR (Euro)';
      language = 'German';
      customs.addAll([
        'Punctuality is very important',
        'Jaywalking is frowned upon',
        'Cash is preferred over cards in many places',
      ]);
      phrases.addAll([
        {'english': 'Help', 'local': 'Hilfe'},
        {'english': 'Emergency', 'local': 'Notfall'},
        {'english': 'Hospital', 'local': 'Krankenhaus'},
      ]);
    } else if (country.contains('australia')) {
      emergency = '000';
      police = '000';
      ambulance = '000';
      currency = 'AUD';
      language = 'English';
      safetyTips.addAll([
        'Beware of dangerous wildlife (spiders, snakes, jellyfish)',
        'UV levels are extreme - use strong sunscreen',
        'Stay between the flags when swimming',
      ]);
      customs.addAll([
        'Casual and laid-back culture',
        'Tipping not mandatory but appreciated',
      ]);
    } else {
      // Generic international emergency
      emergency = '112 (EU) or local equivalent';
      safetyTips.add('Research local emergency numbers before arrival');
      customs.add('Research local customs and dress codes');
    }

    return SoloTravelSafety(
      emergencyNumber: emergency,
      policeNumber: police,
      ambulanceNumber: ambulance,
      safetyTips: safetyTips,
      commonPhrases: phrases,
      currency: currency,
      language: language,
      localCustoms: customs,
    );
  }
}
