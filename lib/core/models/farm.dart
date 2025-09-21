import 'package:cloud_firestore/cloud_firestore.dart';

class Farm {
  final String id;
  final String userId;
  final String name;
  final double? sizeInAcres;
  final FarmLocation location;
  final SoilType? soilType;
  final List<String> primaryCrops;
  final DateTime createdAt;
  final DateTime? lastUpdated;

  Farm({
    required this.id,
    required this.userId,
    required this.name,
    this.sizeInAcres,
    required this.location,
    this.soilType,
    this.primaryCrops = const [],
    required this.createdAt,
    this.lastUpdated,
  });

  factory Farm.fromMap(Map<String, dynamic> map) {
    return Farm(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      sizeInAcres: map['sizeInAcres']?.toDouble(),
      location: FarmLocation.fromMap(map['location'] ?? {}),
      soilType: map['soilType'] != null
          ? SoilType.values.firstWhere(
              (e) => e.toString() == 'SoilType.${map['soilType']}',
              orElse: () => SoilType.unknown,
            )
          : null,
      primaryCrops: List<String>.from(map['primaryCrops'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'sizeInAcres': sizeInAcres,
      'location': location.toMap(),
      'soilType': soilType?.toString().split('.').last,
      'primaryCrops': primaryCrops,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdated': lastUpdated != null
          ? Timestamp.fromDate(lastUpdated!)
          : null,
    };
  }
}

class FarmLocation {
  final double latitude;
  final double longitude;
  final String? address;
  final String? region;

  FarmLocation({
    required this.latitude,
    required this.longitude,
    this.address,
    this.region,
  });

  factory FarmLocation.fromMap(Map<String, dynamic> map) {
    return FarmLocation(
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      address: map['address'],
      region: map['region'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'region': region,
    };
  }
}

enum SoilType { clay, sandy, loamy, silt, peat, chalk, unknown }

extension SoilTypeExtension on SoilType {
  String get displayName {
    switch (this) {
      case SoilType.clay:
        return 'Clay Soil';
      case SoilType.sandy:
        return 'Sandy Soil';
      case SoilType.loamy:
        return 'Loamy Soil';
      case SoilType.silt:
        return 'Silt Soil';
      case SoilType.peat:
        return 'Peat Soil';
      case SoilType.chalk:
        return 'Chalk Soil';
      case SoilType.unknown:
        return 'Unknown';
    }
  }
}
