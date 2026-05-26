import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lead_model.dart';
import '../models/startup_model.dart';
import '../services/lead_service.dart';
import 'auth_provider.dart';
import 'startup_provider.dart';

// ── Singleton service ─────────────────────────────────────────────────────

final leadServiceProvider = Provider<LeadService>((ref) => LeadService());

// ── Live leads stream ─────────────────────────────────────────────────────

final leadsStreamProvider = StreamProvider.autoDispose<List<LeadModel>>((ref) {
  final user    = ref.watch(authStateProvider).value;
  final startup = ref.watch(startupNotifierProvider).value;

  if (user == null || startup == null) return const Stream.empty();

  return ref.read(leadServiceProvider).watchLeads(
    uid: user.uid,
    startupId: startup.id,
  );
});

// ── Lead Discovery State ─────────────────────────────────────────────────

class LeadDiscoveryState {
  final bool isLoading;
  final List<LeadModel> discoveredLeads;   // fresh from API, not yet saved
  final String? errorMessage;
  final int emailsGenerated;
  final int totalLeads;

  const LeadDiscoveryState({
    this.isLoading = false,
    this.discoveredLeads = const [],
    this.errorMessage,
    this.emailsGenerated = 0,
    this.totalLeads = 0,
  });

  LeadDiscoveryState copyWith({
    bool? isLoading,
    List<LeadModel>? discoveredLeads,
    String? errorMessage,
    int? emailsGenerated,
    int? totalLeads,
  }) =>
      LeadDiscoveryState(
        isLoading: isLoading ?? this.isLoading,
        discoveredLeads: discoveredLeads ?? this.discoveredLeads,
        errorMessage: errorMessage,
        emailsGenerated: emailsGenerated ?? this.emailsGenerated,
        totalLeads: totalLeads ?? this.totalLeads,
      );
}

class LeadDiscoveryNotifier extends AutoDisposeAsyncNotifier<LeadDiscoveryState> {
  @override
  Future<LeadDiscoveryState> build() async => const LeadDiscoveryState();

  /// Full auto-discovery flow:
  /// 1. Find leads via Tavily + Gemini
  /// 2. Save to Firestore
  /// 3. Generate emails for all in background
  Future<void> discoverAndGenerate({
    required String targetCustomer,
    required String founderName,
    bool generateEmailsImmediately = true,
  }) async {
    final service = ref.read(leadServiceProvider);
    final user    = ref.read(authStateProvider).value;
    final startup = ref.read(startupNotifierProvider).value;
    if (user == null || startup == null) return;

    // Phase 1: Discover
    state = const AsyncValue.loading();
    List<LeadModel> saved;
    try {
      final discovered = await service.discoverLeads(
        startup: startup,
        targetCustomer: targetCustomer,
        searchRounds: 3,
      );

      state = AsyncValue.data(LeadDiscoveryState(
        isLoading: true,
        discoveredLeads: discovered,
        totalLeads: discovered.length,
      ));

      saved = await service.saveLeadsToFirestore(
        uid: user.uid,
        startupId: startup.id,
        leads: discovered,
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return;
    }

    if (!generateEmailsImmediately) {
      state = AsyncValue.data(LeadDiscoveryState(
        discoveredLeads: saved,
        totalLeads: saved.length,
      ));
      return;
    }

    // Phase 2: Generate emails in background
    state = AsyncValue.data(LeadDiscoveryState(
      isLoading: true,
      discoveredLeads: saved,
      totalLeads: saved.length,
      emailsGenerated: 0,
    ));

    try {
      await service.generateEmailsForAllLeads(
        leads: saved,
        startup: startup,
        founderName: founderName,
        uid: user.uid,
        startupId: startup.id,
        onProgress: (completed, total) {
          state = AsyncValue.data(LeadDiscoveryState(
            isLoading: completed < total,
            discoveredLeads: saved,
            totalLeads: total,
            emailsGenerated: completed,
          ));
        },
      );
    } catch (e) {
      // Non-fatal — leads are saved, just emails failed
      state = AsyncValue.data(LeadDiscoveryState(
        discoveredLeads: saved,
        totalLeads: saved.length,
        errorMessage: 'Email generation partially failed: ${e.toString()}',
      ));
      return;
    }

    state = AsyncValue.data(LeadDiscoveryState(
      discoveredLeads: saved,
      totalLeads: saved.length,
      emailsGenerated: saved.length,
    ));
  }
}

final leadDiscoveryProvider =
    AsyncNotifierProvider.autoDispose<LeadDiscoveryNotifier, LeadDiscoveryState>(
  LeadDiscoveryNotifier.new,
);

// ── Investor Discovery State ──────────────────────────────────────────────

class InvestorDiscoveryState {
  final bool isLoading;
  final List<DiscoveredInvestor> investors;
  final String? errorMessage;

