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

// ── AUTO PIPELINE SETUP ───────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> autoSetupInvestorPipeline({
    required StartupModel startup,
    String geography = 'India',
    int topN = 5,
  }) async {
    final response = await _dio.post('/auto-setup-investor-pipeline', data: {
      'startup_name':  startup.name,
      'startup_idea':  startup.idea,
      'startup_stage': startup.stage,
      'mrr':           startup.mrr,
      'user_count':    startup.userCount,
      'geography':     geography,
      'top_n':         topN,
    });
    final List<dynamic> raw = response.data['pipeline_investors'] ?? [];
    return raw.cast<Map<String, dynamic>>();
  }

  Future<InvestorModel> saveDiscoveredInvestorToPipeline({
    required DiscoveredInvestor discovered,
    required String uid,
    required String startupId,
  }) async {
    final warmthScore = discovered.warmth == 'warm' ? 4
        : discovered.warmth == 'lukewarm' ? 3 : 2;

    final investor = InvestorModel(
      id: '',
      name: discovered.investorName,
      firm: discovered.firm,
      role: '',
      email: '',
      checkSize: '',
      stage: discovered.stage,
      sector: discovered.sectorFocus,
      notes: [
        if (discovered.fitReason.isNotEmpty) 'Fit: ${discovered.fitReason}',
        if (discovered.recentSignal.isNotEmpty) 'Signal: ${discovered.recentSignal}',
        if (discovered.contactApproach.isNotEmpty) 'Approach: ${discovered.contactApproach}',
        if ((discovered.bestHook ?? '').isNotEmpty) 'Hook: ${discovered.bestHook}',
      ].join('\n'),
      status: InvestorStatus.identified,
      warmthScore: warmthScore,
      createdAt: DateTime.now(),
    );

    final col = _db
        .collection('users').doc(uid)
        .collection('startups').doc(startupId)
        .collection('investors');

    final doc = await col.add(investor.toFirestore());
    return investor.copyWith(id: doc.id);
  }

  Future<List<InvestorModel>> saveAutoInvestorsToPipeline({
    required List<Map<String, dynamic>> rawInvestors,
    required String uid,
    required String startupId,
  }) async {
    final col = _db
        .collection('users').doc(uid)
        .collection('startups').doc(startupId)
        .collection('investors');

    final existing = await col.get();
    final existingNames = existing.docs
        .map((d) => (d.data()['name'] as String? ?? '').toLowerCase())
        .toSet();

    final saved = <InvestorModel>[];
    for (final raw in rawInvestors) {
      final name = (raw['investor_name'] as String? ?? '').trim();
      if (name.isEmpty || existingNames.contains(name.toLowerCase())) continue;

      final warmthRaw   = (raw['warmth'] as String? ?? 'cold').toLowerCase();
      final warmthScore = warmthRaw == 'warm' ? 4 : warmthRaw == 'lukewarm' ? 3 : 2;

      final investor = InvestorModel(
        id: '',
        name: name,
        firm: raw['firm'] as String? ?? '',
        role: '',
        email: '',
        checkSize: '',
        stage: raw['stage'] as String? ?? '',
        sector: raw['sector_focus'] as String? ?? '',
        notes: [
          if ((raw['fit_reason'] as String? ?? '').isNotEmpty)
            'Fit: ${raw['fit_reason']}',
          if ((raw['recent_signal'] as String? ?? '').isNotEmpty)
            'Signal: ${raw['recent_signal']}',
          if ((raw['contact_approach'] as String? ?? '').isNotEmpty)
            'Approach: ${raw['contact_approach']}',
          if ((raw['enrichment_summary'] as String? ?? '').isNotEmpty)
            'Intel: ${(raw['enrichment_summary'] as String).substring(0, ((raw['enrichment_summary'] as String).length).clamp(0, 200))}',
        ].join('\n'),
        status: InvestorStatus.identified,
        warmthScore: warmthScore,
        createdAt: DateTime.now(),
      );

      final doc = await col.add(investor.toFirestore());
      saved.add(investor.copyWith(id: doc.id));
      existingNames.add(name.toLowerCase());
    }
    return saved;
  }

  // ── MOOD LOGS ─────────────────────────────────────────────────────────────

  Future<void> saveMoodCheckIn({
    required String uid,
    required String startupId,
    required int score,
    required String emotion,
    String? note,
  }) async {
    await _db
        .collection('users').doc(uid)
        .collection('startups').doc(startupId)
        .collection('mood_logs')
        .add({
          'score':     score,
          'emotion':   emotion,
          'note':      note ?? '',
          'source':    'manual_checkin',
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  Future<List<Map<String, dynamic>>> fetchMoodLogs({
    required String uid,
    required String startupId,
    int days = 7,
  }) async {
    final since = DateTime.now().subtract(Duration(days: days));
    final snap = await _db
        .collection('users').doc(uid)
        .collection('startups').doc(startupId)
        .collection('mood_logs')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(since))
        .orderBy('timestamp', descending: false)
        .get();

    return snap.docs.map((d) {
      final data = d.data();
      return {
        'score':     data['score'] ?? 3,
        'emotion':   data['emotion'] ?? 'neutral',
        'note':      data['note'] ?? '',
        'source':    data['source'] ?? 'chat',
        'timestamp': (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      };
    }).toList();
  }

  Stream<List<Map<String, dynamic>>> watchMoodLogs({
    required String uid,
    required String startupId,
    int days = 7,
  }) {
    final since = DateTime.now().subtract(Duration(days: days));
    return _db
        .collection('users').doc(uid)
        .collection('startups').doc(startupId)
        .collection('mood_logs')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(since))
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              return <String, dynamic>{
                'score':     data['score'] ?? 3,
                'emotion':   data['emotion'] ?? 'neutral',
                'note':      data['note'] ?? '',
                'source':    data['source'] ?? 'chat',
                'timestamp': (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
              };
            }).toList());
  }
}  // <-- this closes the LeadService class