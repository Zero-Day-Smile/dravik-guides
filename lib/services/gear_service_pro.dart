import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:dravik/models/gear.dart';

class GearServicePro {
  static const String _boxName = 'gear_checklists_pro';
  final _uuid = const Uuid();

  // ============================================================================
  // COMPREHENSIVE TEMPLATE LIBRARY
  // ============================================================================

  static final Map<String, List<GearItem>> _templates = {
    // Weekend/Day Hiking (Easy)
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
      GearItem(
          id: '13',
          name: 'Phone + Power Bank',
          category: GearCategory.electronics,
          weight: 300,
          isEssential: true,
          priority: GearPriority.critical),
    ],

    // Multi-Day Himalaya Trek
    'himalaya_7day': [
      // Shelter
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
      // Clothing (Layering System)
      GearItem(
          id: '4',
          name: 'Base Layer (Merino Wool)',
          category: GearCategory.clothing,
          weight: 300,
          quantity: 2,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '5',
          name: 'Mid-Layer Fleece',
          category: GearCategory.clothing,
          weight: 500,
          isEssential: true,
          priority: GearPriority.high),
      GearItem(
          id: '6',
          name: 'Down Jacket (-10°C)',
          category: GearCategory.clothing,
          weight: 800,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '7',
          name: 'Hardshell Rain Jacket',
          category: GearCategory.clothing,
          weight: 400,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '8',
          name: 'Hardshell Rain Pants',
          category: GearCategory.clothing,
          weight: 300,
          isEssential: true,
          priority: GearPriority.high),
      GearItem(
          id: '9',
          name: 'Trekking Boots (Waterproof)',
          category: GearCategory.clothing,
          weight: 1200,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '10',
          name: 'Camp Shoes/Sandals',
          category: GearCategory.clothing,
          weight: 400,
          isEssential: false,
          priority: GearPriority.low),
      GearItem(
          id: '11',
          name: 'Warm Hat & Gloves',
          category: GearCategory.clothing,
          weight: 200,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '12',
          name: 'Buff/Neck Gaiter',
          category: GearCategory.clothing,
          weight: 50,
          isEssential: true,
          priority: GearPriority.high),
      // Navigation
      GearItem(
          id: '13',
          name: 'GPS Device (Garmin)',
          category: GearCategory.navigation,
          weight: 200,
          isEssential: true,
          priority: GearPriority.high),
      GearItem(
          id: '14',
          name: 'Map & Compass',
          category: GearCategory.navigation,
          weight: 100,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '15',
          name: 'Satellite Messenger (InReach)',
          category: GearCategory.navigation,
          weight: 150,
          isEssential: true,
          priority: GearPriority.high),
      // Water & Hydration
      GearItem(
          id: '16',
          name: 'Water Filter (Sawyer/Katadyn)',
          category: GearCategory.water,
          weight: 350,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '17',
          name: 'Water Bottles (1L)',
          category: GearCategory.water,
          weight: 150,
          quantity: 2,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '18',
          name: 'Hydration Bladder (3L)',
          category: GearCategory.water,
          weight: 200,
          isEssential: false,
          priority: GearPriority.medium),
      GearItem(
          id: '19',
          name: 'Electrolyte Tablets',
          category: GearCategory.food,
          weight: 100,
          isEssential: true,
          priority: GearPriority.high),
      // Cooking
      GearItem(
          id: '20',
          name: 'Stove & Fuel Canister',
          category: GearCategory.tools,
          weight: 450,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '21',
          name: 'Cooking Pot (1L)',
          category: GearCategory.tools,
          weight: 250,
          isEssential: true,
          priority: GearPriority.high),
      GearItem(
          id: '22',
          name: 'Utensils (Spork)',
          category: GearCategory.tools,
          weight: 30,
          isEssential: true,
          priority: GearPriority.medium),
      GearItem(
          id: '23',
          name: 'Lighter + Waterproof Matches',
          category: GearCategory.tools,
          weight: 50,
          isEssential: true,
          priority: GearPriority.critical),
      // Food (Per Day)
      GearItem(
          id: '24',
          name: 'Freeze-Dried Meals',
          category: GearCategory.food,
          weight: 180,
          quantity: 7,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '25',
          name: 'Energy Bars',
          category: GearCategory.food,
          weight: 80,
          quantity: 14,
          isEssential: true,
          priority: GearPriority.high),
      GearItem(
          id: '26',
          name: 'Trail Mix/Nuts',
          category: GearCategory.food,
          weight: 150,
          quantity: 7,
          isEssential: true,
          priority: GearPriority.high),
      // Medical & Safety
      GearItem(
          id: '27',
          name: 'Comprehensive First Aid Kit',
          category: GearCategory.firstAid,
          weight: 600,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '28',
          name: 'Altitude Sickness Meds (Diamox)',
          category: GearCategory.firstAid,
          weight: 50,
          isEssential: true,
          priority: GearPriority.high),
      GearItem(
          id: '29',
          name: 'Ibuprofen & Pain Relievers',
          category: GearCategory.firstAid,
          weight: 50,
          isEssential: true,
          priority: GearPriority.high),
      GearItem(
          id: '30',
          name: 'Sunscreen SPF 50+',
          category: GearCategory.firstAid,
          weight: 100,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '31',
          name: 'Lip Balm SPF',
          category: GearCategory.firstAid,
          weight: 20,
          isEssential: true,
          priority: GearPriority.high),
      // Tools & Accessories
      GearItem(
          id: '32',
          name: 'Trekking Poles (Pair)',
          category: GearCategory.tools,
          weight: 500,
          isEssential: true,
          priority: GearPriority.high),
      GearItem(
          id: '33',
          name: 'Headlamp + Extra Batteries',
          category: GearCategory.tools,
          weight: 150,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '34',
          name: 'Multi-tool/Knife',
          category: GearCategory.tools,
          weight: 120,
          isEssential: true,
          priority: GearPriority.high),
      GearItem(
          id: '35',
          name: 'Duct Tape (wrap on pole)',
          category: GearCategory.tools,
          weight: 50,
          isEssential: true,
          priority: GearPriority.medium),
      GearItem(
          id: '36',
          name: 'Repair Kit (tent/gear)',
          category: GearCategory.tools,
          weight: 100,
          isEssential: true,
          priority: GearPriority.medium),
      // Hygiene
      GearItem(
          id: '37',
          name: 'Toilet Paper + Trowel',
          category: GearCategory.tools,
          weight: 150,
          isEssential: true,
          priority: GearPriority.high),
      GearItem(
          id: '38',
          name: 'Hand Sanitizer',
          category: GearCategory.firstAid,
          weight: 80,
          isEssential: true,
          priority: GearPriority.high),
      GearItem(
          id: '39',
          name: 'Toothbrush & Toothpaste',
          category: GearCategory.tools,
          weight: 60,
          isEssential: false,
          priority: GearPriority.low),
      // Electronics
      GearItem(
          id: '40',
          name: 'Phone + Offline Maps',
          category: GearCategory.electronics,
          weight: 200,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '41',
          name: 'Power Bank (20,000mAh)',
          category: GearCategory.electronics,
          weight: 350,
          quantity: 2,
          isEssential: true,
          priority: GearPriority.high),
      GearItem(
          id: '42',
          name: 'Solar Charger',
          category: GearCategory.electronics,
          weight: 300,
          isEssential: false,
          priority: GearPriority.low),
    ],

