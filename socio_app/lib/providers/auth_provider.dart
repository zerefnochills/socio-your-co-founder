import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

// ── Service instance ──────────────────────────────────────────
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// ── Auth state stream — drives the root navigation in main.dart ──
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// ── Current user UID ──────────────────────────────────────────
final currentUidProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).value?.uid;
});

// ── Display name (first name only) ───────────────────────────
final founderNameProvider = Provider<String>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return 'Founder';
  return user.displayName?.split(' ').first ?? 'Founder';
});

// ── Sign-in state notifier ────────────────────────────────────
class SignInNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> signInWithGoogle() async {
    state = const AsyncLoading();
    try {
      final result = await ref.read(authServiceProvider).signInWithGoogle();
      state = const AsyncData(null);
      return result != null; // true = success, false = user cancelled
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    try {
      await ref.read(authServiceProvider).signOut();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final signInNotifierProvider =
    AsyncNotifierProvider<SignInNotifier, void>(SignInNotifier.new);
