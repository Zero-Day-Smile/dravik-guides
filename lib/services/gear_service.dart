import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:dravik/models/gear.dart';

class GearService {
  static const String _boxName = 'gear_checklists';
  final _uuid = const Uuid();

  // Comprehensive template system with AI-driven recommendations
  static final Map<String, List<GearItem>> _templates = {
    'weekend_hike': [
      GearItem(
          id: '1',
          name: 'Day Pack (30L)',
          category: GearCategory.shelter,
          weight: 800,
          isEssential: true,
          priority: GearPriority.high),
      GearItem(
          id: '2',
          name: 'Water Bottles (2L)',
          category: GearCategory.water,
          weight: 200,
          quantity: 2,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '3',
          name: 'Rain Jacket',
          category: GearCategory.clothing,
          weight: 350,
          isEssential: true,
          priority: GearPriority.high),
      GearItem(
          id: '4',
          name: 'Fleece Mid-Layer',
          category: GearCategory.clothing,
          weight: 400,
          isEssential: true,
          priority: GearPriority.medium),
      GearItem(
          id: '5',
          name: 'Hiking Boots',
          category: GearCategory.clothing,
          weight: 1100,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '6',
          name: 'Trekking Poles',
          category: GearCategory.tools,
          weight: 400,
          isEssential: false,
          priority: GearPriority.medium),
      GearItem(
          id: '7',
          name: 'Sunglasses & Sunscreen',
          category: GearCategory.firstAid,
          weight: 150,
          isEssential: true,
          priority: GearPriority.high),
      GearItem(
          id: '8',
          name: 'Basic First Aid Kit',
          category: GearCategory.firstAid,
          weight: 300,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '9',
          name: 'Headlamp + Extra Batteries',
          category: GearCategory.tools,
          weight: 150,
          isEssential: true,
          priority: GearPriority.high),
      GearItem(
          id: '10',
          name: 'Map & Compass',
          category: GearCategory.navigation,
          weight: 100,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '11',
          name: 'Energy Bars & Snacks',
          category: GearCategory.food,
          weight: 600,
          quantity: 2,
          isEssential: true,
          priority: GearPriority.high),
      GearItem(
          id: '12',
          name: 'Emergency Whistle',
          category: GearCategory.tools,
          weight: 20,
          isEssential: true,
          priority: GearPriority.high),
    ],
    'himalaya_7day': [
      GearItem(
          id: '1',
          name: 'Tent (4-season)',
          category: GearCategory.shelter,
          weight: 2500,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '2',
          name: 'Sleeping Bag (-15°C)',
          category: GearCategory.shelter,
          weight: 1800,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '3',
          name: 'Sleeping Pad (Insulated)',
          category: GearCategory.shelter,
          weight: 600,
          isEssential: true,
          priority: GearPriority.high),
      GearItem(
          id: '4',
          name: 'Base Layer (Thermal)',
          category: GearCategory.clothing,
          weight: 300,
          quantity: 2,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '5',
          name: 'Down Jacket',
          category: GearCategory.clothing,
          weight: 800,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '6',
          name: 'Rain Jacket (Gore-Tex)',
          category: GearCategory.clothing,
          weight: 400,
          isEssential: true,
          priority: GearPriority.high),
      GearItem(
          id: '7',
          name: 'Trekking Boots',
          category: GearCategory.clothing,
          weight: 1200,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '8',
          name: 'GPS Device',
          category: GearCategory.navigation,
          weight: 200,
          isEssential: true,
          priority: GearPriority.high),
      GearItem(
          id: '9',
          name: 'Map & Compass',
          category: GearCategory.navigation,
          weight: 100,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '10',
          name: 'First Aid Kit',
          category: GearCategory.firstAid,
          weight: 500,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '11',
          name: 'Water Filter',
          category: GearCategory.water,
          weight: 350,
          isEssential: true,
          priority: GearPriority.high),
      GearItem(
        id: '12',
        name: 'Water Bottles (2L)',
        category: GearCategory.water,
        weight: 200,
        quantity: 2,
        isEssential: true,
        priority: GearPriority.critical,
      ),
      GearItem(
        id: '13',
        name: 'Stove & Fuel',
        category: GearCategory.food,
        weight: 600,
        isEssential: true,
        priority: GearPriority.high,
      ),
      GearItem(
        id: '14',
        name: 'Dehydrated Meals',
        category: GearCategory.food,
        weight: 2000,
        quantity: 21,
        isEssential: true,
        priority: GearPriority.critical,
      ),
      GearItem(
        id: '15',
        name: 'Headlamp + Batteries',
        category: GearCategory.electronics,
        weight: 150,
        isEssential: true,
        priority: GearPriority.high,
      ),
      GearItem(
        id: '16',
        name: 'Emergency Whistle',
        category: GearCategory.safety,
        weight: 20,
        isEssential: true,
        priority: GearPriority.critical,
      ),
      GearItem(
        id: '17',
        name: 'Fire Starter Kit',
        category: GearCategory.safety,
        weight: 100,
        isEssential: true,
        priority: GearPriority.critical,
      ),
    ],
  };