    // Winter Camping
    'winter_expedition': [
      // Shelter (4-Season)
      GearItem(
          id: '1',
          name: '4-Season Tent',
          category: GearCategory.shelter,
          weight: 3200,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '2',
          name: 'Sleeping Bag (-25°C)',
          category: GearCategory.shelter,
          weight: 2500,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '3',
          name: 'Insulated Sleep Pad (R-6+)',
          category: GearCategory.shelter,
          weight: 800,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '4',
          name: 'Sleeping Bag Liner',
          category: GearCategory.shelter,
          weight: 300,
          isEssential: true,
          priority: GearPriority.high),
      // Extreme Cold Clothing
      GearItem(
          id: '5',
          name: 'Expedition Down Parka',
          category: GearCategory.clothing,
          weight: 1500,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '6',
          name: 'Down Pants',
          category: GearCategory.clothing,
          weight: 600,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '7',
          name: 'Vapor Barrier Liner',
          category: GearCategory.clothing,
          weight: 150,
          isEssential: true,
          priority: GearPriority.high),
      GearItem(
          id: '8',
          name: 'Winter Mountaineering Boots',
          category: GearCategory.clothing,
          weight: 1800,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '9',
          name: 'Insulated Gloves + Mitts',
          category: GearCategory.clothing,
          weight: 400,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '10',
          name: 'Balaclava',
          category: GearCategory.clothing,
          weight: 100,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '11',
          name: 'Goggles (Glacier)',
          category: GearCategory.clothing,
          weight: 200,
          isEssential: true,
          priority: GearPriority.critical),
      // Snow/Ice Gear
      GearItem(
          id: '12',
          name: 'Crampons',
          category: GearCategory.tools,
          weight: 900,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '13',
          name: 'Ice Axe',
          category: GearCategory.tools,
          weight: 650,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '14',
          name: 'Snow Shovel',
          category: GearCategory.tools,
          weight: 600,
          isEssential: true,
          priority: GearPriority.high),
      GearItem(
          id: '15',
          name: 'Snow Saw',
          category: GearCategory.tools,
          weight: 300,
          isEssential: false,
          priority: GearPriority.medium),
      GearItem(
          id: '16',
          name: 'Avalanche Probe',
          category: GearCategory.tools,
          weight: 250,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '17',
          name: 'Avalanche Beacon',
          category: GearCategory.navigation,
          weight: 220,
          isEssential: true,
          priority: GearPriority.critical),
      // Cooking (Winter Specific)
      GearItem(
          id: '18',
          name: 'Liquid Fuel Stove (MSR)',
          category: GearCategory.tools,
          weight: 500,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '19',
          name: 'Fuel Bottle (1L)',
          category: GearCategory.tools,
          weight: 150,
          quantity: 2,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '20',
          name: 'Insulated Pot (2L)',
          category: GearCategory.tools,
          weight: 400,
          isEssential: true,
          priority: GearPriority.high),
      // Other
      GearItem(
          id: '21',
          name: 'Emergency Bivy Sack',
          category: GearCategory.shelter,
          weight: 150,
          isEssential: true,
          priority: GearPriority.high),
      GearItem(
          id: '22',
          name: 'Chemical Hand Warmers',
          category: GearCategory.tools,
          weight: 50,
          quantity: 10,
          isEssential: true,
          priority: GearPriority.medium),
    ],

