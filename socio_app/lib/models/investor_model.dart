// models/investor_model.dart
// Socio — Investor Pipeline Model
// Tracks each investor through the full fundraising funnel

enum InvestorStatus {
  identified,    // Found, not yet contacted
  contacted,     // Cold email/DM sent
  responded,     // They replied (positive)
  meeting,       // Meeting scheduled or happened
  dueDiligence,  // They're doing DD
  termSheet,     // Term sheet received
  closed,        // Deal closed ✅
  passed,        // Hard no
  ghosted,       // No response after follow-ups
}

extension InvestorStatusExt on InvestorStatus {
  String get label {
    switch (this) {
      case InvestorStatus.identified:    return 'Identified';
      case InvestorStatus.contacted:     return 'Contacted';
      case InvestorStatus.responded:     return 'Responded';
      case InvestorStatus.meeting:       return 'Meeting';
      case InvestorStatus.dueDiligence:  return 'Due Diligence';
      case InvestorStatus.termSheet:     return 'Term Sheet';
      case InvestorStatus.closed:        return 'Closed';
      case InvestorStatus.passed:        return 'Passed';
      case InvestorStatus.ghosted:       return 'Ghosted';
    }
  }

  String get emoji {
    switch (this) {
      case InvestorStatus.identified:    return '🔍';
      case InvestorStatus.contacted:     return '📧';
      case InvestorStatus.responded:     return '💬';
      case InvestorStatus.meeting:       return '🤝';
      case InvestorStatus.dueDiligence:  return '🔬';
      case InvestorStatus.termSheet:     return '📄';
      case InvestorStatus.closed:        return '✅';
      case InvestorStatus.passed:        return '❌';
      case InvestorStatus.ghosted:       return '👻';
    }
  }

  bool get isActive => ![InvestorStatus.passed, InvestorStatus.ghosted].contains(this);
  bool get isPositive => [
    InvestorStatus.responded,
    InvestorStatus.meeting,
    InvestorStatus.dueDiligence,
    InvestorStatus.termSheet,
    InvestorStatus.closed,
  ].contains(this);

  /// Ordered index for pipeline column display (active stages only)
  int get columnIndex {
    const order = [
      InvestorStatus.identified,
      InvestorStatus.contacted,
      InvestorStatus.responded,
      InvestorStatus.meeting,
      InvestorStatus.dueDiligence,
      InvestorStatus.termSheet,
      InvestorStatus.closed,
    ];
    return order.indexOf(this);
  }

  static InvestorStatus fromString(String s) {
    return InvestorStatus.values.firstWhere(
      (e) => e.name == s,
      orElse: () => InvestorStatus.identified,
    );
  }
}

class InvestorModel {
  final String id;
  final String name;
  final String firm;
  final String role;       // e.g. "Partner", "Managing Director"
  final String email;
  final String linkedIn;
  final String checkSize;  // e.g. "₹50L – ₹1Cr"
  final String stage;      // e.g. "Pre-Seed", "Seed"
  final String sector;     // e.g. "B2B SaaS, AI"
  final InvestorStatus status;
  final String notes;
  final DateTime? lastContactDate;
  final DateTime? nextFollowUpDate;
  final List<String> followUpsSent; // ISO date strings
  final int warmthScore;   // 1–5: how warm is this lead
  final bool hasFollowUpScheduled;
  final DateTime createdAt;

  const InvestorModel({
    required this.id,
    required this.name,
    required this.firm,
    this.role = '',
    this.email = '',
    this.linkedIn = '',
    this.checkSize = '',
    this.stage = '',
    this.sector = '',
    required this.status,
    this.notes = '',
    this.lastContactDate,
    this.nextFollowUpDate,
    this.followUpsSent = const [],
    this.warmthScore = 3,
    this.hasFollowUpScheduled = false,
    required this.createdAt,
  });

  int get daysSinceContact {
    if (lastContactDate == null) return -1;
    return DateTime.now().difference(lastContactDate!).inDays;
  }

  bool get isOverdue {
    if (nextFollowUpDate == null) return false;
    return DateTime.now().isAfter(nextFollowUpDate!);
  }

  InvestorModel copyWith({
    String? id,
    String? name,
    String? firm,
    String? role,
    String? email,
    String? linkedIn,
    String? checkSize,
    String? stage,
    String? sector,
    InvestorStatus? status,
    String? notes,
    DateTime? lastContactDate,
    DateTime? nextFollowUpDate,
    List<String>? followUpsSent,
    int? warmthScore,
    bool? hasFollowUpScheduled,
    DateTime? createdAt,
  }) {
    return InvestorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      firm: firm ?? this.firm,
      role: role ?? this.role,
      email: email ?? this.email,
      linkedIn: linkedIn ?? this.linkedIn,
      checkSize: checkSize ?? this.checkSize,
      stage: stage ?? this.stage,
      sector: sector ?? this.sector,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      lastContactDate: lastContactDate ?? this.lastContactDate,
      nextFollowUpDate: nextFollowUpDate ?? this.nextFollowUpDate,
      followUpsSent: followUpsSent ?? this.followUpsSent,
      warmthScore: warmthScore ?? this.warmthScore,
      hasFollowUpScheduled: hasFollowUpScheduled ?? this.hasFollowUpScheduled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ── Firestore serialization ──────────────────────────────────────────────

  factory InvestorModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return InvestorModel(
      id: docId,
      name: data['name'] ?? '',
      firm: data['firm'] ?? '',
      role: data['role'] ?? '',
      email: data['email'] ?? '',
      linkedIn: data['linkedIn'] ?? '',
      checkSize: data['checkSize'] ?? '',
      stage: data['stage'] ?? '',
      sector: data['sector'] ?? '',
      status: InvestorStatusExt.fromString(data['status'] ?? 'identified'),
      notes: data['notes'] ?? '',
      lastContactDate: data['lastContactDate'] != null
          ? DateTime.tryParse(data['lastContactDate'])
          : null,
      nextFollowUpDate: data['nextFollowUpDate'] != null
          ? DateTime.tryParse(data['nextFollowUpDate'])
          : null,
      followUpsSent: List<String>.from(data['followUpsSent'] ?? []),
      warmthScore: data['warmthScore'] ?? 3,
      hasFollowUpScheduled: data['hasFollowUpScheduled'] ?? false,
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'firm': firm,
      'role': role,
      'email': email,
      'linkedIn': linkedIn,
      'checkSize': checkSize,
      'stage': stage,
      'sector': sector,
      'status': status.name,
      'notes': notes,
      'lastContactDate': lastContactDate?.toIso8601String(),
      'nextFollowUpDate': nextFollowUpDate?.toIso8601String(),
      'followUpsSent': followUpsSent,
      'warmthScore': warmthScore,
      'hasFollowUpScheduled': hasFollowUpScheduled,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
