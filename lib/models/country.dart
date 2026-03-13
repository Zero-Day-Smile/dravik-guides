// Country & Culture Explorer Model
class Country {
  final String code; // ISO 3166-1 alpha-2
  final String name;
  final String flagEmoji;
  final List<String> languages;
  final String currency;
  final String currencySymbol;
  final double exchangeRateToUSD;
  final String timezone;
  final List<String> visaRequirements;
  final List<CustomTip> customs;
  final List<EmergencyContact> emergencyContacts;
  final List<CulturalHighlight> highlights;
  final List<Phrase> phrasebook;

  Country({
    required this.code,
    required this.name,
    required this.flagEmoji,
    required this.languages,
    required this.currency,
    required this.currencySymbol,
    required this.exchangeRateToUSD,
    required this.timezone,
    required this.visaRequirements,
    required this.customs,
    required this.emergencyContacts,
    required this.highlights,
    required this.phrasebook,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      flagEmoji: json['flagEmoji'] ?? '',
      languages: List<String>.from(json['languages'] ?? []),
      currency: json['currency'] ?? '',
      currencySymbol: json['currencySymbol'] ?? '',
      exchangeRateToUSD: (json['exchangeRateToUSD'] ?? 1.0).toDouble(),
      timezone: json['timezone'] ?? '',
      visaRequirements: List<String>.from(json['visaRequirements'] ?? []),
      customs: (json['customs'] as List?)
              ?.map((e) => CustomTip.fromJson(e))
              .toList() ??
          [],
      emergencyContacts: (json['emergencyContacts'] as List?)
              ?.map((e) => EmergencyContact.fromJson(e))
              .toList() ??
          [],
      highlights: (json['highlights'] as List?)
              ?.map((e) => CulturalHighlight.fromJson(e))
              .toList() ??
          [],
      phrasebook: (json['phrasebook'] as List?)
              ?.map((e) => Phrase.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'flagEmoji': flagEmoji,
      'languages': languages,
      'currency': currency,
      'currencySymbol': currencySymbol,
      'exchangeRateToUSD': exchangeRateToUSD,
      'timezone': timezone,
      'visaRequirements': visaRequirements,
      'customs': customs.map((e) => e.toJson()).toList(),
      'emergencyContacts': emergencyContacts.map((e) => e.toJson()).toList(),
      'highlights': highlights.map((e) => e.toJson()).toList(),
      'phrasebook': phrasebook.map((e) => e.toJson()).toList(),
    };
  }
}

class CustomTip {
  final String category; // etiquette, laws, photography, etc.
  final String title;
  final String description;
  final String icon;

  CustomTip({
    required this.category,
    required this.title,
    required this.description,
    required this.icon,
  });

  factory CustomTip.fromJson(Map<String, dynamic> json) {
    return CustomTip(
      category: json['category'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '📝',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'title': title,
      'description': description,
      'icon': icon,
    };
  }
}

class EmergencyContact {
  final String type; // police, medical, fire, embassy
  final String number;
  final String name;

  EmergencyContact({
    required this.type,
    required this.number,
    required this.name,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      type: json['type'] ?? '',
      number: json['number'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'number': number,
      'name': name,
    };
  }
}

class CulturalHighlight {
  final String name;
  final String description;
  final String category; // heritage, festival, food
  final String imageUrl;

  CulturalHighlight({
    required this.name,
    required this.description,
    required this.category,
    required this.imageUrl,
  });

  factory CulturalHighlight.fromJson(Map<String, dynamic> json) {
    return CulturalHighlight(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
    };
  }
}

class Phrase {
  final String category; // greetings, help, directions, etc.
  final String english;
  final String translation;
  final String pronunciation;
  final String audioUrl;

  Phrase({
    required this.category,
    required this.english,
    required this.translation,
    required this.pronunciation,
    this.audioUrl = '',
  });

  factory Phrase.fromJson(Map<String, dynamic> json) {
    return Phrase(
      category: json['category'] ?? '',
      english: json['english'] ?? '',
      translation: json['translation'] ?? '',
      pronunciation: json['pronunciation'] ?? '',
      audioUrl: json['audioUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'english': english,
      'translation': translation,
      'pronunciation': pronunciation,
      'audioUrl': audioUrl,
    };
  }
}