    // Desert Trek
    'desert_trek': [
      GearItem(
          id: '1',
          name: 'Lightweight Tent (Mesh)',
          category: GearCategory.shelter,
          weight: 1200,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '2',
          name: 'Sleeping Bag (+5°C)',
          category: GearCategory.shelter,
          weight: 800,
          isEssential: true,
          priority: GearPriority.high),
      GearItem(
          id: '3',
          name: 'UL Sleeping Pad',
          category: GearCategory.shelter,
          weight: 300,
          isEssential: true,
          priority: GearPriority.medium),
      // Hot Weather Clothing
      GearItem(
          id: '4',
          name: 'Long-Sleeve Sun Shirt',
          category: GearCategory.clothing,
          weight: 150,
          quantity: 2,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '5',
          name: 'Convertible Hiking Pants',
          category: GearCategory.clothing,
          weight: 300,
          isEssential: true,
          priority: GearPriority.high),
      GearItem(
          id: '6',
          name: 'Wide-Brim Sun Hat',
          category: GearCategory.clothing,
          weight: 120,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '7',
          name: 'Lightweight Trail Runners',
          category: GearCategory.clothing,
          weight: 600,
          isEssential: true,
          priority: GearPriority.high),
      GearItem(
          id: '8',
          name: 'Gaiters (Sand Protection)',
          category: GearCategory.clothing,
          weight: 150,
          isEssential: true,
          priority: GearPriority.high),
      // Hydration (Critical in Desert)
      GearItem(
          id: '9',
          name: 'Water Bottles (1L)',
          category: GearCategory.water,
          weight: 150,
          quantity: 4,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '10',
          name: 'Hydration Bladder (3L)',
          category: GearCategory.water,
          weight: 200,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '11',
          name: 'Water Filter + Purification Tablets',
          category: GearCategory.water,
          weight: 400,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '12',
          name: 'Electrolyte Powder',
          category: GearCategory.food,
          weight: 200,
          isEssential: true,
          priority: GearPriority.critical),
      // Sun Protection
      GearItem(
          id: '13',
          name: 'Sunscreen SPF 50+ (2 bottles)',
          category: GearCategory.firstAid,
          weight: 200,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '14',
          name: 'UV-Blocking Sunglasses',
          category: GearCategory.clothing,
          weight: 50,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '15',
          name: 'Lip Balm SPF 30+',
          category: GearCategory.firstAid,
          weight: 20,
          isEssential: true,
          priority: GearPriority.high),
      // Navigation
      GearItem(
          id: '16',
          name: 'GPS + Extra Batteries',
          category: GearCategory.navigation,
          weight: 250,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '17',
          name: 'Compass & Topo Map',
          category: GearCategory.navigation,
          weight: 100,
          isEssential: true,
          priority: GearPriority.critical),
      // Other
      GearItem(
          id: '18',
          name: 'Tarp (Shade/Shelter)',
          category: GearCategory.shelter,
          weight: 500,
          isEssential: true,
          priority: GearPriority.high),
      GearItem(
          id: '19',
          name: 'Reflective Emergency Blanket',
          category: GearCategory.firstAid,
          weight: 60,
          isEssential: true,
          priority: GearPriority.high),
    ],

