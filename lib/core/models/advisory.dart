import 'package:geolocator/geolocator.dart';

/// Crop Advisory Model
class CropAdvisory {
  final String id;
  final String cropName;
  final String location;
  final double latitude;
  final double longitude;
  final String season;
  final DateTime advisoryDate;
  final String stage; // Sowing, Growing, Harvesting
  final List<AdvisoryRecommendation> recommendations;
  final WeatherImpact weatherImpact;
  final SoilHealthAdvice soilAdvice;
  final PestDiseaseAlert? pestAlert;
  final double confidenceScore;

  const CropAdvisory({
    required this.id,
    required this.cropName,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.season,
    required this.advisoryDate,
    required this.stage,
    required this.recommendations,
    required this.weatherImpact,
    required this.soilAdvice,
    this.pestAlert,
    required this.confidenceScore,
  });

  factory CropAdvisory.fromJson(Map<String, dynamic> json) {
    return CropAdvisory(
      id: json['id'] ?? '',
      cropName: json['crop_name'] ?? '',
      location: json['location'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      season: json['season'] ?? '',
      advisoryDate: DateTime.parse(
        json['advisory_date'] ?? DateTime.now().toIso8601String(),
      ),
      stage: json['stage'] ?? 'Growing',
      recommendations: (json['recommendations'] as List? ?? [])
          .map((r) => AdvisoryRecommendation.fromJson(r))
          .toList(),
      weatherImpact: WeatherImpact.fromJson(json['weather_impact'] ?? {}),
      soilAdvice: SoilHealthAdvice.fromJson(json['soil_advice'] ?? {}),
      pestAlert: json['pest_alert'] != null
          ? PestDiseaseAlert.fromJson(json['pest_alert'])
          : null,
      confidenceScore: (json['confidence_score'] ?? 0.8).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'crop_name': cropName,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'season': season,
      'advisory_date': advisoryDate.toIso8601String(),
      'stage': stage,
      'recommendations': recommendations.map((r) => r.toJson()).toList(),
      'weather_impact': weatherImpact.toJson(),
      'soil_advice': soilAdvice.toJson(),
      'pest_alert': pestAlert?.toJson(),
      'confidence_score': confidenceScore,
    };
  }
}

/// Advisory Recommendation
class AdvisoryRecommendation {
  final String id;
  final String type; // Irrigation, Fertilizer, Pesticide, General
  final String title;
  final String description;
  final String priority; // High, Medium, Low
  final String actionRequired;
  final DateTime? deadline;
  final List<String> materials;
  final String dosage;
  final List<String> precautions;

  const AdvisoryRecommendation({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.priority,
    required this.actionRequired,
    this.deadline,
    this.materials = const [],
    this.dosage = '',
    this.precautions = const [],
  });

