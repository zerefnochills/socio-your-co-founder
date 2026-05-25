import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/startup_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ChatService — handles SSE streaming to FastAPI /chat
// Returns a Stream<ChatChunk> so the UI can update word-by-word
// ─────────────────────────────────────────────────────────────────────────────

// ── Config ────────────────────────────────────────────────────────────────────
// Swap this if using deployed Render URL
final String _kBaseUrl = 'http://localhost:8000'; // Dynamic localhost forwarded via adb reverse


// ── Data types ────────────────────────────────────────────────────────────────

enum ChunkType { mood, text, done, error }

class ChatChunk {
  final ChunkType type;
  final String? text;
  final MoodData? mood;

  const ChatChunk({required this.type, this.text, this.mood});
}

class MoodData {
  final String emotion;
  final double score;
  final bool needsSos;
  final Map<String, double> personaWeights;

  const MoodData({
    required this.emotion,
    required this.score,
    required this.needsSos,
    required this.personaWeights,
  });

  factory MoodData.fromJson(Map<String, dynamic> json) => MoodData(
        emotion: json['emotion'] as String? ?? 'neutral',
        score: (json['score'] as num?)?.toDouble() ?? 0.5,
        needsSos: json['needs_sos'] as bool? ?? false,
        personaWeights: Map<String, double>.from(
          (json['persona_weights'] as Map<String, dynamic>? ?? {}).map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ),
        ),
      );
}

// ── Service ───────────────────────────────────────────────────────────────────

class ChatService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _kBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
      responseType: ResponseType.stream,
    ),
  );

  /// Streams chunks from /chat SSE endpoint.
  Stream<ChatChunk> streamChat({
    required String message,
    required StartupModel context,
    required String founderName,
    required List<Map<String, String>> history, // [{role, content}, ...]
  }) async* {
    try {
      final response = await _dio.post<ResponseBody>(
        '/chat',
        data: {
          'message': message,
          ...context.toApiContext(),
          'founder_name': founderName,
          'history': history,
        },
        options: Options(responseType: ResponseType.stream),
      );

      final stream = response.data!.stream;
      final buffer = StringBuffer();

      await for (final chunk in stream) {
        buffer.write(utf8.decode(chunk));
        final raw = buffer.toString();
        buffer.clear();

        // SSE lines come as "data: {...}\n\n"
        for (final line in raw.split('\n')) {
          final trimmed = line.trim();
          if (!trimmed.startsWith('data: ')) continue;

          final jsonStr = trimmed.substring(6);
          if (jsonStr.isEmpty) continue;

          try {
            final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
            final type = parsed['type'] as String? ?? '';

            if (type == 'mood') {
              final moodJson = parsed['data'] as Map<String, dynamic>? ?? {};
              yield ChatChunk(
                type: ChunkType.mood,
                mood: MoodData.fromJson(moodJson),
              );
            } else if (type == 'text') {
              yield ChatChunk(
                type: ChunkType.text,
                text: parsed['data'] as String? ?? '',
              );
            } else if (type == 'done') {
              yield const ChatChunk(type: ChunkType.done);
              return;
            }
          } catch (_) {
            // Partial JSON in buffer — append to next chunk
            buffer.write(trimmed);
          }
        }
      }
    } on DioException catch (e) {
      yield ChatChunk(
        type: ChunkType.error,
        text: _dioErrorMessage(e),
      );
    } catch (e) {
      yield ChatChunk(type: ChunkType.error, text: e.toString());
    }
  }

  String _dioErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Check your backend is running.';
      case DioExceptionType.connectionError:
        return 'Could not reach Socio backend. Is it running?';
      default:
        return 'Something went wrong (${e.response?.statusCode ?? 'unknown'})';
    }
  }
}
