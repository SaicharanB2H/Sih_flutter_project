import 'dart:convert';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../models/advisory.dart';
import '../models/weather.dart';
import '../models/soil.dart';
import '../models/user.dart';

class CropAdvisoryService {
  static const String _tag = 'CropAdvisoryService';

  // Mock API endpoints - in production, these would be real AI services
  static const String _advisoryApiUrl = 'https://api.agri-ai.com/advisory';
  static const String _weatherApiUrl =
      'https://api.openweathermap.org/data/2.5';
  static const String _soilApiUrl = 'https://api.soilgrids.org/rest/services';

  /// Generate comprehensive crop advisory based on location and user data
  static Future<CropAdvisory> generateCropAdvisory({
    required String cropName,
    required double latitude,
    required double longitude,
    required String season,
    required String stage,
    User? user,
  }) async {
    try {
      // Get current weather data
      final weather = await _getWeatherData(latitude, longitude);

      // Get soil information
      final soilInfo = await _getSoilInformation(latitude, longitude);

      // Generate location-specific recommendations
      final recommendations = await _generateRecommendations(
        cropName,
        weather,
        soilInfo,
        season,
        stage,
        user,
      );

      // Analyze weather impact
      final weatherImpact = _analyzeWeatherImpact(weather, cropName, stage);

      // Generate soil health advice
      final soilAdvice = _generateSoilHealthAdvice(soilInfo, cropName);

      // Check for pest/disease alerts
      final pestAlert = await _checkPestDiseaseAlerts(
        cropName,
        weather,
        season,
        latitude,
        longitude,
      );

      // Get location name
      final location = await _getLocationName(latitude, longitude);

      return CropAdvisory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        cropName: cropName,
        location: location,
        latitude: latitude,
        longitude: longitude,
        season: season,
        advisoryDate: DateTime.now(),
        stage: stage,
        recommendations: recommendations,
        weatherImpact: weatherImpact,
        soilAdvice: soilAdvice,
        pestAlert: pestAlert,
        confidenceScore: _calculateConfidenceScore(weather, soilInfo),
      );
    } catch (e) {
      throw Exception('Failed to generate crop advisory: ${e.toString()}');
    }
  }

  /// Get weather data for location
  static Future<Map<String, dynamic>> _getWeatherData(
    double latitude,
    double longitude,
  ) async {
    // Mock weather data - in production, use real weather API
    return {
      'temperature': 25.0 + Random().nextDouble() * 10,
      'humidity': 60.0 + Random().nextDouble() * 30,
      'rainfall': Random().nextDouble() * 20,
      'windSpeed': 5.0 + Random().nextDouble() * 10,
      'uvIndex': 3.0 + Random().nextDouble() * 7,
      'condition': ['sunny', 'cloudy', 'rainy'][Random().nextInt(3)],
      'forecast': _generateWeatherForecast(),
    };
  }

  /// Get soil information for location
  static Future<Map<String, dynamic>> _getSoilInformation(
    double latitude,
    double longitude,
  ) async {
    // Mock soil data - in production, integrate with soil databases
    return {
      'ph': 6.0 + Random().nextDouble() * 2,
      'organicMatter': ['Low', 'Medium', 'High'][Random().nextInt(3)],
      'nitrogen': ['Low', 'Medium', 'High'][Random().nextInt(3)],
      'phosphorus': ['Low', 'Medium', 'High'][Random().nextInt(3)],
      'potassium': ['Low', 'Medium', 'High'][Random().nextInt(3)],
      'moisture': 40.0 + Random().nextDouble() * 40,
      'texture': ['Sandy', 'Clay', 'Loam', 'Silt'][Random().nextInt(4)],
    };
  }

  /// Generate AI-powered recommendations
  static Future<List<AdvisoryRecommendation>> _generateRecommendations(
    String cropName,
    Map<String, dynamic> weather,
    Map<String, dynamic> soil,
    String season,
    String stage,
    User? user,
  ) async {
    List<AdvisoryRecommendation> recommendations = [];

    // Irrigation recommendations based on weather and soil
    recommendations.add(
      _generateIrrigationRecommendation(weather, soil, cropName, stage),
    );

    // Fertilizer recommendations based on soil analysis
    recommendations.addAll(
      _generateFertilizerRecommendations(soil, cropName, stage),
    );

    // Pest management recommendations
    recommendations.add(
      _generatePestManagementRecommendation(cropName, weather, season),
    );

    // Weather-based recommendations
    recommendations.addAll(
      _generateWeatherBasedRecommendations(weather, cropName, stage),
    );

    // Growth stage specific recommendations
    recommendations.addAll(
      _generateStageSpecificRecommendations(cropName, stage, season),
    );

    return recommendations;
  }

  static AdvisoryRecommendation _generateIrrigationRecommendation(
    Map<String, dynamic> weather,
    Map<String, dynamic> soil,
    String cropName,
    String stage,
  ) {
    double rainfall = weather['rainfall'] ?? 0.0;
    double soilMoisture = soil['moisture'] ?? 50.0;

    String priority = 'Medium';
    String action = '';

    if (rainfall < 5 && soilMoisture < 30) {
      priority = 'High';
      action = 'Immediate irrigation required. Apply 25-30mm water.';
    } else if (rainfall < 10 && soilMoisture < 50) {
      priority = 'Medium';
      action = 'Light irrigation recommended. Apply 15-20mm water.';
    } else {
      priority = 'Low';
      action = 'Soil moisture adequate. Monitor for next 3-4 days.';
    }

    return AdvisoryRecommendation(
      id: 'irrigation_${DateTime.now().millisecondsSinceEpoch}',
      type: 'Irrigation',
      title: 'Irrigation Schedule',
      description:
          'Optimal irrigation timing based on weather and soil conditions',
      priority: priority,
      actionRequired: action,
      deadline: DateTime.now().add(const Duration(days: 2)),
      materials: ['Water pump', 'Irrigation pipes'],
      dosage: '20-30mm',
      precautions: [
        'Check soil moisture before irrigation',
        'Avoid over-watering',
      ],
    );
  }

  static List<AdvisoryRecommendation> _generateFertilizerRecommendations(
    Map<String, dynamic> soil,
    String cropName,
    String stage,
  ) {
    List<AdvisoryRecommendation> recommendations = [];

    // NPK recommendations based on soil analysis
    String nitrogen = soil['nitrogen'] ?? 'Medium';
    String phosphorus = soil['phosphorus'] ?? 'Medium';
    String potassium = soil['potassium'] ?? 'Medium';

    if (nitrogen == 'Low') {
      recommendations.add(
        AdvisoryRecommendation(
          id: 'nitrogen_${DateTime.now().millisecondsSinceEpoch}',
          type: 'Fertilizer',
          title: 'Nitrogen Deficiency Treatment',
          description: 'Low nitrogen levels detected in soil analysis',
          priority: 'High',
          actionRequired: 'Apply nitrogen-rich fertilizer',
          deadline: DateTime.now().add(const Duration(days: 7)),
          materials: ['Urea', 'Ammonium Sulfate'],
          dosage: '120-150 kg/ha',
          precautions: [
            'Apply in split doses',
            'Water thoroughly after application',
          ],
        ),
      );
    }

    if (phosphorus == 'Low') {
      recommendations.add(
        AdvisoryRecommendation(
          id: 'phosphorus_${DateTime.now().millisecondsSinceEpoch}',
          type: 'Fertilizer',
          title: 'Phosphorus Application',
          description: 'Phosphorus levels below optimal range',
          priority: 'Medium',
          actionRequired: 'Apply phosphorus fertilizer',
          deadline: DateTime.now().add(const Duration(days: 10)),
          materials: ['Single Super Phosphate', 'DAP'],
          dosage: '60-80 kg/ha',
          precautions: ['Apply at base of plant', 'Mix with soil'],
        ),
      );
    }

    return recommendations;
  }

  static AdvisoryRecommendation _generatePestManagementRecommendation(
    String cropName,
    Map<String, dynamic> weather,
    String season,
  ) {
    double humidity = weather['humidity'] ?? 60.0;
    double temperature = weather['temperature'] ?? 25.0;

    String riskLevel = 'Low';
    String action = 'Continue regular monitoring';

    if (humidity > 80 && temperature > 25) {
      riskLevel = 'High';
      action = 'High risk for fungal diseases. Apply preventive fungicide.';
    } else if (humidity > 70 || temperature > 30) {
      riskLevel = 'Medium';
      action = 'Monitor for early signs of pest/disease activity.';
    }

    return AdvisoryRecommendation(
      id: 'pest_mgmt_${DateTime.now().millisecondsSinceEpoch}',
      type: 'Pesticide',
      title: 'Pest Management',
      description:
          'Preventive pest and disease management based on weather conditions',
      priority: riskLevel == 'High' ? 'High' : 'Medium',
      actionRequired: action,
      deadline: DateTime.now().add(const Duration(days: 5)),
      materials: ['Neem oil', 'Biological pesticide'],
      dosage: '2-3 ml/liter',
      precautions: ['Apply in evening hours', 'Wear protective equipment'],
    );
  }

  static List<AdvisoryRecommendation> _generateWeatherBasedRecommendations(
    Map<String, dynamic> weather,
    String cropName,
    String stage,
  ) {
    List<AdvisoryRecommendation> recommendations = [];

    double temperature = weather['temperature'] ?? 25.0;
    String condition = weather['condition'] ?? 'sunny';

    if (temperature > 35) {
      recommendations.add(
        AdvisoryRecommendation(
          id: 'heat_stress_${DateTime.now().millisecondsSinceEpoch}',
          type: 'General',
          title: 'Heat Stress Management',
          description:
              'High temperatures detected - protect crops from heat stress',
          priority: 'High',
          actionRequired: 'Provide shade and increase irrigation frequency',
          deadline: DateTime.now().add(const Duration(days: 1)),
          materials: ['Shade nets', 'Mulch'],
          dosage: 'As required',
          precautions: ['Avoid midday operations', 'Increase water supply'],
        ),
      );
    }

    if (condition == 'rainy') {
      recommendations.add(
        AdvisoryRecommendation(
          id: 'rain_mgmt_${DateTime.now().millisecondsSinceEpoch}',
          type: 'General',
          title: 'Rainfall Management',
          description: 'Rainy conditions - prevent waterlogging and disease',
          priority: 'Medium',
          actionRequired: 'Ensure proper drainage and monitor for diseases',
          deadline: DateTime.now().add(const Duration(days: 3)),
          materials: ['Drainage channels', 'Fungicide'],
          dosage: 'As per requirement',
          precautions: [
            'Avoid field operations in wet conditions',
            'Check for standing water',
          ],
        ),
      );
    }

    return recommendations;
  }

  static List<AdvisoryRecommendation> _generateStageSpecificRecommendations(
    String cropName,
    String stage,
    String season,
  ) {
    List<AdvisoryRecommendation> recommendations = [];

    switch (stage.toLowerCase()) {
      case 'sowing':
        recommendations.add(
          AdvisoryRecommendation(
            id: 'sowing_${DateTime.now().millisecondsSinceEpoch}',
            type: 'General',
            title: 'Sowing Best Practices',
            description: 'Optimal sowing techniques for current conditions',
            priority: 'High',
            actionRequired: 'Follow recommended seed spacing and depth',
            deadline: DateTime.now().add(const Duration(days: 7)),
            materials: ['Quality seeds', 'Seed treatment chemicals'],
            dosage: 'As per seed packet instructions',
            precautions: [
              'Treat seeds before sowing',
              'Maintain proper spacing',
            ],
          ),
        );
        break;
      case 'growing':
        recommendations.add(
          AdvisoryRecommendation(
            id: 'growing_${DateTime.now().millisecondsSinceEpoch}',
            type: 'General',
            title: 'Growth Stage Management',
            description: 'Key activities during crop growth phase',
            priority: 'Medium',
            actionRequired: 'Regular monitoring and nutrient management',
            deadline: DateTime.now().add(const Duration(days: 14)),
            materials: ['Balanced fertilizer', 'Growth regulators'],
            dosage: 'As per crop requirement',
            precautions: ['Monitor for nutrient deficiencies', 'Control weeds'],
          ),
        );
        break;
      case 'harvesting':
        recommendations.add(
          AdvisoryRecommendation(
            id: 'harvest_${DateTime.now().millisecondsSinceEpoch}',
            type: 'General',
            title: 'Harvest Preparation',
            description: 'Prepare for optimal harvest timing and methods',
            priority: 'High',
            actionRequired: 'Monitor crop maturity indicators',
            deadline: DateTime.now().add(const Duration(days: 5)),
            materials: ['Harvesting tools', 'Storage containers'],
            dosage: 'Not applicable',
            precautions: [
              'Harvest at right maturity',
              'Handle produce carefully',
            ],
          ),
        );
        break;
    }

    return recommendations;
  }

  static WeatherImpact _analyzeWeatherImpact(
    Map<String, dynamic> weather,
    String cropName,
    String stage,
  ) {
    double temperature = weather['temperature'] ?? 25.0;
    double humidity = weather['humidity'] ?? 60.0;
    double rainfall = weather['rainfall'] ?? 10.0;

    String condition = 'Favorable';
    double riskLevel = 0.2;
    List<String> impacts = [];
    List<String> recommendations = [];

    // Temperature analysis
    if (temperature > 35) {
      condition = 'Warning';
      riskLevel = 0.7;
      impacts.add('High temperature stress on crops');
      recommendations.add('Increase irrigation frequency');
      recommendations.add('Provide shade protection');
    } else if (temperature < 15) {
      condition = 'Warning';
      riskLevel = 0.6;
      impacts.add('Cold stress may slow growth');
      recommendations.add('Consider protective covers');
    }

    // Humidity analysis
    if (humidity > 85) {
      condition = condition == 'Favorable' ? 'Warning' : 'Critical';
      riskLevel = max(riskLevel, 0.8);
      impacts.add('High humidity increases disease risk');
      recommendations.add('Improve air circulation');
      recommendations.add('Apply preventive fungicides');
    }

    // Rainfall analysis
    if (rainfall > 50) {
      condition = 'Critical';
      riskLevel = 0.9;
      impacts.add('Excessive rainfall may cause waterlogging');
      recommendations.add('Ensure proper drainage');
      recommendations.add('Monitor for root rot');
    } else if (rainfall < 5) {
      condition = condition == 'Favorable' ? 'Warning' : condition;
      riskLevel = max(riskLevel, 0.6);
      impacts.add('Low rainfall requires irrigation');
      recommendations.add('Schedule irrigation');
    }

    return WeatherImpact(
      condition: condition,
      description: 'Weather impact analysis for $cropName in $stage stage',
      impacts: impacts,
      recommendations: recommendations,
      riskLevel: riskLevel,
      nextAction: recommendations.isNotEmpty
          ? recommendations.first
          : 'Continue monitoring',
    );
  }

  static SoilHealthAdvice _generateSoilHealthAdvice(
    Map<String, dynamic> soil,
    String cropName,
  ) {
    double ph = soil['ph'] ?? 7.0;
    String organicMatter = soil['organicMatter'] ?? 'Medium';
    String nitrogen = soil['nitrogen'] ?? 'Medium';
    String phosphorus = soil['phosphorus'] ?? 'Medium';
    String potassium = soil['potassium'] ?? 'Medium';

    String healthStatus = 'Good';
    List<FertilizerRecommendation> fertilizerRecs = [];
    List<String> improvementTips = [];

    // pH analysis
    if (ph < 6.0 || ph > 8.0) {
      healthStatus = 'Fair';
      if (ph < 6.0) {
        improvementTips.add('Add lime to increase soil pH');
      } else {
        improvementTips.add('Add organic matter to reduce soil pH');
      }
    }

    // Nutrient analysis
    if (nitrogen == 'Low') {
      fertilizerRecs.add(
        FertilizerRecommendation(
          name: 'Urea',
          type: 'Inorganic',
          dosage: '120-150 kg/ha',
          applicationMethod: 'Broadcasting and incorporation',
          timing:
              'Split application - 50% at sowing, 25% at 30 days, 25% at 60 days',
          estimatedCost: 2500.0,
          benefits: ['Quick nitrogen supply', 'Promotes vegetative growth'],
          precautions: [
            'Avoid application during rain',
            'Water thoroughly after application',
          ],
        ),
      );
    }

    if (organicMatter == 'Low') {
      improvementTips.add('Add compost or farmyard manure');
      improvementTips.add('Practice crop rotation with legumes');
    }

    return SoilHealthAdvice(
      healthStatus: healthStatus,
      phLevel: ph,
      organicMatter: organicMatter,
      nitrogen: nitrogen,
      phosphorus: phosphorus,
      potassium: potassium,
      fertilizerRecommendations: fertilizerRecs,
      improvementTips: improvementTips,
      nextTestDate: DateTime.now()
          .add(const Duration(days: 90))
          .toString()
          .split(' ')[0],
    );
  }

  static Future<PestDiseaseAlert?> _checkPestDiseaseAlerts(
    String cropName,
    Map<String, dynamic> weather,
    String season,
    double latitude,
    double longitude,
  ) async {
    // Mock pest/disease alert based on weather conditions
    double humidity = weather['humidity'] ?? 60.0;
    double temperature = weather['temperature'] ?? 25.0;

    if (humidity > 80 && temperature > 25) {
      return PestDiseaseAlert(
        id: 'pest_alert_${DateTime.now().millisecondsSinceEpoch}',
        type: 'Disease',
        name: 'Fungal Leaf Spot',
        severity: 'Medium',
        description:
            'High humidity and temperature create favorable conditions for fungal growth',
        symptoms: ['Yellow spots on leaves', 'Brown patches', 'Leaf wilting'],
        causes: ['High humidity', 'Poor air circulation', 'Wet foliage'],
        treatments: [
          TreatmentOption(
            name: 'Copper-based fungicide',
            type: 'Chemical',
            description: 'Broad spectrum fungicide for leaf spot control',
            dosage: '2-3 grams per liter',
            applicationMethod: 'Foliar spray',
            applicationFrequency: 10,
            effectivenessScore: 0.85,
            estimatedCost: 150.0,
            materials: ['Copper oxychloride', 'Sprayer'],
            precautions: [
              'Wear protective gear',
              'Avoid application during flowering',
            ],
          ),
          TreatmentOption(
            name: 'Neem oil',
            type: 'Organic',
            description: 'Natural fungicide with systemic action',
            dosage: '5-10 ml per liter',
            applicationMethod: 'Foliar spray',
            applicationFrequency: 7,
            effectivenessScore: 0.70,
            estimatedCost: 80.0,
            materials: ['Neem oil', 'Emulsifier'],
            precautions: [
              'Apply in evening',
              'Do not mix with other chemicals',
            ],
          ),
        ],
        preventionMethods: [
          'Improve air circulation',
          'Avoid overhead irrigation',
          'Remove infected plant debris',
          'Maintain proper plant spacing',
        ],
        confidenceLevel: 0.75,
      );
    }

    return null;
  }

  static Future<String> _getLocationName(
    double latitude,
    double longitude,
  ) async {
    // Mock location name - in production, use geocoding service
    return 'Agricultural Zone, District, State';
  }

  static double _calculateConfidenceScore(
    Map<String, dynamic> weather,
    Map<String, dynamic> soil,
  ) {
    // Calculate confidence based on data quality and completeness
    double confidence = 0.8;

    // Adjust based on weather data completeness
    if (weather.containsKey('temperature') && weather.containsKey('humidity')) {
      confidence += 0.1;
    }

    // Adjust based on soil data completeness
    if (soil.containsKey('ph') && soil.containsKey('organicMatter')) {
      confidence += 0.1;
    }

    return min(confidence, 1.0);
  }

  static List<Map<String, dynamic>> _generateWeatherForecast() {
    // Mock 7-day forecast
    List<Map<String, dynamic>> forecast = [];
    for (int i = 1; i <= 7; i++) {
      forecast.add({
        'date': DateTime.now().add(Duration(days: i)).toIso8601String(),
        'temperature': 20.0 + Random().nextDouble() * 15,
        'humidity': 50.0 + Random().nextDouble() * 40,
        'rainfall': Random().nextDouble() * 25,
        'condition': [
          'sunny',
          'cloudy',
          'rainy',
          'partly_cloudy',
        ][Random().nextInt(4)],
      });
    }
    return forecast;
  }

  /// Get historical advisory data for user
  static Future<List<CropAdvisory>> getAdvisoryHistory(String userId) async {
    // Mock implementation - in production, fetch from database
    await Future.delayed(const Duration(milliseconds: 500));
    return [];
  }

  /// Save advisory for future reference
  static Future<void> saveAdvisory(CropAdvisory advisory) async {
    // Mock implementation - in production, save to database
    print('$_tag: Saving advisory: ${advisory.id}');
  }
}
