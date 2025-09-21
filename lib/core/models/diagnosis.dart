import 'package:cloud_firestore/cloud_firestore.dart';

class Diagnosis {
  final String id;
  final String userId;
  final String farmId;
  final String imageUrl;
  final String cropType;
  final DiagnosisResult result;
  final double confidenceScore;
  final List<Treatment> recommendedTreatments;
  final DateTime createdAt;
  final DiagnosisStatus status;

  Diagnosis({
    required this.id,
    required this.userId,
    required this.farmId,
    required this.imageUrl,
    required this.cropType,
    required this.result,
    required this.confidenceScore,
    this.recommendedTreatments = const [],
    required this.createdAt,
    this.status = DiagnosisStatus.pending,
  });

  factory Diagnosis.fromMap(Map<String, dynamic> map) {
    return Diagnosis(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      farmId: map['farmId'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      cropType: map['cropType'] ?? '',
      result: DiagnosisResult.fromMap(map['result'] ?? {}),
      confidenceScore: map['confidenceScore']?.toDouble() ?? 0.0,
      recommendedTreatments:
          (map['recommendedTreatments'] as List?)
              ?.map((item) => Treatment.fromMap(item))
              .toList() ??
          [],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: DiagnosisStatus.values.firstWhere(
        (e) => e.toString() == 'DiagnosisStatus.${map['status']}',
        orElse: () => DiagnosisStatus.pending,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'farmId': farmId,
      'imageUrl': imageUrl,
      'cropType': cropType,
      'result': result.toMap(),
      'confidenceScore': confidenceScore,
      'recommendedTreatments': recommendedTreatments
          .map((t) => t.toMap())
          .toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.toString().split('.').last,
    };
  }
}

class DiagnosisResult {
  final String condition;
  final ConditionType type;
  final String description;
  final SeverityLevel severity;

  DiagnosisResult({
    required this.condition,
    required this.type,
    required this.description,
    required this.severity,
  });

  factory DiagnosisResult.fromMap(Map<String, dynamic> map) {
    return DiagnosisResult(
      condition: map['condition'] ?? '',
      type: ConditionType.values.firstWhere(
        (e) => e.toString() == 'ConditionType.${map['type']}',
        orElse: () => ConditionType.unknown,
      ),
      description: map['description'] ?? '',
      severity: SeverityLevel.values.firstWhere(
        (e) => e.toString() == 'SeverityLevel.${map['severity']}',
        orElse: () => SeverityLevel.mild,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'condition': condition,
      'type': type.toString().split('.').last,
      'description': description,
      'severity': severity.toString().split('.').last,
    };
  }
}

class Treatment {
  final String id;
  final String name;
  final TreatmentType type;
  final String description;
  final List<String> instructions;
  final String? dosage;
  final List<String> precautions;

  Treatment({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    this.instructions = const [],
    this.dosage,
    this.precautions = const [],
  });

  factory Treatment.fromMap(Map<String, dynamic> map) {
    return Treatment(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: TreatmentType.values.firstWhere(
        (e) => e.toString() == 'TreatmentType.${map['type']}',
        orElse: () => TreatmentType.organic,
      ),
      description: map['description'] ?? '',
      instructions: List<String>.from(map['instructions'] ?? []),
      dosage: map['dosage'],
      precautions: List<String>.from(map['precautions'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'description': description,
      'instructions': instructions,
      'dosage': dosage,
      'precautions': precautions,
    };
  }
}

enum DiagnosisStatus { pending, processing, completed, failed }

enum ConditionType { disease, pest, nutrientDeficiency, healthy, unknown }

enum SeverityLevel { mild, moderate, severe, critical }

enum TreatmentType { organic, chemical, preventive, cultural }
