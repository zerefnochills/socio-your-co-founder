// services/lead_service.dart
// Socio — Handles all automated lead + investor discovery, enrichment, follow-ups, and radar intelligence

import 'package:dio/dio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lead_model.dart';
import '../models/investor_model.dart';
import '../models/startup_model.dart';
import 'api_config.dart';

class LeadService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60), // Tavily + LLM can be slow
    headers: {'Content-Type': 'application/json'},
  ));

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── LEAD DISCOVERY ────────────────────────────────────────────────────────

  /// Calls /find-leads on the backend.
  /// Returns a list of discovered leads (NOT yet saved to Firestore).
  Future<List<LeadModel>> discoverLeads({
    required StartupModel startup,
    required String targetCustomer,
    int searchRounds = 3,
  }) async {
    final response = await _dio.post('/find-leads', data: {
      'startup_name': startup.name,
      'startup_idea': startup.idea,
      'startup_stage': startup.stage,
      'target_customer': targetCustomer,
      'num_search_rounds': searchRounds,
    });

    final List<dynamic> rawLeads = response.data['leads'] ?? [];
    return rawLeads
        .map((json) => LeadModel.fromApiJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Saves discovered leads to Firestore under the given startup.
  Future<List<LeadModel>> saveLeadsToFirestore({
    required String uid,
    required String startupId,
    required List<LeadModel> leads,
  }) async {
    final col = _db
        .collection('users')
        .doc(uid)
        .collection('startups')
        .doc(startupId)
        .collection('leads');

    final savedLeads = <LeadModel>[];
    for (final lead in leads) {
      final doc = await col.add(lead.toFirestore());
      savedLeads.add(lead.copyWith(id: doc.id));
    }
    return savedLeads;
  }

  /// Stream all leads for a startup (real-time Firestore updates).
  Stream<List<LeadModel>> watchLeads({
    required String uid,
    required String startupId,
  }) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('startups')
        .doc(startupId)
        .collection('leads')
        .orderBy('priority_score', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(LeadModel.fromFirestore).toList());
  }

  // ── EMAIL GENERATION ──────────────────────────────────────────────────────

  /// Calls /generate-outreach-email for a single lead.
  /// Returns {subject, body} and updates the lead in Firestore.
  Future<LeadModel> generateEmailForLead({
    required LeadModel lead,
    required StartupModel startup,
    required String founderName,
    required String uid,
    required String startupId,
  }) async {
    final response = await _dio.post('/generate-outreach-email', data: {
      'startup_name': startup.name,
      'startup_idea': startup.idea,
      'founder_name': founderName,
      'target_company': lead.company,
      'target_domain': lead.domain,
      'decision_maker_title': lead.decisionMakerTitle,
      'fit_reason': lead.fitReason,
      'budget_signal': lead.budgetSignal,
    });

    final subject = response.data['subject'] as String? ?? '';
    final body    = response.data['body']    as String? ?? '';

    // Update Firestore
    await _db
        .collection('users')
        .doc(uid)
        .collection('startups')
        .doc(startupId)
        .collection('leads')
        .doc(lead.id)
        .update({
          'email_subject': subject,
          'email_body': body,
          'status': LeadStatus.emailReady.value,
          'email_generated_at': FieldValue.serverTimestamp(),
        });

    return lead.copyWith(
      emailSubject: subject,
      emailBody: body,
      status: LeadStatus.emailReady,
      emailGeneratedAt: DateTime.now(),
    );
  }

  /// Generates emails for ALL leads in parallel (batch mode).
  Future<void> generateEmailsForAllLeads({
    required List<LeadModel> leads,
    required StartupModel startup,
    required String founderName,
    required String uid,
    required String startupId,
    void Function(int completed, int total)? onProgress,
  }) async {
    int completed = 0;
    // Process in batches of 3 to avoid overwhelming the backend
    const batchSize = 3;
    final eligibleLeads = leads
        .where((l) => l.emailBody == null || l.emailBody!.isEmpty)
        .toList();

    for (int i = 0; i < eligibleLeads.length; i += batchSize) {
      final batch = eligibleLeads.skip(i).take(batchSize).toList();
      await Future.wait(
        batch.map((lead) async {
          try {
            await generateEmailForLead(
              lead: lead,
              startup: startup,
              founderName: founderName,
              uid: uid,
              startupId: startupId,
            );
            completed++;
            onProgress?.call(completed, eligibleLeads.length);
          } catch (e) {
            // Non-fatal — skip this lead, log and continue
            print('Email gen failed for ${lead.company}: $e');
          }
        }),
      );
      // Small delay between batches to be polite to the backend
      if (i + batchSize < eligibleLeads.length) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  /// Update lead status in Firestore (e.g. mark as sent, replied, etc.)
  Future<void> updateLeadStatus({
    required String uid,
    required String startupId,
    required String leadId,
    required LeadStatus status,
  }) async {
    final Map<String, dynamic> update = {'status': status.value};
    if (status == LeadStatus.sent) {
      update['email_sent_at'] = FieldValue.serverTimestamp();
    }
    await _db
        .collection('users')
        .doc(uid)
        .collection('startups')
        .doc(startupId)
        .collection('leads')
        .doc(leadId)
        .update(update);
  }

  // ── INVESTOR DISCOVERY ────────────────────────────────────────────────────

  /// Calls /find-investors on the backend.
  Future<List<DiscoveredInvestor>> discoverInvestors({
    required StartupModel startup,
    String geography = 'India',
  }) async {
    final response = await _dio.post('/find-investors', data: {
      'startup_name': startup.name,
      'startup_idea': startup.idea,
      'startup_stage': startup.stage,
      'mrr': startup.mrr,
      'user_count': startup.userCount,
      'geography': geography,
    });

    final List<dynamic> raw = response.data['investors'] ?? [];
    return raw
        .map((json) => DiscoveredInvestor.fromApiJson(json as Map<String, dynamic>))
        .toList();
  }

  // ── INVESTOR ENRICHMENT ───────────────────────────────────────────────────

  /// Calls /enrich-investor to get latest news + suggested action.
  Future<DiscoveredInvestor> enrichInvestor({
    required DiscoveredInvestor investor,
    required StartupModel startup,
  }) async {
    final response = await _dio.post('/enrich-investor', data: {
      'investor_name': investor.investorName,
      'firm': investor.firm,
      'startup_name': startup.name,
      'startup_idea': startup.idea,
    });

    return investor.withEnrichment(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  /// Enriches an InvestorModel already in the pipeline and saves to Firestore.
  Future<Map<String, dynamic>> enrichPipelineInvestor({
    required InvestorModel investor,
    required StartupModel startup,
    required String uid,
    required String startupId,
  }) async {
    final response = await _dio.post('/enrich-investor', data: {
      'investor_name': investor.name,
      'firm': investor.firm,
      'startup_name': startup.name,
      'startup_idea': startup.idea,
    });

    final enrichData = Map<String, dynamic>.from(response.data as Map);

    // Save enrichment to Firestore so it's cached
    await _db
        .collection('users')
        .doc(uid)
        .collection('startups')
        .doc(startupId)
        .collection('investors')
        .doc(investor.id)
        .update({
          'enrichment': enrichData,
          'enriched_at': FieldValue.serverTimestamp(),
        });

    return enrichData;
  }

  // ── INVESTOR FOLLOW-UPS ───────────────────────────────────────────────────

  /// Generates a personalized follow-up email JSON for an investor.
  Future<Map<String, dynamic>> generateFollowUp({
    required InvestorModel investor,
    required StartupModel? startup,
  }) async {
    final response = await _dio.post('/investor-followup', data: {
      'investor_name': investor.name,
      'investor_firm': investor.firm,
      'meeting_notes': investor.notes,
      'days_since_contact': investor.daysSinceContact,
      'status': investor.status.label,
      'startup_name': startup?.name ?? 'My Startup',
      'traction': startup != null
          ? 'MRR: ${startup.mrr}, Users: ${startup.userCount}'
          : 'Early stage, building MVP',
    });
    return Map<String, dynamic>.from(response.data as Map);
  }

  // ── COMPETITOR RADAR ──────────────────────────────────────────────────────

  /// Scans for competitors based on the startup's idea and company name.
  Future<List<dynamic>> fetchCompetitors({
    required String idea,
    required String companyName,
  }) async {
    final response = await _dio.post('/competitor-radar', data: {
      'idea': idea,
      'company_name': companyName.isNotEmpty ? companyName : 'My Startup',
    });
    return response.data['competitors'] ?? [];
  }
}