  const InvestorDiscoveryState({
    this.isLoading = false,
    this.investors = const [],
    this.errorMessage,
  });

  InvestorDiscoveryState copyWith({
    bool? isLoading,
    List<DiscoveredInvestor>? investors,
    String? errorMessage,
  }) =>
      InvestorDiscoveryState(
        isLoading: isLoading ?? this.isLoading,
        investors: investors ?? this.investors,
        errorMessage: errorMessage,
      );
}

class InvestorDiscoveryNotifier
    extends AutoDisposeAsyncNotifier<InvestorDiscoveryState> {
  @override
  Future<InvestorDiscoveryState> build() async =>
      const InvestorDiscoveryState();

  Future<void> discover({String geography = 'India'}) async {
    final service = ref.read(leadServiceProvider);
    final startup = ref.read(startupNotifierProvider).value;
    if (startup == null) return;

    state = const AsyncValue.loading();
    try {
      final investors = await service.discoverInvestors(
        startup: startup,
        geography: geography,
      );
      state = AsyncValue.data(InvestorDiscoveryState(investors: investors));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> enrichInvestorAt(int index, StartupModel startup) async {
    final current = state.value;
    if (current == null) return;

    final service  = ref.read(leadServiceProvider);
    final investor = current.investors[index];
    try {
      final enriched = await service.enrichInvestor(
        investor: investor,
        startup: startup,
      );
      final updated = List<DiscoveredInvestor>.from(current.investors)
        ..[index] = enriched;
      state = AsyncValue.data(current.copyWith(investors: updated));
    } catch (e) {
      // Non-fatal
    }
  }
}

final investorDiscoveryProvider = AsyncNotifierProvider.autoDispose<
    InvestorDiscoveryNotifier, InvestorDiscoveryState>(
  InvestorDiscoveryNotifier.new,
);
// ── Automated Investor Pipeline Setup ────────────────────────────────────────

class AutoPipelineState {
  final bool isRunning;
  final int savedCount;
  final String? errorMessage;
  final bool completed;

  const AutoPipelineState({
    this.isRunning = false,
    this.savedCount = 0,
    this.errorMessage,
    this.completed = false,
  });

  AutoPipelineState copyWith({
    bool? isRunning,
    int? savedCount,
    String? errorMessage,
    bool? completed,
  }) =>
      AutoPipelineState(
        isRunning:    isRunning    ?? this.isRunning,
        savedCount:   savedCount   ?? this.savedCount,
        errorMessage: errorMessage,
        completed:    completed    ?? this.completed,
      );
}

class AutoPipelineNotifier extends AutoDisposeAsyncNotifier<AutoPipelineState> {
  @override
  Future<AutoPipelineState> build() async => const AutoPipelineState();

  Future<void> runAutoSetup({String geography = 'India', int topN = 5}) async {
    final service = ref.read(leadServiceProvider);
    final user    = ref.read(authStateProvider).value;
    final startup = ref.read(startupNotifierProvider).value;
    if (user == null || startup == null) return;

    state = const AsyncValue.loading();

    try {
      state = AsyncValue.data(const AutoPipelineState(isRunning: true));
      final rawInvestors = await service.autoSetupInvestorPipeline(
        startup: startup,
        geography: geography,
        topN: topN,
      );

      final saved = await service.saveAutoInvestorsToPipeline(
        rawInvestors: rawInvestors,
        uid: user.uid,
        startupId: startup.id,
      );

      state = AsyncValue.data(AutoPipelineState(
        savedCount: saved.length,
        completed: true,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final autoPipelineProvider = AsyncNotifierProvider.autoDispose<
    AutoPipelineNotifier, AutoPipelineState>(
  AutoPipelineNotifier.new,
);