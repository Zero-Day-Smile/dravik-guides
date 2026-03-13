// Local guide model is defined below; removed invalid import.

class ComprehensiveGuidesData {
  static final List<Guide> allGuides = [
    // ESSENTIAL SURVIVAL & SAFETY
    Guide(
      id: 'survival_complete',
      title: 'Ultimate Wilderness Survival',
      category: 'Survival',
      difficulty: 'Advanced',
      duration: '60 min read',
      description:
          'Complete survival guide covering Rule of 3, shelter building, water purification, fire starting, food foraging, signaling, wildlife encounters, and emergency first aid.',
      imageUrl: 'assets/guides/survival_thumbnail.jpg',
      content: 'assets/guides/survival.md',
      tags: ['survival', 'emergency', 'bushcraft', 'shelter', 'fire', 'water'],
      isOfflineAvailable: true,
      rating: 4.9,
      reviewCount: 1247,
    ),

    Guide(
      id: 'first_aid_complete',
      title: 'Wilderness First Aid Complete',
      category: 'Medical',
      difficulty: 'Intermediate',
      duration: '45 min read',
      description:
          'Comprehensive first aid covering CPR, severe bleeding, fractures, hypothermia, heat injuries, snake bites, concussions, and emergency evacuations.',
      imageUrl: 'assets/guides/first_aid_thumbnail.jpg',
      content: 'assets/guides/first_aid.md',
      tags: ['first aid', 'medical', 'emergency', 'CPR', 'injuries', 'rescue'],
      isOfflineAvailable: true,
      rating: 4.9,
      reviewCount: 892,
    ),

    // NAVIGATION & ORIENTATION
    Guide(
      id: 'navigation_complete',
      title: 'Complete Navigation & Orientation',
      category: 'Navigation',
      difficulty: 'Intermediate',
      duration: '50 min read',
      description:
          'Master map reading, compass use, GPS navigation, celestial navigation (sun/stars), natural navigation, terrain association, and lost procedures.',
      imageUrl: 'assets/guides/navigation_thumbnail.jpg',
      content: 'assets/guides/navigation.md',
      tags: ['navigation', 'compass', 'GPS', 'map', 'orientation', 'celestial'],
      isOfflineAvailable: true,
      rating: 4.8,
      reviewCount: 734,
    ),

    // TREKKING & HIKING
    Guide(
      id: 'trekking_complete',
      title: 'Complete Trekking & Hiking Guide',
      category: 'Trekking',
      difficulty: 'Beginner to Advanced',
      duration: '55 min read',
      description:
          'Everything about trekking: pre-trek conditioning, essential skills, navigation, weather assessment, altitude sickness prevention, emergency procedures, and expert tips.',
      imageUrl: 'assets/guides/trekking_thumbnail.jpg',
      content: 'assets/guides/comprehensive_trekking.md',
      tags: [
        'trekking',
        'hiking',
        'altitude',
        'conditioning',
        'skills',
        'safety'
      ],
      isOfflineAvailable: true,
      rating: 4.9,
      reviewCount: 1456,
    ),

    // CAMPING & GEAR
    Guide(
      id: 'camping_essentials',
      title: 'Camping Essentials & Best Practices',
      category: 'Camping',
      difficulty: 'Beginner',
      duration: '30 min read',
      description:
          'Learn campsite selection, tent setup, cooking techniques, Leave No Trace principles, food storage, and camp safety.',
      imageUrl: 'assets/guides/camping_thumbnail.jpg',
      content: 'camping_essentials.md',
      tags: ['camping', 'tent', 'cooking', 'LNT', 'campsite', 'outdoor'],
      isOfflineAvailable: true,
      rating: 4.7,
      reviewCount: 623,
    ),

    Guide(
      id: 'gear_optimization',
      title: 'Gear Selection & Weight Optimization',
      category: 'Gear',
      difficulty: 'Intermediate',
      duration: '25 min read',
      description:
          'Master the Big 3 (pack, shelter, sleep system), weight reduction strategies, gear testing, and seasonal gear adjustments.',
      imageUrl: 'assets/guides/gear_thumbnail.jpg',
      content: 'gear_optimization.md',
      tags: ['gear', 'ultralight', 'backpacking', 'equipment', 'weight'],
      isOfflineAvailable: true,
      rating: 4.8,
      reviewCount: 891,
    ),

    // WEATHER & ENVIRONMENT
    Guide(
      id: 'weather_reading',
      title: 'Weather Reading & Forecasting',
      category: 'Weather',
      difficulty: 'Intermediate',
      duration: '20 min read',
      description:
          'Read clouds, predict storms, understand wind patterns, use barometers, and make field weather forecasts.',
      imageUrl: 'assets/guides/weather_thumbnail.jpg',
      content: 'weather_reading.md',
      tags: ['weather', 'forecasting', 'clouds', 'storms', 'safety'],
      isOfflineAvailable: true,
      rating: 4.7,
      reviewCount: 542,
    ),

    Guide(
      id: 'altitude_guide',
      title: 'High Altitude Trekking Guide',
      category: 'Altitude',
      difficulty: 'Advanced',
      duration: '35 min read',
      description:
          'Altitude sickness (AMS/HACE/HAPE), acclimatization schedules, medication (Diamox, Dexamethasone), descent protocols, and prevention strategies.',
      imageUrl: 'assets/guides/altitude_thumbnail.jpg',
      content: 'altitude_guide.md',
      tags: ['altitude', 'AMS', 'HACE', 'HAPE', 'acclimatization', 'mountains'],
      isOfflineAvailable: true,
      rating: 4.9,
      reviewCount: 673,
    ),

    // WILDLIFE & NATURE
    Guide(
      id: 'wildlife_encounters',
      title: 'Wildlife Encounters & Safety',
      category: 'Wildlife',
      difficulty: 'Intermediate',
      duration: '30 min read',
      description:
          'Handle encounters with bears (black/grizzly), mountain lions, moose, snakes, insects, and dangerous wildlife. Prevention and response protocols.',
      imageUrl: 'assets/guides/wildlife_thumbnail.jpg',
      content: 'wildlife_encounters.md',
      tags: ['wildlife', 'bears', 'safety', 'animals', 'defense', 'encounters'],
      isOfflineAvailable: true,
      rating: 4.8,
      reviewCount: 789,
    ),

    Guide(
      id: 'plant_identification',
      title: 'Edible & Poisonous Plants',
      category: 'Foraging',
      difficulty: 'Advanced',
      duration: '40 min read',
      description:
          'Identify edible plants, berries, nuts. Universal edibility test. Recognize poisonous plants. Safe foraging practices.',
      imageUrl: 'assets/guides/plants_thumbnail.jpg',
      content: 'plant_identification.md',
      tags: [
        'foraging',
        'plants',
        'edible',
        'poisonous',
        'berries',
        'survival'
      ],
      isOfflineAvailable: true,
      rating: 4.6,
      reviewCount: 456,
    ),

    // WATER & HYDRATION
    Guide(
      id: 'water_sources',
      title: 'Finding & Purifying Water',
      category: 'Water',
      difficulty: 'Beginner',
      duration: '20 min read',
      description:
          'Locate water sources, purification methods (boiling, chemical, UV, filtration), water storage, and hydration strategies.',
      imageUrl: 'assets/guides/water_thumbnail.jpg',
      content: 'water_sources.md',
      tags: ['water', 'purification', 'hydration', 'survival', 'filtration'],
      isOfflineAvailable: true,
      rating: 4.8,
      reviewCount: 667,
    ),

    // TERRAIN-SPECIFIC GUIDES
    Guide(
      id: 'mountain_safety',
      title: 'Mountain Safety & Techniques',
      category: 'Mountains',
      difficulty: 'Advanced',
      duration: '35 min read',
      description:
          'Route finding, scrambling, glacier travel, crevasse rescue, avalanche safety, and mountain weather.',
      imageUrl: 'assets/guides/mountains_thumbnail.jpg',
      content: 'mountain_safety.md',
      tags: ['mountains', 'climbing', 'glacier', 'avalanche', 'alpine'],
      isOfflineAvailable: true,
      rating: 4.9,
      reviewCount: 534,
    ),

    Guide(
      id: 'desert_survival',
      title: 'Desert Survival & Navigation',
      category: 'Desert',
      difficulty: 'Intermediate',
      duration: '25 min read',
      description:
          'Desert-specific skills: water conservation, heat management, sun protection, navigation in featureless terrain, and emergency shelter.',
      imageUrl: 'assets/guides/desert_thumbnail.jpg',
      content: 'desert_survival.md',
      tags: ['desert', 'arid', 'heat', 'water', 'navigation', 'survival'],
      isOfflineAvailable: true,
      rating: 4.7,
      reviewCount: 423,
    ),

    Guide(
      id: 'winter_camping',
      title: 'Winter Camping & Snow Skills',
      category: 'Winter',
      difficulty: 'Advanced',
      duration: '40 min read',
      description:
          'Winter camping techniques, snow shelters, cold weather gear, avalanche basics, and winter survival.',
      imageUrl: 'assets/guides/winter_thumbnail.jpg',
      content: 'winter_camping.md',
      tags: ['winter', 'snow', 'cold', 'avalanche', 'camping', 'ice'],
      isOfflineAvailable: true,
      rating: 4.8,
      reviewCount: 612,
    ),

    Guide(
      id: 'jungle_survival',
      title: 'Jungle & Rainforest Survival',
      category: 'Jungle',
      difficulty: 'Advanced',
      duration: '30 min read',
      description:
          'Navigate dense jungle, find water, avoid dangerous plants/animals, build tropical shelters, and prevent tropical diseases.',
      imageUrl: 'assets/guides/jungle_thumbnail.jpg',
      content: 'jungle_survival.md',
      tags: ['jungle', 'rainforest', 'tropical', 'machete', 'diseases'],
      isOfflineAvailable: true,
      rating: 4.6,
      reviewCount: 387,
    ),

    // SKILLS & TECHNIQUES
    Guide(
      id: 'knots_guide',
      title: 'Essential Knots for Outdoor Activities',
      category: 'Skills',
      difficulty: 'Beginner',
      duration: '15 min read',
      description:
          'Learn 15 essential knots: bowline, clove hitch, taut-line, figure-8, prusik, and more with step-by-step diagrams.',
      imageUrl: 'assets/guides/knots_thumbnail.jpg',
      content: 'knots_guide.md',
      tags: ['knots', 'rope', 'skills', 'camping', 'climbing', 'techniques'],
      isOfflineAvailable: true,
      rating: 4.7,
      reviewCount: 789,
    ),

    Guide(
      id: 'photography_guide',
      title: 'Outdoor Photography Guide',
      category: 'Photography',
      difficulty: 'Beginner',
      duration: '20 min read',
      description:
          'Capture stunning outdoor photos: golden hour, composition, camera settings, protecting gear, and post-processing tips.',
      imageUrl: 'assets/guides/photo_thumbnail.jpg',
      content: 'photography_guide.md',
      tags: ['photography', 'camera', 'landscapes', 'tips', 'golden hour'],
      isOfflineAvailable: true,
      rating: 4.6,
      reviewCount: 543,
    ),

    // GROUP & EXPEDITION
    Guide(
      id: 'group_dynamics',
      title: 'Group Trekking & Leadership',
      category: 'Group',
      difficulty: 'Intermediate',
      duration: '25 min read',
      description:
          'Lead group treks, manage different fitness levels, decision-making, conflict resolution, and emergency coordination.',
      imageUrl: 'assets/guides/group_thumbnail.jpg',
      content: 'group_dynamics.md',
      tags: ['group', 'leadership', 'teamwork', 'expedition', 'management'],
      isOfflineAvailable: true,
      rating: 4.7,
      reviewCount: 456,
    ),

    Guide(
      id: 'expedition_planning',
      title: 'Expedition Planning & Logistics',
      category: 'Planning',
      difficulty: 'Advanced',
      duration: '45 min read',
      description:
          'Plan multi-week expeditions: permits, logistics, resupply, budgeting, risk assessment, and contingency planning.',
      imageUrl: 'assets/guides/expedition_thumbnail.jpg',
      content: 'expedition_planning.md',
      tags: ['expedition', 'planning', 'logistics', 'permits', 'budgeting'],
      isOfflineAvailable: true,
      rating: 4.8,
      reviewCount: 387,
    ),

    // FITNESS & CONDITIONING
    Guide(
      id: 'trek_fitness',
      title: 'Trekking Fitness & Training',
      category: 'Fitness',
      difficulty: 'Beginner',
      duration: '20 min read',
      description:
          '8-week training program: cardio, strength, flexibility, altitude preparation, and injury prevention.',
      imageUrl: 'assets/guides/fitness_thumbnail.jpg',
      content: 'trek_fitness.md',
      tags: ['fitness', 'training', 'conditioning', 'exercise', 'preparation'],
      isOfflineAvailable: true,
      rating: 4.7,
      reviewCount: 892,
    ),

    // SUSTAINABLE TRAVEL
    Guide(
      id: 'leave_no_trace',
      title: 'Leave No Trace Principles',
      category: 'Ethics',
      difficulty: 'Beginner',
      duration: '15 min read',
      description:
          'Practice sustainable outdoor ethics: plan ahead, camp on durable surfaces, dispose waste properly, respect wildlife.',
      imageUrl: 'assets/guides/lnt_thumbnail.jpg',
      content: 'leave_no_trace.md',
      tags: ['LNT', 'ethics', 'sustainability', 'conservation', 'responsible'],
      isOfflineAvailable: true,
      rating: 4.9,
      reviewCount: 1123,
    ),
  ];

