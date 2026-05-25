import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageRole { user, socio }

class MessageModel {
  final String id;
  final MessageRole role;
  final String content;
  final double moodScore;
  final String emotion;
  final DateTime timestamp;
  final bool isStreaming;

  MessageModel({
    required this.id,
    required this.role,
    required this.content,
    this.moodScore = 0.7,
    this.emotion = 'neutral',
    required this.timestamp,
    this.isStreaming = false,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      role: data['role'] == 'user' ? MessageRole.user : MessageRole.socio,
      content: data['content'] ?? '',
      moodScore: (data['mood_score'] ?? 0.7).toDouble(),
      emotion: data['emotion'] ?? 'neutral',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'role': role == MessageRole.user ? 'user' : 'socio',
        'content': content,
        'mood_score': moodScore,
        'emotion': emotion,
        'timestamp': FieldValue.serverTimestamp(),
      };

  // For sending chat history to the backend API
  Map<String, dynamic> toApiMessage() => {
        'role': role == MessageRole.user ? 'user' : 'socio',
        'content': content,
      };

  MessageModel copyWith({
    String? content,
    double? moodScore,
    String? emotion,
    bool? isStreaming,
  }) =>
      MessageModel(
        id: id,
        role: role,
        content: content ?? this.content,
        moodScore: moodScore ?? this.moodScore,
        emotion: emotion ?? this.emotion,
        timestamp: timestamp,
        isStreaming: isStreaming ?? this.isStreaming,
      );
}
