import 'package:hive/hive.dart';

class OfflineRegionService {
  static final OfflineRegionService _instance = OfflineRegionService._();
  factory OfflineRegionService() => _instance;
  OfflineRegionService._();

  Future<Box> _regionsBox() async => Hive.openBox('offline_regions');

  Future<void> saveRegion(
    String name,
    double minLat,
    double maxLat,
    double minLon,
    double maxLon,
  ) async {
    final box = await _regionsBox();
    final region = {
      'name': name,
      'minLat': minLat,
      'maxLat': maxLat,
      'minLon': minLon,
      'maxLon': maxLon,
      'savedAt': DateTime.now().toIso8601String(),
      'trails': <Map>[], // Populated by MapScreen when visible
      'weather': <Map>[], // Populated by weather service
      'guides': <String>[],
    };
    await box.put(name, region);
  }

  Future<List<Map>> getSavedRegions() async {
    final box = await _regionsBox();
    return box.values.whereType<Map>().toList().cast<Map>();
  }

  Future<Map?> getRegion(String name) async {
    final box = await _regionsBox();
    return box.get(name) as Map?;
  }

  Future<void> deleteRegion(String name) async {
    final box = await _regionsBox();
    await box.delete(name);
  }

  Future<void> updateRegionTrails(String regionName, List<Map> trails) async {
    final box = await _regionsBox();
    final region = box.get(regionName) as Map?;
    if (region != null) {
      region['trails'] = trails;
      await box.put(regionName, region);
    }
  }

  Future<void> updateRegionWeather(String regionName, List<Map> weather) async {
    final box = await _regionsBox();
    final region = box.get(regionName) as Map?;
    if (region != null) {
      region['weather'] = weather;
      await box.put(regionName, region);
    }
  }

  Future<int> getRegionSize(String regionName) async {
    final region = await getRegion(regionName);
    if (region == null) return 0;

    int size = 0;
    size += (region['trails'] as List?)?.length ?? 0 * 1000; // ~1KB per trail
    size +=
        (region['weather'] as List?)?.length ?? 0 * 500; // ~500B per forecast
    return size;
  }
}
