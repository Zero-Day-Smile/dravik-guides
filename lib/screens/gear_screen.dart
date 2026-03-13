import 'package:flutter/material.dart';
import 'package:dravik/models/gear.dart';
import 'package:dravik/services/gear_service.dart';
import 'package:dravik/widgets/edition_banner_for_screen.dart';
import 'package:dravik/config/edition_copy.dart';

class GearScreen extends StatefulWidget {
  const GearScreen({super.key});

  @override
  State<GearScreen> createState() => _GearScreenState();
}

class _GearScreenState extends State<GearScreen> {
  final GearService _gearService = GearService();
  List<GearChecklist> _checklists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChecklists();
  }

  Future<void> _loadChecklists() async {
    setState(() => _isLoading = true);
    _checklists = await _gearService.getAllChecklists();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Widget content = _isLoading
      ? const Center(child: CircularProgressIndicator())
      : _checklists.isEmpty
        ? _buildEmptyState(isDark)
        : _buildChecklistGrid(isDark);

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      appBar: AppBar(
        title: const Text('Gear Checklists'),
        backgroundColor: Colors.green[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateChecklistDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          const EditionBannerForScreen(screen: EditionScreen.gear),
          Expanded(child: content),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAIChecklistDialog,
        backgroundColor: Colors.green,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('AI Generate'),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.backpack_outlined,
            size: 100,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Gear Checklists Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first checklist or use AI to generate one',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAIChecklistDialog,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Generate with AI'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistGrid(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _checklists.length,
      itemBuilder: (context, index) {
        final checklist = _checklists[index];
        final completion = checklist.completionPercentage;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () => _openChecklist(checklist),
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
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getTripTypeIcon(checklist.tripType),
                          color: Colors.green.shade700,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              checklist.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${checklist.items.length} items • ${(checklist.totalWeight / 1000).toStringAsFixed(1)} kg',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                            value: 'duplicate',
                            child: Row(
                              children: [
                                Icon(Icons.copy),
                                SizedBox(width: 8),
                                Text('Duplicate'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete',
                                    style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) =>
                            _handleChecklistAction(value.toString(), checklist),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        label: Text(checklist.terrain),
                        backgroundColor: Colors.orange.shade100,
                        labelStyle: TextStyle(
                            color: Colors.orange.shade900, fontSize: 12),
                      ),
                      Chip(
                        label: Text('${checklist.durationDays} days'),
                        backgroundColor: Colors.blue.shade100,
                        labelStyle: TextStyle(
                            color: Colors.blue.shade900, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: completion / 100,
                          backgroundColor: Colors.grey.shade300,
                          color:
                              completion == 100 ? Colors.green : Colors.orange,
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${completion.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              completion == 100 ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
        // TODO: Implement duplicate
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Checklist'),
            content: Text('Delete "${checklist.name}"?'),
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
          title: const Text('Create Checklist'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
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
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Terrain',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => terrain = value,
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Duration (days)',
                    border: OutlineInputBorder(),
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
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;
                await _gearService.createChecklistFromTemplate(
                  'himalaya_7day',
                  nameController.text,
                  selectedType,
                  terrain,
                  duration,
                );
                if (mounted) {
                  final navigator = Navigator.of(context);
                  navigator.pop();
                }
                _loadChecklists();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Create'),
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
          title: const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.green),
              SizedBox(width: 8),
              Text('AI Checklist Generator'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: destController,
                  decoration: const InputDecoration(
                    labelText: 'Destination',
                    hintText: 'e.g., Everest Base Camp',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Terrain',
                    hintText: 'e.g., Snow, Mountain, Desert',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => terrain = value,
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Duration (days)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => duration = int.tryParse(value) ?? 7,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TripType>(
                  initialValue: tripType,
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
                      setDialogState(() => tripType = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Group Size',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => groupSize = int.tryParse(value) ?? 1,
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Vegan-friendly'),
                  value: isVegan,
                  onChanged: (value) {
                    setDialogState(() => isVegan = value ?? false);
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
            ElevatedButton.icon(
              onPressed: () async {
                if (destController.text.isEmpty) return;
                if (!mounted) return;
                Navigator.pop(context);

                // Show loading
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
                            Text('Generating AI checklist...'),
                          ],
                        ),
                      ),
                    ),
                  ),
                );

                await _gearService.generateAIChecklist(
                  destination: destController.text,
                  terrain: terrain,
                  durationDays: duration,
                  tripType: tripType,
                  groupSize: groupSize,
                  isVegan: isVegan,
                );

                if (mounted) {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  navigator.pop();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('✨ AI Checklist generated!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = GearCategory.values;
    final completion = _checklist.completionPercentage;

    return Scaffold(
      appBar: AppBar(
        title: Text(_checklist.name),
        backgroundColor: Colors.green[900],
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
            padding: const EdgeInsets.all(16),
            color: isDark ? Colors.grey[850] : Colors.green.shade50,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(
                        'Items', '${_checklist.items.length}', Icons.check_box),
                    _buildStatCard(
                        'Weight',
                        '${(_checklist.totalWeight / 1000).toStringAsFixed(1)} kg',
                        Icons.scale),
                    _buildStatCard(
                        'Duration',
                        '${_checklist.durationDays} days',
                        Icons.calendar_today),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: completion / 100,
                        backgroundColor: Colors.grey.shade300,
                        color: completion == 100 ? Colors.green : Colors.orange,
                        minHeight: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${completion.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: completion == 100 ? Colors.green : Colors.orange,
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

                return ExpansionTile(
                  title: Text(
                    category.toString().split('.').last,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${items.length} items'),
                  leading:
                      Icon(_getCategoryIcon(category), color: Colors.green),
                  children: items.map((item) {
                    return CheckboxListTile(
                      value: item.isChecked,
                      onChanged: (checked) async {
                        await _gearService.toggleItemChecked(
                            _checklist.id, item.id);
                        final updated =
                            await _gearService.getChecklistById(_checklist.id);
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
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '${item.weight}g${item.quantity > 1 ? ' × ${item.quantity}' : ''}'),
                          if (item.notes.isNotEmpty)
                            Text(item.notes,
                                style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      secondary: item.isEssential
                          ? const Icon(Icons.priority_high, color: Colors.red)
                          : null,
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.green),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
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
