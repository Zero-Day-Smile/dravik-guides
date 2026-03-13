import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:dravik/models/country.dart';

class CountryService {
  static const String _cacheBoxName = 'countries';

  // Predefined countries data (in real app, this would come from a JSON file or API)
  static final List<Country> _countries = [
    Country(
      code: 'NP',
      name: 'Nepal',
      flagEmoji: '🇳🇵',
      languages: ['Nepali', 'English'],
      currency: 'Nepalese Rupee',
      currencySymbol: '₨',
      exchangeRateToUSD: 132.5,
      timezone: 'NPT (UTC+5:45)',
      visaRequirements: [
        'Tourist visa available on arrival',
        'Fee: \$30 for 15 days, \$50 for 30 days',
        'Passport valid for 6 months',
      ],
      customs: [
        CustomTip(
          category: 'Etiquette',
          title: 'Namaste Greeting',
          description: 'Press palms together and bow slightly. Say "Namaste"',
          icon: '🙏',
        ),
        CustomTip(
          category: 'Religious',
          title: 'Temple Etiquette',
          description:
              'Remove shoes before entering temples. Ask before photographing',
          icon: '🕉️',
        ),
        CustomTip(
          category: 'Cultural',
          title: 'Left Hand Usage',
          description:
              'Use right hand for eating and greeting. Left hand considered unclean',
          icon: '✋',
        ),
      ],
      emergencyContacts: [
        EmergencyContact(type: 'Police', number: '100', name: 'Nepal Police'),
        EmergencyContact(type: 'Medical', number: '102', name: 'Ambulance'),
        EmergencyContact(
            type: 'Tourist Police', number: '1144', name: 'Tourist Police'),
      ],
      highlights: [
        CulturalHighlight(
          name: 'Everest Base Camp',
          description: 'World-famous trekking destination',
          category: 'Adventure',
          imageUrl: '',
        ),
        CulturalHighlight(
          name: 'Dashain Festival',
          description: '15-day harvest festival in Oct/Nov',
          category: 'Festival',
          imageUrl: '',
        ),
      ],
      phrasebook: [
        Phrase(
          category: 'Greetings',
          english: 'Hello',
          translation: 'नमस्ते (Namaste)',
          pronunciation: 'nuh-muh-stay',
        ),
        Phrase(
          category: 'Help',
          english: 'Help me!',
          translation: 'मलाई मद्दत गर्नुहोस्! (Malai maddat garnuhos!)',
          pronunciation: 'muh-lie mud-dut gur-nu-hos',
        ),
        Phrase(
          category: 'Directions',
          english: 'Where is the hospital?',
          translation: 'अस्पताल कहाँ छ? (Aspatal kaha cha?)',
          pronunciation: 'us-puh-taal kuh-haa chuh',
        ),
      ],
    ),
    Country(
      code: 'NZ',
      name: 'New Zealand',
      flagEmoji: '🇳🇿',
      languages: ['English', 'Māori'],
      currency: 'New Zealand Dollar',
      currencySymbol: 'NZ\$',
      exchangeRateToUSD: 1.62,
      timezone: 'NZST (UTC+12)',
      visaRequirements: [
        'Visa waiver for many countries up to 90 days',
        'Electronic Travel Authority (NZeTA) required',
        'Fee: NZ\$23 online or NZ\$17 via app',
      ],
      customs: [
        CustomTip(
          category: 'Etiquette',
          title: 'Māori Greeting',
          description:
              'Hongi (pressing noses) is traditional. Otherwise handshake',
          icon: '🤝',
        ),
        CustomTip(
          category: 'Environmental',
          title: 'Conservation',
          description: 'Very strict biosecurity. Declare all food, hiking gear',
          icon: '🌿',
        ),
        CustomTip(
          category: 'Safety',
          title: 'Outdoor Safety',
          description: 'Weather changes rapidly. Always check forecasts',
          icon: '⛰️',
        ),
      ],
      emergencyContacts: [
        EmergencyContact(type: 'Police', number: '111', name: 'NZ Police'),
        EmergencyContact(type: 'Medical', number: '111', name: 'Ambulance'),
        EmergencyContact(
            type: 'Search & Rescue', number: '111', name: 'Emergency Services'),
      ],
      highlights: [
        CulturalHighlight(
          name: 'Milford Track',
          description: 'One of the world\'s finest walks through fjords',
          category: 'Hiking',
          imageUrl: '',
        ),
        CulturalHighlight(
          name: 'Tongariro Alpine Crossing',
          description: '19km day hike through volcanic landscape',
          category: 'Adventure',
          imageUrl: '',
        ),
      ],
      phrasebook: [
        Phrase(
          category: 'Greetings',
          english: 'Hello',
          translation: 'Kia ora',
          pronunciation: 'key-ah or-ah',
        ),
        Phrase(
          category: 'Help',
          english: 'Help!',
          translation: 'Āwhina!',
          pronunciation: 'ah-fee-nah',
        ),
        Phrase(
          category: 'Directions',
          english: 'Where is the trail?',
          translation: 'Kei hea te ara?',
          pronunciation: 'kay hay-ah teh ah-rah',
        ),
      ],
    ),
    Country(
      code: 'IS',
      name: 'Iceland',
      flagEmoji: '🇮🇸',
      languages: ['Icelandic', 'English'],
      currency: 'Icelandic Króna',
      currencySymbol: 'kr',
      exchangeRateToUSD: 138.5,
      timezone: 'GMT (UTC+0)',
      visaRequirements: [
        'Schengen visa rules apply',
        'Visa-free for EU/EEA, US, Canada up to 90 days',
        'Passport valid for 3 months beyond stay',
      ],
      customs: [
        CustomTip(
          category: 'Environmental',
          title: 'Respect Nature',
          description:
              'Stay on marked paths. Don\'t damage moss (takes decades to regrow)',
          icon: '🌋',
        ),
        CustomTip(
          category: 'Cultural',
          title: 'Tipping',
          description: 'Not customary. Service included in prices',
          icon: '💰',
        ),
        CustomTip(
          category: 'Safety',
          title: 'Weather Awareness',
          description:
              'Check road conditions (road.is). Weather extremely changeable',
          icon: '❄️',
        ),
      ],
      emergencyContacts: [
        EmergencyContact(
            type: 'Police', number: '112', name: 'Icelandic Police'),
        EmergencyContact(
            type: 'Medical', number: '112', name: 'Emergency Services'),
        EmergencyContact(
            type: 'ICE-SAR', number: '112', name: 'Search & Rescue'),
      ],
      highlights: [
        CulturalHighlight(
          name: 'Laugavegur Trail',
          description: '55km trek through geothermal landscapes',
          category: 'Hiking',
          imageUrl: '',
        ),
        CulturalHighlight(
          name: 'Northern Lights',
          description: 'Best viewed Sept-April away from cities',
          category: 'Natural Phenomenon',
          imageUrl: '',
        ),
      ],
      phrasebook: [
        Phrase(
          category: 'Greetings',
          english: 'Hello',
          translation: 'Halló',
          pronunciation: 'hah-loh',
        ),
        Phrase(
          category: 'Help',
          english: 'Help!',
          translation: 'Hjálp!',
          pronunciation: 'hyowlp',
        ),
        Phrase(
          category: 'Directions',
          english: 'Where is the bathroom?',
          translation: 'Hvar er klósettið?',
          pronunciation: 'kvar er klow-set-ith',
        ),
      ],
    ),
    Country(
      code: 'CH',
      name: 'Switzerland',
      flagEmoji: '🇨🇭',
      languages: ['German', 'French', 'Italian', 'English'],
      currency: 'Swiss Franc',
      currencySymbol: 'CHF',
      exchangeRateToUSD: 0.88,
      timezone: 'CET (UTC+1)',
      visaRequirements: [
        'Schengen visa rules apply',
        'Visa-free for many countries up to 90 days',
        'Passport valid for 3 months beyond stay',
      ],
      customs: [
        CustomTip(
          category: 'Etiquette',
          title: 'Punctuality',
          description: 'Being on time is very important. Trains run precisely',
          icon: '⏰',
        ),
        CustomTip(
          category: 'Cultural',
          title: 'Quiet Hours',
          description: 'No noise after 10 PM. Sundays are very quiet',
          icon: '🤫',
        ),
        CustomTip(
          category: 'Environmental',
          title: 'Alpine Code',
          description: 'Stay on trails. Carry trash out. Respect wildlife',
          icon: '🏔️',
        ),
      ],
      emergencyContacts: [
        EmergencyContact(type: 'Police', number: '117', name: 'Swiss Police'),
        EmergencyContact(type: 'Medical', number: '144', name: 'Ambulance'),
        EmergencyContact(
            type: 'Mountain Rescue', number: '1414', name: 'REGA Air Rescue'),
      ],
      highlights: [
        CulturalHighlight(
          name: 'Haute Route',
          description: 'Classic alpine trek from Chamonix to Zermatt',
          category: 'Hiking',
          imageUrl: '',
        ),
        CulturalHighlight(
          name: 'Matterhorn',
          description: 'Iconic pyramid-shaped mountain',
          category: 'Mountaineering',
          imageUrl: '',
        ),
      ],
      phrasebook: [
        Phrase(
          category: 'Greetings',
          english: 'Hello',
          translation: 'Grüezi (German)',
          pronunciation: 'grew-et-see',
        ),
        Phrase(
          category: 'Help',
          english: 'Help!',
          translation: 'Hilfe!',
          pronunciation: 'hil-feh',
        ),
        Phrase(
          category: 'Directions',
          english: 'Where is the train station?',
          translation: 'Wo ist der Bahnhof?',
          pronunciation: 'vo ist dair bahn-hof',
        ),
      ],
    ),
    Country(
      code: 'PE',
      name: 'Peru',
      flagEmoji: '🇵🇪',
      languages: ['Spanish', 'Quechua', 'Aymara'],
      currency: 'Peruvian Sol',
      currencySymbol: 'S/',
      exchangeRateToUSD: 3.75,
      timezone: 'PET (UTC-5)',
      visaRequirements: [
        'Visa-free for most countries up to 90-183 days',
        'Passport valid for 6 months',
        'Return ticket may be required',
      ],
      customs: [
        CustomTip(
          category: 'Etiquette',
          title: 'Greetings',
          description: 'Kiss on cheek common. Men shake hands',
          icon: '😊',
        ),
        CustomTip(
          category: 'Cultural',
          title: 'Altitude',
          description:
              'Acclimatize in Cusco before Machu Picchu. Coca tea helps',
          icon: '⛰️',
        ),
        CustomTip(
          category: 'Safety',
          title: 'Water',
          description: 'Drink only bottled water. Be careful with street food',
          icon: '💧',
        ),
      ],
      emergencyContacts: [
        EmergencyContact(
            type: 'Police', number: '105', name: 'Policía Nacional'),
        EmergencyContact(
            type: 'Medical', number: '116', name: 'SAMU Ambulance'),
        EmergencyContact(
            type: 'Tourist Police',
            number: '01-460-0921',
            name: 'Tourist Police'),
      ],
      highlights: [
        CulturalHighlight(
          name: 'Inca Trail',
          description: '4-day trek to Machu Picchu. Permits required',
          category: 'Hiking',
          imageUrl: '',
        ),
        CulturalHighlight(
          name: 'Machu Picchu',
          description: '15th-century Inca citadel in the clouds',
          category: 'Historical',
          imageUrl: '',
        ),
      ],
      phrasebook: [
        Phrase(
          category: 'Greetings',
          english: 'Hello',
          translation: 'Hola',
          pronunciation: 'oh-lah',
        ),
        Phrase(
          category: 'Help',
          english: 'Help!',
          translation: '¡Ayuda!',
          pronunciation: 'ah-yoo-dah',
        ),
        Phrase(
          category: 'Directions',
          english: 'Where is the bathroom?',
          translation: '¿Dónde está el baño?',
          pronunciation: 'don-deh es-tah el bahn-yo',
        ),
      ],
    ),
    Country(
      code: 'CL',
      name: 'Chile',
      flagEmoji: '🇨🇱',
      languages: ['Spanish'],
      currency: 'Chilean Peso',
      currencySymbol: '\$',
      exchangeRateToUSD: 895.0,
      timezone: 'CLT (UTC-3)',
      visaRequirements: [
        'Visa-free for many countries up to 90 days',
        'Reciprocity fee for some nationalities',
        'Passport valid for 6 months',
      ],
      customs: [
        CustomTip(
          category: 'Etiquette',
          title: 'Greetings',
          description:
              'Kiss on right cheek common. Even between men in informal settings',
          icon: '🤝',
        ),
        CustomTip(
          category: 'Cultural',
          title: 'Meal Times',
          description: 'Lunch 1-3 PM. Dinner late (9-10 PM)',
          icon: '🍽️',
        ),
        CustomTip(
          category: 'Environmental',
          title: 'Patagonia Rules',
          description: 'No fires except designated areas. Pack out all trash',
          icon: '🏕️',
        ),
      ],
      emergencyContacts: [
        EmergencyContact(type: 'Police', number: '133', name: 'Carabineros'),
        EmergencyContact(type: 'Medical', number: '131', name: 'SAMU'),
        EmergencyContact(type: 'Fire', number: '132', name: 'Bomberos'),
      ],
      highlights: [
        CulturalHighlight(
          name: 'Torres del Paine W Trek',
          description: '5-day circuit through Patagonian wilderness',
          category: 'Hiking',
          imageUrl: '',
        ),
        CulturalHighlight(
          name: 'Atacama Desert',
          description: 'Driest non-polar desert. Stargazing paradise',
          category: 'Nature',
          imageUrl: '',
        ),
      ],
      phrasebook: [
        Phrase(
          category: 'Greetings',
          english: 'Hello',
          translation: 'Hola',
          pronunciation: 'oh-lah',
        ),
        Phrase(
          category: 'Help',
          english: 'Help!',
          translation: '¡Ayuda!',
          pronunciation: 'ah-yoo-dah',
        ),
        Phrase(
          category: 'Common',
          english: 'Thank you',
          translation: 'Gracias',
          pronunciation: 'grah-see-ahs',
        ),
      ],
    ),
    Country(
      code: 'NO',
      name: 'Norway',
      flagEmoji: '🇳🇴',
      languages: ['Norwegian', 'English'],
      currency: 'Norwegian Krone',
      currencySymbol: 'kr',
      exchangeRateToUSD: 10.8,
      timezone: 'CET (UTC+1)',
      visaRequirements: [
        'Schengen visa rules apply',
        'Visa-free for many countries up to 90 days',
        'Passport valid for 3 months beyond stay',
      ],
      customs: [
        CustomTip(
          category: 'Cultural',
          title: 'Allemannsretten',
          description: 'Right to roam: camp anywhere wild for 2 nights',
          icon: '⛺',
        ),
        CustomTip(
          category: 'Environmental',
          title: 'Leave No Trace',
          description: 'Pack out all trash. Don\'t damage vegetation',
          icon: '🌲',
        ),
        CustomTip(
          category: 'Safety',
          title: 'Weather Prepared',
          description:
              'Weather changes rapidly in mountains. Always bring layers',
          icon: '🧥',
        ),
      ],
      emergencyContacts: [
        EmergencyContact(
            type: 'Police', number: '112', name: 'Norwegian Police'),
        EmergencyContact(type: 'Medical', number: '113', name: 'Ambulance'),
        EmergencyContact(
            type: 'Search & Rescue', number: '120', name: 'Red Cross Rescue'),
      ],
      highlights: [
        CulturalHighlight(
          name: 'Preikestolen (Pulpit Rock)',
          description: '604m cliff overlooking Lysefjord',
          category: 'Hiking',
          imageUrl: '',
        ),
        CulturalHighlight(
          name: 'Trolltunga',
          description: 'Spectacular rock formation 1100m above sea',
          category: 'Adventure',
          imageUrl: '',
        ),
      ],
      phrasebook: [
        Phrase(
          category: 'Greetings',
          english: 'Hello',
          translation: 'Hei',
          pronunciation: 'hay',
        ),
        Phrase(
          category: 'Help',
          english: 'Help!',
          translation: 'Hjelp!',
          pronunciation: 'yelp',
        ),
        Phrase(
          category: 'Common',
          english: 'Thank you',
          translation: 'Takk',
          pronunciation: 'tahk',
        ),
      ],
    ),
    Country(
      code: 'CA',
      name: 'Canada',
      flagEmoji: '🇨🇦',
      languages: ['English', 'French'],
      currency: 'Canadian Dollar',
      currencySymbol: 'CA\$',
      exchangeRateToUSD: 1.35,
      timezone: 'Multiple zones (UTC-3.5 to UTC-8)',
      visaRequirements: [
        'eTA required for visa-exempt travelers',
        'Fee: CA\$7, valid 5 years',
        'Some nationalities require visa',
      ],
      customs: [
        CustomTip(
          category: 'Etiquette',
          title: 'Politeness',
          description: 'Canadians say "sorry" often. Very polite culture',
          icon: '🙏',
        ),
        CustomTip(
          category: 'Wildlife',
          title: 'Bear Safety',
          description: 'Carry bear spray in wilderness. Make noise on trails',
          icon: '🐻',
        ),
        CustomTip(
          category: 'Cultural',
          title: 'Tipping',
          description: '15-20% at restaurants. Similar to US customs',
          icon: '💵',
        ),
      ],
      emergencyContacts: [
        EmergencyContact(type: 'Police', number: '911', name: 'Police'),
        EmergencyContact(
            type: 'Medical', number: '911', name: 'Emergency Services'),
        EmergencyContact(
            type: 'Parks', number: '1-888-773-8888', name: 'Parks Canada'),
      ],
      highlights: [
        CulturalHighlight(
          name: 'West Coast Trail',
          description: '75km challenging coastal trail in BC',
          category: 'Hiking',
          imageUrl: '',
        ),
        CulturalHighlight(
          name: 'Canadian Rockies',
          description: 'Banff, Jasper, Lake Louise - iconic mountain scenery',
          category: 'Nature',
          imageUrl: '',
        ),
      ],
      phrasebook: [
        Phrase(
          category: 'Greetings',
          english: 'Hello',
          translation: 'Hello / Bonjour',
          pronunciation: 'heh-loh / bon-zhoor',
        ),
        Phrase(
          category: 'Help',
          english: 'Help!',
          translation: 'Help! / À l\'aide!',
          pronunciation: 'help / ah led',
        ),
        Phrase(
          category: 'Common',
          english: 'Sorry',
          translation: 'Sorry',
          pronunciation: 'soh-ree',
        ),
      ],
    ),
    Country(
      code: 'BT',
      name: 'Bhutan',
      flagEmoji: '🇧🇹',
      languages: ['Dzongkha', 'English'],
      currency: 'Bhutanese Ngultrum',
      currencySymbol: 'Nu.',
      exchangeRateToUSD: 83.5,
      timezone: 'BTT (UTC+6)',
      visaRequirements: [
        'All tourists except Indians need visa',
        'Must book through licensed tour operator',
        'Sustainable Development Fee: \$100/day',
      ],
      customs: [
        CustomTip(
          category: 'Religious',
          title: 'Buddhist Etiquette',
          description: 'Walk clockwise around monasteries. Remove shoes',
          icon: '☸️',
        ),
        CustomTip(
          category: 'Cultural',
          title: 'Dress Code',
          description: 'Modest dress. Locals wear traditional dress',
          icon: '👔',
        ),
        CustomTip(
          category: 'Environmental',
          title: 'No Plastic',
          description: 'Plastic bags banned. Very eco-conscious country',
          icon: '♻️',
        ),
      ],
      emergencyContacts: [
        EmergencyContact(type: 'Police', number: '113', name: 'Bhutan Police'),
        EmergencyContact(
            type: 'Medical', number: '112', name: 'Emergency Services'),
        EmergencyContact(type: 'Fire', number: '110', name: 'Fire Service'),
      ],
      highlights: [
        CulturalHighlight(
          name: 'Tiger\'s Nest Monastery',
          description: 'Iconic monastery clinging to cliff at 3120m',
          category: 'Cultural',
          imageUrl: '',
        ),
        CulturalHighlight(
          name: 'Jomolhari Trek',
          description: 'Spectacular high-altitude trek beneath sacred peak',
          category: 'Hiking',
          imageUrl: '',
        ),
      ],
      phrasebook: [
        Phrase(
          category: 'Greetings',
          english: 'Hello',
          translation: 'Kuzu zangpo',
          pronunciation: 'koo-zoo zang-po',
        ),
        Phrase(
          category: 'Help',
          english: 'Help!',
          translation: 'Rogé!',
          pronunciation: 'ro-gay',
        ),
        Phrase(
          category: 'Common',
          english: 'Thank you',
          translation: 'Kadrin che',
          pronunciation: 'kad-reen cheh',
        ),
      ],
    ),
    Country(
      code: 'TZ',
      name: 'Tanzania',
      flagEmoji: '🇹🇿',
      languages: ['Swahili', 'English'],
      currency: 'Tanzanian Shilling',
      currencySymbol: 'TSh',
      exchangeRateToUSD: 2650.0,
      timezone: 'EAT (UTC+3)',
      visaRequirements: [
        'E-visa available for most nationalities',
        'Fee: \$50-100 depending on nationality',
        'Passport valid for 6 months',
      ],
      customs: [
        CustomTip(
          category: 'Etiquette',
          title: 'Greetings',
          description: 'Handshakes common. Use right hand only',
          icon: '🤝',
        ),
        CustomTip(
          category: 'Cultural',
          title: 'Jambo vs Mambo',
          description: 'Jambo for tourists. Locals say "Mambo" or "Habari"',
          icon: '👋',
        ),
        CustomTip(
          category: 'Wildlife',
          title: 'Safari Rules',
          description: 'Stay in vehicle. Don\'t stand up. Respect animal space',
          icon: '🦁',
        ),
      ],
      emergencyContacts: [
        EmergencyContact(type: 'Police', number: '112', name: 'Police'),
        EmergencyContact(type: 'Medical', number: '114', name: 'Ambulance'),
        EmergencyContact(type: 'Fire', number: '115', name: 'Fire Services'),
      ],
      highlights: [
        CulturalHighlight(
          name: 'Mount Kilimanjaro',
          description: 'Africa\'s highest peak at 5895m. Multiple routes',
          category: 'Mountaineering',
          imageUrl: '',
        ),
        CulturalHighlight(
          name: 'Serengeti Safari',
          description: 'Witness the Great Migration. Big Five country',
          category: 'Wildlife',
          imageUrl: '',
        ),
      ],
      phrasebook: [
        Phrase(
          category: 'Greetings',
          english: 'Hello',
          translation: 'Habari',
          pronunciation: 'hah-bah-ree',
        ),
        Phrase(
          category: 'Help',
          english: 'Help!',
          translation: 'Saidia!',
          pronunciation: 'sah-ee-dee-ah',
        ),
        Phrase(
          category: 'Common',
          english: 'Thank you',
          translation: 'Asante',
          pronunciation: 'ah-sahn-teh',
        ),
      ],
    ),
  ];

