class PlaceGuideAirport {
  final String name;
  final String? iata;
  final String? icao;
  final double distanceKm;

  PlaceGuideAirport({
    required this.name,
    this.iata,
    this.icao,
    required this.distanceKm,
  });
}

class PlaceGuideTransportStop {
  final String name;
  final String type; // bus, train, subway
  final double distanceKm;

  PlaceGuideTransportStop({
    required this.name,
    required this.type,
    required this.distanceKm,
  });
}

class PlaceClimateSummary {
  final int month; // 1-12
  final double? temperatureMeanC;
  final double? precipitationMm;

  PlaceClimateSummary({
    required this.month,
    this.temperatureMeanC,
    this.precipitationMm,
  });
}

class SoloTravelSafety {
  final String? emergencyNumber;
  final String? policeNumber;
  final String? ambulanceNumber;
  final List<String> safetyTips;
  final List<Map<String, String>> commonPhrases; // {phrase: translation}
  final String? currency;
  final String? language;
  final List<String> localCustoms;

  SoloTravelSafety({
    this.emergencyNumber,
    this.policeNumber,
    this.ambulanceNumber,
    required this.safetyTips,
    required this.commonPhrases,
    this.currency,
    this.language,
    required this.localCustoms,
  });
}

class PlaceGuide {
  final String placeName;
  final double latitude;
  final double longitude;
  final PlaceClimateSummary climate;
  final List<PlaceGuideAirport> nearestAirports;
  final List<PlaceGuideTransportStop> nearbyTransport;
  final SoloTravelSafety? safetyInfo;
  final DateTime generatedAt;

  PlaceGuide({
    required this.placeName,
    required this.latitude,
    required this.longitude,
    required this.climate,
    required this.nearestAirports,
    required this.nearbyTransport,
    this.safetyInfo,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'placeName': placeName,
        'latitude': latitude,
        'longitude': longitude,
        'climate': {
          'month': climate.month,
          'temperatureMeanC': climate.temperatureMeanC,
          'precipitationMm': climate.precipitationMm,
        },
        'nearestAirports': nearestAirports
            .map((a) => {
                  'name': a.name,
                  'iata': a.iata,
                  'icao': a.icao,
                  'distanceKm': a.distanceKm,
                })
            .toList(),
        'nearbyTransport': nearbyTransport
            .map((t) => {
                  'name': t.name,
                  'type': t.type,
                  'distanceKm': t.distanceKm,
                })
            .toList(),
        'safetyInfo': safetyInfo != null
            ? {
                'emergencyNumber': safetyInfo!.emergencyNumber,
                'policeNumber': safetyInfo!.policeNumber,
                'ambulanceNumber': safetyInfo!.ambulanceNumber,
                'safetyTips': safetyInfo!.safetyTips,
                'commonPhrases': safetyInfo!.commonPhrases,
                'currency': safetyInfo!.currency,
                'language': safetyInfo!.language,
                'localCustoms': safetyInfo!.localCustoms,
              }
            : null,
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory PlaceGuide.fromJson(Map<String, dynamic> json) => PlaceGuide(
        placeName: json['placeName'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        climate: PlaceClimateSummary(
          month: (json['climate']['month'] as num).toInt(),
          temperatureMeanC:
              (json['climate']['temperatureMeanC'] as num?)?.toDouble(),
          precipitationMm:
              (json['climate']['precipitationMm'] as num?)?.toDouble(),
        ),
        nearestAirports: (json['nearestAirports'] as List)
            .map((a) => PlaceGuideAirport(
                  name: a['name'] as String,
                  iata: a['iata'] as String?,
                  icao: a['icao'] as String?,
                  distanceKm: (a['distanceKm'] as num).toDouble(),
                ))
            .toList(),
        nearbyTransport: (json['nearbyTransport'] as List)
            .map((t) => PlaceGuideTransportStop(
                  name: t['name'] as String,
                  type: t['type'] as String,
                  distanceKm: (t['distanceKm'] as num).toDouble(),
                ))
            .toList(),
        safetyInfo: json['safetyInfo'] != null
            ? SoloTravelSafety(
                emergencyNumber:
                    json['safetyInfo']['emergencyNumber'] as String?,
                policeNumber: json['safetyInfo']['policeNumber'] as String?,
                ambulanceNumber:
                    json['safetyInfo']['ambulanceNumber'] as String?,
                safetyTips:
                    List<String>.from(json['safetyInfo']['safetyTips'] ?? []),
                commonPhrases: List<Map<String, String>>.from(
                  (json['safetyInfo']['commonPhrases'] ?? []).map(
                    (p) => Map<String, String>.from(p),
                  ),
                ),
                currency: json['safetyInfo']['currency'] as String?,
                language: json['safetyInfo']['language'] as String?,
                localCustoms:
                    List<String>.from(json['safetyInfo']['localCustoms'] ?? []),
              )
            : null,
        generatedAt: DateTime.parse(json['generatedAt'] as String),
      );
}
