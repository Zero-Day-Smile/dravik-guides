import 'package:flutter/material.dart';
import 'package:dravik/models/gear.dart';
import 'package:dravik/services/gear_service.dart';
import 'package:dravik/theme_provider.dart';
import 'package:dravik/widgets/edition_banner_for_screen.dart';
import 'package:dravik/config/edition_copy.dart';

class GearScreen extends StatefulWidget {
  const GearScreen({super.key});

  @override
  State<GearScreen> createState() => _GearScreenState();
}

class _GearScreenState extends State<GearScreen>
    with SingleTickerProviderStateMixin {
  final GearService _gearService = GearService();
  List<GearChecklist> _checklists = [];
  bool _isLoading = true;
  String _viewMode = 'grid'; // grid or list
  String _sortBy = 'name'; // name, date, completion
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadChecklists();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChecklists() async {
    setState(() => _isLoading = true);
    _checklists = await _gearService.getAllChecklists();
    _sortChecklists();
    setState(() => _isLoading = false);
  }

  void _sortChecklists() {
    switch (_sortBy) {
      case 'name':
        _checklists.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'date':
        _checklists.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'completion':
        _checklists.sort(
            (a, b) => b.completionPercentage.compareTo(a.completionPercentage));
        break;
    }
  }

  List<GearChecklist> get _activeChecklists =>
      _checklists.where((c) => c.completionPercentage < 100).toList();
  List<GearChecklist> get _completedChecklists =>
      _checklists.where((c) => c.completionPercentage == 100).toList();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (context, isDark, _) {
        return Scaffold(
          backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 200,
                  floating: false,
                  pinned: true,
                  backgroundColor:
                      isDark ? Colors.grey[850] : Colors.green[700],
                  flexibleSpace: FlexibleSpaceBar(
                    title: const Text('Gear Manager',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [Colors.grey[850]!, Colors.grey[900]!]
                              : [Colors.green[700]!, Colors.green[900]!],
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -30,
                            top: -30,
                            child: Icon(Icons.backpack,
                                size: 200,
                                color: Colors.white.withOpacity(0.1)),
                          ),
                          Positioned(
                            left: 16,
                            bottom: 60,
                            child: _buildQuickStats(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(
                          _viewMode == 'grid' ? Icons.list : Icons.grid_view),
                      onPressed: () {
                        setState(() {
                          _viewMode = _viewMode == 'grid' ? 'list' : 'grid';
                        });
                      },
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.sort),
                      onSelected: (value) {
                        setState(() {
                          _sortBy = value;
                          _sortChecklists();
                        });
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                            value: 'name', child: Text('Sort by Name')),
                        const PopupMenuItem(
                            value: 'date', child: Text('Sort by Date')),
                        const PopupMenuItem(
                            value: 'completion',
                            child: Text('Sort by Completion')),
                      ],
                    ),
                  ],
                  bottom: TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    tabs: [
                      Tab(text: 'All (${_checklists.length})'),
                      Tab(text: 'Active (${_activeChecklists.length})'),
                      Tab(text: 'Done (${_completedChecklists.length})'),
                    ],
                  ),
                ),
              ];
            },
            body: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      const EditionBannerForScreen(screen: EditionScreen.gearNew),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildChecklistView(_checklists, isDark),
                            _buildChecklistView(_activeChecklists, isDark),
                            _buildChecklistView(_completedChecklists, isDark),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                heroTag: 'ai',
                onPressed: _showAIChecklistDialog,
                backgroundColor: Colors.purple,
                child: const Icon(Icons.auto_awesome),
              ),
              const SizedBox(height: 12),
              FloatingActionButton(
                heroTag: 'add',
                onPressed: _showCreateChecklistDialog,
                backgroundColor: Colors.green,
                child: const Icon(Icons.add),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickStats() {
    final totalItems =
        _checklists.fold<int>(0, (sum, c) => sum + c.items.length);
    final totalWeight =
        _checklists.fold<double>(0, (sum, c) => sum + c.totalWeight) / 1000;
    final avgCompletion = _checklists.isEmpty
        ? 0.0
        : _checklists.fold<double>(
                0, (sum, c) => sum + c.completionPercentage) /
            _checklists.length;

    return Row(
      children: [
        _buildMiniStat(totalItems.toString(), 'Items', Icons.checklist),
        const SizedBox(width: 16),
        _buildMiniStat(
            '${totalWeight.toStringAsFixed(1)}kg', 'Weight', Icons.scale),
        const SizedBox(width: 16),
        _buildMiniStat(
            '${avgCompletion.toStringAsFixed(0)}%', 'Avg', Icons.pie_chart),
      ],
    );
  }

  Widget _buildMiniStat(String value, String label, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  Widget _buildChecklistView(List<GearChecklist> checklists, bool isDark) {
    if (checklists.isEmpty) {
      return _buildEmptyState(isDark);
    }

    if (_viewMode == 'grid') {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: checklists.length,
        itemBuilder: (context, index) =>
            _buildGridCard(checklists[index], isDark),
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: checklists.length,
        itemBuilder: (context, index) =>
            _buildListCard(checklists[index], isDark),
      );
    }
  }

  Widget _buildGridCard(GearChecklist checklist, bool isDark) {
    final completion = checklist.completionPercentage;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _openChecklist(checklist),
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _getGradientColors(checklist.tripType),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Center(
                    child: Icon(_getTripTypeIcon(checklist.tripType),
                        size: 50, color: Colors.white),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          checklist.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${checklist.items.length} items • ${(checklist.totalWeight / 1000).toStringAsFixed(1)}kg',
                          style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black54,
                              fontSize: 11),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: completion / 100,
                                backgroundColor: Colors.grey[300],
                                color: completion == 100
                                    ? Colors.green
                                    : Colors.orange,
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text('${completion.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 8,
              right: 8,
              child: PopupMenuButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(
                      value: 'duplicate', child: Text('Duplicate')),
                  const PopupMenuItem(
                      value: 'delete',
                      child:
                          Text('Delete', style: TextStyle(color: Colors.red))),
                ],
                onSelected: (value) =>
                    _handleChecklistAction(value.toString(), checklist),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListCard(GearChecklist checklist, bool isDark) {
    final completion = checklist.completionPercentage;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openChecklist(checklist),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _getGradientColors(checklist.tripType),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_getTripTypeIcon(checklist.tripType),
                    color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(checklist.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      '${checklist.items.length} items • ${(checklist.totalWeight / 1000).toStringAsFixed(1)}kg • ${checklist.terrain}',
                      style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: completion / 100,
                            backgroundColor: Colors.grey[300],
                            color: completion == 100
                                ? Colors.green
                                : Colors.orange,
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${completion.toStringAsFixed(0)}%',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(
                      value: 'duplicate', child: Text('Duplicate')),
                  const PopupMenuItem(
                      value: 'delete',
                      child:
                          Text('Delete', style: TextStyle(color: Colors.red))),
                ],
                onSelected: (value) =>
                    _handleChecklistAction(value.toString(), checklist),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.green[50],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.backpack_outlined,
                size: 80, color: Colors.green[300]),
          ),
          const SizedBox(height: 24),
          const Text('No Checklists Yet',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Create your first gear checklist',
              style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 16)),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _showCreateChecklistDialog,
                icon: const Icon(Icons.add),
                label: const Text('Create Manual'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _showAIChecklistDialog,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('AI Generate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Color> _getGradientColors(TripType type) {
    switch (type) {
      case TripType.hiking:
        return [Colors.green[600]!, Colors.green[800]!];
      case TripType.trekking:
        return [Colors.blue[600]!, Colors.blue[800]!];
      case TripType.camping:
        return [Colors.orange[600]!, Colors.orange[800]!];
      case TripType.mountaineering:
        return [Colors.purple[600]!, Colors.purple[800]!];
      case TripType.touring:
        return [Colors.teal[600]!, Colors.teal[800]!];
      case TripType.expedition:
        return [Colors.red[600]!, Colors.red[800]!];
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

  void _handleChecklistAction(String action, GearChecklist checklist) async {
    switch (action) {
      case 'edit':
        _openChecklist(checklist);
        break;
      case 'duplicate':
        // Duplicate checklist
        final newChecklist = GearChecklist(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: '${checklist.name} (Copy)',
          description: checklist.description,
          tripType: checklist.tripType,
          terrain: checklist.terrain,
          durationDays: checklist.durationDays,
          items: checklist.items
              .map((item) => GearItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString() +
                        item.id,
                    name: item.name,
                    category: item.category,
                    weight: item.weight,
                    quantity: item.quantity,
                    isEssential: item.isEssential,
                    notes: item.notes,
                    isChecked: false,
                  ))
              .toList(),
          totalWeight: checklist.totalWeight,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _gearService.saveChecklist(newChecklist);
        _loadChecklists();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Checklist duplicated')),
          );
        }
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Checklist'),
            content: Text('Delete "${checklist.name}"? This cannot be undone.'),
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
          await _gearService.deleteChecklist(checklist.id);
          _loadChecklists();
        }
        break;
    }
  }

  void _openChecklist(GearChecklist checklist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChecklistDetailScreen(checklist: checklist),
      ),
    ).then((_) => _loadChecklists());
  }

  void _showCreateChecklistDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    TripType selectedType = TripType.hiking;
    String terrain = 'Mountain';
    int duration = 7;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.add_circle_outline, color: Colors.green),
              SizedBox(width: 8),
              Text('Create Checklist'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Checklist Name',
                    hintText: 'e.g., Everest Base Camp Trek',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.description),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TripType>(
                  initialValue: selectedType,
                  decoration: InputDecoration(
                    labelText: 'Trip Type',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.category),
                  ),
                  items: TripType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          Icon(_getTripTypeIcon(type), size: 20),
                          const SizedBox(width: 8),
                          Text(type.toString().split('.').last),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedType = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: terrain,
                  decoration: InputDecoration(
                    labelText: 'Terrain',
                    hintText: 'e.g., Mountain, Desert, Snow',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.terrain),
                  ),
                  onChanged: (value) => terrain = value,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: duration.toString(),
                  decoration: InputDecoration(
                    labelText: 'Duration (days)',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.calendar_today),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => duration = int.tryParse(value) ?? 7,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a name')),
                  );
                  return;
                }
                await _gearService.createChecklistFromTemplate(
                  'himalaya_7day',
                  nameController.text.trim(),
                  selectedType,
                  terrain,
                  duration,
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('✓ Checklist created'),
                        backgroundColor: Colors.green),
                  );
                }
                _loadChecklists();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              icon: const Icon(Icons.check),
              label: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAIChecklistDialog() {
    final destController = TextEditingController();
    String terrain = 'Mountain';
    int duration = 7;
    TripType tripType = TripType.trekking;
    int groupSize = 1;
    bool isVegan = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.purple, Colors.deepPurple],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Text('AI Checklist Generator'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: destController,
                  decoration: InputDecoration(
                    labelText: 'Destination',
                    hintText: 'e.g., Everest Base Camp',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: terrain,
                  decoration: InputDecoration(
                    labelText: 'Terrain',
                    hintText: 'e.g., Snow, Mountain, Desert',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.terrain),
                  ),
                  onChanged: (value) => terrain = value,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: duration.toString(),
                        decoration: InputDecoration(
                          labelText: 'Days',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.calendar_today),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) =>
                            duration = int.tryParse(value) ?? 7,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: groupSize.toString(),
                        decoration: InputDecoration(
                          labelText: 'People',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.group),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) =>
                            groupSize = int.tryParse(value) ?? 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TripType>(
                  initialValue: tripType,
                  decoration: InputDecoration(
                    labelText: 'Trip Type',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.category),
                  ),
                  items: TripType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          Icon(_getTripTypeIcon(type), size: 20),
                          const SizedBox(width: 8),
                          Text(type.toString().split('.').last),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => tripType = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Vegan-friendly'),
                  subtitle: const Text('Plant-based food options'),
                  value: isVegan,
                  onChanged: (value) {
                    setDialogState(() => isVegan = value ?? false);
                  },
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey[300]!)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (destController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a destination')),
                  );
                  return;
                }
                Navigator.pop(context);

                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => Center(
                    child: Card(
                      margin: const EdgeInsets.all(24),
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                                color: Colors.purple),
                            const SizedBox(height: 20),
                            const Text('✨ AI is creating your checklist...',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(
                              'Analyzing ${destController.text}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );

                await _gearService.generateAIChecklist(
                  destination: destController.text.trim(),
                  terrain: terrain,
                  durationDays: duration,
                  tripType: tripType,
                  groupSize: groupSize,
                  isVegan: isVegan,
                );

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✨ AI Checklist generated successfully!'),
                      backgroundColor: Colors.purple,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  _loadChecklists();
                }
              },
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Checklist detail screen remains the same, just import it
class ChecklistDetailScreen extends StatefulWidget {
  final GearChecklist checklist;

  const ChecklistDetailScreen({super.key, required this.checklist});

  @override
  State<ChecklistDetailScreen> createState() => _ChecklistDetailScreenState();
}

class _ChecklistDetailScreenState extends State<ChecklistDetailScreen> {
  final GearService _gearService = GearService();
  late GearChecklist _checklist;

  @override
  void initState() {
    super.initState();
    _checklist = widget.checklist;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (context, isDark, _) {
        final categories = GearCategory.values;
        final completion = _checklist.completionPercentage;

        return Scaffold(
          appBar: AppBar(
            title: Text(_checklist.name),
            backgroundColor: isDark ? Colors.grey[850] : Colors.green[700],
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  // TODO: Share checklist
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Header Stats
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [Colors.grey[850]!, Colors.grey[900]!]
                        : [Colors.green[50]!, Colors.green[100]!],
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard(
                          '${_checklist.items.length}',
                          'Items',
                          Icons.check_box,
                          Colors.blue,
                        ),
                        _buildStatCard(
                          '${(_checklist.totalWeight / 1000).toStringAsFixed(1)}kg',
                          'Weight',
                          Icons.scale,
                          Colors.orange,
                        ),
                        _buildStatCard(
                          '${_checklist.durationDays}d',
                          'Duration',
                          Icons.calendar_today,
                          Colors.purple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 16,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[300],
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: completion / 100,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  gradient: LinearGradient(
                                    colors: completion == 100
                                        ? [Colors.green, Colors.green[700]!]
                                        : [Colors.orange, Colors.orange[700]!],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: completion == 100
                                ? Colors.green
                                : Colors.orange,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${completion.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Items by Category
              Expanded(
                child: ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final items = _checklist.items
                        .where((i) => i.category == category)
                        .toList();

                    if (items.isEmpty) return const SizedBox.shrink();

                    final checkedCount = items.where((i) => i.isChecked).length;

                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ExpansionTile(
                        title: Text(
                          category.toString().split('.').last,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle:
                            Text('$checkedCount/${items.length} items checked'),
                        leading: CircleAvatar(
                          backgroundColor: Colors.green[100],
                          child: Icon(_getCategoryIcon(category),
                              color: Colors.green[700], size: 20),
                        ),
                        children: items.map((item) {
                          return CheckboxListTile(
                            value: item.isChecked,
                            onChanged: (checked) async {
                              await _gearService.toggleItemChecked(
                                  _checklist.id, item.id);
                              final updated = await _gearService
                                  .getChecklistById(_checklist.id);
                              if (updated != null) {
                                setState(() => _checklist = updated);
                              }
                            },
                            title: Text(
                              item.name,
                              style: TextStyle(
                                decoration: item.isChecked
                                    ? TextDecoration.lineThrough
                                    : null,
                                fontWeight: item.isEssential
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text('${item.weight}g'),
                                    if (item.quantity > 1)
                                      Text(' × ${item.quantity}'),
                                    if (item.isEssential) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.red[100],
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text('ESSENTIAL',
                                            style: TextStyle(
                                                fontSize: 9,
                                                color: Colors.red[900],
                                                fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ],
                                ),
                                if (item.notes.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(item.notes,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                            fontStyle: FontStyle.italic)),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
      String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  IconData _getCategoryIcon(GearCategory category) {
    switch (category) {
      case GearCategory.shelter:
        return Icons.cabin;
      case GearCategory.clothing:
        return Icons.checkroom;
      case GearCategory.navigation:
        return Icons.explore;
      case GearCategory.firstAid:
        return Icons.medical_services;
      case GearCategory.food:
        return Icons.restaurant;
      case GearCategory.water:
        return Icons.water_drop;
      case GearCategory.tools:
        return Icons.construction;
      case GearCategory.electronics:
        return Icons.devices;
      case GearCategory.personal:
        return Icons.person;
      case GearCategory.safety:
        return Icons.security;
      case GearCategory.other:
        return Icons.category;
    }
  }
}
