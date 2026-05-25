// providers/pipeline_provider.dart
// Socio — Investor Pipeline State (Riverpod)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/investor_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';
import 'startup_provider.dart';

// ── Pipeline list provider ───────────────────────────────────────────────────

final pipelineProvider =
    StateNotifierProvider<PipelineNotifier, AsyncValue<List<InvestorModel>>>(
  (ref) {
    final uid = ref.watch(authStateProvider).value?.uid;
    final startupId = ref.watch(startupIdProvider);
    final fs = ref.watch(firestoreServiceProvider);
    return PipelineNotifier(fs, uid, startupId);
  },
);

// Selected investor for detail view
final selectedInvestorProvider = StateProvider<InvestorModel?>((ref) => null);

// Active tab filter (null = all, or a specific InvestorStatus)
final pipelineFilterProvider = StateProvider<InvestorStatus?>((ref) => null);

// Sort mode
enum PipelineSortMode { warmth, lastContact, stage, name }
final pipelineSortProvider =
    StateProvider<PipelineSortMode>((ref) => PipelineSortMode.warmth);

// Derived: filtered + sorted investors for current view
final filteredInvestorsProvider = Provider<List<InvestorModel>>((ref) {
  final raw = ref.watch(pipelineProvider).value ?? [];
  final filter = ref.watch(pipelineFilterProvider);
  final sort = ref.watch(pipelineSortProvider);

  var list = filter == null ? raw : raw.where((i) => i.status == filter).toList();

  switch (sort) {
    case PipelineSortMode.warmth:
      list.sort((a, b) => b.warmthScore.compareTo(a.warmthScore));
      break;
    case PipelineSortMode.lastContact:
      list.sort((a, b) {
        if (a.lastContactDate == null) return 1;
        if (b.lastContactDate == null) return -1;
        return b.lastContactDate!.compareTo(a.lastContactDate!);
      });
      break;
    case PipelineSortMode.stage:
      list.sort((a, b) => a.status.columnIndex.compareTo(b.status.columnIndex));
      break;
    case PipelineSortMode.name:
      list.sort((a, b) => a.name.compareTo(b.name));
      break;
  }

  return list;
});

// Pipeline stats (counts per status)
final pipelineStatsProvider = Provider<Map<InvestorStatus, int>>((ref) {
  final raw = ref.watch(pipelineProvider).value ?? [];
  final Map<InvestorStatus, int> counts = {};
  for (final inv in raw) {
    counts[inv.status] = (counts[inv.status] ?? 0) + 1;
  }
  return counts;
});

// Overdue follow-ups
final overdueInvestorsProvider = Provider<List<InvestorModel>>((ref) {
  final raw = ref.watch(pipelineProvider).value ?? [];
  return raw.where((i) => i.isOverdue && i.status.isActive).toList();
});

// ── Notifier ─────────────────────────────────────────────────────────────────

class PipelineNotifier extends StateNotifier<AsyncValue<List<InvestorModel>>> {
  final FirestoreService _fs;
  final String? _uid;
  final String? _startupId;

  PipelineNotifier(this._fs, this._uid, this._startupId)
      : super(const AsyncValue.loading()) {
    if (_uid != null && _startupId != null && _startupId!.isNotEmpty) _listen();
  }

  void _listen() {
    _fs
        .investorsStream(_uid!, _startupId!)
        .listen(
          (list) => state = AsyncValue.data(list),
          onError: (e, st) => state = AsyncValue.error(e, st),
        );
  }

  Future<void> addInvestor(InvestorModel investor) async {
    if (_uid == null || _startupId == null || _startupId!.isEmpty) return;
    await _fs.addInvestor(_uid!, _startupId!, investor);
  }

  Future<void> updateStatus(String investorId, InvestorStatus newStatus) async {
    if (_uid == null || _startupId == null || _startupId!.isEmpty) return;
    await _fs.updateInvestorStatus(_uid!, _startupId!, investorId, newStatus);
  }

  Future<void> updateInvestor(InvestorModel investor) async {
    if (_uid == null || _startupId == null || _startupId!.isEmpty) return;
    await _fs.updateInvestor(_uid!, _startupId!, investor);
  }

  Future<void> deleteInvestor(String investorId) async {
    if (_uid == null || _startupId == null || _startupId!.isEmpty) return;
    await _fs.deleteInvestor(_uid!, _startupId!, investorId);
  }

  Future<void> recordFollowUp(String investorId) async {
    if (_uid == null || _startupId == null || _startupId!.isEmpty) return;
    final investors = state.value ?? [];
    final investor = investors.firstWhere((i) => i.id == investorId);
    final updated = investor.copyWith(
      lastContactDate: DateTime.now(),
      followUpsSent: [
        ...investor.followUpsSent,
        DateTime.now().toIso8601String(),
      ],
      // Auto-schedule next follow-up in 5 days
      nextFollowUpDate: DateTime.now().add(const Duration(days: 5)),
    );
    await _fs.updateInvestor(_uid!, _startupId!, updated);
  }
}
