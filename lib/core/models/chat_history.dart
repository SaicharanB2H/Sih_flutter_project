import 'package:hive/hive.dart';

// Note: Run 'flutter packages pub run build_runner build' to generate .g.dart files
// part 'chat_history.g.dart';

@HiveType(typeId: 0)
class ChatHistory extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String message;

  @HiveField(2)
  final String response;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final bool isUser;

  @HiveField(5)
  final String? imageBase64;

  ChatHistory({
    required this.id,
    required this.message,
    required this.response,
    required this.timestamp,
    required this.isUser,
    this.imageBase64,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'response': response,
      'timestamp': timestamp.toIso8601String(),
      'isUser': isUser,
      'imageBase64': imageBase64,
    };
  }

  factory ChatHistory.fromJson(Map<String, dynamic> json) {
    return ChatHistory(
      id: json['id'] as String,
      message: json['message'] as String,
      response: json['response'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isUser: json['isUser'] as bool,
      imageBase64: json['imageBase64'] as String?,
    );
  }
}

@HiveType(typeId: 1)
class DiagnosisHistory extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String imageBase64;

  @HiveField(2)
  final String diagnosis;

  @HiveField(3)
  final String treatment;

  @HiveField(4)
  final String cropType;

  @HiveField(5)
  final DateTime timestamp;

  @HiveField(6)
  final double confidence;

  @HiveField(7)
  final List<String> symptoms;

  @HiveField(8)
  final List<String> recommendations;

  DiagnosisHistory({
    required this.id,
    required this.imageBase64,
    required this.diagnosis,
    required this.treatment,
    required this.cropType,
    required this.timestamp,
    required this.confidence,
    required this.symptoms,
    required this.recommendations,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageBase64': imageBase64,
      'diagnosis': diagnosis,
      'treatment': treatment,
      'cropType': cropType,
      'timestamp': timestamp.toIso8601String(),
      'confidence': confidence,
      'symptoms': symptoms,
      'recommendations': recommendations,
    };
  }

  factory DiagnosisHistory.fromJson(Map<String, dynamic> json) {
    return DiagnosisHistory(
      id: json['id'] as String,
      imageBase64: json['imageBase64'] as String,
      diagnosis: json['diagnosis'] as String,
      treatment: json['treatment'] as String,
      cropType: json['cropType'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      confidence: (json['confidence'] as num).toDouble(),
      symptoms: List<String>.from(json['symptoms'] as List),
      recommendations: List<String>.from(json['recommendations'] as List),
    );
  }
}
