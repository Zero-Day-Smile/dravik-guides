import 'package:flutter/material.dart';
import 'package:dravik/models/trip.dart';
import 'package:dravik/services/trip_planner_service.dart';
import 'package:dravik/services/trip_safety_analyzer.dart';
import 'package:intl/intl.dart';
import 'package:dravik/widgets/edition_banner_for_screen.dart';
import 'package:dravik/config/edition_copy.dart';

class TripPlannerScreen extends StatefulWidget {
  const TripPlannerScreen({super.key});

  @override
  State<TripPlannerScreen> createState() => _TripPlannerScreenState();
}

class _TripPlannerScreenState extends State<TripPlannerScreen>
    with SingleTickerProviderStateMixin {
  final TripPlannerService _tripService = TripPlannerService();
  late TabController _tabController;
  List<Trip> _allTrips = [];
  List<Trip> _filteredTrips = [];
  TripStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadTrips();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    switch (_tabController.index) {
      case 0:
        _filterStatus = null;
        break;
      case 1:
        _filterStatus = TripStatus.planning;
        break;
      case 2:
        _filterStatus = TripStatus.upcoming;
        break;
      case 3:
        _filterStatus = TripStatus.active;
        break;
    }
    _filterTrips();
  }

  void _filterTrips() {
    setState(() {
      if (_filterStatus == null) {
        _filteredTrips = _allTrips;
      } else {
        _filteredTrips =
            _allTrips.where((t) => t.status == _filterStatus).toList();
      }
    });
  }

  Future<void> _loadTrips() async {
    _allTrips = await _tripService.getAllTrips();
    _filterTrips();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      appBar: AppBar(
        title: const Text('Trip Planner'),
        backgroundColor: Colors.green[900],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Planning'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Active'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTripTab(isDark),
          _buildTripTab(isDark),
          _buildTripTab(isDark),
          _buildTripTab(isDark),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTripDialog,
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add),
        label: const Text('New Trip'),
      ),
    );
  }

  Widget _buildTripTab(bool isDark) {
    return Column(
      children: [
        const EditionBannerForScreen(screen: EditionScreen.tripPlanner),
        Expanded(child: _buildTripList(isDark)),
      ],
    );
  }

  Widget _buildTripList(bool isDark) {
    if (_filteredTrips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 100,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Trips Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first trip to start planning',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredTrips.length,
      itemBuilder: (context, index) {
        final trip = _filteredTrips[index];
        return _buildTripCard(trip, isDark);
      },
    );
  }

  Widget _buildTripCard(Trip trip, bool isDark) {
    final daysUntil = trip.startDate.difference(DateTime.now()).inDays;
    final duration = trip.endDate.difference(trip.startDate).inDays + 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _openTripDetail(trip),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          _getStatusColor(trip.status).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getTripTypeIcon(trip.type),
                      color: _getStatusColor(trip.status),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          trip.description,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(trip.status),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${DateFormat('MMM dd').format(trip.startDate)} - ${DateFormat('MMM dd, yyyy').format(trip.endDate)}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const Spacer(),
                  Text(
                    '$duration days',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              if (trip.status == TripStatus.upcoming && daysUntil >= 0) ...[
                const SizedBox(height: 8),
                FutureBuilder<TripSafetyScore>(
                  future: TripSafetyAnalyzer().analyzeTripSafety(trip),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox.shrink();
                    }
                    final score = snapshot.data!;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: score.getRatingColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(score.getEmoji(),
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 4),
                          Text(
                            '${score.safetyRating} (Risk: ${score.riskScore}%)',
                            style: TextStyle(
                              color: score.getRatingColor(),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time,
                          size: 16, color: Colors.orange.shade900),
                      const SizedBox(width: 4),
                      Text(
                        '$daysUntil days until trip',
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (trip.status == TripStatus.planning) ...[
                const SizedBox(height: 8),
                FutureBuilder<TripSafetyScore>(
                  future: TripSafetyAnalyzer().analyzeTripSafety(trip),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox.shrink();
                    }
                    final score = snapshot.data!;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: score.getRatingColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(score.getEmoji(),
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 4),
                          Text(
                            score.safetyRating,
                            style: TextStyle(
                              color: score.getRatingColor(),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
              if (trip.itinerary.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.route, size: 16, color: Colors.green.shade700),
                    const SizedBox(width: 4),
                    Text(
                      '${trip.itinerary.length} days planned',
                      style:
                          TextStyle(color: Colors.green.shade700, fontSize: 12),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.terrain, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 4),
                    Text(
                      '${trip.estimatedDistance.toStringAsFixed(1)} km',
                      style:
                          TextStyle(color: Colors.blue.shade700, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(TripStatus status) {
    Color color = _getStatusColor(status);
    String label = status.toString().split('.').last;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label[0].toUpperCase() + label.substring(1),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _getStatusColor(TripStatus status) {
    switch (status) {
      case TripStatus.planning:
        return Colors.blue;
      case TripStatus.upcoming:
        return Colors.orange;
      case TripStatus.active:
        return Colors.green;
      case TripStatus.completed:
        return Colors.grey;
      case TripStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getTripTypeIcon(TripType type) {
    switch (type) {
      case TripType.hiking:
        return Icons.hiking;
      case TripType.trekking:
        return Icons.terrain;
      case TripType.camping:
        return Icons.cabin;
      case TripType.mountaineering:
        return Icons.landscape;
      case TripType.touring:
        return Icons.tour;
      case TripType.expedition:
        return Icons.explore;
    }
  }

  void _openTripDetail(Trip trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripDetailScreen(trip: trip),
      ),
    ).then((_) => _loadTrips());
  }

  void _showCreateTripDialog() {
    final nameController = TextEditingController();
    final destController = TextEditingController();
    TripType selectedType = TripType.trekking;
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create New Trip'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Trip Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: destController,
                  decoration: const InputDecoration(
                    labelText: 'Destination',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TripType>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Trip Type',
                    border: OutlineInputBorder(),
                  ),
                  items: TripType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.toString().split('.').last),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedType = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('Start Date'),
                  subtitle: Text(DateFormat('MMM dd, yyyy').format(startDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: startDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() => startDate = picked);
                    }
                  },
                ),
                ListTile(
                  title: const Text('End Date'),
                  subtitle: Text(DateFormat('MMM dd, yyyy').format(endDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: endDate,
                      firstDate: startDate,
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() => endDate = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    destController.text.isEmpty) {
                  return;
                }
                await _tripService.createTrip(
                  name: nameController.text,
                  description: destController.text,
                  type: selectedType,
                  startDate: startDate,
                  endDate: endDate,
                  countryCode: 'NP',
                );
                if (mounted) {
                  Navigator.pop(context);
                }
                _loadTrips();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

class TripDetailScreen extends StatefulWidget {
  final Trip trip;

  const TripDetailScreen({super.key, required this.trip});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  final TripPlannerService _tripService = TripPlannerService();
  late Trip _trip;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final duration = _trip.endDate.difference(_trip.startDate).inDays + 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(_trip.name),
        backgroundColor: Colors.green[900],
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'generate',
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome),
                    SizedBox(width: 8),
                    Text('AI Generate Itinerary'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) => _handleAction(value.toString()),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip Header
            Container(
              padding: const EdgeInsets.all(16),
              color: isDark ? Colors.grey[850] : Colors.green.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _trip.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${DateFormat('MMM dd').format(_trip.startDate)} - ${DateFormat('MMM dd, yyyy').format(_trip.endDate)}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '$duration days',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat(
                          'Distance',
                          '${_trip.estimatedDistance.toStringAsFixed(1)} km',
                          Icons.straighten),
                      _buildStat(
                          'Elevation',
                          '${_trip.estimatedElevation.toStringAsFixed(0)} m',
                          Icons.terrain),
                      _buildStat(
                          'Days', '${_trip.itinerary.length}', Icons.event),
                    ],
                  ),
                ],
              ),
            ),
            // Itinerary
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Itinerary',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (_trip.itinerary.isEmpty)
                        TextButton.icon(
                          onPressed: () => _handleAction('generate'),
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Generate with AI'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_trip.itinerary.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.route,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            'No itinerary yet',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _trip.itinerary.length,
                      itemBuilder: (context, index) {
                        final day = _trip.itinerary[index];
                        return _buildDayCard(day, index + 1);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.green),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildDayCard(TripDay day, int dayNumber) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green,
          child: Text(
            '$dayNumber',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          day.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(day.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.straighten, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${day.distanceKm.toStringAsFixed(1)} km',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 12),
                Icon(Icons.terrain, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${day.elevationGainM.toStringAsFixed(0)} m',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
        children: day.waypoints.map((waypoint) {
          return ListTile(
            leading: Icon(
              _getWaypointIcon(waypoint.type),
              color: Colors.green.shade700,
            ),
            title: Text(waypoint.name),
            subtitle: waypoint.notes.isNotEmpty ? Text(waypoint.notes) : null,
          );
        }).toList(),
      ),
    );
  }

  IconData _getWaypointIcon(WaypointType type) {
    switch (type) {
      case WaypointType.start:
        return Icons.play_arrow;
      case WaypointType.shelter:
        return Icons.flag;
      case WaypointType.camp:
        return Icons.cabin;
      case WaypointType.viewpoint:
        return Icons.landscape;
      case WaypointType.poi:
        return Icons.place;
      case WaypointType.emergency:
        return Icons.warning;
      case WaypointType.water:
        return Icons.water_drop;
      case WaypointType.food:
        return Icons.restaurant;
      case WaypointType.end:
        return Icons.stop;
    }
  }

  void _handleAction(String action) async {
    switch (action) {
      case 'edit':
        // TODO: Implement edit
        break;
      case 'generate':
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Generating AI itinerary...'),
                  ],
                ),
              ),
            ),
          ),
        );

        await _tripService.generateAIItinerary(
          destination: _trip.name,
          type: _trip.type,
          startDate: _trip.startDate,
          durationDays: _trip.endDate.difference(_trip.startDate).inDays + 1,
          dailyDistanceKm: 15.0,
          countryCode: _trip.countryCode,
        );
        final updated = await _tripService.getTripById(_trip.id);
        if (mounted) {
          Navigator.pop(context);
          if (updated != null) {
            setState(() => _trip = updated);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✨ AI Itinerary generated!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Trip'),
            content: Text('Delete "${_trip.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await _tripService.deleteTrip(_trip.id);
          if (mounted) Navigator.pop(context);
        }
        break;
    }
  }
}
