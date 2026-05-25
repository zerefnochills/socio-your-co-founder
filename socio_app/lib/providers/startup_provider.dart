import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/startup_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

// ── Service instance ──────────────────────────────────────────
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// ── Load primary startup (used everywhere) ────────────────────
// Returns a Future — resolves once on first load
final startupFutureProvider = FutureProvider<StartupModel>((ref) async {
  // Re-fetch when auth changes (i.e. on sign-in / sign-out)
  ref.watch(authStateProvider);
  return ref.read(firestoreServiceProvider).getOrCreateStartup();
});

// ── Startup notifier — manages saving + updating context ──────
class StartupNotifier extends AsyncNotifier<StartupModel> {
  @override
  Future<StartupModel> build() async {
    return ref.read(firestoreServiceProvider).getOrCreateStartup();
  }

  /// Save startup context — called from onboarding screen
  Future<void> save(StartupModel startup) async {
    state = const AsyncLoading();
    try {
      final saved =
          await ref.read(firestoreServiceProvider).saveStartup(startup);
      state = AsyncData(saved);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Update a single field without replacing everything
  Future<void> updateField({
    String? name,
    String? idea,
    String? stage,
    String? mrr,
    String? userCount,
  }) async {
    final current = state.value;
    if (current == null) return;

    final updated = current.copyWith(
      name: name,
      idea: idea,
      stage: stage,
      mrr: mrr,
      userCount: userCount,
    );

    await save(updated);
  }
}

final startupNotifierProvider =
    AsyncNotifierProvider<StartupNotifier, StartupModel>(
  StartupNotifier.new,
);

// ── Convenience: current startup ID ──────────────────────────
final startupIdProvider = Provider<String>((ref) {
  return ref.watch(startupNotifierProvider).value?.id ?? '';
});

// ── Convenience: API context map ready to send to backend ─────
// Use this in chat_service, outreach_service etc.
final apiContextProvider = Provider<Map<String, dynamic>>((ref) {
  final startup = ref.watch(startupNotifierProvider).value;
  if (startup == null) {
    return {
      'startup_name': 'My Startup',
      'startup_idea': '',
      'startup_stage': 'Idea stage',
      'mrr': '0',
      'user_count': '0',
    };
  }
  return startup.toApiContext();
});