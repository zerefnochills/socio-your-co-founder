import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/outreach_service.dart';
import '../services/firestore_service.dart';
import 'startup_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OutreachProvider — Riverpod state for cold outreach generation
// ─────────────────────────────────────────────────────────────────────────────

// ── State ─────────────────────────────────────────────────────────────────────

enum OutreachStatus { idle, loading, success, error }

class OutreachState {
  final OutreachStatus status;
  final OutreachResult? result;
  final String? error;

  // Form fields (kept in state so they survive tab switches)
  final String targetName;
  final String targetCompany;
  final String targetRole;
  final String traction;
  final String ask;

  const OutreachState({
    this.status = OutreachStatus.idle,
    this.result,
    this.error,
    this.targetName = '',
    this.targetCompany = '',
    this.targetRole = '',
    this.traction = 'Early stage, building MVP',
    this.ask = '15-minute intro call',
  });

  bool get isLoading => status == OutreachStatus.loading;
  bool get hasResult => status == OutreachStatus.success && result != null;
  bool get canGenerate =>
      targetName.trim().isNotEmpty && targetCompany.trim().isNotEmpty;

  OutreachState copyWith({
    OutreachStatus? status,
    OutreachResult? result,
    String? error,
    String? targetName,
    String? targetCompany,
    String? targetRole,
    String? traction,
    String? ask,
  }) =>
      OutreachState(
        status: status ?? this.status,
        result: result ?? this.result,
        error: error ?? this.error,
        targetName: targetName ?? this.targetName,
        targetCompany: targetCompany ?? this.targetCompany,
        targetRole: targetRole ?? this.targetRole,
        traction: traction ?? this.traction,
        ask: ask ?? this.ask,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class OutreachNotifier extends StateNotifier<OutreachState> {
  final Ref _ref;
  final OutreachService _service;

  OutreachNotifier(this._ref, this._service) : super(const OutreachState());

  void updateField({
    String? targetName,
    String? targetCompany,
    String? targetRole,
    String? traction,
    String? ask,
  }) {
    state = state.copyWith(
      targetName: targetName,
      targetCompany: targetCompany,
      targetRole: targetRole,
      traction: traction,
      ask: ask,
    );
  }

  Future<void> generate() async {
    if (!state.canGenerate) return;

    state = state.copyWith(status: OutreachStatus.loading, error: null);

    try {
      final startup = _ref.read(startupNotifierProvider).value;
      final startupName = startup?.name ?? 'My Startup';
      final startupIdea = startup?.idea ?? 'A great product';

      final result = await _service.generate(
        OutreachRequest(
          targetName: state.targetName.trim(),
          targetCompany: state.targetCompany.trim(),
          targetRole: state.targetRole.trim().isEmpty
              ? 'Decision maker'
              : state.targetRole.trim(),
          startupName: startupName,
          startupIdea: startupIdea,
          traction: state.traction.trim().isEmpty
              ? 'Early stage, building MVP'
              : state.traction.trim(),
          ask: state.ask.trim().isEmpty
              ? '15-minute intro call'
              : state.ask.trim(),
        ),
      );

      state = state.copyWith(
        status: OutreachStatus.success,
        result: result,
      );

      // Save to Firestore outreach collection
      final startupId = _ref.read(startupIdProvider);
      if (startupId.isNotEmpty) {
        await _ref.read(firestoreServiceProvider).saveOutreach(
          startupId,
          {
            'target_name': state.targetName.trim(),
            'target_company': state.targetCompany.trim(),
            'target_role': state.targetRole.trim().isEmpty
                ? 'Decision maker'
                : state.targetRole.trim(),
            'email_body': result.coldEmailBody,
            'call_script': result.callScript,
            'followups': result.followUps
                .map((f) => {
                      'day': f.day,
                      'subject': f.subject,
                      'body': f.body,
                    })
                .toList(),
          },
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: OutreachStatus.error,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void reset() => state = const OutreachState();
}

// ── Providers ─────────────────────────────────────────────────────────────────

final outreachServiceProvider =
    Provider<OutreachService>((_) => OutreachService());

final outreachProvider =
    StateNotifierProvider<OutreachNotifier, OutreachState>((ref) {
  return OutreachNotifier(ref, ref.read(outreachServiceProvider));
});