    // Beach/Coastal Camping
    'coastal_camping': [
      GearItem(
          id: '1',
          name: 'Beach Tent (Wind Resistant)',
          category: GearCategory.shelter,
          weight: 2000,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '2',
          name: 'Sleeping Bag (+10°C)',
          category: GearCategory.shelter,
          weight: 700,
          isEssential: true,
          priority: GearPriority.medium),
      GearItem(
          id: '3',
          name: 'Sand Stakes (Extra)',
          category: GearCategory.shelter,
          weight: 300,
          quantity: 8,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '4',
          name: 'Waterproof Dry Bags',
          category: GearCategory.tools,
          weight: 200,
          quantity: 3,
          isEssential: true,
          priority: GearPriority.high),
      GearItem(
          id: '5',
          name: 'Swim Gear (Goggles, Fins)',
          category: GearCategory.tools,
          weight: 600,
          isEssential: false,
          priority: GearPriority.low),
      GearItem(
          id: '6',
          name: 'Beach Sandals',
          category: GearCategory.clothing,
          weight: 300,
          isEssential: true,
          priority: GearPriority.medium),
      GearItem(
          id: '7',
          name: 'Sunscreen (Water Resistant)',
          category: GearCategory.firstAid,
          weight: 200,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '8',
          name: 'Cooler (for fresh food)',
          category: GearCategory.food,
          weight: 1500,
          isEssential: false,
          priority: GearPriority.low),
    ],

    // Ultralight Backpacking
    'ultralight_3day': [
      // Big 3 (Ultra-Lightweight)
      GearItem(
          id: '1',
          name: 'Ultralight Tent (900g)',
          category: GearCategory.shelter,
          weight: 900,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '2',
          name: 'Ultralight Sleeping Bag',
          category: GearCategory.shelter,
          weight: 600,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '3',
          name: 'Ultralight Sleeping Pad',
          category: GearCategory.shelter,
          weight: 250,
          isEssential: true,
          priority: GearPriority.high),
      // Minimal Clothing
      GearItem(
          id: '4',
          name: 'Merino Shirt',
          category: GearCategory.clothing,
          weight: 150,
          isEssential: true,
          priority: GearPriority.high),
      GearItem(
          id: '5',
          name: 'Rain Jacket (100g)',
          category: GearCategory.clothing,
          weight: 100,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '6',
          name: 'Trail Runners',
          category: GearCategory.clothing,
          weight: 500,
          isEssential: true,
          priority: GearPriority.critical),
      // Minimal Cooking
      GearItem(
          id: '7',
          name: 'Alcohol Stove (DIY)',
          category: GearCategory.tools,
          weight: 30,
          isEssential: true,
          priority: GearPriority.medium),
      GearItem(
          id: '8',
          name: 'Titanium Pot (600ml)',
          category: GearCategory.tools,
          weight: 100,
          isEssential: true,
          priority: GearPriority.high),
      // Essentials Only
      GearItem(
          id: '9',
          name: 'Micro First Aid Kit',
          category: GearCategory.firstAid,
          weight: 100,
          isEssential: true,
          priority: GearPriority.high),
      GearItem(
          id: '10',
          name: 'Smart Phone (navigation)',
          category: GearCategory.navigation,
          weight: 200,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '11',
          name: 'Dehydrated Meals',
          category: GearCategory.food,
          weight: 150,
          quantity: 6,
          isEssential: true,
          priority: GearPriority.critical),
    ],

