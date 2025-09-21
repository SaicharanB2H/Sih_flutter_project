import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String userId;
  final String sessionId;
  final String content;
  final MessageType type;
  final MessageSender sender;
  final DateTime timestamp;
  final String? language;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.sessionId,
    required this.content,
    required this.type,
    required this.sender,
    required this.timestamp,
    this.language,
    this.metadata,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      sessionId: map['sessionId'] ?? '',
      content: map['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${map['type']}',
        orElse: () => MessageType.text,
      ),
      sender: MessageSender.values.firstWhere(
        (e) => e.toString() == 'MessageSender.${map['sender']}',
        orElse: () => MessageSender.user,
      ),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      language: map['language'],
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'sessionId': sessionId,
      'content': content,
      'type': type.toString().split('.').last,
      'sender': sender.toString().split('.').last,
      'timestamp': Timestamp.fromDate(timestamp),
      'language': language,
      'metadata': metadata,
    };
  }
}

class ChatSession {
  final String id;
  final String userId;
  final String title;
  final DateTime createdAt;
  final DateTime lastActivity;
  final List<String> messageIds;
  final SessionStatus status;
  final String? farmId;

  ChatSession({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    required this.lastActivity,
    this.messageIds = const [],
    this.status = SessionStatus.active,
    this.farmId,
  });

  factory ChatSession.fromMap(Map<String, dynamic> map) {
    return ChatSession(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActivity:
          (map['lastActivity'] as Timestamp?)?.toDate() ?? DateTime.now(),
      messageIds: List<String>.from(map['messageIds'] ?? []),
      status: SessionStatus.values.firstWhere(
        (e) => e.toString() == 'SessionStatus.${map['status']}',
        orElse: () => SessionStatus.active,
      ),
      farmId: map['farmId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActivity': Timestamp.fromDate(lastActivity),
      'messageIds': messageIds,
      'status': status.toString().split('.').last,
      'farmId': farmId,
    };
  }
}

class Advisory {
  final String id;
  final String title;
  final String content;
  final AdvisoryType type;
  final List<String> targetCrops;
  final String? location;
  final Priority priority;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final Map<String, String> translations;

  Advisory({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    this.targetCrops = const [],
    this.location,
    this.priority = Priority.normal,
    required this.createdAt,
    this.expiresAt,
    this.translations = const {},
  });

  factory Advisory.fromMap(Map<String, dynamic> map) {
    return Advisory(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      type: AdvisoryType.values.firstWhere(
        (e) => e.toString() == 'AdvisoryType.${map['type']}',
        orElse: () => AdvisoryType.general,
      ),
      targetCrops: List<String>.from(map['targetCrops'] ?? []),
      location: map['location'],
      priority: Priority.values.firstWhere(
        (e) => e.toString() == 'Priority.${map['priority']}',
        orElse: () => Priority.normal,
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate(),
      translations: Map<String, String>.from(map['translations'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type.toString().split('.').last,
      'targetCrops': targetCrops,
      'location': location,
      'priority': priority.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'translations': translations,
    };
  }
}

enum MessageType { text, voice, image, advisory }

enum MessageSender { user, ai, system }

enum SessionStatus { active, archived, deleted }

enum AdvisoryType {
  planting,
  irrigation,
  fertilization,
  pestControl,
  harvesting,
  weather,
  market,
  general,
}

enum Priority { low, normal, high, urgent }
