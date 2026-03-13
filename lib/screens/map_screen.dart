import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:math' show Point;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart' as fmtc;
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:url_launcher/url_launcher.dart';
import 'package:dravik/models/enums.dart';
import 'package:dravik/services/mission_engine/mission_engine.dart';
import 'package:dravik/services/mission_engine/mission_event.dart';
import 'package:dravik/services/mission_engine/mission_state.dart';
import 'package:dravik/services/power_manager/mission_power_manager.dart';
import 'package:dravik/services/sensor_layer/compass_adapter.dart';
import 'package:dravik/services/sensor_layer/location_sensor_adapter.dart';
import 'package:dravik/services/overpass_service.dart';
import 'package:dravik/services/search_service.dart';
import 'package:dravik/services/weather_service.dart';
import 'package:dravik/models/weather.dart';
import 'package:dravik/models/place_guide.dart';
import 'package:dravik/screens/place_guide_screen.dart';
import 'package:dravik/config/platform_capabilities.dart';
import 'package:dravik/widgets/edition_banner_for_screen.dart';
import 'package:dravik/config/edition_copy.dart';
import 'package:dravik/widgets/mission_status_card.dart';

class MapScreen extends StatefulWidget {
  final String? initialQuery;
  final bool autoDownloadRegion;
  // Optional target coordinates to focus and mark on map
  final double? initialLat;
  final double? initialLon;