    // Family Camping (Car Camping)
    'family_car_camping': [
      GearItem(
          id: '1',
          name: 'Large Family Tent (6-person)',
          category: GearCategory.shelter,
          weight: 5000,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '2',
          name: 'Sleeping Bags',
          category: GearCategory.shelter,
          weight: 1200,
          quantity: 4,
          isEssential: true,
          priority: GearPriority.critical),
      GearItem(
          id: '3',
          name: 'Air Mattresses',
          category: GearCategory.shelter,
          weight: 1500,
          quantity: 2,
          isEssential: true,
          priority: GearPriority.high),
      GearItem(
          id: '4',
          name: 'Camp Chairs',
          category: GearCategory.tools,
          weight: 800,
          quantity: 4,
          isEssential: true,
          priority: GearPriority.medium),
      GearItem(
          id: '5',
          name: 'Camp Table',
          category: GearCategory.tools,
          weight: 3000,
          isEssential: true,
          priority: GearPriority.medium),
      GearItem(
          id: '6',
          name: 'Propane Stove (2-burner)',
          category: GearCategory.tools,
          weight: 2000,
          isEssential: true,
          priority: GearPriority.high),
      GearItem(
          id: '7',
          name: 'Cooler (Large)',
          category: GearCategory.food,
          weight: 3000,
          isEssential: true,
          priority: GearPriority.high),
      GearItem(
          id: '8',
          name: 'Lantern (LED)',
          category: GearCategory.tools,
          weight: 400,
          isEssential: true,
          priority: GearPriority.high),
      GearItem(
          id: '9',
          name: 'Games & Entertainment',
          category: GearCategory.tools,
          weight: 1000,
          isEssential: false,
          priority: GearPriority.low),
      GearItem(
          id: '10',
          name: 'First Aid Kit (Comprehensive)',
          category: GearCategory.firstAid,
          weight: 800,
          isEssential: true,
          priority: GearPriority.critical),
    ],
  };

  // ============================================================================
  // AI-POWERED GEAR RECOMMENDATION ENGINE
  // ============================================================================

  Future<GearChecklist> generateAIChecklist({
    required String destination,
    required String terrain,
    required int durationDays,
    required TripType tripType,
    required int groupSize,
    double? temperature,
    String? weatherCondition,
    int? altitude,
    bool isVegan = false,
  }) async {
    // Smart template selection based on inputs
    String selectedTemplate = _selectSmartTemplate(
      terrain: terrain,
      durationDays: durationDays,
      tripType: tripType,
      temperature: temperature,
      altitude: altitude,
    );

    final baseItems = List<GearItem>.from(
        _templates[selectedTemplate] ?? _templates['weekend_hike']!);
    final customizedItems = <GearItem>[];

    // Apply AI customizations
    for (var item in baseItems) {
      var customizedItem = item;

      // Adjust quantities based on duration and group size
      if (item.category == GearCategory.food) {
        int mealsPerDay = 3;
        customizedItem = item.copyWith(
          quantity: (durationDays * mealsPerDay * groupSize),
        );
      }

      // Adjust for group size (tents, stoves, etc.)
      if (item.name.contains('Tent') && groupSize > 2) {
        int tentCount = (groupSize / 2).ceil();
        customizedItem = item.copyWith(quantity: tentCount);
      }

      customizedItems.add(customizedItem);
    }

    // Add weather-specific items
    if (weatherCondition != null) {
      customizedItems.addAll(_addWeatherSpecificGear(weatherCondition));
    }

    // Add terrain-specific items
    customizedItems.addAll(_addTerrainSpecificGear(terrain, altitude));

    // Add altitude-specific items
    if (altitude != null && altitude > 3000) {
      customizedItems.addAll(_addAltitudeGear(altitude));
    }

    // Temperature-specific adjustments
    if (temperature != null) {
      customizedItems.addAll(_addTemperatureGear(temperature));
    }

    final checklist = GearChecklist(
      id: _uuid.v4(),
      name: '$destination ${durationDays}D Trek',
      description:
          'AI-Generated: $terrain terrain, $groupSize people, ${temperature ?? "unknown"}°C',
      tripType: tripType,
      terrain: terrain,
      durationDays: durationDays,
      items: customizedItems,
      totalWeight: customizedItems.fold(
          0.0, (sum, item) => sum + (item.weight * item.quantity)),
      isTemplate: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await saveChecklist(checklist);
    return checklist;
  }

  String _selectSmartTemplate({
    required String terrain,
    required int durationDays,
    required TripType tripType,
    double? temperature,
    int? altitude,
  }) {
    terrain = terrain.toLowerCase();

    // Winter conditions
    if (temperature != null && temperature < -5) {
      return 'winter_expedition';
    }

    // High altitude
    if (altitude != null && altitude > 4000) {
      return 'himalaya_7day';
    }

    // Desert terrain
    if (terrain.contains('desert') || terrain.contains('arid')) {
      return 'desert_trek';
    }

    // Coastal/beach
    if (terrain.contains('beach') || terrain.contains('coast')) {
      return 'coastal_camping';
    }

    // Snow/ice terrain
    if (terrain.contains('snow') ||
        terrain.contains('ice') ||
        terrain.contains('glacier')) {
      return 'winter_expedition';
    }

    // Car-style camping
    if (tripType == TripType.camping) {
      return 'family_car_camping';
    }

    // Ultralight preference (short duration, hiking/trekking)
    if (durationDays <= 3 &&
        (tripType == TripType.hiking || tripType == TripType.trekking)) {
      return 'ultralight_3day';
    }

    // Multi-day mountain trek
    if (durationDays >= 5 &&
        (terrain.contains('mountain') || terrain.contains('himalaya'))) {
      return 'himalaya_7day';
    }

    // Default: weekend hike
    return 'weekend_hike';
  }

  List<GearItem> _addWeatherSpecificGear(String weatherCondition) {
    final items = <GearItem>[];
    weatherCondition = weatherCondition.toLowerCase();

    if (weatherCondition.contains('rain') || weatherCondition.contains('wet')) {
      items.add(GearItem(
        id: _uuid.v4(),
        name: 'Pack Rain Cover',
        category: GearCategory.shelter,
        weight: 200,
        isEssential: true,
        priority: GearPriority.high,
      ));
      items.add(GearItem(
        id: _uuid.v4(),
        name: 'Waterproof Stuff Sacks',
        category: GearCategory.shelter,
        weight: 100,
        quantity: 3,
        isEssential: true,
        priority: GearPriority.medium,
      ));
    }

    if (weatherCondition.contains('wind')) {
      items.add(GearItem(
        id: _uuid.v4(),
        name: 'Windproof Jacket',
        category: GearCategory.clothing,
        weight: 300,
        isEssential: true,
        priority: GearPriority.high,
      ));
    }

    return items;
  }

  List<GearItem> _addTerrainSpecificGear(String terrain, int? altitude) {
    final items = <GearItem>[];
    terrain = terrain.toLowerCase();

    if (terrain.contains('snow') || terrain.contains('ice')) {
      items.addAll([
        GearItem(
          id: _uuid.v4(),
          name: 'Crampons',
          category: GearCategory.tools,
          weight: 850,
          isEssential: true,
          priority: GearPriority.critical,
        ),
        GearItem(
          id: _uuid.v4(),
          name: 'Ice Axe',
          category: GearCategory.tools,
          weight: 600,
          isEssential: true,
          priority: GearPriority.critical,
        ),
        GearItem(
          id: _uuid.v4(),
          name: 'Snow Goggles',
          category: GearCategory.clothing,
          weight: 120,
          isEssential: true,
          priority: GearPriority.high,
        ),
      ]);
    }

    if (terrain.contains('rock') || terrain.contains('scramble')) {
      items.add(GearItem(
        id: _uuid.v4(),
        name: 'Climbing Helmet',
        category: GearCategory.tools,
        weight: 300,
        isEssential: true,
        priority: GearPriority.high,
      ));
    }

    if (terrain.contains('river') || terrain.contains('water crossing')) {
      items.add(GearItem(
        id: _uuid.v4(),
        name: 'Water Crossing Sandals',
        category: GearCategory.clothing,
        weight: 250,
        isEssential: true,
        priority: GearPriority.medium,
      ));
    }

    return items;
  }

  List<GearItem> _addAltitudeGear(int altitude) {
    final items = <GearItem>[];

    if (altitude > 3000) {
      items.add(GearItem(
        id: _uuid.v4(),
        name: 'Altitude Medication (Diamox)',
        category: GearCategory.firstAid,
        weight: 50,
        isEssential: true,
        priority: GearPriority.critical,
      ));
    }

    if (altitude > 4000) {
      items.addAll([
        GearItem(
          id: _uuid.v4(),
          name: 'Pulse Oximeter',
          category: GearCategory.firstAid,
          weight: 80,
          isEssential: true,
          priority: GearPriority.high,
        ),
        GearItem(
          id: _uuid.v4(),
          name: 'Dexamethasone (Emergency)',
          category: GearCategory.firstAid,
          weight: 30,
          isEssential: true,
          priority: GearPriority.high,
        ),
      ]);
    }

    return items;
  }

  List<GearItem> _addTemperatureGear(double temperature) {
    final items = <GearItem>[];

    if (temperature < 0) {
      items.addAll([
        GearItem(
          id: _uuid.v4(),
          name: 'Insulated Water Bottle Sleeve',
          category: GearCategory.water,
          weight: 100,
          isEssential: true,
          priority: GearPriority.high,
        ),
        GearItem(
          id: _uuid.v4(),
          name: 'Hand Warmers',
          category: GearCategory.tools,
          weight: 40,
          quantity: 5,
          isEssential: true,
          priority: GearPriority.medium,
        ),
      ]);
    }

    if (temperature > 30) {
      items.addAll([
        GearItem(
          id: _uuid.v4(),
          name: 'Cooling Towel',
          category: GearCategory.tools,
          weight: 80,
          isEssential: false,
          priority: GearPriority.low,
        ),
        GearItem(
          id: _uuid.v4(),
          name: 'Extra Electrolytes',
          category: GearCategory.food,
          weight: 150,
          isEssential: true,
          priority: GearPriority.high,
        ),
      ]);
    }

    return items;
  }

  // ============================================================================
  // CRUD OPERATIONS
  // ============================================================================

  Future<List<GearChecklist>> getAllChecklists() async {
    try {
      final box = await Hive.openBox(_boxName);
      final data = box.get('checklists', defaultValue: <String>[]);

      if (data is List) {
        return data
            .map((item) => GearChecklist.fromJson(json.decode(item)))
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

  // ============================================================================
  // UTILITY FUNCTIONS
  // ============================================================================

  Map<String, String> getAvailableTemplates() {
    return {
      'weekend_hike': 'Weekend Hike (1-2 Days)',
      'himalaya_7day': 'Himalaya Trek (7 Days)',
      'winter_expedition': 'Winter Expedition',
      'desert_trek': 'Desert Trek',
      'coastal_camping': 'Coastal/Beach Camping',
      'ultralight_3day': 'Ultralight Backpacking (3 Days)',
      'family_car_camping': 'Family Car Camping',
    };
  }

  Future<Map<String, dynamic>> getPackingStats(String checklistId) async {
    final checklist = await getChecklistById(checklistId);
    if (checklist == null) return {};

    final items = checklist.items;
    final checkedCount = items.where((i) => i.isChecked).length;
    final totalCount = items.length;
    final totalWeight =
        items.fold(0.0, (sum, item) => sum + (item.weight * item.quantity));
    final packedWeight = items
        .where((i) => i.isChecked)
        .fold(0.0, (sum, item) => sum + (item.weight * item.quantity));

    final categoryBreakdown = <String, double>{};
    for (var item in items) {
      final cat = item.category.toString().split('.').last;
      categoryBreakdown[cat] =
          (categoryBreakdown[cat] ?? 0.0) + (item.weight * item.quantity);
    }

    return {
      'checkedCount': checkedCount,
      'totalCount': totalCount,
      'percentage': totalCount > 0
          ? (checkedCount / totalCount * 100).toStringAsFixed(1)
          : '0',
      'totalWeight': totalWeight,
      'packedWeight': packedWeight,
      'remainingWeight': totalWeight - packedWeight,
      'categoryBreakdown': categoryBreakdown,
    };
  }
}
