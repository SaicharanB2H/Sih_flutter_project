import 'package:cloud_firestore/cloud_firestore.dart';

class WeatherData {
  final String id;
  final double latitude;
  final double longitude;
  final String locationName;
  final CurrentWeather current;
  final List<DailyForecast> dailyForecast;
  final List<WeatherAlert> alerts;
  final DateTime lastUpdated;

  WeatherData({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.current,
    this.dailyForecast = const [],
    this.alerts = const [],
    required this.lastUpdated,
  });

  factory WeatherData.fromMap(Map<String, dynamic> map) {
    return WeatherData(
      id: map['id'] ?? '',
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      locationName: map['locationName'] ?? '',
      current: CurrentWeather.fromMap(map['current'] ?? {}),
      dailyForecast:
          (map['dailyForecast'] as List?)
              ?.map((item) => DailyForecast.fromMap(item))
              .toList() ??
          [],
      alerts:
          (map['alerts'] as List?)
              ?.map((item) => WeatherAlert.fromMap(item))
              .toList() ??
          [],
      lastUpdated:
          (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'current': current.toMap(),
      'dailyForecast': dailyForecast.map((f) => f.toMap()).toList(),
      'alerts': alerts.map((a) => a.toMap()).toList(),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}

class CurrentWeather {
  final double temperature;
  final double humidity;
  final double windSpeed;
  final String windDirection;
  final double pressure;
  final double uvIndex;
  final String condition;
  final String description;
  final String iconCode;

  CurrentWeather({
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.windDirection,
    required this.pressure,
    required this.uvIndex,
    required this.condition,
    required this.description,
    required this.iconCode,
  });

  factory CurrentWeather.fromMap(Map<String, dynamic> map) {
    return CurrentWeather(
      temperature: map['temperature']?.toDouble() ?? 0.0,
      humidity: map['humidity']?.toDouble() ?? 0.0,
      windSpeed: map['windSpeed']?.toDouble() ?? 0.0,
      windDirection: map['windDirection'] ?? '',
      pressure: map['pressure']?.toDouble() ?? 0.0,
      uvIndex: map['uvIndex']?.toDouble() ?? 0.0,
      condition: map['condition'] ?? '',
      description: map['description'] ?? '',
      iconCode: map['iconCode'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'windDirection': windDirection,
      'pressure': pressure,
      'uvIndex': uvIndex,
      'condition': condition,
      'description': description,
      'iconCode': iconCode,
    };
  }
}

class DailyForecast {
  final DateTime date;
  final double maxTemp;
  final double minTemp;
  final double humidity;
  final double precipitationChance;
  final String condition;
  final String iconCode;

  DailyForecast({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.humidity,
    required this.precipitationChance,
    required this.condition,
    required this.iconCode,
  });

  factory DailyForecast.fromMap(Map<String, dynamic> map) {
    return DailyForecast(
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      maxTemp: map['maxTemp']?.toDouble() ?? 0.0,
      minTemp: map['minTemp']?.toDouble() ?? 0.0,
      humidity: map['humidity']?.toDouble() ?? 0.0,
      precipitationChance: map['precipitationChance']?.toDouble() ?? 0.0,
      condition: map['condition'] ?? '',
      iconCode: map['iconCode'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'maxTemp': maxTemp,
      'minTemp': minTemp,
      'humidity': humidity,
      'precipitationChance': precipitationChance,
      'condition': condition,
      'iconCode': iconCode,
    };
  }
}

class WeatherAlert {
  final String id;
  final String title;
  final String description;
  final AlertSeverity severity;
  final DateTime startTime;
  final DateTime endTime;
  final List<String> affectedAreas;

  WeatherAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.startTime,
    required this.endTime,
    this.affectedAreas = const [],
  });

  factory WeatherAlert.fromMap(Map<String, dynamic> map) {
    return WeatherAlert(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      severity: AlertSeverity.values.firstWhere(
        (e) => e.toString() == 'AlertSeverity.${map['severity']}',
        orElse: () => AlertSeverity.minor,
      ),
      startTime: (map['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (map['endTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      affectedAreas: List<String>.from(map['affectedAreas'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'severity': severity.toString().split('.').last,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'affectedAreas': affectedAreas,
    };
  }
}

enum AlertSeverity { minor, moderate, severe, extreme }