  Future<List<Country>> getAllCountries() async {
    try {
      final box = await Hive.openBox(_cacheBoxName);
      final cached = box.get('all_countries');

      if (cached != null) {
        final List<dynamic> data = json.decode(cached);
        return data.map((c) => Country.fromJson(c)).toList();
      }

      // Cache the predefined data
      await _cacheCountries(_countries);
      return _countries;
    } catch (e) {
      return _countries;
    }
  }

  Future<Country?> getCountryByCode(String code) async {
    final countries = await getAllCountries();
    try {
      return countries.firstWhere((c) => c.code == code);
    } catch (e) {
      return null;
    }
  }

  Future<List<Country>> searchCountries(String query) async {
    final countries = await getAllCountries();
    final lowerQuery = query.toLowerCase();
    return countries
        .where((c) =>
            c.name.toLowerCase().contains(lowerQuery) ||
            c.code.toLowerCase().contains(lowerQuery))
        .toList();
  }

  Future<void> _cacheCountries(List<Country> countries) async {
    try {
      final box = await Hive.openBox(_cacheBoxName);
      final data = json.encode(countries.map((c) => c.toJson()).toList());
      await box.put('all_countries', data);
    } catch (e) {
      // Ignore cache errors
    }
  }

  // Currency conversion
  double convertCurrency(double amount, String fromCode, String toCode) {
    // This is a simplified version. In production, use real exchange rates
    // For now, just return the amount
    return amount;
  }

  // Phrasebook utilities
  Future<List<Phrase>> getPhrasesByCategory(
      String countryCode, String category) async {
    final country = await getCountryByCode(countryCode);
    if (country == null) return [];

    return country.phrasebook.where((p) => p.category == category).toList();
  }

  List<String> getPhraseCategories(Country country) {
    return country.phrasebook.map((p) => p.category).toSet().toList();
  }
}