  const MapScreen({
    super.key,
    this.initialQuery,
    this.autoDownloadRegion = false,
    this.initialLat,
    this.initialLon,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  MapLibreMapController? _mapController;
  LatLngBounds? _selectedBounds;
  LatLng? _navTarget; // target to focus and display when opened from AR
  final latlong.Distance _geo = const latlong.Distance();
  final MissionEngine _missionEngine = Get.isRegistered<MissionEngine>()
      ? Get.find<MissionEngine>()
      : Get.put(MissionEngine(), permanent: true);
  final MissionPowerManager _missionPowerManager =
      Get.isRegistered<MissionPowerManager>()
          ? Get.find<MissionPowerManager>()
          : Get.put(MissionPowerManager(), permanent: true);
  final CompassAdapter _compassAdapter = CompassAdapter();
  final LocationSensorAdapter _locationAdapter = LocationSensorAdapter();
  LatLng? _myPosition;
  double? _distanceToTarget;
  double? _bearingToTarget;
  double _lastHeadingDegrees = 0;
  latlong.LatLng? _lastSlopeSamplePosition;
  double? _lastSlopeSampleAltitude;
  static const int _slopeSmoothingWindowMin = 3;
  static const int _slopeSmoothingWindowMax = 8;
  final List<double> _recentSlopeSamples = <double>[];
  final TextEditingController _regionSearchController = TextEditingController();
  final SearchService _searchService = SearchService();
  final WeatherService _weatherService = WeatherService();
  bool _isLoadingRegion = false;
  bool _isLocating = false;
  final bool _myLocationEnabled = false; // enable only if permission already granted
  bool _showWeatherOverlay = false;
  bool _showHillshade = false;
  bool _showTopo = false;
  final String _languageCode = 'en';
  bool _showShops = true;
  bool _showFood = true;
  bool _showMedical = true;
  bool _showFuel = true;
  bool _showOutdoor = true;
  bool _showTransport = true;
  bool _showHotels = true;
  bool _showAttractions = true;
  bool _showAtm = true;
  bool _showChemists = true;
  bool _showRepair = false;
  bool _showLandcover = false;
  bool _showProtectedAreas = false;
  bool _showImagery = false;
  String _mapStyle = 'topographic'; // osm, satellite, topographic
  bool _showLayerPanel = false;
  WeatherData? _currentWeather;
  // Routing state
  String _travelMode = 'walking'; // walking, driving, cycling
  LatLng? _lastRouteOrigin;
  bool _isRouting = false;
  List<Map<String, dynamic>> _trails = [];
  List<Map<String, dynamic>> _shelters = [];
  List<Map<String, dynamic>> _waterSources = [];
  List<Map<String, dynamic>> _poiShops = [];
  List<Map<String, dynamic>> _poiFood = [];
  List<Map<String, dynamic>> _poiMedical = [];
  List<Map<String, dynamic>> _poiFuel = [];
  List<Map<String, dynamic>> _poiOutdoor = [];
  List<Map<String, dynamic>> _poiTransport = [];
  List<Map<String, dynamic>> _poiHotels = [];
  List<Map<String, dynamic>> _poiAttractions = [];
  List<Map<String, dynamic>> _poiAtm = [];
  List<Map<String, dynamic>> _poiChemists = [];
  List<Map<String, dynamic>> _poiRepair = [];
  List<Map<String, dynamic>> _landcover = [];
  List<Map<String, dynamic>> _protectedAreas = [];
  List<Map<String, dynamic>> _savedPlaces = [];
  bool _isRefreshingSavedPlaces = false;
  String? _placeInfoTitle;
  String? _placeInfoSummary;
  String? _placeInfoUrl;
  bool _isPlaceInfoLoading = false;
  String? _lastPlaceInfoQuery;
  final Map<String, String> _trailColorScheme = {
    'hiking': '#FF6B35',
    'trekking': '#E63946',
    'trail': '#F77F00',
    'path': '#FCBF49',
  };
  bool _isMapStyleReady = false;
  int _styleEpoch = 0;
  final List<Future<void> Function()> _pendingStyleOperations =
      <Future<void> Function()>[];

  void _enqueueStyleOperation(Future<void> Function() operation) {
    _pendingStyleOperations.add(operation);
  }

  Future<void> _flushPendingStyleOperations(int epoch) async {
    if (!_isMapStyleReady || _mapController == null || epoch != _styleEpoch) {
      return;
    }

    final operations =
        List<Future<void> Function()>.from(_pendingStyleOperations);
    _pendingStyleOperations.clear();

    for (final operation in operations) {
      if (!_isMapStyleReady || _mapController == null || epoch != _styleEpoch) {
        return;
      }
      try {
        await operation();
      } catch (error) {
        if (kDebugMode) {
          debugPrint('Deferred style operation failed: $error');
        }
      }
    }
  }

  void _onMapStyleLoaded() {
    _isMapStyleReady = true;
    final epoch = _styleEpoch;
    // Defer to after the first frame so the map can render before we start
    // adding sources/layers (prevents 90+ skipped-frame spikes on startup).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && epoch == _styleEpoch) {
        unawaited(_bootstrapStyleOperations(epoch));
      }
    });
  }

  Future<void> _bootstrapStyleOperations(int epoch) async {
    if (!_isMapStyleReady || _mapController == null || epoch != _styleEpoch) {
      return;
    }

    await _loadShelterIcon();
    if (epoch != _styleEpoch) return;

    // Yield a frame between each heavy stage so Flutter can render
    // between platform-channel bursts and avoid skipped-frame warnings.
    await Future.delayed(Duration.zero);
    if (epoch != _styleEpoch) return;

    _applyInitialQueryAndMaybeDownload();

    await Future.delayed(Duration.zero);
    if (epoch != _styleEpoch) return;

    await _refreshSavedPlacesLayer();

    if (epoch != _styleEpoch) return;
    if (_navTarget != null) {
      await Future.delayed(Duration.zero);
      await _focusOnTarget(_navTarget!);
      await _updateRoute();
    }

    await _flushPendingStyleOperations(epoch);
  }

  Future<void> _refreshSavedPlacesLayer() async {
    if (_mapController == null || !_isMapStyleReady) {
      _enqueueStyleOperation(() => _refreshSavedPlacesLayer());
      return;
    }
    if (_isRefreshingSavedPlaces) return;
    _isRefreshingSavedPlaces = true;
    try {
      // Remove both label and circle layers before removing the source
      try {
        await _mapController!.removeLayer('saved-places-text-layer');
      } catch (_) {}
      try {
        await _mapController!.removeLayer('saved-places-layer');
      } catch (_) {}
      try {
        await _mapController!.removeSource('saved-places');
      } catch (_) {}

      if (_savedPlaces.isEmpty) return;

      final features = _savedPlaces.map((place) {
        return {
          'type': 'Feature',
          'properties': {
            'id': place['id'],
            'name': place['name'],
          },
          'geometry': {
            'type': 'Point',
            'coordinates': [place['lon'], place['lat']],
          },
        };
      }).toList();

      await _addSourceReplacingIfNeeded(
        'saved-places',
        GeojsonSourceProperties(
          data: {
            'type': 'FeatureCollection',
            'features': features,
          },
        ),
      );

      try {
        await _mapController!.addLayer(
          'saved-places',
          'saved-places-layer',
          const CircleLayerProperties(
            circleRadius: 6.5,
            circleColor: '#1A73E8',
            circleStrokeColor: '#ffffff',
            circleStrokeWidth: 2.5,
          ),
          belowLayerId: 'trails-layer',
        );
        // Add labels for saved places
        await _mapController!.addLayer(
          'saved-places',
          'saved-places-text-layer',
          SymbolLayerProperties(
            textField: [Expressions.get, 'name'],
            textSize: 12,
            textColor: '#0D47A1',
            textHaloColor: '#ffffff',
            textHaloWidth: 1.5,
            textAnchor: 'top',
            textOffset: const [0, 1.2],
            textAllowOverlap: true,
            textIgnorePlacement: true,
            textOptional: false,
          ),
        );
      } catch (_) {}
    } finally {
      _isRefreshingSavedPlaces = false;
    }
  }

  Future<void> _addSourceReplacingIfNeeded(
      String id, GeojsonSourceProperties props) async {
    if (_mapController == null || !_isMapStyleReady) {
      _enqueueStyleOperation(() => _addSourceReplacingIfNeeded(id, props));
      return;
    }
    try {
      await _mapController!.addSource(id, props);
    } catch (e) {
      final message = e.toString();
      if (message.contains('already exists')) {
        try {
          await _mapController!.removeSource(id);
        } catch (_) {}
        try {
          await _mapController!.addSource(id, props);
        } catch (_) {}
      }
    }
  }

  String _buildRasterStyle(String url, {String attribution = ''}) {
    return jsonEncode({
      'version': 8,
      'sources': {
        'raster-tiles': {
          'type': 'raster',
          'tiles': [url],
          'tileSize': 256,
          if (attribution.isNotEmpty) 'attribution': attribution,
        },
      },
      'layers': [
        {
          'id': 'raster-tiles',
          'type': 'raster',
          'source': 'raster-tiles',
        },
      ],
    });
  }

  String _getMapStyleUrl() {
    switch (_mapStyle) {
      case 'satellite':
        return _buildRasterStyle(
          'https://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
          attribution: 'Tiles © Esri & NASA',
        );
      case 'topographic':
        return _buildRasterStyle(
          'https://tile.opentopomap.org/{z}/{x}/{y}.png',
          attribution: 'Map data: © OpenStreetMap, SRTM | Style: OpenTopoMap',
        );
      default:
        return _buildRasterStyle(
          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          attribution: '© OpenStreetMap contributors',
        );
    }
  }

  Future<void> _refreshCurrentRegionData() async {
    if (_isLoadingRegion) return;
    final query = _regionSearchController.text.trim();
    if (query.isNotEmpty || _selectedBounds != null) {
      await _loadRegionData(query);
    }
  }

  Future<void> _loadSavedPlaces() async {
    try {
      if (!Hive.isBoxOpen('saved_places')) {
        await Hive.openBox('saved_places');
      }
      final box = Hive.box('saved_places');
      final places = box.values
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      setState(() => _savedPlaces = places);
      await _refreshSavedPlacesLayer();
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to load saved places: $e');
    }
  }

  Future<void> _loadShelterIcon() async {
    if (_mapController != null) {
      try {
        final ByteData data =
            await rootBundle.load('assets/icons/shelter_icon.png');
        final Uint8List bytes = data.buffer.asUint8List();
        await _mapController!.addImage('shelter-icon', bytes);
      } catch (e) {
        if (kDebugMode) print('Error loading shelter icon: $e');
      }
    }
  }

  Future<void> _loadRegionData(String query) async {
    setState(() => _isLoadingRegion = true);
    try {
      final bounds = query.isNotEmpty
          ? await _searchService.fetchBoundsForPlace(
                query,
                languageCode: _languageCode,
              ) ??
              LatLngBounds(
                southwest: LatLng(27.9781, 86.9150),
                northeast: LatLng(27.9981, 86.9350),
              )
          : _selectedBounds ??
              LatLngBounds(
                southwest: LatLng(27.9781, 86.9150),
                northeast: LatLng(27.9981, 86.9350),
              );

      final centerLat =
          (bounds.southwest.latitude + bounds.northeast.latitude) / 2;
      final centerLng =
          (bounds.southwest.longitude + bounds.northeast.longitude) / 2;
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(centerLat, centerLng), 13.0),
      );

      setState(() => _selectedBounds = bounds);

      if (query.isNotEmpty) {
        _maybeFetchPlaceInfo(query);
      }

      final overpass = OverpassService();
      _trails = await overpass.fetchTrails(
        southwest: bounds.southwest,
        northeast: bounds.northeast,
        trailName: query.isNotEmpty ? query : null,
      );
      _shelters = await overpass.fetchShelters(
        southwest: bounds.southwest,
        northeast: bounds.northeast,
      );
      _waterSources = await overpass.fetchWaterSources(
        southwest: bounds.southwest,
        northeast: bounds.northeast,
      );

      // POIs
      _poiShops = _showShops
          ? await overpass.fetchPOIs(
              southwest: bounds.southwest,
              northeast: bounds.northeast,
              key: 'shop',
              values: [
                'supermarket',
                'convenience',
                'outdoor',
                'sports',
                'bakery',
                'clothes',
                'mall',
                'department_store'
              ],
              label: 'Shopping',
            )
          : [];
      _poiFood = _showFood
          ? await overpass.fetchPOIs(
              southwest: bounds.southwest,
              northeast: bounds.northeast,
              key: 'amenity',
              values: ['restaurant', 'cafe', 'fast_food', 'bar'],
              label: 'Food & Drink',
            )
          : [];
      _poiMedical = _showMedical
          ? await overpass.fetchPOIs(
              southwest: bounds.southwest,
              northeast: bounds.northeast,
              key: 'amenity',
              values: ['hospital', 'clinic'],
              label: 'Medical',
            )
          : [];
      _poiChemists = _showChemists
          ? await overpass.fetchPOIs(
              southwest: bounds.southwest,
              northeast: bounds.northeast,
              key: 'amenity',
              values: ['pharmacy'],
              label: 'Chemist',
            )
          : [];
      _poiFuel = _showFuel
          ? await overpass.fetchPOIs(
              southwest: bounds.southwest,
              northeast: bounds.northeast,
              key: 'amenity',
              values: ['fuel', 'charging_station'],
              label: 'Fuel',
            )
          : [];
      _poiOutdoor = _showOutdoor
          ? await overpass.fetchPOIs(
              southwest: bounds.southwest,
              northeast: bounds.northeast,
              key: 'tourism',
              values: ['viewpoint', 'camp_site'],
              label: 'Outdoor',
            )
          : [];
      _poiTransport = _showTransport
          ? await overpass.fetchCompositePOIs(
              southwest: bounds.southwest,
              northeast: bounds.northeast,
              filters: [
                {
                  'key': 'highway',
                  'values': ['bus_stop']
                },
                {
                  'key': 'railway',
                  'values': ['station', 'tram_stop']
                },
              ],
              defaultLabel: 'Transit',
            )
          : [];
      _poiHotels = _showHotels
          ? await overpass.fetchPOIs(
              southwest: bounds.southwest,
              northeast: bounds.northeast,
              key: 'tourism',
              values: ['hotel', 'motel', 'guest_house', 'hostel'],
              label: 'Stay',
            )
          : [];
      _poiAttractions = _showAttractions
          ? await overpass.fetchPOIs(
              southwest: bounds.southwest,
              northeast: bounds.northeast,
              key: 'tourism',
              values: [
                'attraction',
                'museum',
                'theme_park',
                'artwork',
                'zoo',
                'aquarium'
              ],
              label: 'Attraction',
            )
          : [];
      _poiAtm = _showAtm
          ? await overpass.fetchPOIs(
              southwest: bounds.southwest,
              northeast: bounds.northeast,
              key: 'amenity',
              values: ['atm', 'bank'],
              label: 'ATM/Bank',
            )
          : [];
      _poiRepair = _showRepair
          ? await overpass.fetchPOIs(
              southwest: bounds.southwest,
              northeast: bounds.northeast,
              key: 'shop',
              values: ['car_repair', 'bicycle_repair', 'car_service'],
              label: 'Repair',
            )
          : [];

      // Landcover & protected areas
      _landcover = _showLandcover
          ? await overpass.fetchLandcover(
              southwest: bounds.southwest,
              northeast: bounds.northeast,
            )
          : [];
      _protectedAreas = _showProtectedAreas
          ? await overpass.fetchProtectedAreas(
              southwest: bounds.southwest,
              northeast: bounds.northeast,
            )
          : [];

      await _mapController?.removeLayer("trails-layer");
      await _mapController?.removeSource("trails");
      await _mapController?.removeLayer("shelters-layer");
      await _mapController?.removeSource("shelters");
      await _mapController?.removeLayer("water-sources-layer");
      await _mapController?.removeSource("water-sources");
      await _removePoiLayers();

      // Clear terrain overlays so we can re-add in correct order
      await _removeTerrainLayers();

      if (_mapController != null) {
        await _mapController!.addSource(
          "trails",
          GeojsonSourceProperties(data: {
            "type": "FeatureCollection",
            "features": _trails,
          }),
        );
        await _mapController!.addLayer(
          "trails",
          "trails-layer",
          LineLayerProperties(
            lineColor: _trailColorScheme == TrailColorScheme.difficultyBased
                ? [
                    "match",
                    ["get", "difficulty"],
                    "hiking",
                    "#00FF00",
                    "mountain_hiking",
                    "#80FF00",
                    "demanding_mountain_hiking",
                    "#FFA500",
                    "alpine_hiking",
                    "#FF4500",
                    "demanding_alpine_hiking",
                    "#FF0000",
                    "difficult_alpine_hiking",
                    "#8B0000",
                    "#FF5500",
                  ]
                : "#FF5500",
            lineWidth: 2.5,
          ),
        );

        await _mapController!.addSource(
          "shelters",
          GeojsonSourceProperties(data: {
            "type": "FeatureCollection",
            "features": _shelters,
          }),
        );
        await _mapController!.addLayer(
          "shelters",
          "shelters-layer",
          SymbolLayerProperties(
            iconImage: "shelter-icon",
            iconSize: 1.5,
          ),
        );

        await _mapController!.addSource(
          "water-sources",
          GeojsonSourceProperties(data: {
            "type": "FeatureCollection",
            "features": _waterSources,
          }),
        );
        await _mapController!.addLayer(
          "water-sources",
          "water-sources-layer",
          SymbolLayerProperties(
            iconImage: "water",
            iconSize: 1.2,
          ),
        );

        await _addPoiLayer('poi-shops', _poiShops, '#00897B');
        await _addPoiLayer('poi-food', _poiFood, '#D84315');
        await _addPoiLayer('poi-medical', _poiMedical, '#C62828');
        await _addPoiLayer('poi-fuel', _poiFuel, '#6A1B9A');
        await _addPoiLayer('poi-outdoor', _poiOutdoor, '#2E7D32');
        await _addPoiLayer('poi-transport', _poiTransport, '#1565C0');
        await _addPoiLayer('poi-hotels', _poiHotels, '#5D4037');
        await _addPoiLayer('poi-attractions', _poiAttractions, '#F57C00');
        await _addPoiLayer('poi-atm', _poiAtm, '#455A64');
        await _addPoiLayer('poi-chemist', _poiChemists, '#00ACC1');
        await _addPoiLayer('poi-repair', _poiRepair, '#6D4C41');

        // Add landcover and protected areas layers
        await _addLandcoverLayer();
        await _addProtectedAreasLayer();

        // Re-apply terrain overlays after sources are refreshed
        await _applyTerrainLayers();

        _mapController!.onFeatureTapped.clear();
        _mapController!.onFeatureTapped.add((Point<double> point,
            LatLng coordinates,
            String id,
            String layerId,
            Annotation? annotation) {
          Map<String, dynamic>? feature;
          String type = '';
          if (_trails
              .any((t) => t['properties']?['id'].toString() == id.toString())) {
            feature = _trails.firstWhere(
                (t) => t['properties']?['id'].toString() == id.toString());
            type = 'Trail';
          } else if (_shelters
              .any((s) => s['properties']?['id'].toString() == id.toString())) {
            feature = _shelters.firstWhere(
                (s) => s['properties']?['id'].toString() == id.toString());
            type = 'Shelter';
          } else if (_waterSources
              .any((w) => w['properties']?['id'].toString() == id.toString())) {
            feature = _waterSources.firstWhere(
                (w) => w['properties']?['id'].toString() == id.toString());
            type = 'Water Source';
          }

          if (feature != null && feature['properties'] != null) {
            final properties = feature['properties'] as Map<String, dynamic>?;
            showDialog(
              context: context,
              builder: (_) => Dialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.info,
                              color: Colors.blue.shade600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              (properties?['name'] as String?) ??
                                  'Unnamed $type',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: type == 'Trail'
                              ? [
                                  _buildDetailRow(
                                    'Surface',
                                    (properties?['surface'] as String?) ??
                                        'Unknown',
                                    Icons.terrain,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildDetailRow(
                                    'Difficulty',
                                    (properties?['difficulty'] as String?) ??
                                        'Unknown',
                                    Icons.trending_up,
                                  ),
                                ]
                              : [
                                  _buildDetailRow(
                                    'Type',
                                    type,
                                    Icons.place,
                                  ),
                                ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        });

        await _refreshSavedPlacesLayer();

        _showSuccessSnackbar('Data loaded', 'Map is ready with all features');
      }
    } catch (e) {
      String errorMessage = 'Failed to load data: $e';
      String errorTitle = 'Failed to load data';
      if (e.toString().contains('TimeoutException')) {
        errorTitle = 'Request timed out';
        errorMessage = 'Try again with a different region';
      } else if (e.toString().contains('Geocoding failed')) {
        errorTitle = 'Location not found';
        errorMessage = 'Try a different search term';
      } else if (e.toString().contains('rate limit')) {
        errorTitle = 'Rate limit exceeded';
        errorMessage = 'Please try again later';
      }
      _showErrorSnackbar(errorTitle, errorMessage);
    } finally {
      setState(() => _isLoadingRegion = false);
    }
  }

  Future<void> _downloadRegion() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _showErrorSnackbar(
        'No internet connection',
        'Please check your connectivity and try again',
      );
      return;
    }

    if (!mounted) return;
    final bounds = await showDialog<LatLngBounds>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.map, color: Colors.blue.shade600),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Select Trekking Region',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TypeAheadField(
                builder: (context, controller, focusNode) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: 'Search Region',
                      hintText: 'e.g., Patagonia, Everest',
                      prefixIcon:
                          Icon(Icons.search, color: Colors.blue.shade600),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  );
                },
                suggestionsCallback: (pattern) async {
                  final recent = Hive.box('recent_searches')
                      .values
                      .toList()
                      .cast<String>();
                  final suggestions =
                      await _searchService.fetchLocationSuggestions(pattern,
                          languageCode: _languageCode);
                  final predefined = [
                    'Himalayas (Mt. Everest)',
                    'Alps (Mont Blanc)',
                    'Annapurna',
                    'Kilimanjaro',
                    'Appalachian Trail',
                    'Andes (Inca Trail)',
                  ];
                  return [...predefined, ...recent, ...suggestions]
                      .take(8)
                      .toList();
                },
                itemBuilder: (context, suggestion) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 16, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      Text(suggestion),
                    ],
                  ),
                ),
                onSelected: (suggestion) async {
                  final nav = Navigator.of(context);
                  try {
                    final selectedBounds =
                        await _searchService.fetchBoundsForPlace(
                              suggestion,
                              languageCode: _languageCode,
                            ) ??
                            LatLngBounds(
                              southwest: LatLng(27.9781, 86.9150),
                              northeast: LatLng(27.9981, 86.9350),
                            );
                    nav.pop(selectedBounds);
                  } catch (e) {
                    _showErrorSnackbar(
                      'Failed to fetch region',
                      'Try a different search term',
                    );
                  }
                },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (bounds != null) {
      setState(() => _selectedBounds = bounds);
      try {
        final store = fmtc.FMTCStore('DravikMaps');
        final baseRegion = fmtc.RectangleRegion(
          fm.LatLngBounds(
            latlong.LatLng(
                bounds.southwest.latitude, bounds.southwest.longitude),
            latlong.LatLng(
                bounds.northeast.latitude, bounds.northeast.longitude),
          ),
        );
        final region = baseRegion.toDownloadable(
          minZoom: 10,
          maxZoom: 15,
          options: fm.TileLayer(
            // OSM standard tiles: free, no key; cache with FMTC to respect fair use
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const [],
          ),
        );
        final download = store.download.startForeground(
          region: region,
        );
        final tileEvents = download.tileEvents;
        final progressEvents = download.downloadProgress;

        progressEvents.listen((progress) {
          final current = progress.successfulTilesCount;
          final total = progress.maxTilesCount;
          if (total > 0) {
            if (!mounted) return;
            _showInfoSnackbar(
              'Downloading: ${(current / total * 100).toStringAsFixed(0)}%',
            );
          }
        });

        await tileEvents.drain();

        _showSuccessSnackbar(
          'Region downloaded',
          'Offline map is ready to use',
        );

        await _loadRegionData(_regionSearchController.text);
      } catch (e) {
        _showErrorSnackbar(
          'Failed to download region',
          'Check your connection and try again',
        );
      }
    }
  }

  Future<void> _showSearchSheet() async {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.search, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'Search place',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TypeAheadField(
                builder: (context, controller, focusNode) {
                  controller.text = _regionSearchController.text;
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: 'Find a place',
                      hintText: 'City, landmark, trail...',
                      prefixIcon:
                          Icon(Icons.search, color: Colors.blue.shade600),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    autofocus: true,
                  );
                },
                suggestionsCallback: (pattern) async {
                  if (pattern.isEmpty) return const [];
                  final suggestions =
                      await _searchService.fetchLocationSuggestions(pattern,
                          languageCode: _languageCode);
                  return suggestions.take(8).toList();
                },
                itemBuilder: (context, suggestion) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.place, size: 16, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          suggestion,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                onSelected: (suggestion) async {
                  Navigator.pop(context);
                  _regionSearchController.text = suggestion;
                  await _loadRegionData(suggestion);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _applyInitialQueryAndMaybeDownload() {
    // Placeholder for applying initial query from widget parameter
    // and possibly downloading offline tiles for that region
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _regionSearchController.text = widget.initialQuery!;
      _loadRegionData(widget.initialQuery!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWeb = PlatformCapabilities.isWeb;
    final isIOS = PlatformCapabilities.isIOS;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Map', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchSheet,
            tooltip: 'Search place',
          ),
          IconButton(
            icon: const Icon(Icons.travel_explore),
            onPressed: _openPlaceGuide,
            tooltip: 'Place Guide (AI)',
          ),
          IconButton(
            icon: Icon(
                _showWeatherOverlay ? Icons.wb_sunny : Icons.wb_sunny_outlined),
            onPressed: () async {
              setState(() => _showWeatherOverlay = !_showWeatherOverlay);
              if (_showWeatherOverlay && _mapController != null) {
                final center = _mapController!.cameraPosition;
                _fetchWeather(center?.target.latitude ?? 0,
                    center?.target.longitude ?? 0);
              }
            },
            tooltip: 'Toggle weather',
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: _downloadRegion,
            tooltip: 'Download offline map',
          ),
          IconButton(
            icon: const Icon(Icons.layers_outlined),
            onPressed: _showLayerSheet,
            tooltip: 'Manage layers',
          ),
        ],
      ),
      body: Stack(
        children: [
          MapLibreMap(
            key: ValueKey(
                'maplibre-style-$_mapStyle'), // force remount on style change to avoid native crashes
            onMapCreated: (controller) {
              _mapController = controller;
              _isMapStyleReady = false;
              _styleEpoch++;
              _pendingStyleOperations.clear();
            },
            onStyleLoadedCallback: _onMapStyleLoaded,
            initialCameraPosition: const CameraPosition(
              target: LatLng(27.9881, 86.9250),
              zoom: 13.0,
            ),
            minMaxZoomPreference: const MinMaxZoomPreference(3.0, 22.0),
            // Map style changes based on selection
            styleString: _getMapStyleUrl(),
            myLocationEnabled: _myLocationEnabled,
            compassEnabled: true,
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: true,
            zoomGesturesEnabled: true,
            onMapClick: (point, latLng) => _handleMapTap(latLng),
            onMapLongClick: (point, latLng) => _promptSavePin(latLng),
          ),
          if (_isLoadingRegion)
            Center(
              child: ScaleTransition(
                scale: AlwaysStoppedAnimation(1.0),
                child: Card(
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(
                            Colors.blue.shade600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading map data...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (_showWeatherOverlay && _currentWeather != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: _buildWeatherCard(),
            ),
          if (isWeb || isIOS)
            Positioned(
              top: _showWeatherOverlay && _currentWeather != null ? 130 : 14,
              left: 0,
              right: 0,
              child: const EditionBannerForScreen(screen: EditionScreen.map),
            ),
          if (_placeInfoSummary != null || _isPlaceInfoLoading)
            Positioned(
              top: (_showWeatherOverlay && _currentWeather != null) ? 140 : 16,
              left: 16,
              right: 16,
              child: _buildPlaceInfoCard(),
            ),
          // Target banner showing passed-in coordinates
          if (_navTarget != null)
            Positioned(
              top: (_showWeatherOverlay && _currentWeather != null)
                  ? 240
                  : (_placeInfoSummary != null || _isPlaceInfoLoading)
                      ? 110
                      : 16,
              left: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[850]
                    : Colors.white,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.place, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '${_navTarget!.latitude.toStringAsFixed(5)}, ${_navTarget!.longitude.toStringAsFixed(5)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Layer toggle button
          Positioned(
            top: 16,
            right: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              color: isDark ? Colors.grey[850] : Colors.white,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(() => _showLayerPanel = !_showLayerPanel),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.layers_outlined,
                    color: _showLayerPanel
                        ? const Color(0xFF1A73E8)
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ),
            ),
          ),
          // Compact layer control panel (toggleable)
          if (_showLayerPanel)
            GestureDetector(
              onTap: () => setState(() => _showLayerPanel = false),
              child: Container(
                color: Colors.transparent,
                child: Stack(
                  children: [
                    Positioned(
                      top: 70,
                      right: 16,
                      child: GestureDetector(
                        onTap: () {}, // Prevent dismissal when tapping panel
                        child: _buildCompactLayerPanel(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: (_navTarget != null ||
                    (_showWeatherOverlay && _currentWeather != null))
                ? 150
                : 96,
            right: 16,
            child: _buildMissionStatusCard(),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'locate-me',
                  mini: true,
                  onPressed: _goToMyLocation,
                  tooltip: 'My location',
                  child: _isLocating
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Icon(Icons.my_location),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'saved-places',
                  mini: true,
                  onPressed: _showSavedPlacesSheet,
                  tooltip: 'Saved places',
                  child: const Icon(Icons.bookmark_outline),
                ),
              ],
            ),
          ),
          if (_showWeatherOverlay && _currentWeather != null)
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.extended(
                onPressed: _showWeatherDetails,
                backgroundColor: Colors.blue.shade600,
                label: const Text('Details'),
                icon: const Icon(Icons.info_outline, size: 20),
              ),
            ),
          // Directions and Save buttons for target
          if (_navTarget != null)
            Positioned(
              bottom:
                  (_showWeatherOverlay && _currentWeather != null) ? 76 : 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Travel mode selector
                  Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(10),
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[900]
                        : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _modeChip('walking', Icons.directions_walk),
                          const SizedBox(width: 6),
                          _modeChip('cycling', Icons.directions_bike),
                          const SizedBox(width: 6),
                          _modeChip('driving', Icons.directions_car),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FloatingActionButton.extended(
                    onPressed: _openExternalDirections,
                    backgroundColor: Colors.green.shade600,
                    icon: Icon(
                      _travelMode == 'walking'
                          ? Icons.directions_walk
                          : _travelMode == 'cycling'
                              ? Icons.directions_bike
                              : Icons.directions_car,
                      size: 20,
                    ),
                    label: const Text('Directions'),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton.extended(
                    onPressed: _saveNavTarget,
                    backgroundColor: Colors.orange.shade700,
                    icon: const Icon(Icons.bookmark_add_outlined, size: 20),
                    label: const Text('Save target'),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton(
                    heroTag: 'clear-target',
                    mini: true,
                    backgroundColor: Colors.red.shade600,
                    onPressed: _clearTarget,
                    tooltip: 'Clear target',
                    child: const Icon(Icons.clear),
                  ),
                ],
              ),
            ),
          // Bottom-center chip for distance/bearing
          if (_navTarget != null &&
              _distanceToTarget != null &&
              _bearingToTarget != null)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(20),
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[900]
                      : Colors.white,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.straighten, size: 18),
                        const SizedBox(width: 6),
                        Text(_formatDistance(_distanceToTarget!)),
                        const SizedBox(width: 12),
                        const Icon(Icons.explore, size: 18),
                        const SizedBox(width: 6),
                        Text('${_bearingToTarget!.toStringAsFixed(0)}°'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _fetchWeather(double lat, double lon) async {
    try {
      final weather = await _weatherService.getWeather(lat, lon);
      setState(() => _currentWeather = weather);
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar(
            'Weather unavailable', 'Unable to fetch weather data');
      }
    }
  }

  Future<void> _focusOnTarget(LatLng target) async {
    if (_mapController == null || !_isMapStyleReady) {
      _enqueueStyleOperation(() => _focusOnTarget(target));
      return;
    }
    // Center camera
    try {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(target, 15.5),
      );
    } catch (_) {}

    // Remove previous target layers/sources if exist
    try {
      await _mapController!.removeLayer('nav-target-text-layer');
    } catch (_) {}
    try {
      await _mapController!.removeLayer('nav-target-layer');
    } catch (_) {}
    try {
      await _mapController!.removeSource('nav-target');
    } catch (_) {}

    // Add new target source and layers
    try {
      await _mapController!.addSource(
        'nav-target',
        GeojsonSourceProperties(
          data: {
            'type': 'FeatureCollection',
            'features': [
              {
                'type': 'Feature',
                'properties': {
                  'name': 'Target',
                },
                'geometry': {
                  'type': 'Point',
                  'coordinates': [target.longitude, target.latitude],
                }
              }
            ],
          },
        ),
      );

      await _mapController!.addLayer(
        'nav-target',
        'nav-target-layer',
        const CircleLayerProperties(
          circleRadius: 8,
          circleColor: '#EA4335',
          circleOpacity: 1.0,
          circleStrokeColor: '#ffffff',
          circleStrokeWidth: 2.5,
        ),
        belowLayerId: 'trails-layer',
      );

      await _mapController!.addLayer(
        'nav-target',
        'nav-target-text-layer',
        SymbolLayerProperties(
          textField: ['get', 'name'],
          textSize: 11,
          textColor: '#333333',
          textHaloColor: '#ffffff',
          textHaloWidth: 1.5,
          textOffset: [0, 1.6],
          textAnchor: 'top',
          textOptional: true,
        ),
      );
    } catch (_) {}

    // Attempt routing after focusing
    _updateRoute();
  }

  void _startMissionTracking(LatLng latLng) {
    _missionEngine.accept(
      StartMission(
        occurredAt: DateTime.now(),
        routeName: widget.initialQuery?.trim().isNotEmpty == true
            ? widget.initialQuery!.trim()
            : 'Map target',
        target: MissionCoordinates(
          latitude: latLng.latitude,
          longitude: latLng.longitude,
        ),
      ),
    );
  }

  MissionFix _missionFixFromPosition(geo.Position position) {
    final accuracy = position.accuracy.isFinite ? position.accuracy.abs() : 999;
    final clampedConfidence = ((50 - accuracy).clamp(0, 50)) / 50;
    return MissionFix(
      coordinates: MissionCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
        altitudeMeters: position.altitude,
        headingDegrees: position.heading,
      ),
      recordedAt: position.timestamp,
      isMock: position.isMocked,
      confidence: clampedConfidence.toDouble(),
    );
  }

  void _recordMissionFix(geo.Position position) {
    _missionEngine.accept(
      MissionFixAcquired(
        occurredAt: DateTime.now(),
        fix: _missionFixFromPosition(position),
      ),
    );
  }

  void _recordMissionFixLoss([String? reason]) {
    _missionEngine.accept(
      MissionFixLost(
        occurredAt: DateTime.now(),
        reason: reason,
      ),
    );
  }

  void _recordConnectivity(bool isOffline) {
    _missionEngine.accept(
      ConnectivityChanged(
        occurredAt: DateTime.now(),
        isOffline: isOffline,
      ),
    );
  }

  double _headingConfidencePercent(HeadingConfidence confidence) {
    switch (confidence) {
      case HeadingConfidence.unavailable:
        return 0;
      case HeadingConfidence.low:
        return 33;
      case HeadingConfidence.medium:
        return 66;
      case HeadingConfidence.high:
        return 100;
    }
  }

  void _recordHeadingConfidence(HeadingConfidence confidence) {
    _missionEngine.accept(
      HeadingReported(
        occurredAt: DateTime.now(),
        headingDegrees: _lastHeadingDegrees,
        confidencePercent: _headingConfidencePercent(confidence),
      ),
    );
  }

  void _recordAltitude(double altitudeMeters, {double? accuracyMeters}) {
    _missionEngine.accept(
      AltitudeReported(
        occurredAt: DateTime.now(),
        altitudeMeters: altitudeMeters,
        accuracyMeters: accuracyMeters,
      ),
    );
  }

  void _recordSpeed(double speedMetersPerSecond) {
    _missionEngine.accept(
      SpeedReported(
        occurredAt: DateTime.now(),
        speedMetersPerSecond: speedMetersPerSecond,
      ),
    );
  }

  void _recordSlope(double slopePercent) {
    _missionEngine.accept(
      SlopeReported(
        occurredAt: DateTime.now(),
        slopePercent: slopePercent,
      ),
    );
  }

  int _adaptiveSlopeWindow(double speedMetersPerSecond) {
    if (speedMetersPerSecond >= 3) {
      return _slopeSmoothingWindowMin;
    }
    if (speedMetersPerSecond <= 0.7) {
      return _slopeSmoothingWindowMax;
    }

    final normalized = (speedMetersPerSecond - 0.7) / (3 - 0.7);
    final span = _slopeSmoothingWindowMax - _slopeSmoothingWindowMin;
    final window = _slopeSmoothingWindowMax - (normalized * span);
    return window.round().clamp(
          _slopeSmoothingWindowMin,
          _slopeSmoothingWindowMax,
        );
  }

  void _updateSlopeTelemetry(geo.Position position) {
    final currentPosition = latlong.LatLng(position.latitude, position.longitude);
    final previousPosition = _lastSlopeSamplePosition;
    final previousAltitude = _lastSlopeSampleAltitude;

    _lastSlopeSamplePosition = currentPosition;
    _lastSlopeSampleAltitude = position.altitude;

    if (previousPosition == null || previousAltitude == null) {
      return;
    }

    final horizontalDistance =
        _geo.distance(previousPosition, currentPosition).toDouble();
    if (horizontalDistance < 3) {
      return;
    }

    final altitudeDelta = position.altitude - previousAltitude;
    final slopePercent = ((altitudeDelta / horizontalDistance) * 100)
        .clamp(-99.0, 99.0)
        .toDouble();

    final windowSize = _adaptiveSlopeWindow(position.speed);

    _recentSlopeSamples.add(slopePercent);
    if (_recentSlopeSamples.length > windowSize) {
      _recentSlopeSamples.removeAt(0);
    }

    final smoothedSlope =
        _recentSlopeSamples.reduce((a, b) => a + b) / _recentSlopeSamples.length;
    _recordSlope(smoothedSlope);
  }

  void _stopMissionTracking() {
    _lastSlopeSamplePosition = null;
    _lastSlopeSampleAltitude = null;
    _recentSlopeSamples.clear();
    if (_missionEngine.status == MissionStatus.idle) {
      return;
    }
    _missionEngine.accept(
      StopMission(occurredAt: DateTime.now()),
    );
  }

  Widget _buildMissionStatusCard() {
    return Obx(() {
      final runtime = _missionEngine.runtime.value;
      final fallbackBattery = _missionPowerManager.lastBatteryPercent.value;
      final batteryPercent = runtime.context.batteryPercent ??
          (fallbackBattery >= 0 ? fallbackBattery : null);

      if (runtime.status == MissionStatus.idle && _navTarget == null) {
        return const SizedBox.shrink();
      }

      return MissionStatusCard(
        runtime: runtime,
        batteryPercent: batteryPercent,
      );
    });
  }

  void _startTargetTracking() async {
    try {
      // Ensure location permission is available
      final hasPermission = await _locationAdapter.ensurePermission();
      if (!hasPermission) {
        _missionEngine.accept(
          LocationPermissionDenied(occurredAt: DateTime.now()),
        );
        _recordMissionFixLoss('Location permission denied or not available');
        return;
      }

      // Get immediate position once
      final pos = await _locationAdapter.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
        ),
      );
      await _missionPowerManager.refreshBatteryLevel();
      _myPosition = LatLng(pos.latitude, pos.longitude);
      _recordMissionFix(pos);
      _recordAltitude(pos.altitude);
      _recordSpeed(pos.speed);
      _updateSlopeTelemetry(pos);
      _updateTargetMetrics();
      await _updateRoute();
    } catch (error) {
      _recordMissionFixLoss('Unable to acquire initial GPS position: $error');
    }

    // Start stream updates
    final settings = geo.LocationSettings(
      accuracy: geo.LocationAccuracy.high,
      distanceFilter: 5,
    );
    await _locationAdapter.startTracking(
      locationSettings: settings,
      onPosition: (p) async {
        _myPosition = LatLng(p.latitude, p.longitude);
        _recordMissionFix(p);
        _recordAltitude(p.altitude);
        _recordSpeed(p.speed);
        _updateSlopeTelemetry(p);
        _updateTargetMetrics();
        // Update route when moved significantly (>30m) or no route yet
        if (_lastRouteOrigin == null ||
            _geo.distance(
                    latlong.LatLng(_lastRouteOrigin!.latitude,
                        _lastRouteOrigin!.longitude),
                    latlong.LatLng(_myPosition!.latitude, _myPosition!.longitude)) >
                30) {
          await _updateRoute();
        }
      },
      onError: (Object error) {
        _recordMissionFixLoss('Location stream failed: $error');
      },
      onDone: () {
        _recordMissionFixLoss('Location stream closed');
      },
    );

    await _compassAdapter.startTracking(
      onHeading: (double headingDegrees) {
        _lastHeadingDegrees = headingDegrees;
      },
      onConfidence: _recordHeadingConfidence,
      onError: (Object error) {
        _recordHeadingConfidence(HeadingConfidence.unavailable);
      },
      onDone: () {
        _recordHeadingConfidence(HeadingConfidence.unavailable);
      },
    );
  }

  void _updateTargetMetrics() {
    if (_navTarget == null || _myPosition == null) return;
    final from = latlong.LatLng(_myPosition!.latitude, _myPosition!.longitude);
    final to = latlong.LatLng(_navTarget!.latitude, _navTarget!.longitude);
    _distanceToTarget = _geo.distance(from, to).toDouble();
    _bearingToTarget = _geo.bearing(from, to).toDouble();
    if (mounted) setState(() {});
  }

  Future<void> _drawLine(List<List<double>> coordinates,
      {String sourceId = 'nav-route',
      String layerId = 'nav-route-layer',
      String color = '#1A73E8'}) async {
    if (_mapController == null || !_isMapStyleReady) {
      _enqueueStyleOperation(
        () => _drawLine(
          coordinates,
          sourceId: sourceId,
          layerId: layerId,
          color: color,
        ),
      );
      return;
    }
    try {
      await _mapController!.removeLayer(layerId);
    } catch (_) {}
    try {
      await _mapController!.removeSource(sourceId);
    } catch (_) {}
    try {
      await _mapController!.addSource(
        sourceId,
        GeojsonSourceProperties(
          data: {
            'type': 'FeatureCollection',
            'features': [
              {
                'type': 'Feature',
                'geometry': {
                  'type': 'LineString',
                  'coordinates': coordinates,
                },
                'properties': {}
              }
            ],
          },
        ),
      );
      await _mapController!.addLayer(
        sourceId,
        layerId,
        LineLayerProperties(
          lineColor: color,
          lineWidth: 3.0,
          lineOpacity: 0.9,
        ),
        belowLayerId: 'saved-places-layer',
      );
    } catch (_) {}
  }

  Future<void> _updateRoute() async {
    if (_navTarget == null || _myPosition == null || _isRouting) return;
    _isRouting = true;
    final shouldFlagReroute =
        _lastRouteOrigin != null && _missionEngine.status == MissionStatus.tracking;
    if (shouldFlagReroute) {
      _missionEngine.accept(
        RerouteRequested(
          occurredAt: DateTime.now(),
          reason: 'Position changed enough to refresh route',
        ),
      );
    }
    _lastRouteOrigin = _myPosition;
    try {
      // If offline, draw straight line and return
      final connectivity = await Connectivity().checkConnectivity();
      final offline = connectivity == ConnectivityResult.none;
      _recordConnectivity(offline);
      if (offline) {
        await _drawLine([
          [_myPosition!.longitude, _myPosition!.latitude],
          [_navTarget!.longitude, _navTarget!.latitude],
        ], sourceId: 'nav-route', layerId: 'nav-route-layer', color: '#1A73E8');
        if (_missionEngine.status == MissionStatus.rerouting) {
          _missionEngine.accept(RerouteResolved(occurredAt: DateTime.now()));
        }
        return;
      }
      final profile = _travelMode == 'driving'
          ? 'driving'
          : _travelMode == 'cycling'
              ? 'cycling'
              : 'walking';
      final url = Uri.parse(
          'https://router.project-osrm.org/route/v1/$profile/${_myPosition!.longitude},${_myPosition!.latitude};${_navTarget!.longitude},${_navTarget!.latitude}?overview=full&geometries=geojson');
      final resp = await http.get(url).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final geom = routes[0]['geometry'] as Map<String, dynamic>?;
          final coords = (geom?['coordinates'] as List?)
              ?.map<List<double>>(
                  (c) => [(c[0] as num).toDouble(), (c[1] as num).toDouble()])
              .toList();
          if (coords != null && coords.length >= 2) {
            await _drawLine(coords,
                sourceId: 'nav-route',
                layerId: 'nav-route-layer',
                color: '#1A73E8');
            if (_missionEngine.status == MissionStatus.rerouting) {
              _missionEngine.accept(RerouteResolved(occurredAt: DateTime.now()));
            }
            _isRouting = false;
            if (mounted) setState(() {});
            return;
          }
        }
      }
      // Fallback: draw straight line
      await _drawLine([
        [_myPosition!.longitude, _myPosition!.latitude],
        [_navTarget!.longitude, _navTarget!.latitude],
      ], sourceId: 'nav-route', layerId: 'nav-route-layer', color: '#1A73E8');
      if (_missionEngine.status == MissionStatus.rerouting) {
        _missionEngine.accept(RerouteResolved(occurredAt: DateTime.now()));
      }
    } catch (error) {
      // Fallback: straight line on errors
      try {
        await _drawLine([
          [_myPosition!.longitude, _myPosition!.latitude],
          [_navTarget!.longitude, _navTarget!.latitude],
        ], sourceId: 'nav-route', layerId: 'nav-route-layer', color: '#1A73E8');
        if (_missionEngine.status == MissionStatus.rerouting) {
          _missionEngine.accept(RerouteResolved(occurredAt: DateTime.now()));
        }
      } catch (_) {}
      if (kDebugMode) {
        debugPrint('Route refresh failed, using fallback line: $error');
      }
    } finally {
      _isRouting = false;
      if (mounted) setState(() {});
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  Future<void> _openExternalDirections() async {
    if (_navTarget == null) return;
    final lat = _navTarget!.latitude;
    final lon = _navTarget!.longitude;
    final googleMode = _travelMode == 'driving'
        ? 'driving'
        : _travelMode == 'cycling'
            ? 'bicycling'
            : 'walking';
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon&travelmode=$googleMode');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showErrorSnackbar('Directions unavailable', 'Cannot open maps app');
    }
  }

  // When user taps the map, set navigation target and start routing
  Future<void> _handleMapTap(LatLng latLng) async {
    // Clear existing target visuals first
    try {
      await _mapController?.removeLayer('nav-route-layer');
    } catch (_) {}
    try {
      await _mapController?.removeSource('nav-route');
    } catch (_) {}

    setState(() {
      _navTarget = latLng;
      _distanceToTarget = null;
      _bearingToTarget = null;
      _lastRouteOrigin = null;
    });

    _startMissionTracking(latLng);
    await _focusOnTarget(latLng);
    _startTargetTracking();
  }

  // Mode chip widget for the selector panel
  Widget _modeChip(String mode, IconData icon) {
    final bool active = _travelMode == mode;
    final Color activeColor = const Color(0xFF1A73E8);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () {
        if (_travelMode != mode) {
          setState(() => _travelMode = mode);
          _updateRoute();
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? activeColor
              : (isDark ? Colors.grey[850] : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active
                ? activeColor
                : (isDark ? Colors.white10 : Colors.grey.shade300),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: active ? Colors.white : null),
            const SizedBox(width: 6),
            Text(
              mode[0].toUpperCase() + mode.substring(1),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _clearTarget() async {
    await _locationAdapter.stopTracking();
    await _compassAdapter.stopTracking();
    _lastSlopeSamplePosition = null;
    _lastSlopeSampleAltitude = null;
    _recentSlopeSamples.clear();
    _distanceToTarget = null;
    _bearingToTarget = null;
    _lastRouteOrigin = null;
    _stopMissionTracking();
    // Remove layers and sources
    if (_mapController != null) {
      for (final layer in [
        'nav-route-layer',
        'nav-target-text-layer',
        'nav-target-layer',
      ]) {
        try {
          await _mapController!.removeLayer(layer);
        } catch (_) {}
      }
      for (final source in [
        'nav-route',
        'nav-target',
      ]) {
        try {
          await _mapController!.removeSource(source);
        } catch (_) {}
      }
    }
    setState(() {
      _navTarget = null;
    });
  }

  Future<void> _saveNavTarget() async {
    if (_navTarget == null) return;
    final controller = TextEditingController(text: 'Pinned target');
    if (!mounted) return;
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save target'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'Camp, viewpoint, trailhead…',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await _savePlace(name, _navTarget!);
    }
  }

  @override
  void dispose() {
    unawaited(_locationAdapter.stopTracking());
    unawaited(_compassAdapter.stopTracking());
    _stopMissionTracking();
    super.dispose();
  }

  Future<void> _applyTerrainLayers() async {
    if (_mapController == null) return;

    // Hillshade overlay
    if (_showHillshade) {
      try {
        await _mapController!.addSource(
          'hillshade-source',
          RasterSourceProperties(
            tiles: const [
              'https://tiles.wmflabs.org/hillshading/{z}/{x}/{y}.png'
            ],
            tileSize: 256,
          ),
        );
      } catch (_) {}

      try {
        await _mapController!.addLayer(
          'hillshade-source',
          'hillshade-layer',
          const RasterLayerProperties(rasterOpacity: 0.35),
          belowLayerId: 'trails-layer',
        );
      } catch (_) {}
    }

    // Topographic overlay (OpenTopoMap tiles, semi-transparent)
    if (_showTopo) {
      try {
        await _mapController!.addSource(
          'topo-source',
          RasterSourceProperties(
            tiles: const ['https://tile.opentopomap.org/{z}/{x}/{y}.png'],
            tileSize: 256,
          ),
        );
      } catch (_) {}

      try {
        await _mapController!.addLayer(
          'topo-source',
          'topo-layer',
          const RasterLayerProperties(rasterOpacity: 0.45),
          belowLayerId: 'trails-layer',
        );
      } catch (_) {}
    }
  }

  Future<void> _removeTerrainLayers() async {
    if (_mapController == null) return;
    for (final layer in ['hillshade-layer', 'topo-layer']) {
      try {
        await _mapController!.removeLayer(layer);
      } catch (_) {}
    }
    for (final source in ['hillshade-source', 'topo-source']) {
      try {
        await _mapController!.removeSource(source);
      } catch (_) {}
    }
  }

  void _showLayerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, controller) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                controller: controller,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade600,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Map Layers',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Terrain Section
                    _buildLayerSection(
                      'Terrain',
                      Icons.terrain,
                      [
                        _buildLayerTile(
                          'Hillshade',
                          'Terrain relief visualization',
                          _showHillshade,
                          (v) async {
                            Navigator.pop(context);
                            setState(() => _showHillshade = v);
                            await _removeTerrainLayers();
                            await _applyTerrainLayers();
                          },
                        ),
                        _buildLayerTile(
                          'Topographic',
                          'Contour lines overlay',
                          _showTopo,
                          (v) async {
                            Navigator.pop(context);
                            setState(() => _showTopo = v);
                            await _removeTerrainLayers();
                            await _applyTerrainLayers();
                          },
                        ),
                        _buildLayerTile(
                          'Satellite',
                          'Aerial imagery',
                          _showImagery,
                          (v) async {
                            Navigator.pop(context);
                            setState(() => _showImagery = v);
                            await _removeImageryLayer();
                            await _applyImageryLayer();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Points of Interest Section
                    _buildLayerSection(
                      'Points of Interest',
                      Icons.location_on,
                      [
                        _buildLayerTile(
                          'Public Transport',
                          'Bus, tram, rail stops',
                          _showTransport,
                          (v) async {
                            Navigator.pop(context);
                            setState(() => _showTransport = v);
                            await _reloadPois();
                          },
                        ),
                        _buildLayerTile(
                          'Restaurants & Cafes',
                          'Food, drinks, bars',
                          _showFood,
                          (v) async {
                            Navigator.pop(context);
                            setState(() => _showFood = v);
                            await _reloadPois();
                          },
                        ),
                        _buildLayerTile(
                          'Hotels & Stays',
                          'Hotels, hostels, guest houses',
                          _showHotels,
                          (v) async {
                            Navigator.pop(context);
                            setState(() => _showHotels = v);
                            await _reloadPois();
                          },
                        ),
                        _buildLayerTile(
                          'Attractions',
                          'Museums, parks, sights',
                          _showAttractions,
                          (v) async {
                            Navigator.pop(context);
                            setState(() => _showAttractions = v);
                            await _reloadPois();
                          },
                        ),
                        _buildLayerTile(
                          'Shopping',
                          'Supermarkets, malls',
                          _showShops,
                          (v) async {
                            Navigator.pop(context);
                            setState(() => _showShops = v);
                            await _reloadPois();
                          },
                        ),
                        _buildLayerTile(
                          'ATM & Bank',
                          'Cash, banking points',
                          _showAtm,
                          (v) async {
                            Navigator.pop(context);
                            setState(() => _showAtm = v);
                            await _reloadPois();
                          },
                        ),
                        _buildLayerTile(
                          'Fuel & Charging',
                          'Petrol, EV chargers',
                          _showFuel,
                          (v) async {
                            Navigator.pop(context);
                            setState(() => _showFuel = v);
                            await _reloadPois();
                          },
                        ),
                        _buildLayerTile(
                          'Hospitals',
                          'Hospitals, clinics',
                          _showMedical,
                          (v) async {
                            Navigator.pop(context);
                            setState(() => _showMedical = v);
                            await _reloadPois();
                          },
                        ),
                        _buildLayerTile(
                          'Chemists',
                          'Pharmacies / chemists',
                          _showChemists,
                          (v) async {
                            Navigator.pop(context);
                            setState(() => _showChemists = v);
                            await _reloadPois();
                          },
                        ),
                        _buildLayerTile(
                          'Outdoor Spots',
                          'Viewpoints, campsites',
                          _showOutdoor,
                          (v) async {
                            Navigator.pop(context);
                            setState(() => _showOutdoor = v);
                            await _reloadPois();
                          },
                        ),
                        _buildLayerTile(
                          'Repair Shops',
                          'Bike/car repair, service',
                          _showRepair,
                          (v) async {
                            Navigator.pop(context);
                            setState(() => _showRepair = v);
                            await _reloadPois();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Natural Features Section
                    _buildLayerSection(
                      'Natural Features',
                      Icons.eco,
                      [
                        _buildLayerTile(
                          'Landcover',
                          'Forests, deserts, wetlands',
                          _showLandcover,
                          (v) async {
                            Navigator.pop(context);
                            setState(() => _showLandcover = v);
                            if (v) {
                              await _removeLandcoverLayer();
                            }
                            await _loadRegionData(_regionSearchController.text);
                          },
                        ),
                        _buildLayerTile(
                          'Protected Areas',
                          'National parks, reserves',
                          _showProtectedAreas,
                          (v) async {
                            Navigator.pop(context);
                            setState(() => _showProtectedAreas = v);
                            if (v) {
                              await _removeProtectedAreasLayer();
                            }
                            await _loadRegionData(_regionSearchController.text);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Tip
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 18, color: Colors.amber.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Enable offline caching before large downloads to respect fair use limits.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.amber.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLayerSection(String title, IconData icon, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.blue.shade600),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...tiles,
      ],
    );
  }

  Widget _buildLayerTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.blue.shade600,
        inactiveThumbColor: Colors.grey.shade400,
      ),
    );
  }

  Future<void> _addPoiLayer(
      String id, List<Map<String, dynamic>> features, String color) async {
    if (_mapController == null || features.isEmpty) return;
    try {
      await _mapController!.addSource(
        '$id-source',
        GeojsonSourceProperties(data: {
          'type': 'FeatureCollection',
          'features': features,
        }),
      );
    } catch (_) {}

    try {
      await _mapController!.addLayer(
        '$id-source',
        '$id-layer',
        CircleLayerProperties(
          circleRadius: 3.5,
          circleColor: color,
          circleOpacity: 0.85,
          circleStrokeColor: '#ffffff',
          circleStrokeWidth: 0.5,
        ),
        belowLayerId: 'trails-layer',
      );
      // Add text labels for POIs
      try {
        await _mapController!.addLayer(
          '$id-source',
          '$id-text-layer',
          SymbolLayerProperties(
            textField: ['get', 'name'],
            textSize: 9,
            textColor: '#333333',
            textHaloColor: '#ffffff',
            textHaloWidth: 1.2,
            textOffset: [0, 1.2],
            textAnchor: 'top',
            textOptional: true,
            textAllowOverlap: false,
          ),
        );
      } catch (_) {}
    } catch (_) {}
  }

  Future<void> _removePoiLayers() async {
    if (_mapController == null) return;
    const ids = [
      'poi-shops',
      'poi-food',
      'poi-medical',
      'poi-fuel',
      'poi-outdoor',
      'poi-transport',
      'poi-hotels',
      'poi-attractions',
      'poi-atm',
      'poi-chemist',
      'poi-repair'
    ];
    for (final id in ids) {
      // Remove text labels first if present, then the circle layer, then source
      try {
        await _mapController!.removeLayer('$id-text-layer');
      } catch (_) {}
      try {
        await _mapController!.removeLayer('$id-layer');
      } catch (_) {}
      try {
        await _mapController!.removeSource('$id-source');
      } catch (_) {}
    }
  }

  Future<void> _reloadPois() async {
    if (_selectedBounds == null) return;
    await _removePoiLayers();
    await _loadRegionData(_regionSearchController.text);
  }

  Future<void> _maybeFetchPlaceInfo(String query) async {
    if (query.isEmpty || query == _lastPlaceInfoQuery) return;
    _lastPlaceInfoQuery = query;
    setState(() {
      _isPlaceInfoLoading = true;
      _placeInfoTitle = null;
      _placeInfoSummary = null;
      _placeInfoUrl = null;
    });

    final slug = Uri.encodeComponent(query);
    final language = _languageCode.isNotEmpty ? _languageCode : 'en';
    final uri = Uri.parse(
        'https://$language.wikipedia.org/api/rest_v1/page/summary/$slug');

    try {
      final response = await http.get(uri, headers: {
        'User-Agent': 'Dravik/1.0'
      }).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final contentUrls = data['content_urls'] as Map<String, dynamic>?;
        final desktop = contentUrls?['desktop'] as Map<String, dynamic>?;
        final mobile = contentUrls?['mobile'] as Map<String, dynamic>?;
        if (mounted) {
          setState(() {
            _placeInfoTitle = data['title'] as String? ?? query;
            _placeInfoSummary = (data['extract'] as String?) ??
                (data['description'] as String?) ??
                'No summary available yet.';
            _placeInfoUrl =
                (desktop?['page'] as String?) ?? (mobile?['page'] as String?);
          });
        }
      } else {
        if (kDebugMode) {
          debugPrint('Place info response: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Place info fetch failed: $e');
    } finally {
      if (mounted) setState(() => _isPlaceInfoLoading = false);
    }
  }

  Future<void> _goToMyLocation() async {
    if (_mapController == null || _isLocating) return;
    setState(() => _isLocating = true);
    try {
      var permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
      }

      if (permission == geo.LocationPermission.deniedForever) {
        _showErrorSnackbar(
          'Location permission required',
          'Enable location in Settings to use this feature',
        );
        await openAppSettings();
        return;
      }

      if (permission == geo.LocationPermission.denied) {
        _showErrorSnackbar(
          'Location blocked',
          'Location is needed to center the map on you',
        );
        return;
      }

      final position = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high,
      );
      final target = LatLng(position.latitude, position.longitude);
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(target, 15.5),
      );
      if (_showWeatherOverlay) {
        _fetchWeather(position.latitude, position.longitude);
      }
    } catch (e) {
      _showErrorSnackbar('Location unavailable', 'Unable to get your position');
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  Future<void> _promptSavePin(LatLng point) async {
    final reverse = await _searchService.reverseGeocode(
      point.latitude,
      point.longitude,
      languageCode: _languageCode,
    );
    final controller = TextEditingController(
      text: reverse?.displayName ?? 'Pinned location',
    );

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.push_pin, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Save this place',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Camp spot, cafe, trailhead...',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _savePlace(
                      controller.text,
                      point,
                      country: reverse?.country,
                    );
                  },
                  icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                  label: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePlace(
    String name,
    LatLng coords, {
    String? country,
  }) async {
    try {
      if (!Hive.isBoxOpen('saved_places')) {
        await Hive.openBox('saved_places');
      }
      final box = Hive.box('saved_places');
      final entry = <String, dynamic>{
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': name.isEmpty ? 'Pinned location' : name,
        'lat': coords.latitude,
        'lon': coords.longitude,
        'country': country,
        'savedAt': DateTime.now().toIso8601String(),
      };
      await box.put(entry['id'], entry);
      await _loadSavedPlaces();
      _showSuccessSnackbar('Location saved', entry['name'] as String);
    } catch (e) {
      _showErrorSnackbar('Save failed', 'Could not save this place');
    }
  }

  Future<void> _deleteSavedPlace(String id) async {
    if (!Hive.isBoxOpen('saved_places')) {
      await Hive.openBox('saved_places');
    }
    final box = Hive.box('saved_places');
    await box.delete(id);
    await _loadSavedPlaces();
  }

  Future<void> _showSavedPlacesSheet() async {
    await _loadSavedPlaces();
    if (!mounted) return;
    final formatter = DateFormat.yMMMd().add_jm();
    final sorted = [..._savedPlaces]..sort(
        (a, b) => (b['savedAt'] as String).compareTo(a['savedAt'] as String));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool isTimelineView = false;
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.5,
              minChildSize: 0.35,
              maxChildSize: 0.95,
              builder: (_, controller) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bookmark, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            'Saved places (${sorted.length})',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(
                                isTimelineView ? Icons.list : Icons.timeline),
                            onPressed: () {
                              setState(() {
                                isTimelineView = !isTimelineView;
                              });
                            },
                            tooltip:
                                isTimelineView ? 'List view' : 'Timeline view',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: sorted.isEmpty
                            ? const Center(
                                child: Text('No saved places yet'),
                              )
                            : isTimelineView
                                ? _buildTimelineView(sorted, controller)
                                : _buildListView(sorted, controller, formatter),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildListView(
    List<Map<dynamic, dynamic>> sorted,
    ScrollController controller,
    DateFormat formatter,
  ) {
    return ListView.builder(
      controller: controller,
      itemCount: sorted.length,
      itemBuilder: (_, idx) {
        final place = sorted[idx];
        final date = DateTime.tryParse(place['savedAt'] as String? ?? '');
        return Card(
          child: ListTile(
            title: Text(place['name'] as String? ?? 'Saved place'),
            subtitle: Text(
              [
                if (place['country'] != null) place['country'] as String,
                if (date != null) formatter.format(date),
              ].join(' • '),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.map_outlined),
                  onPressed: () async {
                    Navigator.pop(context);
                    final target = LatLng(
                      place['lat'] as double,
                      place['lon'] as double,
                    );
                    await _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(target, 14.5),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await _deleteSavedPlace(place['id'] as String);
                    Navigator.pop(context);
                    _showSavedPlacesSheet();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimelineView(
    List<Map<dynamic, dynamic>> sorted,
    ScrollController controller,
  ) {
    // Group places by country, then by date
    final Map<String, Map<String, List<Map<dynamic, dynamic>>>>
        groupedByCountry = {};

    for (final place in sorted) {
      final country = place['country'] as String? ?? 'Unknown';
      final date = DateTime.tryParse(place['savedAt'] as String? ?? '');
      final dateKey =
          date != null ? DateFormat.yMMMd().format(date) : 'Unknown date';

      groupedByCountry.putIfAbsent(country, () => {});
      groupedByCountry[country]!.putIfAbsent(dateKey, () => []);
      groupedByCountry[country]![dateKey]!.add(place);
    }

    return ListView.builder(
      controller: controller,
      itemCount: groupedByCountry.length,
      itemBuilder: (_, countryIdx) {
        final country = groupedByCountry.keys.elementAt(countryIdx);
        final dateGroups = groupedByCountry[country]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Country header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              margin: const EdgeInsets.only(bottom: 8, top: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flag, size: 20, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    country,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    '${dateGroups.values.fold<int>(0, (sum, places) => sum + places.length)} places',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            // Date groups
            ...dateGroups.entries.map((dateEntry) {
              final dateKey = dateEntry.key;
              final places = dateEntry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 24, bottom: 4),
                    child: Text(
                      dateKey,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  ...places.map((place) {
                    return Card(
                      margin:
                          const EdgeInsets.only(left: 32, right: 8, bottom: 6),
                      child: ListTile(
                        dense: true,
                        title: Text(place['name'] as String? ?? 'Saved place'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.map_outlined, size: 20),
                              onPressed: () async {
                                Navigator.pop(context);
                                final target = LatLng(
                                  place['lat'] as double,
                                  place['lon'] as double,
                                );
                                await _mapController?.animateCamera(
                                  CameraUpdate.newLatLngZoom(target, 14.5),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: () async {
                                await _deleteSavedPlace(place['id'] as String);
                                Navigator.pop(context);
                                _showSavedPlacesSheet();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildPlaceInfoCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: isDark ? Colors.grey[900] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.travel_explore, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _placeInfoTitle ?? 'Exploring...',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_isPlaceInfoLoading)
                  const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_placeInfoSummary != null)
              Text(
                _placeInfoSummary!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey.shade800,
                ),
              ),
            if (_placeInfoSummary != null)
              TextButton(
                onPressed: _showPlaceInfoDetails,
                child: const Text('More about this place'),
              ),
            if (_placeInfoSummary == null && !_isPlaceInfoLoading)
              Text(
                'No summary available yet.',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showPlaceInfoDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.place, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _placeInfoTitle ?? 'Place info',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_placeInfoSummary != null)
                  Text(
                    _placeInfoSummary!,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(height: 1.4),
                  )
                else
                  const Text('No description available yet.'),
                const SizedBox(height: 12),
                if (_placeInfoUrl != null)
                  Text(
                    'Source: Wikipedia',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactLayerPanel() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const activeBgColor = Color(0xFF1A73E8); // Google-like blue
    final inactiveBgColor = isDark ? Colors.grey.shade800 : Colors.white;
    final borderColor = isDark ? Colors.white12 : Colors.grey.shade300;
    const activeTextColor = Colors.white;
    final inactiveTextColor = isDark ? Colors.white70 : Colors.black87;

    Widget chip({
      required String label,
      required IconData icon,
      required bool isActive,
      required VoidCallback onTap,
    }) {
      return Material(
        color: isActive ? activeBgColor : inactiveBgColor,
        elevation: isActive ? 2 : 0,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isActive ? activeTextColor : inactiveTextColor,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive ? activeTextColor : inactiveTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? Colors.black.withValues(alpha: 0.8) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Map style',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                chip(
                  label: 'Street',
                  icon: Icons.map_outlined,
                  isActive: _mapStyle == 'osm',
                  onTap: () {
                    setState(() => _mapStyle = 'osm');
                    unawaited(_refreshCurrentRegionData());
                  },
                ),
                chip(
                  label: 'Satellite',
                  icon: Icons.satellite_alt_outlined,
                  isActive: _mapStyle == 'satellite',
                  onTap: () {
                    setState(() => _mapStyle = 'satellite');
                    unawaited(_refreshCurrentRegionData());
                  },
                ),
                chip(
                  label: 'Terrain',
                  icon: Icons.terrain_outlined,
                  isActive: _mapStyle == 'topographic',
                  onTap: () {
                    setState(() => _mapStyle = 'topographic');
                    unawaited(_refreshCurrentRegionData());
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Layers',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                chip(
                  label: 'Transit',
                  icon: Icons.directions_bus_outlined,
                  isActive: _showTransport,
                  onTap: () {
                    setState(() => _showTransport = !_showTransport);
                    unawaited(_refreshCurrentRegionData());
                  },
                ),
                chip(
                  label: 'Food',
                  icon: Icons.restaurant_outlined,
                  isActive: _showFood,
                  onTap: () {
                    setState(() => _showFood = !_showFood);
                    unawaited(_refreshCurrentRegionData());
                  },
                ),
                chip(
                  label: 'Hotels',
                  icon: Icons.hotel_outlined,
                  isActive: _showHotels,
                  onTap: () {
                    setState(() => _showHotels = !_showHotels);
                    unawaited(_refreshCurrentRegionData());
                  },
                ),
                chip(
                  label: 'Shops',
                  icon: Icons.store_mall_directory_outlined,
                  isActive: _showShops,
                  onTap: () {
                    setState(() => _showShops = !_showShops);
                    unawaited(_refreshCurrentRegionData());
                  },
                ),
                chip(
                  label: 'ATM',
                  icon: Icons.atm_outlined,
                  isActive: _showAtm,
                  onTap: () {
                    setState(() => _showAtm = !_showAtm);
                    unawaited(_refreshCurrentRegionData());
                  },
                ),
                chip(
                  label: 'Medical',
                  icon: Icons.local_hospital_outlined,
                  isActive: _showMedical,
                  onTap: () {
                    setState(() => _showMedical = !_showMedical);
                    unawaited(_refreshCurrentRegionData());
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard() {
    final weather = _currentWeather!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark
          ? Colors.grey[850]?.withValues(alpha: 0.98)
          : Colors.white.withValues(alpha: 0.98),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [Colors.blue.shade900, Colors.blue.shade800]
                : [Colors.blue.shade400, Colors.blue.shade600],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _weatherService.getWeatherIcon(weather.description),
                  style: const TextStyle(fontSize: 48),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${weather.temperature.toStringAsFixed(0)}°',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      weather.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.water_drop,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.8)),
                        const SizedBox(width: 4),
                        Text(
                          '${weather.humidity}%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.air,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.8)),
                        const SizedBox(width: 4),
                        Text(
                          '${weather.windSpeed.toStringAsFixed(0)} km/h',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWeatherDetails() {
    if (_currentWeather == null) return;
    final weather = _currentWeather!;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, controller) {
            return SingleChildScrollView(
              controller: controller,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade400,
                                Colors.blue.shade600,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _weatherService.getWeatherIcon(weather.description),
                            style: const TextStyle(fontSize: 56),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${weather.temperature.toStringAsFixed(0)}°C',
                                style: const TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                weather.description,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Feels like ${weather.feelsLike.toStringAsFixed(0)}°C',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    // Weather Details Grid
                    Text(
                      'Current Conditions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildWeatherDetailCard(
                          'Humidity',
                          '${weather.humidity}%',
                          Icons.water_drop,
                        ),
                        _buildWeatherDetailCard(
                          'Wind Speed',
                          '${weather.windSpeed.toStringAsFixed(0)} km/h',
                          Icons.air,
                        ),
                        _buildWeatherDetailCard(
                          'Feels Like',
                          '${weather.feelsLike.toStringAsFixed(0)}°C',
                          Icons.thermostat,
                        ),
                        _buildWeatherDetailCard(
                          'UV Index',
                          '${weather.humidity}',
                          Icons.wb_sunny,
                        ),
                      ],
                    ),
                    if (weather.daily.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 20, color: Colors.blue.shade600),
                          const SizedBox(width: 8),
                          const Text(
                            '7-Day Forecast',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...weather.daily.take(7).map((day) {
                        final date = day.date;
                        final dayName = [
                          'Monday',
                          'Tuesday',
                          'Wednesday',
                          'Thursday',
                          'Friday',
                          'Saturday',
                          'Sunday'
                        ][date.weekday - 1];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dayName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '${date.month}/${date.day}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _weatherService.getWeatherIcon(day.description),
                                style: const TextStyle(fontSize: 32),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  day.description,
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${day.tempMax.toStringAsFixed(0)}°',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '${day.tempMin.toStringAsFixed(0)}°',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWeatherDetailCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: Colors.blue.shade600),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _addLandcoverLayer() async {
    if (_mapController == null || !_showLandcover || _landcover.isEmpty) return;
    try {
      await _mapController!.addSource(
        'landcover-source',
        GeojsonSourceProperties(data: {
          'type': 'FeatureCollection',
          'features': _landcover,
        }),
      );
    } catch (_) {}

    try {
      await _mapController!.addLayer(
        'landcover-source',
        'landcover-layer',
        FillLayerProperties(
          fillColor: [
            'get',
            'color',
          ],
          fillOpacity: 0.25,
          fillOutlineColor: '#000000',
        ),
        belowLayerId: 'trails-layer',
      );
    } catch (_) {}
  }

  Future<void> _addProtectedAreasLayer() async {
    if (_mapController == null ||
        !_showProtectedAreas ||
        _protectedAreas.isEmpty) {
      return;
    }
    try {
      await _mapController!.addSource(
        'protected-areas-source',
        GeojsonSourceProperties(data: {
          'type': 'FeatureCollection',
          'features': _protectedAreas,
        }),
      );
    } catch (_) {}

    try {
      await _mapController!.addLayer(
        'protected-areas-source',
        'protected-areas-layer',
        FillLayerProperties(
          fillColor: '#4CAF50',
          fillOpacity: 0.15,
          fillOutlineColor: '#2E7D32',
        ),
        belowLayerId: 'trails-layer',
      );
    } catch (_) {}

    // Add labels for protected areas
    try {
      await _mapController!.addLayer(
        'protected-areas-source',
        'protected-areas-label',
        SymbolLayerProperties(
          textField: [
            'get',
            'name',
          ],
          textSize: 11,
          textColor: '#1B5E20',
          textHaloColor: '#FFFFFF',
          textHaloWidth: 1,
        ),
      );
    } catch (_) {}
  }

  Future<void> _removeLandcoverLayer() async {
    if (_mapController == null) return;
    try {
      await _mapController!.removeLayer('landcover-layer');
    } catch (_) {}
    try {
      await _mapController!.removeSource('landcover-source');
    } catch (_) {}
  }

  Future<void> _removeProtectedAreasLayer() async {
    if (_mapController == null) return;
    try {
      await _mapController!.removeLayer('protected-areas-label');
    } catch (_) {}
    try {
      await _mapController!.removeLayer('protected-areas-layer');
    } catch (_) {}
    try {
      await _mapController!.removeSource('protected-areas-source');
    } catch (_) {}
  }

  Future<void> _applyImageryLayer() async {
    if (_mapController == null || !_showImagery) return;
    try {
      await _mapController!.addSource(
        'imagery-source',
        RasterSourceProperties(
          tiles: const [
            'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
          ],
          tileSize: 256,
          attribution: '© Esri',
        ),
      );
    } catch (_) {}

    try {
      await _mapController!.addLayer(
        'imagery-source',
        'imagery-layer',
        const RasterLayerProperties(rasterOpacity: 0.85),
        belowLayerId: 'trails-layer',
      );
    } catch (_) {}
  }

  Future<void> _removeImageryLayer() async {
    if (_mapController == null) return;
    try {
      await _mapController!.removeLayer('imagery-layer');
    } catch (_) {}
    try {
      await _mapController!.removeSource('imagery-source');
    } catch (_) {}
  }

  void _showSuccessSnackbar(String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (message.isNotEmpty)
                        Text(
                          message,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackbar(String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (message.isNotEmpty)
                        Text(
                          message,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showInfoSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.info_outline,
                color: Colors.blue.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blue.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<void> _openPlaceGuide() async {
    final result = await Navigator.of(context).push<PlaceGuide>(
      MaterialPageRoute(builder: (_) => const PlaceGuideScreen()),
    );
    if (result != null && mounted) {
      // User generated a guide and wants to show it on the map
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(result.latitude, result.longitude),
          12.0,
        ),
      );
      _showInfoSnackbar('Showing ${result.placeName} on map');
      // Optionally overlay airports/transport as markers
      _overlayPlaceGuideMarkers(result);
    }
  }

  Future<void> _overlayPlaceGuideMarkers(PlaceGuide guide) async {
    // Add airports as symbols
    for (final airport in guide.nearestAirports.take(3)) {
      try {
        await _mapController?.addSymbol(
          SymbolOptions(
            geometry: LatLng(guide.latitude, guide.longitude),
            iconImage: 'airport',
            iconSize: 0.3,
            textField: airport.name,
            textSize: 10,
            textColor: '#000000',
            textHaloColor: '#FFFFFF',
            textHaloWidth: 1,
          ),
        );
      } catch (_) {}
    }
  }
}
