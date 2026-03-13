import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:dravik/services/group_sync_service.dart';
import 'package:dravik/models/sync_member.dart';
import 'dart:math' show cos, sqrt, asin;
import 'package:dravik/config/feature_flags.dart';
import 'package:dravik/widgets/platform_unavailable_screen.dart';

class GroupSyncScreen extends StatefulWidget {
  const GroupSyncScreen({super.key});

  @override
  State<GroupSyncScreen> createState() => _GroupSyncScreenState();
}

class _GroupSyncScreenState extends State<GroupSyncScreen> {
  final GroupSyncService _syncService = GroupSyncService();
  List<SyncMember> _members = [];
  bool _isActive = false;
  bool _isLoading = false;
  Position? _myPosition;
  StreamSubscription<List<SyncMember>>? _membersSub;
  StreamSubscription<Position>? _positionSub;

  @override
  void initState() {
    super.initState();
    _initializeSync();
  }

  Future<void> _initializeSync() async {
    await _syncService.initialize('Explorer');

    // Listen to members stream
    _membersSub = _syncService.membersStream.listen((members) {
      if (mounted) {
        setState(() {
          _members = members;
        });
      }
    });

    // Get my location
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 10,
      ),
    ).listen((position) {
      if (mounted) {
        setState(() {
          _myPosition = position;
        });
      }
    });
  }

  Future<void> _toggleSync() async {
    if (_isActive) {
      await _syncService.stopGroupSync();
      if (mounted) {
        setState(() {
          _isActive = false;
          _members = [];
        });
      }
    } else {
      setState(() {
        _isLoading = true;
      });

      final success = await _syncService.startGroupSync();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isActive = success;
        });

        if (!success) {
          if (mounted) {
            final messenger = ScaffoldMessenger.of(context);
            messenger.showSnackBar(
              const SnackBar(
                content: Text(
                    'Failed to start group sync. Enable Bluetooth and location.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  String _formatDistance(double km) {
    if (km < 1) {
      return '${(km * 1000).toInt()}m';
    }
    return '${km.toStringAsFixed(1)}km';
  }

  Widget _buildMemberCard(SyncMember member) {
    String? distanceText;
    if (_myPosition != null &&
        member.latitude != null &&
        member.longitude != null) {
      final distance = _calculateDistance(
        _myPosition!.latitude,
        _myPosition!.longitude,
        member.latitude!,
        member.longitude!,
      );
      distanceText = _formatDistance(distance);
    }

    final timeSinceUpdate = DateTime.now().difference(member.lastUpdate);
    final isStale = timeSinceUpdate.inMinutes > 5;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: member.needsAlert() ? 6 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: member.needsAlert() ? Colors.red : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      member.isConnected ? Colors.green : Colors.grey,
                  child: Text(
                    member.name[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isStale
                            ? 'Last seen ${timeSinceUpdate.inMinutes}m ago'
                            : member.statusMessage ?? 'Active',
                        style: TextStyle(
                          fontSize: 14,
                          color: isStale ? Colors.orange : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (distanceText != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      distanceText,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            member.getBatteryIcon(),
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${member.batteryLevel}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: member.batteryLevel < 20
                                  ? Colors.red
                                  : Colors.black,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            member.getBatteryStatus(),
                            style: TextStyle(
                              color: member.batteryLevel < 20
                                  ? Colors.red
                                  : Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: member.batteryLevel / 100,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            member.batteryLevel >= 50
                                ? Colors.green
                                : member.batteryLevel >= 20
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (member.needsAlert())
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        member.batteryLevel < 15
                            ? 'Critical battery level!'
                            : 'No update for ${timeSinceUpdate.inMinutes} minutes',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
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
  }

  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.isEnabled(AppFeature.groupSync)) {
      return const PlatformUnavailableScreen(
        title: 'Group Sync',
        message:
            'Live group sync depends on mobile device radios and location streams. Use Android/iOS app for this feature.',
        icon: Icons.people,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Sync'),
        actions: [
          if (_isActive)
            IconButton(
              icon: const Icon(Icons.sos),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Send SOS Alert?'),
                    content: const Text(
                      'This will alert all group members of an emergency.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Send SOS'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await _syncService.sendSosAlert();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('SOS alert sent to group'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: _isActive ? Colors.green[50] : Colors.grey[100],
            child: Row(
              children: [
                Icon(
                  _isActive
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth_disabled,
                  color: _isActive ? Colors.green : Colors.grey,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isActive ? 'Group Sync Active' : 'Group Sync Inactive',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _isActive
                            ? '${_members.length} member(s) connected'
                            : 'Start sync to connect with nearby members',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: _toggleSync,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isActive ? Colors.red : Colors.green,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: Text(_isActive ? 'Stop' : 'Start'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _members.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.group_off,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isActive
                              ? 'Searching for members...'
                              : 'No members connected',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (_isActive) ...[
                          const SizedBox(height: 16),
                          const CircularProgressIndicator(),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _members.length,
                    itemBuilder: (context, index) =>
                        _buildMemberCard(_members[index]),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _membersSub?.cancel();
    _positionSub?.cancel();
    super.dispose();
  }
}
