import 'package:maplibre_gl/maplibre_gl.dart';

class NominatimResult {
  final LatLng southwest;
  final LatLng northeast;
  final LatLng? center;
  final String? displayName;
  final String? country;

  NominatimResult({
    required this.southwest,
    required this.northeast,
    this.center,
    this.displayName,
    this.country,
  });

  factory NominatimResult.fromJson(Map<String, dynamic> json) {
    final bounding = json['boundingbox'] as List?;
    final south = bounding != null && bounding.length >= 4
        ? double.tryParse(bounding[0].toString()) ?? 0
        : double.tryParse(json['lat']?.toString() ?? '') ?? 0;
    final north = bounding != null && bounding.length >= 4
        ? double.tryParse(bounding[1].toString()) ?? 0
        : south;
    final west = bounding != null && bounding.length >= 4
        ? double.tryParse(bounding[2].toString()) ?? 0
        : double.tryParse(json['lon']?.toString() ?? '') ?? 0;
    final east = bounding != null && bounding.length >= 4
        ? double.tryParse(bounding[3].toString()) ?? 0
        : west;

    final centerLat = double.tryParse(json['lat']?.toString() ?? '');
    final centerLon = double.tryParse(json['lon']?.toString() ?? '');

    String? country;
    final address = json['address'] as Map<String, dynamic>?;
    if (address != null) {
      country = address['country'] as String?;
    }

    return NominatimResult(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
      center: centerLat != null && centerLon != null
          ? LatLng(centerLat, centerLon)
          : null,
      displayName: json['display_name'] as String?,
      country: country,
    );
  }

  LatLngBounds toLatLngBounds() {
    return LatLngBounds(southwest: southwest, northeast: northeast);
  }
}
