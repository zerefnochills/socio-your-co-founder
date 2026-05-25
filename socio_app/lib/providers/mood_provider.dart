// providers/mood_provider.dart
// Socio — Automated Mood Tracker: real-time Firestore-backed mood state
// All data is sourced from Firestore (auto-logged by chat + manual check-ins).
// No hardcoded arrays anywhere in the mood pipeline.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/lead_service.dart';
import 'auth_provider.dart';
import 'startup_provider.dart';
import 'outreach_provider.dart';

// ── Real-time mood log stream (last 7 days) ──────────────────────────────────

final moodLogsStreamProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(authStateProvider).value;
  final startup = ref.watch(startupNotifierProvider).value;

  if (user == null || startup == null) {
    return const Stream.empty();
  }

  return ref.read(leadServiceProvider).watchMoodLogs(
        uid: user.uid,
        startupId: startup.id,
      );
});

// ── Derived: daily average scores for the chart (Mon–Sun) ───────────────────

final weeklyMoodScoresProvider = Provider.autoDispose<List<double>>((ref) {
  final logs = ref.watch(moodLogsStreamProvider).value ?? [];

  final Map<int, List<double>> byDay = {
    1: [], 2: [], 3: [], 4: [], 5: [], 6: [], 7: [],
  };

  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));

  for (final log in logs) {
    final ts = log['timestamp'] as DateTime?;
    if (ts == null) continue;
    if (ts.isBefore(DateTime(weekStart.year, weekStart.month, weekStart.day))) {
      continue;
    }
    final dayOfWeek = ts.weekday;
    final rawScore = log['score'];
    double score;
    if (rawScore is double && rawScore <= 1.0) {
      score = rawScore * 5.0;
    } else {
      score = (rawScore as num).toDouble().clamp(1.0, 5.0);
    }
    byDay[dayOfWeek]!.add(score);
  }

  return List.generate(7, (i) {
    final dayScores = byDay[i + 1]!;
    if (dayScores.isEmpty) return 0.0;
    return dayScores.reduce((a, b) => a + b) / dayScores.length;
  });
});

// ── Derived: today's dominant emotion from chat logs ────────────────────────

final todayEmotionProvider = Provider.autoDispose<String>((ref) {
  final logs = ref.watch(moodLogsStreamProvider).value ?? [];
  final today = DateTime.now();

  final todayLogs = logs.where((log) {
    final ts = log['timestamp'] as DateTime?;
    if (ts == null) return false;
    return ts.year == today.year &&
        ts.month == today.month &&
        ts.day == today.day;
  }).toList();

  if (todayLogs.isEmpty) return 'Focused';
  return todayLogs.last['emotion'] as String? ?? 'Focused';
});

// ── Derived: weekly average score (0–5) ─────────────────────────────────────

final weeklyAverageMoodProvider = Provider.autoDispose<double>((ref) {
  final scores = ref.watch(weeklyMoodScoresProvider);
  final nonZero = scores.where((s) => s > 0).toList();
  if (nonZero.isEmpty) return 3.5;
  return nonZero.reduce((a, b) => a + b) / nonZero.length;
});

// ── Manual check-in submission notifier ─────────────────────────────────────

class MoodCheckInNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  MoodCheckInNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> submitCheckIn({
    required int score,
    required String emotion,
    String? note,
  }) async {
    final user = _ref.read(authStateProvider).value;
    final startup = _ref.read(startupNotifierProvider).value;
    if (user == null || startup == null) return;

    state = const AsyncValue.loading();
    try {
      await _ref.read(leadServiceProvider).saveMoodCheckIn(
            uid: user.uid,
            startupId: startup.id,
            score: score,
            emotion: emotion,
            note: note,
          );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final moodCheckInProvider =
    StateNotifierProvider.autoDispose<MoodCheckInNotifier, AsyncValue<void>>(
  (ref) => MoodCheckInNotifier(ref),
);