  static List<Guide> getGuidesByCategory(String category) {
    return allGuides.where((g) => g.category == category).toList();
  }

  static List<String> getAllCategories() {
    return allGuides.map((g) => g.category).toSet().toList()..sort();
  }

  static List<Guide> searchGuides(String query) {
    query = query.toLowerCase();
    return allGuides
        .where((g) =>
            g.title.toLowerCase().contains(query) ||
            g.description.toLowerCase().contains(query) ||
            g.tags.any((tag) => tag.toLowerCase().contains(query)))
        .toList();
  }

  static List<Guide> getRecommendedGuides(
      String userLevel, String userInterest) {
    // Simple recommendation based on difficulty and category
    return allGuides
        .where((g) =>
            g.difficulty.toLowerCase().contains(userLevel.toLowerCase()) ||
            g.category.toLowerCase().contains(userInterest.toLowerCase()))
        .take(5)
        .toList();
  }

  static Guide? getGuideById(String id) {
    try {
      return allGuides.firstWhere((g) => g.id == id);
    } catch (e) {
      return null;
    }
  }
}

class Guide {
  final String id;
  final String title;
  final String category;
  final String difficulty;
  final String duration;
  final String description;
  final String imageUrl;
  final String content; // Path to markdown file
  final List<String> tags;
  final bool isOfflineAvailable;
  final double rating;
  final int reviewCount;

  Guide({
    required this.id,
    required this.title,
    required this.category,
    required this.difficulty,
    required this.duration,
    required this.description,
    required this.imageUrl,
    required this.content,
    required this.tags,
    required this.isOfflineAvailable,
    required this.rating,
    required this.reviewCount,
  });
}
