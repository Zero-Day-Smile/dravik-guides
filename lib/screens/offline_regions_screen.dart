import 'package:flutter/material.dart';
import 'package:dravik/services/offline_region_service.dart';
import 'package:dravik/services/offline_weather_service.dart';
import 'package:dravik/config/feature_flags.dart';
import 'package:dravik/widgets/platform_unavailable_screen.dart';

class OfflineRegionsScreen extends StatefulWidget {
  const OfflineRegionsScreen({super.key});

  @override
  State<OfflineRegionsScreen> createState() => _OfflineRegionsScreenState();
}

class _OfflineRegionsScreenState extends State<OfflineRegionsScreen> {
  final _regionService = OfflineRegionService();
  final _weatherService = OfflineWeatherService();
  List<Map> _regions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRegions();
  }

  Future<void> _loadRegions() async {
    setState(() => _loading = true);
    _regions = await _regionService.getSavedRegions();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveNewRegion() async {
    final nameCtrl = TextEditingController();
    final latCtrl = TextEditingController();
    final lonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Region'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                  hintText: 'Region name (e.g., "Mount Blanc")'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: latCtrl,
              decoration: const InputDecoration(hintText: 'Center latitude'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lonCtrl,
              decoration: const InputDecoration(hintText: 'Center longitude'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final lat = double.tryParse(latCtrl.text);
              final lon = double.tryParse(lonCtrl.text);

              if (name.isEmpty || lat == null || lon == null) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid input')),
                  );
                }
                return;
              }

              // Save with 0.5 degree radius (~55km)
              await _regionService.saveRegion(
                name,
                lat - 0.5,
                lat + 0.5,
                lon - 0.5,
                lon + 0.5,
              );

              // Download weather for region
              await _weatherService.downloadForecast(lat, lon, name);

              Navigator.pop(ctx);
              _loadRegions();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.isEnabled(AppFeature.offlineRegions)) {
      return const PlatformUnavailableScreen(
        title: 'Offline Regions',
        message:
            'Offline region downloads are optimized for mobile app usage and storage controls.',
        icon: Icons.download,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Regions'),
        backgroundColor: Colors.deepPurple.shade700,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _regions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.download,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text(
                        'No offline regions saved',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Save regions to download weather & trails',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _regions.length,
                  itemBuilder: (ctx, i) {
                    final region = _regions[i];
                    return _buildRegionCard(region);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveNewRegion,
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.add_location),
        label: const Text('Save Region'),
      ),
    );
  }

  Widget _buildRegionCard(Map region) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        leading: Icon(Icons.location_on, color: Colors.deepPurple),
        title: Text(region['name'] ?? 'Unknown'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${region['minLat']?.toStringAsFixed(2)} to ${region['maxLat']?.toStringAsFixed(2)}°N',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              '${region['minLon']?.toStringAsFixed(2)} to ${region['maxLon']?.toStringAsFixed(2)}°E',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('📍 ${(region['trails'] as List?)?.length ?? 0} trails',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(width: 12),
                Text(
                    '🌦️ ${(region['weather'] as List?)?.length ?? 0} forecasts',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (_) => [
            PopupMenuItem(
              child: const Text('Delete'),
              onTap: () async {
                await _regionService.deleteRegion(region['name']);
                _loadRegions();
              },
            ),
          ],
        ),
      ),
    );
  }
}