  factory AdvisoryRecommendation.fromJson(Map<String, dynamic> json) {
    return AdvisoryRecommendation(
      id: json['id'] ?? '',
      type: json['type'] ?? 'General',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      priority: json['priority'] ?? 'Medium',
      actionRequired: json['action_required'] ?? '',
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'])
          : null,
      materials: List<String>.from(json['materials'] ?? []),
      dosage: json['dosage'] ?? '',
      precautions: List<String>.from(json['precautions'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'priority': priority,
      'action_required': actionRequired,
      'deadline': deadline?.toIso8601String(),
      'materials': materials,
      'dosage': dosage,
      'precautions': precautions,
    };
  }
}

/// Weather Impact Analysis
class WeatherImpact {
  final String condition; // Favorable, Warning, Critical
  final String description;
  final List<String> impacts;
  final List<String> recommendations;
  final double riskLevel; // 0.0 to 1.0
  final String nextAction;

  const WeatherImpact({
    required this.condition,
    required this.description,
    required this.impacts,
    required this.recommendations,
    required this.riskLevel,
    required this.nextAction,
  });

  factory WeatherImpact.fromJson(Map<String, dynamic> json) {
    return WeatherImpact(
      condition: json['condition'] ?? 'Favorable',
      description: json['description'] ?? '',
      impacts: List<String>.from(json['impacts'] ?? []),
      recommendations: List<String>.from(json['recommendations'] ?? []),
      riskLevel: (json['risk_level'] ?? 0.0).toDouble(),
      nextAction: json['next_action'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'condition': condition,
      'description': description,
      'impacts': impacts,
      'recommendations': recommendations,
      'risk_level': riskLevel,
      'next_action': nextAction,
    };
  }
}

/// Soil Health Advice
class SoilHealthAdvice {
  final String healthStatus; // Excellent, Good, Fair, Poor
  final double phLevel;
  final String organicMatter; // High, Medium, Low
  final String nitrogen; // High, Medium, Low
  final String phosphorus; // High, Medium, Low
  final String potassium; // High, Medium, Low
  final List<FertilizerRecommendation> fertilizerRecommendations;
  final List<String> improvementTips;
  final String nextTestDate;

  const SoilHealthAdvice({
    required this.healthStatus,
    required this.phLevel,
    required this.organicMatter,
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
    required this.fertilizerRecommendations,
    required this.improvementTips,
    required this.nextTestDate,
  });

  factory SoilHealthAdvice.fromJson(Map<String, dynamic> json) {
    return SoilHealthAdvice(
      healthStatus: json['health_status'] ?? 'Good',
      phLevel: (json['ph_level'] ?? 7.0).toDouble(),
      organicMatter: json['organic_matter'] ?? 'Medium',
      nitrogen: json['nitrogen'] ?? 'Medium',
      phosphorus: json['phosphorus'] ?? 'Medium',
      potassium: json['potassium'] ?? 'Medium',
      fertilizerRecommendations:
          (json['fertilizer_recommendations'] as List? ?? [])
              .map((f) => FertilizerRecommendation.fromJson(f))
              .toList(),
      improvementTips: List<String>.from(json['improvement_tips'] ?? []),
      nextTestDate: json['next_test_date'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'health_status': healthStatus,
      'ph_level': phLevel,
      'organic_matter': organicMatter,
      'nitrogen': nitrogen,
      'phosphorus': phosphorus,
      'potassium': potassium,
      'fertilizer_recommendations': fertilizerRecommendations
          .map((f) => f.toJson())
          .toList(),
      'improvement_tips': improvementTips,
      'next_test_date': nextTestDate,
    };
  }
}

/// Fertilizer Recommendation
class FertilizerRecommendation {
  final String name;
  final String type; // Organic, Inorganic, Bio-fertilizer
  final String dosage;
  final String applicationMethod;
  final String timing;
  final double estimatedCost;
  final List<String> benefits;
  final List<String> precautions;

  const FertilizerRecommendation({
    required this.name,
    required this.type,
    required this.dosage,
    required this.applicationMethod,
    required this.timing,
    required this.estimatedCost,
    required this.benefits,
    required this.precautions,
  });

  factory FertilizerRecommendation.fromJson(Map<String, dynamic> json) {
    return FertilizerRecommendation(
      name: json['name'] ?? '',
      type: json['type'] ?? 'Organic',
      dosage: json['dosage'] ?? '',
      applicationMethod: json['application_method'] ?? '',
      timing: json['timing'] ?? '',
      estimatedCost: (json['estimated_cost'] ?? 0.0).toDouble(),
      benefits: List<String>.from(json['benefits'] ?? []),
      precautions: List<String>.from(json['precautions'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'dosage': dosage,
      'application_method': applicationMethod,
      'timing': timing,
      'estimated_cost': estimatedCost,
      'benefits': benefits,
      'precautions': precautions,
    };
  }
}

/// Pest/Disease Alert
class PestDiseaseAlert {
  final String id;
  final String type; // Pest, Disease, Nutrient Deficiency
  final String name;
  final String severity; // Low, Medium, High, Critical
  final String description;
  final List<String> symptoms;
  final List<String> causes;
  final List<TreatmentOption> treatments;
  final List<String> preventionMethods;
  final String imageUrl;
  final double confidenceLevel;

  const PestDiseaseAlert({
    required this.id,
    required this.type,
    required this.name,
    required this.severity,
    required this.description,
    required this.symptoms,
    required this.causes,
    required this.treatments,
    required this.preventionMethods,
    this.imageUrl = '',
    required this.confidenceLevel,
  });

  factory PestDiseaseAlert.fromJson(Map<String, dynamic> json) {
    return PestDiseaseAlert(
      id: json['id'] ?? '',
      type: json['type'] ?? 'Disease',
      name: json['name'] ?? '',
      severity: json['severity'] ?? 'Medium',
      description: json['description'] ?? '',
      symptoms: List<String>.from(json['symptoms'] ?? []),
      causes: List<String>.from(json['causes'] ?? []),
      treatments: (json['treatments'] as List? ?? [])
          .map((t) => TreatmentOption.fromJson(t))
          .toList(),
      preventionMethods: List<String>.from(json['prevention_methods'] ?? []),
      imageUrl: json['image_url'] ?? '',
      confidenceLevel: (json['confidence_level'] ?? 0.8).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'severity': severity,
      'description': description,
      'symptoms': symptoms,
      'causes': causes,
      'treatments': treatments.map((t) => t.toJson()).toList(),
      'prevention_methods': preventionMethods,
      'image_url': imageUrl,
      'confidence_level': confidenceLevel,
    };
  }
}

/// Treatment Option
class TreatmentOption {
  final String name;
  final String type; // Chemical, Organic, Biological, Cultural
  final String description;
  final String dosage;
  final String applicationMethod;
  final int applicationFrequency; // days
  final double effectivenessScore;
  final double estimatedCost;
  final List<String> materials;
  final List<String> precautions;

  const TreatmentOption({
    required this.name,
    required this.type,
    required this.description,
    required this.dosage,
    required this.applicationMethod,
    required this.applicationFrequency,
    required this.effectivenessScore,
    required this.estimatedCost,
    required this.materials,
    required this.precautions,
  });

  factory TreatmentOption.fromJson(Map<String, dynamic> json) {
    return TreatmentOption(
      name: json['name'] ?? '',
      type: json['type'] ?? 'Organic',
      description: json['description'] ?? '',
      dosage: json['dosage'] ?? '',
      applicationMethod: json['application_method'] ?? '',
      applicationFrequency: json['application_frequency'] ?? 7,
      effectivenessScore: (json['effectiveness_score'] ?? 0.8).toDouble(),
      estimatedCost: (json['estimated_cost'] ?? 0.0).toDouble(),
      materials: List<String>.from(json['materials'] ?? []),
      precautions: List<String>.from(json['precautions'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'description': description,
      'dosage': dosage,
      'application_method': applicationMethod,
      'application_frequency': applicationFrequency,
      'effectiveness_score': effectivenessScore,
      'estimated_cost': estimatedCost,
      'materials': materials,
      'precautions': precautions,
    };
  }
}

/// User Feedback Model
class UserFeedback {
  final String id;
  final String userId;
  final String featureUsed;
  final int rating; // 1-5 stars
  final String comments;
  final DateTime submittedAt;
  final Map<String, dynamic> usageData;
  final String category; // Bug Report, Feature Request, General Feedback

  const UserFeedback({
    required this.id,
    required this.userId,
    required this.featureUsed,
    required this.rating,
    required this.comments,
    required this.submittedAt,
    this.usageData = const {},
    required this.category,
  });

  factory UserFeedback.fromJson(Map<String, dynamic> json) {
    return UserFeedback(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      featureUsed: json['feature_used'] ?? '',
      rating: json['rating'] ?? 5,
      comments: json['comments'] ?? '',
      submittedAt: DateTime.parse(
        json['submitted_at'] ?? DateTime.now().toIso8601String(),
      ),
      usageData: Map<String, dynamic>.from(json['usage_data'] ?? {}),
      category: json['category'] ?? 'General Feedback',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'feature_used': featureUsed,
      'rating': rating,
      'comments': comments,
      'submitted_at': submittedAt.toIso8601String(),
      'usage_data': usageData,
      'category': category,
    };
  }
}
