import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dravik/screens/map_screen.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:sensors_plus/sensors_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:dravik/models/ar_poi.dart';
import 'package:dravik/services/overpass_service.dart';
import 'package:http/http.dart' as http;
import 'package:dravik/config/feature_flags.dart';
import 'package:dravik/widgets/platform_unavailable_screen.dart';

/// Professional AR Scanner like Google Gemini
/// Uses camera + sensors for real-time 3D AR overlays
class ArTrailScannerPro extends StatefulWidget {
  const ArTrailScannerPro({super.key});

  @override
  State<ArTrailScannerPro> createState() => _ArTrailScannerProState();
}

class _ArTrailScannerProState extends State<ArTrailScannerPro>
    with SingleTickerProviderStateMixin {
  // Camera
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _cameraReady = false;

  // Location & POIs
  geo.Position? _currentPosition;
  List<ArPoi> _nearbyPois = [];
  ArPoi? _selectedPoi;
  final OverpassService _overpassService = OverpassService();

  // Device orientation sensors
  double _deviceHeading = 0.0; // Compass direction (0-360°)
  double _devicePitch = 0.0; // Vertical tilt (-90° to +90°)
  double _deviceRoll = 0.0; // Screen rotation

  StreamSubscription<CompassEvent>? _compassSubscription;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;

  // Animation & UI
  bool _isLoading = true;
  bool _showDebug = true;
  late AnimationController _pulseController;

  // AR Configuration
  static const double _maxArDistance = 3000; // 3km max range
  static const double _horizontalFov = 90.0; // Camera field of view
  static const double _verticalFov = 60.0;

  // Navigation features
  ArPoi? _navigationTarget; // Currently navigating to this POI
  StreamSubscription<geo.Position>?
      _locationSubscription; // Real-time position updates
  double? _targetDistance;
  double? _targetBearing;
  int? _estimatedTimeMinutes;

  // Frame throttling to prevent buffer exhaustion
  DateTime _lastFrameTime = DateTime.now();
  static const Duration _frameThrottle = Duration(milliseconds: 33); // ~30fps

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _initializeAr();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _compassSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _locationSubscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initializeAr() async {
    setState(() => _isLoading = true);

    try {
      // Check permissions (do not prompt while user is away)
      final cameraStatus = await Permission.camera.status;
      final locationStatus = await Permission.locationWhenInUse.status;

      if (!cameraStatus.isGranted || !locationStatus.isGranted) {
        _showSnack('AR disabled: grant Camera & Location in Settings',
            color: Colors.red);
        setState(() => _isLoading = false);
        return;
      }

      // Initialize camera with balanced quality (fixes ImageReader buffer issues)
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        final backCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras!.first,
        );

        // Use low resolution to minimize ImageReader buffer pressure
        _cameraController = CameraController(
          backCamera,
          ResolutionPreset.low,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.yuv420,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() => _cameraReady = true);
        }

        // Minimize frame processing overhead
        try {
          await _cameraController!.setExposureMode(ExposureMode.auto);
          await _cameraController!.setFlashMode(FlashMode.off);
        } catch (_) {}
      }

      // Get high-accuracy location
      _currentPosition = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.bestForNavigation,
      );

      // Load nearby POIs
      await _loadNearbyPois();

      // Start sensor fusion
      _listenToSensors();

      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack('AR Scanner Ready', color: Colors.green);
      }
    } catch (e) {
      if (mounted) {
        _showSnack('AR initialization failed: $e', color: Colors.red);
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnack(String message, {Color color = Colors.black87}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: color),
      );
    });
  }

  void _listenToSensors() {
    // Compass for accurate heading
    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (event.heading != null && mounted) {
        setState(() {
          _deviceHeading = event.heading!;
        });
      }
    });

    // Accelerometer for pitch and roll
    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      if (!mounted) return;

      final x = event.x;
      final y = event.y;
      final z = event.z;

      // Calculate pitch (forward/backward tilt)
      final pitch = math.atan2(-y, math.sqrt(x * x + z * z)) * (180 / math.pi);

      // Calculate roll (left/right tilt)
      final roll = math.atan2(x, z) * (180 / math.pi);

      setState(() {
        _devicePitch = pitch;
        _deviceRoll = roll;
      });
    });

    // Gyroscope for smooth motion (can be used for filtering)
    _gyroscopeSubscription = gyroscopeEventStream().listen((event) {
      // Can use this for motion prediction if needed
    });
  }

  Future<void> _loadNearbyPois() async {
    if (_currentPosition == null) return;

    try {
      final pois = <ArPoi>[];

      // Fetch water sources
      // Create bounding box around current position (±0.027° ≈ 3km)
      const offset = 0.027;
      final waterFeatures = await _overpassService.fetchWaterSources(
        southwest: LatLng(
          _currentPosition!.latitude - offset,
          _currentPosition!.longitude - offset,
        ),
        northeast: LatLng(
          _currentPosition!.latitude + offset,
          _currentPosition!.longitude + offset,
        ),
      );

      for (var feature in waterFeatures) {
        final geometry = feature['geometry'];
        if (geometry != null && geometry['type'] == 'Point') {
          final coords = geometry['coordinates'] as List;
          final distance = _calculateDistance(coords[1], coords[0]);

          if (distance <= _maxArDistance) {
            pois.add(ArPoi(
              id: feature['properties']['id']?.toString() ??
                  'water_${pois.length}',
              name: feature['properties']['name'] ?? 'Water Source',
              type: 'water',
              latitude: coords[1],
              longitude: coords[0],
              description: '💧 ${distance.toStringAsFixed(0)}m away',
            ));
          }
        }
      }

      // Fetch shelters
      final shelterFeatures = await _overpassService.fetchShelters(
        southwest: LatLng(
          _currentPosition!.latitude - offset,
          _currentPosition!.longitude - offset,
        ),
        northeast: LatLng(
          _currentPosition!.latitude + offset,
          _currentPosition!.longitude + offset,
        ),
      );

      for (var feature in shelterFeatures) {
        final geometry = feature['geometry'];
        if (geometry != null && geometry['type'] == 'Point') {
          final coords = geometry['coordinates'] as List;
          final distance = _calculateDistance(coords[1], coords[0]);

          if (distance <= _maxArDistance) {
            pois.add(ArPoi(
              id: feature['properties']['id']?.toString() ??
                  'shelter_${pois.length}',
              name: feature['properties']['name'] ?? 'Shelter',
              type: 'shelter',
              latitude: coords[1],
              longitude: coords[0],
              description: '🏠 ${distance.toStringAsFixed(0)}m away',
            ));
          }
        }
      }

      // Add test POIs for demonstration
      if (pois.length < 3) {
        pois.addAll([
          ArPoi(
            id: 'test_north',
            name: 'Mountain Peak',
            type: 'landmark',
            latitude: _currentPosition!.latitude + 0.01,
            longitude: _currentPosition!.longitude,
            description: '⛰️ Peak 1.1km north',
          ),
          ArPoi(
            id: 'test_east',
            name: 'Forest Trail',
            type: 'landmark',
            latitude: _currentPosition!.latitude + 0.005,
            longitude: _currentPosition!.longitude + 0.015,
            description: '🌲 Trail 1.5km east',
          ),
          ArPoi(
            id: 'test_se',
            name: 'Lake View',
            type: 'water',
            latitude: _currentPosition!.latitude - 0.008,
            longitude: _currentPosition!.longitude + 0.012,
            description: '🏞️ Lake 900m southeast',
          ),
          ArPoi(
            id: 'test_close',
            name: 'Nearby Landmark',
            type: 'shelter',
            latitude: _currentPosition!.latitude + 0.002,
            longitude: _currentPosition!.longitude + 0.002,
            description: '📍 Point 200m away',
          ),
        ]);
      }

      if (mounted) {
        setState(() {
          _nearbyPois = pois;
        });
      }
    } catch (e) {
      debugPrint('Error loading POIs: $e');

      // Fallback demo POIs
      if (_currentPosition != null && mounted) {
        setState(() {
          _nearbyPois = [
            ArPoi(
              id: 'demo_1',
              name: 'Demo Point North',
              type: 'landmark',
              latitude: _currentPosition!.latitude + 0.003,
              longitude: _currentPosition!.longitude,
              description: '🎯 Demo 300m',
            ),
            ArPoi(
              id: 'demo_2',
              name: 'Demo Point East',
              type: 'water',
              latitude: _currentPosition!.latitude,
              longitude: _currentPosition!.longitude + 0.005,
              description: '🎯 Demo 500m',
            ),
          ];
        });
      }
    }
  }

  double _calculateDistance(double lat2, double lon2) {
    if (_currentPosition == null) return 0;
    return geo.Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      lat2,
      lon2,
    );
  }

  double _calculateBearing(double lat2, double lon2) {
    if (_currentPosition == null) return 0;

    final lat1 = _currentPosition!.latitude * math.pi / 180;
    final lon1 = _currentPosition!.longitude * math.pi / 180;
    final lat2Rad = lat2 * math.pi / 180;
    final lon2Rad = lon2 * math.pi / 180;

    final dLon = lon2Rad - lon1;

    final y = math.sin(dLon) * math.cos(lat2Rad);
    final x = math.cos(lat1) * math.sin(lat2Rad) -
        math.sin(lat1) * math.cos(lat2Rad) * math.cos(dLon);

    final bearing = math.atan2(y, x) * (180 / math.pi);
    return (bearing + 360) % 360;
  }

  /// Start navigation to a POI with real-time tracking
  Future<void> _startNavigationTo(ArPoi poi) async {
    setState(() {
      _navigationTarget = poi;
      _targetDistance = _calculateDistance(poi.latitude, poi.longitude);
      _targetBearing = _calculateBearing(poi.latitude, poi.longitude);
      _estimatedTimeMinutes =
          ((_targetDistance ?? 0) / 1.4 / 60).ceil(); // ~1.4 m/s walking speed
    });

    // Cancel previous subscription
    _locationSubscription?.cancel();

    // Start real-time position tracking for navigation
    final settings = geo.LocationSettings(
      accuracy: geo.LocationAccuracy.high,
      distanceFilter: 5, // Update every 5 meters
    );

    _locationSubscription =
        geo.Geolocator.getPositionStream(locationSettings: settings).listen(
            (geo.Position position) {
      if (!mounted) return;

      setState(() {
        _currentPosition = position;
        _targetDistance = _calculateDistance(poi.latitude, poi.longitude);
        _targetBearing = _calculateBearing(poi.latitude, poi.longitude);
        _estimatedTimeMinutes = ((_targetDistance ?? 0) / 1.4 / 60).ceil();
      });

      // Stop navigation when within 30 meters
      if ((_targetDistance ?? 0) < 30) {
        _stopNavigation();
        _showSnack('🎉 You reached ${poi.name}!', color: Colors.green);
      }
    }, onError: (e) {
      debugPrint('Navigation GPS Error: $e');
      _showSnack('GPS Error: $e', color: Colors.red);
      _stopNavigation();
    });

    _showSnack('Navigating to ${poi.name}...', color: Colors.blue);
    debugPrint(
        'Started navigation to: ${poi.name} (${poi.latitude}, ${poi.longitude})');
  }

  /// Stop current navigation and cleanup
  void _stopNavigation() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    setState(() {
      _navigationTarget = null;
      _targetDistance = null;
      _targetBearing = null;
      _estimatedTimeMinutes = null;
    });
  }

  /// Fetch route from OSRM (walking mode)
  Future<void> _fetchRouteToTarget(ArPoi target) async {
    if (_currentPosition == null) {
      debugPrint('Cannot fetch route: no current position');
      return;
    }

    try {
      final url = Uri.parse('https://router.project-osrm.org/route/v1/walking/'
          '${_currentPosition!.longitude},${_currentPosition!.latitude};'
          '${target.longitude},${target.latitude}?overview=full&geometries=geojson');

      debugPrint('Fetching route from OSRM: $url');
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List?;

        if (routes != null && routes.isNotEmpty) {
          final firstRoute = routes[0] as Map<String, dynamic>;
          final geometry = firstRoute['geometry'] as Map<String, dynamic>;
          final coordinates = geometry['coordinates'] as List? ?? [];

          debugPrint('Route coordinates fetched: ${coordinates.length} points');

          // Convert coordinates to LatLng waypoints
          final waypoints = <LatLng>[];
          for (var coord in coordinates) {
            if (coord is List && coord.length >= 2) {
              waypoints.add(LatLng(coord[1] as double, coord[0] as double));
            }
          }

          debugPrint('Route loaded: ${waypoints.length} waypoints');
        } else {
          debugPrint('No routes found in OSRM response');
        }
      } else {
        debugPrint(
            'OSRM request failed with status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('Route fetch error: $e');
      _showSnack('Route error: $e', color: Colors.orange);
    }
  }

  bool _isPoiVisible(ArPoi poi) {
    final bearing = _calculateBearing(poi.latitude, poi.longitude);
    final relativeBearing = (bearing - _deviceHeading + 360) % 360;

    // Normalize to -180 to +180
    final normalizedBearing =
        relativeBearing > 180 ? relativeBearing - 360 : relativeBearing;

    // Check if within horizontal FOV
    final horizontalVisible = normalizedBearing.abs() <= _horizontalFov / 2;

    // Check vertical visibility based on pitch
    final distance = _calculateDistance(poi.latitude, poi.longitude);

    // For distant objects, they should be visible when looking straight ahead
    // For close objects, they should be visible when looking down
    double expectedPitch;
    if (distance < 100) {
      expectedPitch = -30; // Look down for close objects
    } else if (distance < 500) {
      expectedPitch = -15;
    } else {
      expectedPitch = 0; // Look straight for distant objects
    }

    final pitchDiff = (_devicePitch - expectedPitch).abs();
    final verticalVisible = pitchDiff < _verticalFov / 2;

    return horizontalVisible && verticalVisible;
  }

  Offset _getPoiScreenPosition(ArPoi poi, Size screenSize) {
    final bearing = _calculateBearing(poi.latitude, poi.longitude);
    final relativeBearing = (bearing - _deviceHeading + 360) % 360;

    // Normalize to -180 to +180
    final normalizedBearing =
        relativeBearing > 180 ? relativeBearing - 360 : relativeBearing;

    // Map bearing to horizontal screen position
    final x = screenSize.width / 2 +
        (normalizedBearing / _horizontalFov) * screenSize.width;

    // Calculate vertical position based on distance and pitch
    final distance = _calculateDistance(poi.latitude, poi.longitude);

    // Base Y position depends on pitch
    double y = screenSize.height / 2;

    // Adjust for pitch (tilting up moves markers down)
    y -= _devicePitch * 8;

    // Adjust for distance (closer objects appear lower)
    if (distance < 100) {
      y += screenSize.height * 0.2; // Very close = much lower
    } else if (distance < 500) {
      y += screenSize.height * 0.1;
    }

    return Offset(
      x.clamp(0, screenSize.width),
      y.clamp(screenSize.height * 0.1, screenSize.height * 0.9),
    );
  }

  Color _getPoiColor(ArPoi poi) {
    switch (poi.type) {
      case 'water':
        return Colors.cyan;
      case 'shelter':
        return Colors.orange;
      case 'landmark':
      default:
        return Colors.green;
    }
  }

  Widget _buildArOverlay(Size screenSize) {
    // Throttle AR updates to prevent camera buffer exhaustion
    final now = DateTime.now();
    if (now.difference(_lastFrameTime) < _frameThrottle) {
      // Return empty/cached overlay if throttled
      return Stack(children: []);
    }
    _lastFrameTime = now;

    final visiblePois = _nearbyPois.where((poi) => _isPoiVisible(poi)).toList();

    return Stack(
      children: [
        // Draw AR markers
        ...visiblePois.map((poi) {
          final position = _getPoiScreenPosition(poi, screenSize);
          final distance = _calculateDistance(poi.latitude, poi.longitude);
          final color = _getPoiColor(poi);

          // Scale based on distance (closer = larger)
          double scale;
          if (distance < 100) {
            scale = 1.5;
          } else if (distance < 500) {
            scale = 1.2;
          } else if (distance < 1000) {
            scale = 1.0;
          } else {
            scale = 0.8;
          }

          return Positioned(
            left: position.dx - 30 * scale,
            top: position.dy - 30 * scale,
            child: GestureDetector(
              onTap: () => setState(() => _selectedPoi = poi),
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final pulse = 1.0 +
                      (math.sin(_pulseController.value * 2 * math.pi) * 0.1);

                  return Transform.scale(
                    scale: scale * pulse,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Marker icon
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: Icon(
                            poi.type == 'water'
                                ? Icons.water_drop
                                : poi.type == 'shelter'
                                    ? Icons.home
                                    : Icons.location_on,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Label
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                poi.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                '${distance.toStringAsFixed(0)}m',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTopPanel() {
    return Positioned(
      top: 60,
      left: 20,
      right: 20,
      child: Card(
        color: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.radar, color: Colors.blue[300], size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'AR Trail Scanner Pro',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      _showDebug ? Icons.bug_report : Icons.bug_report_outlined,
                      color: Colors.white70,
                    ),
                    onPressed: () => setState(() => _showDebug = !_showDebug),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${_nearbyPois.length} locations found within 3km',
                style: TextStyle(
                  color: Colors.blue[200],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDebugPanel() {
    if (!_showDebug) return const SizedBox.shrink();

    final visibleCount = _nearbyPois.where((poi) => _isPoiVisible(poi)).length;

    return Positioned(
      top: 180,
      left: 20,
      child: Card(
        color: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Debug Info',
                style: TextStyle(
                  color: Colors.yellow[700],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Heading: ${_deviceHeading.toStringAsFixed(0)}°',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              Text(
                'Pitch: ${_devicePitch.toStringAsFixed(1)}°',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              Text(
                'Roll: ${_deviceRoll.toStringAsFixed(1)}°',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              Text(
                'Visible: $visibleCount / ${_nearbyPois.length}',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              if (_currentPosition != null)
                Text(
                  'GPS: ±${_currentPosition!.accuracy.toStringAsFixed(1)}m',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPoiDetailsPanel() {
    if (_selectedPoi == null) return const SizedBox.shrink();

    final distance = _calculateDistance(
      _selectedPoi!.latitude,
      _selectedPoi!.longitude,
    );

    final bearing = _calculateBearing(
      _selectedPoi!.latitude,
      _selectedPoi!.longitude,
    );

    final color = _getPoiColor(_selectedPoi!);

    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Card(
        color: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _selectedPoi!.type == 'water'
                                ? Icons.water_drop
                                : _selectedPoi!.type == 'shelter'
                                    ? Icons.home
                                    : Icons.location_on,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedPoi!.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _selectedPoi!.type.toUpperCase(),
                                style: TextStyle(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => setState(() => _selectedPoi = null),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _selectedPoi!.description,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      Icons.straighten,
                      '${distance.toStringAsFixed(0)}m',
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoChip(
                      Icons.explore,
                      '${bearing.toStringAsFixed(0)}°',
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => setState(() => _selectedPoi = null),
                    child: const Text('Close',
                        style: TextStyle(color: Colors.white70)),
                  ),
                  const SizedBox(width: 8),
                  // Navigation button (AR feature)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                    ),
                    icon: const Icon(Icons.navigation),
                    label: const Text('Navigate'),
                    onPressed: () async {
                      final poi = _selectedPoi!;
                      setState(() => _selectedPoi = null);

                      // Start navigation and fetch route
                      await _startNavigationTo(poi);
                      await _fetchRouteToTarget(poi);
                    },
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Map'),
                    onPressed: () {
                      final poi = _selectedPoi!;
                      setState(() => _selectedPoi = null);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MapScreen(
                            initialLat: poi.latitude,
                            initialLon: poi.longitude,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Navigation info panel showing real-time direction guidance
  Widget _buildNavigationPanel() {
    if (_navigationTarget == null) return const SizedBox.shrink();

    // Calculate relative bearing: how much to rotate from current heading to target
    final bearing = _targetBearing ?? 0;
    final heading = _deviceHeading;
    final angle = ((bearing - heading + 360) % 360);
    final normalizedAngle = angle > 180 ? angle - 360 : angle;

    return Positioned(
      bottom: 80,
      left: 20,
      right: 20,
      child: Card(
        color: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Navigating to',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        _navigationTarget!.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: _stopNavigation,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      Icons.straighten,
                      '${(_targetDistance ?? 0).toStringAsFixed(0)}m',
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoChip(
                      Icons.explore,
                      '${bearing.toStringAsFixed(0)}°',
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoChip(
                      Icons.schedule,
                      '${_estimatedTimeMinutes ?? 0}m',
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Compass compass - shows relative bearing
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blue, width: 2),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Cardinal directions
                    Positioned(
                      top: 8,
                      child: const Text(
                        'N',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Center dot (your current position)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    // Arrow pointing to target
                    Transform.rotate(
                      angle: normalizedAngle * math.pi / 180,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            width: 4,
                            height: 30,
                            color: Colors.red,
                          ),
                          Container(
                            width: 0,
                            height: 0,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                            ),
                            child: const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.red,
                              size: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Bearing: ${bearing.toStringAsFixed(1)}° | Heading: ${heading.toStringAsFixed(1)}° | Δ: ${normalizedAngle.toStringAsFixed(1)}°',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.isEnabled(AppFeature.arScanner)) {
      return const PlatformUnavailableScreen(
        title: 'AR Scanner Pro',
        message:
            'AR scanner uses device camera and sensors and is available in Android and iOS app builds.',
        icon: Icons.camera_alt,
      );
    }

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : () => _loadNearbyPois(),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Initializing AR Scanner...',
                    style: TextStyle(
                      color: Colors.blue[200],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                // Camera feed
                if (_cameraReady && _cameraController != null)
                  SizedBox.expand(
                    child: CameraPreview(_cameraController!),
                  )
                else
                  Container(color: Colors.black),

                // AR overlay
                Positioned.fill(
                  child: _buildArOverlay(size),
                ),

                // UI panels
                _buildTopPanel(),
                _buildDebugPanel(),
                _buildNavigationPanel(), // Navigation guide
                _buildPoiDetailsPanel(),
              ],
            ),
    );
  }
}
