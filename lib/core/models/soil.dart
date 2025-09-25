class DetailedSoilType {
  final String id;
  final String name;
  final String description;
  final String color;
  final List<String> characteristics;
  final List<String> suitableCrops;
  final double phRange;
  final String fertility;
  final String drainage;
  final String texture;

  const DetailedSoilType({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.characteristics,
    required this.suitableCrops,
    required this.phRange,
    required this.fertility,
    required this.drainage,
    required this.texture,
  });

  factory DetailedSoilType.fromJson(Map<String, dynamic> json) {
    return DetailedSoilType(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      color: json['color'] ?? '#8B4513',
      characteristics: List<String>.from(json['characteristics'] ?? []),
      suitableCrops: List<String>.from(json['suitable_crops'] ?? []),
      phRange: (json['ph_range'] ?? 7.0).toDouble(),
      fertility: json['fertility'] ?? 'Medium',
      drainage: json['drainage'] ?? 'Good',
      texture: json['texture'] ?? 'Loamy',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'characteristics': characteristics,
      'suitable_crops': suitableCrops,
      'ph_range': phRange,
      'fertility': fertility,
      'drainage': drainage,
      'texture': texture,
    };
  }
}

class SoilAnalysis {
  final String id;
  final double latitude;
  final double longitude;
  final String location;
  final DetailedSoilType soilType;
  final DateTime analyzedAt;
  final Map<String, dynamic> additionalData;

  const SoilAnalysis({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.location,
    required this.soilType,
    required this.analyzedAt,
    this.additionalData = const {},
  });

  factory SoilAnalysis.fromJson(Map<String, dynamic> json) {
    return SoilAnalysis(
      id: json['id'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      location: json['location'] ?? '',
      soilType: DetailedSoilType.fromJson(json['soil_type'] ?? {}),
      analyzedAt: DateTime.parse(
        json['analyzed_at'] ?? DateTime.now().toIso8601String(),
      ),
      additionalData: Map<String, dynamic>.from(json['additional_data'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'location': location,
      'soil_type': soilType.toJson(),
      'analyzed_at': analyzedAt.toIso8601String(),
      'additional_data': additionalData,
    };
  }
}

// Predefined soil types common in India
class DetailedSoilTypes {
  static const alluvial = DetailedSoilType(
    id: 'alluvial',
    name: 'Alluvial Soil',
    description:
        'Fertile soil formed by river deposits, excellent for agriculture',
    color: '#D2B48C',
    characteristics: [
      'Rich in potash and phosphoric acid',
      'Poor in nitrogen and humus',
      'Fine-grained and fertile',
      'Good water retention',
    ],
    suitableCrops: [
      'Rice',
      'Wheat',
      'Sugarcane',
      'Cotton',
      'Jute',
      'Maize',
      'Pulses',
    ],
    phRange: 6.5,
    fertility: 'High',
    drainage: 'Good',
    texture: 'Sandy loam to clay loam',
  );

  static const black = DetailedSoilType(
    id: 'black',
    name: 'Black Soil (Regur)',
    description: 'Cotton soil, rich in lime, iron, magnesia and alumina',
    color: '#2F2F2F',
    characteristics: [
      'High clay content',
      'Rich in calcium and magnesium',
      'Good moisture retention',
      'Swells when wet, shrinks when dry',
    ],
    suitableCrops: [
      'Cotton',
      'Wheat',
      'Jowar',
      'Linseed',
      'Virginia tobacco',
      'Castor',
      'Sunflower',
    ],
    phRange: 7.8,
    fertility: 'High',
    drainage: 'Poor',
    texture: 'Clay',
  );

  static const red = DetailedSoilType(
    id: 'red',
    name: 'Red Soil',
    description: 'Formed by weathering of ancient crystalline rocks',
    color: '#CD853F',
    characteristics: [
      'Rich in iron oxide',
      'Porous and friable',
      'Less fertile in upper layers',
      'More fertile in lower layers',
    ],
    suitableCrops: [
      'Rice',
      'Wheat',
      'Sugarcane',
      'Pulses',
      'Millets',
      'Tobacco',
      'Oil seeds',
    ],
    phRange: 6.2,
    fertility: 'Medium',
    drainage: 'Good',
    texture: 'Sandy to clay',
  );

  static const laterite = DetailedSoilType(
    id: 'laterite',
    name: 'Laterite Soil',
    description: 'Formed in areas with high temperature and heavy rainfall',
    color: '#B22222',
    characteristics: [
      'Rich in iron and aluminum',
      'Poor in nitrogen, phosphorus, and potassium',
      'Well-drained but low fertility',
      'Hard when dry',
    ],
    suitableCrops: ['Rice', 'Ragi', 'Cashew', 'Rubber', 'Tea', 'Coffee'],
    phRange: 5.5,
    fertility: 'Low',
    drainage: 'Excellent',
    texture: 'Clay with lateritic nodules',
  );

  static const desert = DetailedSoilType(
    id: 'desert',
    name: 'Desert Soil',
    description: 'Arid soil with low water retention capacity',
    color: '#F4A460',
    characteristics: [
      'Low organic matter',
      'High salt content',
      'Sandy texture',
      'Poor water retention',
    ],
    suitableCrops: [
      'Bajra',
      'Pulses',
      'Barley',
      'Wheat (with irrigation)',
      'Mustard',
    ],
    phRange: 8.2,
    fertility: 'Low',
    drainage: 'Excessive',
    texture: 'Sandy',
  );

  static const mountain = DetailedSoilType(
    id: 'mountain',
    name: 'Mountain Soil',
    description: 'Forest soil found in mountainous regions',
    color: '#8FBC8F',
    characteristics: [
      'Rich in organic matter',
      'Acidic in nature',
      'Shallow depth',
      'Prone to erosion',
    ],
    suitableCrops: [
      'Tea',
      'Coffee',
      'Spices',
      'Tropical fruits',
      'Forest products',
    ],
    phRange: 5.8,
    fertility: 'Medium',
    drainage: 'Good',
    texture: 'Loamy',
  );

  static List<DetailedSoilType> get all => [
    alluvial,
    black,
    red,
    laterite,
    desert,
    mountain,
  ];

  static DetailedSoilType? getById(String id) {
    try {
      return all.firstWhere((soil) => soil.id == id);
    } catch (e) {
      return null;
    }
  }
}
