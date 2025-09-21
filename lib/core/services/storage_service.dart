import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../models/chat_history.dart';

class StorageService {
  static const String _chatHistoryKey = 'chat_history';
  static const String _diagnosisHistoryKey = 'diagnosis_history';
  static const Uuid _uuid = Uuid();

  static Future<void> initialize() async {
    // No initialization needed for SharedPreferences
  }

  // Chat History Methods
  static Future<void> saveChatMessage({
    required String message,
    required String response,
    required bool isUser,
    String? imageBase64,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final chatHistory = ChatHistory(
      id: _uuid.v4(),
      message: message,
      response: response,
      timestamp: DateTime.now(),
      isUser: isUser,
      imageBase64: imageBase64,
    );

    // Get existing chat history
    final existing = await getAllChatHistory();
    existing.add(chatHistory);

    // Convert to JSON and save
    final jsonList = existing.map((chat) => chat.toJson()).toList();
    await prefs.setString(_chatHistoryKey, json.encode(jsonList));
  }

  static Future<List<ChatHistory>> getAllChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_chatHistoryKey);

    if (jsonString == null) return [];

    try {
      final jsonList = json.decode(jsonString) as List;
      final chatList = jsonList
          .map((json) => ChatHistory.fromJson(json as Map<String, dynamic>))
          .toList();
      chatList.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return chatList;
    } catch (e) {
      return [];
    }
  }

  static Future<void> clearChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chatHistoryKey);
  }

  // Diagnosis History Methods
  static Future<void> saveDiagnosis({
    required String imageBase64,
    required String diagnosis,
    required String treatment,
    required String cropType,
    required double confidence,
    required List<String> symptoms,
    required List<String> recommendations,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final diagnosisHistory = DiagnosisHistory(
      id: _uuid.v4(),
      imageBase64: imageBase64,
      diagnosis: diagnosis,
      treatment: treatment,
      cropType: cropType,
      timestamp: DateTime.now(),
      confidence: confidence,
      symptoms: symptoms,
      recommendations: recommendations,
    );

    // Get existing diagnosis history
    final existing = await getAllDiagnosisHistory();
    existing.add(diagnosisHistory);

    // Convert to JSON and save
    final jsonList = existing.map((diag) => diag.toJson()).toList();
    await prefs.setString(_diagnosisHistoryKey, json.encode(jsonList));
  }

  static Future<List<DiagnosisHistory>> getAllDiagnosisHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_diagnosisHistoryKey);

    if (jsonString == null) return [];

    try {
      final jsonList = json.decode(jsonString) as List;
      final diagnosisList = jsonList
          .map(
            (json) => DiagnosisHistory.fromJson(json as Map<String, dynamic>),
          )
          .toList();
      diagnosisList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return diagnosisList;
    } catch (e) {
      return [];
    }
  }

  static Future<void> clearDiagnosisHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_diagnosisHistoryKey);
  }

  static Future<void> deleteDiagnosis(String id) async {
    final existing = await getAllDiagnosisHistory();
    existing.removeWhere((diag) => diag.id == id);

    final prefs = await SharedPreferences.getInstance();
    final jsonList = existing.map((diag) => diag.toJson()).toList();
    await prefs.setString(_diagnosisHistoryKey, json.encode(jsonList));
  }
}
