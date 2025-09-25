import 'dart:convert';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import '../models/soil.dart';

class SoilDetectionService {
  static const String _tag = 'SoilDetectionService';

  // India's major soil regions (simplified mapping)
  static const Map<String, List<double>> _soilRegions = {
    'alluvial': [
      // Gangetic plains, Punjab, Haryana, UP, Bihar, West Bengal
      25.0, 31.0, 74.0, 89.0, // lat_min, lat_max, lng_min, lng_max
    ],
    'black': [
      // Deccan plateau - Maharashtra, Gujarat, MP, Karnataka
      15.0, 26.0, 72.0, 80.0,
    ],
    'red': [
      // Tamil Nadu, Andhra Pradesh, Karnataka, Kerala parts
      8.0, 20.0, 75.0, 84.0,
    ],
    'laterite': [
      // Coastal areas - Kerala, Karnataka coast, Goa, parts of WB
      8.0, 22.0, 68.0, 78.0,
    ],
    'desert': [
      // Rajasthan, Gujarat desert areas
      23.0, 30.0, 68.0, 75.0,
    ],
    'mountain': [
      // Himalayan regions, Western ghats, Eastern ghats
      28.0, 37.0, 74.0, 95.0,
    ],
  };

  /// Get current location
  static Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Get address from coordinates
  static Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.locality}, ${place.administrativeArea}, ${place.country}';
      }
      return 'Unknown location';
    } catch (e) {
      return 'Lat: ${latitude.toStringAsFixed(4)}, Lng: ${longitude.toStringAsFixed(4)}';
    }
  }

  /// Detect soil type based on location
  static Future<SoilAnalysis> detectSoilType(
    double latitude,
    double longitude,
  ) async {
    try {
      // Get location address
      String location = await getAddressFromCoordinates(latitude, longitude);

      // Determine soil type based on geographic region
      DetailedSoilType soilType = _determineSoilTypeByRegion(
        latitude,
        longitude,
      );

      // Create analysis result
      return SoilAnalysis(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        latitude: latitude,
        longitude: longitude,
        location: location,
        soilType: soilType,
        analyzedAt: DateTime.now(),
        additionalData: {
          'detection_method': 'geolocation',
          'confidence': _calculateConfidence(latitude, longitude),
        },
      );
    } catch (e) {
      throw Exception('Failed to detect soil type: ${e.toString()}');
    }
  }

  /// Determine soil type based on geographic coordinates
  static DetailedSoilType _determineSoilTypeByRegion(
    double latitude,
    double longitude,
  ) {
    // Check each soil region
    for (String soilId in _soilRegions.keys) {
      List<double> bounds = _soilRegions[soilId]!;
      double latMin = bounds[0];
      double latMax = bounds[1];
      double lngMin = bounds[2];
      double lngMax = bounds[3];

      if (latitude >= latMin &&
          latitude <= latMax &&
          longitude >= lngMin &&
          longitude <= lngMax) {
        DetailedSoilType? soil = DetailedSoilTypes.getById(soilId);
        if (soil != null) return soil;
      }
    }

    // Special cases for better accuracy
    if (_isInGangeticPlains(latitude, longitude)) {
      return DetailedSoilTypes.alluvial;
    } else if (_isInDeccanPlateau(latitude, longitude)) {
      return DetailedSoilTypes.black;
    } else if (_isInWesternGhats(latitude, longitude)) {
      return DetailedSoilTypes.laterite;
    } else if (_isInRajasthanDesert(latitude, longitude)) {
      return DetailedSoilTypes.desert;
    } else if (_isInHimalayanRegion(latitude, longitude)) {
      return DetailedSoilTypes.mountain;
    }

    // Default to red soil for peninsular India
    return DetailedSoilTypes.red;
  }

  /// Calculate confidence score based on location precision
  static double _calculateConfidence(double latitude, double longitude) {
    // Base confidence for geolocation-based detection
    double baseConfidence = 0.75;

    // Adjust based on known high-accuracy regions
    if (_isInWellMappedRegion(latitude, longitude)) {
      return min(baseConfidence + 0.15, 1.0);
    }

    return baseConfidence;
  }

  // Helper methods for geographic region identification
  static bool _isInGangeticPlains(double lat, double lng) {
    return lat >= 24.0 && lat <= 31.0 && lng >= 74.0 && lng <= 89.0;
  }

  static bool _isInDeccanPlateau(double lat, double lng) {
    return lat >= 15.0 && lat <= 26.0 && lng >= 72.0 && lng <= 82.0;
  }

  static bool _isInWesternGhats(double lat, double lng) {
    return lat >= 8.0 && lat <= 21.0 && lng >= 72.0 && lng <= 77.0;
  }

  static bool _isInRajasthanDesert(double lat, double lng) {
    return lat >= 24.0 && lat <= 30.0 && lng >= 69.0 && lng <= 76.0;
  }

  static bool _isInHimalayanRegion(double lat, double lng) {
    return lat >= 28.0 && lat <= 37.0 && lng >= 74.0 && lng <= 95.0;
  }

  static bool _isInWellMappedRegion(double lat, double lng) {
    // Areas with more accurate soil mapping data
    return _isInGangeticPlains(lat, lng) ||
        _isInDeccanPlateau(lat, lng) ||
        _isInRajasthanDesert(lat, lng);
  }

  /// Get nearby soil analysis data (mock implementation)
  static Future<List<SoilAnalysis>> getNearbyAnalyses(
    double latitude,
    double longitude, {
    double radiusKm = 50.0,
  }) async {
    // This would typically fetch from a database
    // For now, return mock data
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      SoilAnalysis(
        id: 'nearby_1',
        latitude: latitude + 0.01,
        longitude: longitude + 0.01,
        location: 'Nearby Farm A',
        soilType: _determineSoilTypeByRegion(latitude, longitude),
        analyzedAt: DateTime.now().subtract(const Duration(days: 5)),
        additionalData: {'source': 'farmer_report'},
      ),
      SoilAnalysis(
        id: 'nearby_2',
        latitude: latitude - 0.01,
        longitude: longitude - 0.01,
        location: 'Nearby Farm B',
        soilType: _determineSoilTypeByRegion(latitude, longitude),
        analyzedAt: DateTime.now().subtract(const Duration(days: 12)),
        additionalData: {'source': 'government_survey'},
      ),
    ];
  }

  /// Save soil analysis to local storage (future implementation)
  static Future<void> saveSoilAnalysis(SoilAnalysis analysis) async {
    // Implementation would save to local database
    print('$_tag: Saving soil analysis: ${analysis.id}');
  }

  /// Get historical soil analyses (future implementation)
  static Future<List<SoilAnalysis>> getHistoricalAnalyses() async {
    // Implementation would fetch from local database
    await Future.delayed(const Duration(milliseconds: 300));
    return [];
  }
}
