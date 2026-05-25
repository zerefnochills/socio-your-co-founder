import 'package:cloud_firestore/cloud_firestore.dart';

class StartupModel {
  final String id;
  final String name;
  final String idea;
  final String stage;
  final String mrr;
  final String userCount;
  final DateTime updatedAt;

  StartupModel({
    required this.id,
    required this.name,
    required this.idea,
    required this.stage,
    required this.mrr,
    required this.userCount,
    required this.updatedAt,
  });

  factory StartupModel.empty() => StartupModel(
        id: '',
        name: '',
        idea: '',
        stage: 'Idea stage',
        mrr: '0',
        userCount: '0',
        updatedAt: DateTime.now(),
      );

  factory StartupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StartupModel(
      id: doc.id,
      name: data['name'] ?? '',
      idea: data['idea'] ?? '',
      stage: data['stage'] ?? 'Idea stage',
      mrr: (data['mrr'] ?? 0).toString(),
      userCount: (data['user_count'] ?? 0).toString(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'idea': idea,
        'stage': stage,
        'mrr': mrr,
        'user_count': userCount,
        'updated_at': FieldValue.serverTimestamp(),
      };

  StartupModel copyWith({
    String? id,
    String? name,
    String? idea,
    String? stage,
    String? mrr,
    String? userCount,
  }) =>
      StartupModel(
        id: id ?? this.id,
        name: name ?? this.name,
        idea: idea ?? this.idea,
        stage: stage ?? this.stage,
        mrr: mrr ?? this.mrr,
        userCount: userCount ?? this.userCount,
        updatedAt: DateTime.now(),
      );

  // Converts to the format the FastAPI backend expects
  Map<String, dynamic> toApiContext() => {
        'startup_name': name.isEmpty ? 'My Startup' : name,
        'startup_idea': idea,
        'startup_stage': stage,
        'mrr': mrr,
        'user_count': userCount,
      };
}
