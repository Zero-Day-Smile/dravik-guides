// Enhanced Gear Checklist Models
class GearChecklist {
  final String id;
  final String name;
  final String description;
  final TripType tripType;
  final String terrain;
  final int durationDays;
  final List<GearItem> items;
  final double totalWeight;
  final bool isTemplate;
  final DateTime createdAt;
  final DateTime updatedAt;

  GearChecklist({
    required this.id,
    required this.name,
    required this.description,
    required this.tripType,
    required this.terrain,
    required this.durationDays,
    required this.items,
    required this.totalWeight,
    this.isTemplate = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GearChecklist.fromJson(Map<String, dynamic> json) {
    return GearChecklist(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      tripType: TripType.values.firstWhere(
        (e) => e.toString() == 'TripType.${json['tripType']}',
        orElse: () => TripType.hiking,
      ),
      terrain: json['terrain'] ?? '',
      durationDays: json['durationDays'] ?? 1,
      items:
          (json['items'] as List?)?.map((e) => GearItem.fromJson(e)).toList() ??
              [],
      totalWeight: (json['totalWeight'] ?? 0).toDouble(),
      isTemplate: json['isTemplate'] ?? false,
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'tripType': tripType.toString().split('.').last,
      'terrain': terrain,
      'durationDays': durationDays,
      'items': items.map((e) => e.toJson()).toList(),
      'totalWeight': totalWeight,
      'isTemplate': isTemplate,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  double get completionPercentage {
    if (items.isEmpty) return 0;
    final checkedCount = items.where((item) => item.isChecked).length;
    return (checkedCount / items.length) * 100;
  }
}

class GearItem {
  final String id;
  final String name;
  final GearCategory category;
  final double weight; // in grams
  final int quantity;
  final bool isEssential;
  final bool isChecked;
  final String notes;
  final GearPriority priority;

  GearItem({
    required this.id,
    required this.name,
    required this.category,
    required this.weight,
    this.quantity = 1,
    this.isEssential = false,
    this.isChecked = false,
    this.notes = '',
    this.priority = GearPriority.medium,
  });

  factory GearItem.fromJson(Map<String, dynamic> json) {
    return GearItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: GearCategory.values.firstWhere(
        (e) => e.toString() == 'GearCategory.${json['category']}',
        orElse: () => GearCategory.other,
      ),
      weight: (json['weight'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
      isEssential: json['isEssential'] ?? false,
      isChecked: json['isChecked'] ?? false,
      notes: json['notes'] ?? '',
      priority: GearPriority.values.firstWhere(
        (e) => e.toString() == 'GearPriority.${json['priority']}',
        orElse: () => GearPriority.medium,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category.toString().split('.').last,
      'weight': weight,
      'quantity': quantity,
      'isEssential': isEssential,
      'isChecked': isChecked,
      'notes': notes,
      'priority': priority.toString().split('.').last,
    };
  }

  GearItem copyWith({
    String? id,
    String? name,
    GearCategory? category,
    double? weight,
    int? quantity,
    bool? isEssential,
    bool? isChecked,
    String? notes,
    GearPriority? priority,
  }) {
    return GearItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      weight: weight ?? this.weight,
      quantity: quantity ?? this.quantity,
      isEssential: isEssential ?? this.isEssential,
      isChecked: isChecked ?? this.isChecked,
      notes: notes ?? this.notes,
      priority: priority ?? this.priority,
    );
  }
}

enum GearCategory {
  shelter, // tent, sleeping bag, sleeping pad
  clothing, // layers, rain gear, boots
  navigation, // map, compass, GPS
  firstAid, // medical supplies
  food, // meals, snacks, stove
  water, // bottles, filter, purification
  tools, // knife, multitool, repair kit
  electronics, // phone, charger, headlamp
  personal, // toiletries, documents
  safety, // whistle, fire starter, emergency shelter
  other
}

enum GearPriority { low, medium, high, critical }

enum TripType { hiking, trekking, camping, mountaineering, touring, expedition }
