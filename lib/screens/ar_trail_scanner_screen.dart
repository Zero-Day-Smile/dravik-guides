import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:dravik/screens/map_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:dravik/models/ar_poi.dart';
import 'package:dravik/services/overpass_service.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:dravik/config/feature_flags.dart';
import 'package:dravik/widgets/platform_unavailable_screen.dart';

class ArTrailScannerScreen extends StatefulWidget {
  const ArTrailScannerScreen({super.key});

  @override
  State<ArTrailScannerScreen> createState() => _ArTrailScannerScreenState();
}

class _ArTrailScannerScreenState extends State<ArTrailScannerScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isLoading = true;
  bool _cameraReady = false;
  Position? _currentPosition;
  List<ArPoi> _nearbyPois = [];
  double _deviceHeading = 0.0; // Device compass heading
  double _devicePitch = 0.0; // Device pitch (tilt)
  double _deviceRoll = 0.0; // Device roll
  final OverpassService _overpassService = OverpassService();
  StreamSubscription<CompassEvent>? _compassSubscription;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  final bool _debugMode = true; // Show debug info

  @override
  void initState() {
    super.initState();
    _initializeAr();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _compassSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeAr() async {
    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);

    // Request permissions
    final cameraStatus = await Permission.camera.request();
    final locationStatus = await Permission.location.request();

    if (cameraStatus.isDenied || locationStatus.isDenied) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Camera and location permissions required for AR'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Initialize camera
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        setState(() => _cameraReady = true);
      }

      // Get current location
      _currentPosition = await Geolocator.getCurrentPosition();

      // Load nearby POIs
      await _loadNearbyPois();

      // Listen to device orientation
      _listenToSensors();

      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('AR initialization failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _listenToSensors() {
    // Use flutter_compass for accurate heading
    _compassSubscription = FlutterCompass.events?.listen((CompassEvent event) {
      if (event.heading != null) {
        setState(() {
          _deviceHeading = event.heading!;
        });
      }
    });

    // Listen to accelerometer for pitch and roll
    _accelerometerSubscription =
        accelerometerEventStream().listen((AccelerometerEvent event) {
      // Calculate pitch (forward/backward tilt)
      final pitch = math.atan2(
              event.y, math.sqrt(event.x * event.x + event.z * event.z)) *
          (180 / math.pi);

      // Calculate roll (left/right tilt)
      final roll = math.atan2(event.x, event.z) * (180 / math.pi);

      setState(() {
        _devicePitch = pitch;
        _deviceRoll = roll;
      });
    });

    // Listen to gyroscope for smoothing
    _gyroscopeSubscription =
        gyroscopeEventStream().listen((GyroscopeEvent event) {
      // Gyroscope provides rotation rate, can be used for smoothing
      // Currently just for data availability, not used in calculations
    });
  }

  Future<void> _loadNearbyPois() async {
    if (_currentPosition == null) return;

    try {
      // Create bounds around current location (±0.02 degrees ≈ 2km)
      final bounds = LatLngBounds(
        southwest: LatLng(
          _currentPosition!.latitude - 0.02,
          _currentPosition!.longitude - 0.02,
        ),
        northeast: LatLng(
          _currentPosition!.latitude + 0.02,
          _currentPosition!.longitude + 0.02,
        ),
      );

      // Fetch water sources
      final waterFeatures = await _overpassService.fetchWaterSources(
        southwest: bounds.southwest,
        northeast: bounds.northeast,
      );

      // Fetch shelters
      final shelterFeatures = await _overpassService.fetchShelters(
        southwest: bounds.southwest,
        northeast: bounds.northeast,
      );

      // Fetch trails as landmarks
      final trailFeatures = await _overpassService.fetchTrails(
        southwest: bounds.southwest,
        northeast: bounds.northeast,
      );

      // Convert to ArPoi objects
      final List<ArPoi> pois = [];

      for (var feature in waterFeatures) {
        final geometry = feature['geometry'];
        if (geometry != null && geometry['type'] == 'Point') {
          final coords = geometry['coordinates'] as List;
          pois.add(ArPoi(
            id: feature['properties']['id']?.toString() ?? '',
            name: feature['properties']['name'] ?? 'Water Source',
            type: 'water',
            latitude: coords[1],
            longitude: coords[0],
            description: 'Natural water source',
          ));
        }
      }

      for (var feature in shelterFeatures) {
        final geometry = feature['geometry'];
        if (geometry != null && geometry['type'] == 'Point') {
          final coords = geometry['coordinates'] as List;
          pois.add(ArPoi(
            id: feature['properties']['id']?.toString() ?? '',
            name: feature['properties']['name'] ?? 'Shelter',
            type: 'shelter',
            latitude: coords[1],
            longitude: coords[0],
            description: 'Emergency shelter',
          ));
        }
      }

      // Add trail points as landmarks
      for (var feature in trailFeatures) {
        final geometry = feature['geometry'];
        if (geometry != null && geometry['type'] == 'Point') {
          final coords = geometry['coordinates'] as List;
          pois.add(ArPoi(
            id: feature['properties']['id']?.toString() ?? '',
            name: feature['properties']['name'] ?? 'Trail Point',
            type: 'landmark',
            latitude: coords[1],
            longitude: coords[0],
            description: 'Hiking trail point',
          ));
        }
      }

      // Add some test POIs if nothing found
      if (pois.isEmpty && _currentPosition != null) {
        pois.addAll([
          ArPoi(
            id: 'test_1',
            name: 'Test Point North',
            type: 'landmark',
            latitude: _currentPosition!.latitude + 0.001,
            longitude: _currentPosition!.longitude,
            description: 'Test marker to the north',
          ),
          ArPoi(
            id: 'test_2',
            name: 'Test Point East',
            type: 'water',
            latitude: _currentPosition!.latitude,
            longitude: _currentPosition!.longitude + 0.001,
            description: 'Test marker to the east',
          ),
          ArPoi(
            id: 'test_3',
            name: 'Test Point South',
            type: 'shelter',
            latitude: _currentPosition!.latitude - 0.001,
            longitude: _currentPosition!.longitude,
            description: 'Test marker to the south',
          ),
        ]);
      }

      setState(() => _nearbyPois = pois);
    } catch (e) {
      // Add fallback test POIs on error
      if (_currentPosition != null) {
        setState(() {
          _nearbyPois = [
            ArPoi(
              id: 'fallback_1',
              name: 'Demo Point',
              type: 'landmark',
              latitude: _currentPosition!.latitude + 0.0005,
              longitude: _currentPosition!.longitude + 0.0005,
              description: 'Demo AR marker',
            ),
          ];
        });
      }
    }
  }

  // Calculate bearing from current location to POI
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

  // Calculate distance in meters
  double _calculateDistance(double lat2, double lon2) {
    if (_currentPosition == null) return 0;

    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      lat2,
      lon2,
    );
  }

  // Check if POI is in camera view
  bool _isPoiInView(ArPoi poi) {
    final bearing = _calculateBearing(poi.latitude, poi.longitude);
    final relativeBearing = (bearing - _deviceHeading + 360) % 360;

    // FOV is typically ~60 degrees horizontally, check if within ±45 degrees
    // Also check vertical FOV based on pitch
    final horizontalInView = relativeBearing < 45 || relativeBearing > 315;

    // Vertical check: if device tilted down, only show closer POIs
    // if tilted up, show all
    final distance = _calculateDistance(poi.latitude, poi.longitude);
    final verticalInView = _devicePitch > -30 || distance < 500;

    return horizontalInView && verticalInView;
  }

  // Calculate screen position for POI overlay with pitch compensation
  Offset _getPoiScreenPosition(ArPoi poi, Size screenSize) {
    final bearing = _calculateBearing(poi.latitude, poi.longitude);
    final relativeBearing = (bearing - _deviceHeading + 360) % 360;

    // Map relative bearing to horizontal screen position
    // -45° to +45° maps to 0 to screenWidth
    final normalizedBearing =
        (relativeBearing > 180) ? relativeBearing - 360 : relativeBearing;

    final x =
        screenSize.width / 2 + (normalizedBearing * screenSize.width / 90);

    // Vertical position based on distance AND pitch
    final distance = _calculateDistance(poi.latitude, poi.longitude);

    // Base Y position in center
    double y = screenSize.height * 0.5;

    // Adjust for distance (closer = lower on screen)
    y += (200 - distance.clamp(0, 200)) * 0.5;

    // Adjust for device pitch (tilting up = POIs move down)
    y -= _devicePitch * 3;

    return Offset(x.clamp(0, screenSize.width),
        y.clamp(screenSize.height * 0.2, screenSize.height * 0.8));
  }

  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.isEnabled(AppFeature.arScanner)) {
      return const PlatformUnavailableScreen(
        title: 'AR Trail Scanner',
        message:
            'This feature needs native camera + sensor access and is available on Android and iOS app builds.',
        icon: Icons.camera,
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.3),
        elevation: 0,
        title: const Text('AR Trail Scanner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showArInfo,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNearbyPois,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              fit: StackFit.expand,
              children: [
                // Camera preview
                if (_cameraReady && _cameraController != null)
                  CameraPreview(_cameraController!)
                else
                  Container(color: Colors.black),

                // AR overlay
                if (_currentPosition != null) _buildArOverlay(),

                // Debug overlay
                if (_debugMode) _buildDebugOverlay(),

                // Status bar at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildStatusBar(),
                ),
              ],
            ),
    );
  }

  Widget _buildArOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = Size(constraints.maxWidth, constraints.maxHeight);

        return Stack(
          children: _nearbyPois.where(_isPoiInView).map((poi) {
            final position = _getPoiScreenPosition(poi, screenSize);
            final distance = _calculateDistance(poi.latitude, poi.longitude);

            return Positioned(
              left: position.dx - 50,
              top: position.dy - 100,
              child: _buildPoiMarker(poi, distance),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPoiMarker(ArPoi poi, double distanceMeters) {
    return GestureDetector(
      onTap: () => _showPoiDetails(poi, distanceMeters),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _getPoiColor(poi.type), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              poi.getIcon(),
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 4),
            Text(
              poi.name.length > 15
                  ? '${poi.name.substring(0, 12)}...'
                  : poi.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
            const SizedBox(height: 2),
            Text(
              _formatDistance(distanceMeters),
              style: TextStyle(
                color: _getPoiColor(poi.type),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugOverlay() {
    return Positioned(
      top: 100,
      left: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DEBUG INFO',
              style: const TextStyle(
                color: Colors.yellow,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Heading: ${_deviceHeading.toStringAsFixed(1)}°',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            Text(
              'Pitch: ${_devicePitch.toStringAsFixed(1)}°',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            Text(
              'Roll: ${_deviceRoll.toStringAsFixed(1)}°',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            Text(
              'POIs: ${_nearbyPois.length} total',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            Text(
              'Visible: ${_nearbyPois.where(_isPoiInView).length}',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            if (_currentPosition != null)
              Text(
                'GPS: ${_currentPosition!.latitude.toStringAsFixed(5)}, ${_currentPosition!.longitude.toStringAsFixed(5)}',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatusItem(
              Icons.explore, '${_deviceHeading.toStringAsFixed(0)}°'),
          _buildStatusItem(Icons.pin_drop, '${_nearbyPois.length} POIs'),
          _buildStatusItem(
            Icons.my_location,
            _currentPosition != null ? 'GPS Active' : 'No GPS',
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getPoiColor(String type) {
    switch (type) {
      case 'water':
        return Colors.blue;
      case 'shelter':
        return Colors.orange;
      case 'landmark':
        return Colors.purple;
      case 'hazard':
        return Colors.red;
      case 'cultural':
        return Colors.amber;
      default:
        return Colors.green;
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)}m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
  }

  void _showPoiDetails(ArPoi poi, double distance) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(poi.getIcon(), style: const TextStyle(fontSize: 48)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        poi.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        poi.getTypeLabel(),
                        style: TextStyle(
                          color: _getPoiColor(poi.type),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
                Icons.straighten, 'Distance', _formatDistance(distance)),
            _buildDetailRow(
              Icons.explore,
              'Bearing',
              '${_calculateBearing(poi.latitude, poi.longitude).toStringAsFixed(0)}°',
            ),
            if (poi.elevation != null)
              _buildDetailRow(Icons.terrain, 'Elevation',
                  '${poi.elevation!.toStringAsFixed(0)}m'),
            const SizedBox(height: 16),
            Text(
              poi.description,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('Open in Map'),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(this.context).push(
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
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  void _showArInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AR Trail Scanner'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎯 How to Use:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Point your camera at the landscape'),
            Text('• Look around to discover nearby POIs'),
            Text('• Tap markers for detailed information'),
            Text('• Works offline with cached data'),
            SizedBox(height: 16),
            Text(
              '💧 Blue: Water sources',
              style: TextStyle(color: Colors.blue),
            ),
            Text(
              '🏕️ Orange: Shelters',
              style: TextStyle(color: Colors.orange),
            ),
            Text(
              '⚠️ Red: Hazards',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
