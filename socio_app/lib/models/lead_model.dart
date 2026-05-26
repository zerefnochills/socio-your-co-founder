import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single auto-discovered outreach lead.
/// Stored under: users/{uid}/startups/{sid}/leads/{lead_id}
class LeadModel {
  final String id;
  final String company;
  final String domain;
  final String fitReason;
  final String decisionMakerTitle;
  final String companySize;    // "startup" | "SMB" | "mid-market" | "enterprise"
  final String budgetSignal;
  final int priorityScore;     // 0-100

  // Set after email is generated
  final String? emailSubject;
  final String? emailBody;

  // Workflow state
  final LeadStatus status;
  final DateTime discoveredAt;
  final DateTime? emailGeneratedAt;
  final DateTime? emailSentAt;

  const LeadModel({
    required this.id,
    required this.company,
    required this.domain,
    required this.fitReason,
    required this.decisionMakerTitle,
    required this.companySize,
    required this.budgetSignal,
    required this.priorityScore,
    this.emailSubject,
    this.emailBody,
    required this.status,
    required this.discoveredAt,
    this.emailGeneratedAt,
    this.emailSentAt,
  });

  // ── Firestore serialisation ─────────────────────────────────────────────

  factory LeadModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return LeadModel(
      id: doc.id,
      company: d['company'] ?? '',
      domain: d['domain'] ?? '',
      fitReason: d['fit_reason'] ?? '',
      decisionMakerTitle: d['decision_maker_title'] ?? '',
      companySize: d['company_size'] ?? '',
      budgetSignal: d['budget_signal'] ?? '',
      priorityScore: (d['priority_score'] ?? 0) as int,
      emailSubject: d['email_subject'],
      emailBody: d['email_body'],
      status: LeadStatus.fromString(d['status'] ?? 'discovered'),
      discoveredAt: (d['discovered_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      emailGeneratedAt: (d['email_generated_at'] as Timestamp?)?.toDate(),
      emailSentAt: (d['email_sent_at'] as Timestamp?)?.toDate(),
    );
  }

  /// Construct from JSON returned by /find-leads endpoint
  factory LeadModel.fromApiJson(Map<String, dynamic> json) {
    return LeadModel(
      id: '',  // assigned by Firestore
      company: json['company'] ?? '',
      domain: json['domain'] ?? '',
      fitReason: json['fit_reason'] ?? '',
      decisionMakerTitle: json['decision_maker_title'] ?? '',
      companySize: json['company_size'] ?? '',
      budgetSignal: json['budget_signal'] ?? '',
      priorityScore: (json['priority_score'] ?? 0) as int,
      status: LeadStatus.discovered,
      discoveredAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'company': company,
    'domain': domain,
    'fit_reason': fitReason,
    'decision_maker_title': decisionMakerTitle,
    'company_size': companySize,
    'budget_signal': budgetSignal,
    'priority_score': priorityScore,
    'email_subject': emailSubject,
    'email_body': emailBody,
    'status': status.value,
    'discovered_at': Timestamp.fromDate(discoveredAt),
    'email_generated_at': emailGeneratedAt != null ? Timestamp.fromDate(emailGeneratedAt!) : null,
    'email_sent_at': emailSentAt != null ? Timestamp.fromDate(emailSentAt!) : null,
  };

  LeadModel copyWith({
    String? id,
    String? emailSubject,
    String? emailBody,
    LeadStatus? status,
    DateTime? emailGeneratedAt,
    DateTime? emailSentAt,
  }) =>
      LeadModel(
        id: id ?? this.id,
        company: company,
        domain: domain,
        fitReason: fitReason,
        decisionMakerTitle: decisionMakerTitle,
        companySize: companySize,
        budgetSignal: budgetSignal,
        priorityScore: priorityScore,
        emailSubject: emailSubject ?? this.emailSubject,
        emailBody: emailBody ?? this.emailBody,
        status: status ?? this.status,
        discoveredAt: discoveredAt,
        emailGeneratedAt: emailGeneratedAt ?? this.emailGeneratedAt,
        emailSentAt: emailSentAt ?? this.emailSentAt,
      );
}

// ── Status enum ────────────────────────────────────────────────────────────

enum LeadStatus {
  discovered,       // found by AI, no email yet
  emailReady,       // email generated, not sent
  sent,             // founder marked as sent
  replied,          // got a reply
  notInterested,    // dead lead
  converted;        // became a customer

  String get value => name;

  static LeadStatus fromString(String s) =>
      LeadStatus.values.firstWhere(
        (e) => e.value == s,
        orElse: () => LeadStatus.discovered,
      );

  String get label {
    switch (this) {
      case LeadStatus.discovered:    return 'Discovered';
      case LeadStatus.emailReady:    return 'Email Ready';
      case LeadStatus.sent:          return 'Sent';
      case LeadStatus.replied:       return 'Replied';
      case LeadStatus.notInterested: return 'Not Interested';
      case LeadStatus.converted:     return 'Converted';
    }
  }
}


/// Discovered investor from /find-investors endpoint.
/// Stored as a suggested card before the founder accepts it to the pipeline.
class DiscoveredInvestor {
  final String investorName;
  final String firm;
  final String fitReason;
  final String stage;
  final String sectorFocus;
  final String recentSignal;
  final String contactApproach;
  final String warmth;          // "cold" | "lukewarm" | "warm"
  final int priorityScore;

  // Enrichment data (from /enrich-investor, loaded on demand)
  final String? recentActivity;
  final String? relevanceNote;
  final String? suggestedAction;
  final String? bestHook;

  const DiscoveredInvestor({
    required this.investorName,
    required this.firm,
    required this.fitReason,
    required this.stage,
    required this.sectorFocus,
    required this.recentSignal,
    required this.contactApproach,
    required this.warmth,
    required this.priorityScore,
    this.recentActivity,
    this.relevanceNote,
    this.suggestedAction,
    this.bestHook,
  });

  factory DiscoveredInvestor.fromApiJson(Map<String, dynamic> json) {
    return DiscoveredInvestor(
      investorName: json['investor_name'] ?? '',
      firm: json['firm'] ?? '',
      fitReason: json['fit_reason'] ?? '',
      stage: json['stage'] ?? '',
      sectorFocus: json['sector_focus'] ?? '',
      recentSignal: json['recent_signal'] ?? '',
      contactApproach: json['contact_approach'] ?? '',
      warmth: json['warmth'] ?? 'cold',
      priorityScore: (json['priority_score'] ?? 0) as int,
    );
  }

  DiscoveredInvestor withEnrichment(Map<String, dynamic> enrichData) {
    return DiscoveredInvestor(
      investorName: investorName,
      firm: firm,
      fitReason: fitReason,
      stage: stage,
      sectorFocus: sectorFocus,
      recentSignal: recentSignal,
      contactApproach: contactApproach,
      warmth: warmth,
      priorityScore: priorityScore,
      recentActivity: enrichData['recent_activity'],
      relevanceNote: enrichData['relevance_note'],
      suggestedAction: enrichData['suggested_action'],
      bestHook: enrichData['best_hook'],
    );
  }
}