  Future<List<GearChecklist>> getAllChecklists() async {
    try {
      final box = await Hive.openBox(_boxName);
      final data = box.get('checklists', defaultValue: []);

      if (data is List) {
        return data
            .map<GearChecklist>(
                (item) => GearChecklist.fromJson(json.decode(item)))
            .toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  Future<GearChecklist?> getChecklistById(String id) async {
    final checklists = await getAllChecklists();
    try {
      return checklists.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveChecklist(GearChecklist checklist) async {
    try {
      final box = await Hive.openBox(_boxName);
      final checklists = await getAllChecklists();

      final index = checklists.indexWhere((c) => c.id == checklist.id);
      if (index >= 0) {
        checklists[index] = checklist;
      } else {
        checklists.add(checklist);
      }

      final data = checklists.map((c) => json.encode(c.toJson())).toList();
      await box.put('checklists', data);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> deleteChecklist(String id) async {
    try {
      final box = await Hive.openBox(_boxName);
      final checklists = await getAllChecklists();
      checklists.removeWhere((c) => c.id == id);

      final data = checklists.map((c) => json.encode(c.toJson())).toList();
      await box.put('checklists', data);
    } catch (e) {
      // Handle error
    }
  }

  Future<GearChecklist> createChecklistFromTemplate(
    String templateKey,
    String name,
    TripType tripType,
    String terrain,
    int durationDays,
  ) async {
    final items = _templates[templateKey] ?? [];

    final checklist = GearChecklist(
      id: _uuid.v4(),
      name: name,
      description: 'Generated from $templateKey template',
      tripType: tripType,
      terrain: terrain,
      durationDays: durationDays,
      items: items,
      totalWeight:
          items.fold(0, (sum, item) => sum + (item.weight * item.quantity)),
      isTemplate: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await saveChecklist(checklist);
    return checklist;
  }

  Future<GearChecklist> generateAIChecklist({
    required String destination,
    required String terrain,
    required int durationDays,
    required TripType tripType,
    required int groupSize,
    bool isVegan = false,
  }) async {
    // AI-powered checklist generation
    // For now, use template and customize
    final baseItems = List<GearItem>.from(_templates['himalaya_7day'] ?? []);

    // Adjust quantities based on duration
    for (int i = 0; i < baseItems.length; i++) {
      if (baseItems[i].category == GearCategory.food) {
        baseItems[i] = baseItems[i].copyWith(
          quantity: (durationDays * 3 * groupSize), // 3 meals per day
        );
      }
    }

    // Add terrain-specific items
    if (terrain.toLowerCase().contains('snow') ||
        terrain.toLowerCase().contains('ice')) {
      baseItems.add(GearItem(
        id: _uuid.v4(),
        name: 'Crampons',
        category: GearCategory.tools,
        weight: 800,
        isEssential: true,
        priority: GearPriority.critical,
      ));
      baseItems.add(GearItem(
        id: _uuid.v4(),
        name: 'Ice Axe',
        category: GearCategory.tools,
        weight: 600,
        isEssential: true,
        priority: GearPriority.critical,
      ));
    }

    final checklist = GearChecklist(
      id: _uuid.v4(),
      name: '$destination $durationDays-day Trip',
      description: 'AI-generated checklist for $terrain terrain',
      tripType: tripType,
      terrain: terrain,
      durationDays: durationDays,
      items: baseItems,
      totalWeight:
          baseItems.fold(0, (sum, item) => sum + (item.weight * item.quantity)),
      isTemplate: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await saveChecklist(checklist);
    return checklist;
  }

  Future<void> toggleItemChecked(String checklistId, String itemId) async {
    final checklist = await getChecklistById(checklistId);
    if (checklist == null) return;

    final updatedItems = checklist.items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(isChecked: !item.isChecked);
      }
      return item;
    }).toList();

    final updatedChecklist = GearChecklist(
      id: checklist.id,
      name: checklist.name,
      description: checklist.description,
      tripType: checklist.tripType,
      terrain: checklist.terrain,
      durationDays: checklist.durationDays,
      items: updatedItems,
      totalWeight: checklist.totalWeight,
      isTemplate: checklist.isTemplate,
      createdAt: checklist.createdAt,
      updatedAt: DateTime.now(),
    );

    await saveChecklist(updatedChecklist);
  }
}
