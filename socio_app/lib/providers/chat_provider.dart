import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/message_model.dart';
import '../models/startup_model.dart';
import '../services/chat_service.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';
import 'startup_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ChatProvider — Riverpod state management for the chat screen
// Handles: message history, SSE streaming, mood updates, STT, startup context
// ─────────────────────────────────────────────────────────────────────────────

// ── State ─────────────────────────────────────────────────────────────────────

class ChatState {
  final List<MessageModel> messages;
  final bool isStreaming;
  final bool isListening; // STT active
  final MoodData? latestMood;
  final StartupModel? startupContext;
  final String? errorBanner; // transient error shown at top

  const ChatState({
    this.messages = const [],
    this.isStreaming = false,
    this.isListening = false,
    this.latestMood,
    this.startupContext,
    this.errorBanner,
  });

  ChatState copyWith({
    List<MessageModel>? messages,
    bool? isStreaming,
    bool? isListening,
    MoodData? latestMood,
    StartupModel? startupContext,
    String? errorBanner,
    bool clearError = false,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        isStreaming: isStreaming ?? this.isStreaming,
        isListening: isListening ?? this.isListening,
        latestMood: latestMood ?? this.latestMood,
        startupContext: startupContext ?? this.startupContext,
        errorBanner: clearError ? null : (errorBanner ?? this.errorBanner),
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref _ref;
  final ChatService _service;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _hasInitialized = false;

  ChatNotifier(this._ref, this._service) : super(const ChatState()) {
    _initSpeech();
  }

  // ── STT init ────────────────────────────────────────────────────────────────
  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onError: (e) => _showError('Mic error: ${e.errorMsg}'),
      );
    } catch (_) {
      _speechAvailable = false;
    }
  }

  // ── Set startup context (call after Firestore load) ─────────────────────────
  void setStartupContext(StartupModel ctx) async {
    state = state.copyWith(startupContext: ctx);

    if (_hasInitialized) return;
    _hasInitialized = true;

    final startupId = _ref.read(startupIdProvider);
    if (startupId.isEmpty) return;

    // Load recent messages from Firestore!
    try {
      final recent = await _ref.read(firestoreServiceProvider).getRecentMessages(startupId);
      state = state.copyWith(messages: recent);
    } catch (e) {
      _showError('Failed to load chat history.');
    }

    // Add Socio welcome message if chat is empty
    if (state.messages.isEmpty) {
      final founderName = _ref.read(founderNameProvider);
      final welcomeContent = "Hey $founderName, I've loaded your startup context — **${ctx.name.isEmpty ? 'My Startup' : ctx.name}**.\n\nI'm your co-founder now. What's on your mind today?";
      _addSocioMessage(welcomeContent);
      
      // Save welcome message to Firestore
      final welcomeMsg = MessageModel(
        id: '',
        role: MessageRole.socio,
        content: welcomeContent,
        timestamp: DateTime.now(),
      );
      await _ref.read(firestoreServiceProvider).saveMessage(startupId, welcomeMsg);
    }
  }

  // ── Send a message ──────────────────────────────────────────────────────────
  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isStreaming) return;

    final ctx = state.startupContext;
    if (ctx == null) {
      _showError('Startup context not loaded yet. Please wait.');
      return;
    }

    final startupId = _ref.read(startupIdProvider);
    final founderName = _ref.read(founderNameProvider);

    // Add user message locally
    final userMsg = MessageModel(
      id: _uid(),
      role: MessageRole.user,
      content: trimmed,
      timestamp: DateTime.now(),
    );

    // Add empty streaming Socio message locally
    final socioMsg = MessageModel(
      id: _uid(),
      role: MessageRole.socio,
      content: '',
      isStreaming: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg, socioMsg],
      isStreaming: true,
      clearError: true,
    );

    // Save user message to Firestore
    await _ref.read(firestoreServiceProvider).saveMessage(startupId, userMsg);

    // Build history for API (last 10 messages, excluding current streaming one)
    final history = state.messages
        .where((m) => !m.isStreaming)
        .map((m) => {
              'role': m.role == MessageRole.user ? 'user' : 'assistant',
              'content': m.content,
            })
        .toList();

    String accumulatedText = '';
    String streamingId = socioMsg.id;

    await for (final chunk in _service.streamChat(
      message: trimmed,
      context: ctx,
      founderName: founderName,
      history: history,
    )) {
      switch (chunk.type) {
        case ChunkType.mood:
          state = state.copyWith(latestMood: chunk.mood);
          // Log mood to Firestore mood_logs collection
          await _ref.read(firestoreServiceProvider).saveMoodLog(
            startupId,
            score: chunk.mood!.score,
            emotion: chunk.mood!.emotion,
          );
          break;

        case ChunkType.text:
          accumulatedText += chunk.text ?? '';
          state = state.copyWith(
            messages: state.messages.map((m) {
              if (m.id == streamingId) {
                return m.copyWith(content: accumulatedText);
              }
              return m;
            }).toList(),
          );
          break;

        case ChunkType.done:
          state = state.copyWith(
            messages: state.messages.map((m) {
              if (m.id == streamingId) {
                return m.copyWith(
                  content: accumulatedText,
                  isStreaming: false,
                  moodScore: state.latestMood?.score ?? 0.7,
                  emotion: state.latestMood?.emotion ?? 'neutral',
                );
              }
              return m;
            }).toList(),
            isStreaming: false,
          );

          // Save Socio response to Firestore
          final finalSocioMsg = MessageModel(
            id: '',
            role: MessageRole.socio,
            content: accumulatedText,
            moodScore: state.latestMood?.score ?? 0.7,
            emotion: state.latestMood?.emotion ?? 'neutral',
            timestamp: DateTime.now(),
          );
          await _ref.read(firestoreServiceProvider).saveMessage(startupId, finalSocioMsg);
          break;

        case ChunkType.error:
          state = state.copyWith(
            messages: state.messages.map((m) {
              if (m.id == streamingId) {
                return m.copyWith(
                  content: chunk.text ?? 'Something went wrong.',
                  isStreaming: false,
                );
              }
              return m;
            }).toList(),
            isStreaming: false,
          );
          _showError(chunk.text ?? 'Unknown error');
          break;
      }
    }
  }

  // ── STT toggle ──────────────────────────────────────────────────────────────
  Future<String?> toggleListening() async {
    if (!_speechAvailable) {
      _showError('Microphone not available on this device.');
      return null;
    }

    if (state.isListening) {
      await _speech.stop();
      state = state.copyWith(isListening: false);
      return null;
    }

    state = state.copyWith(isListening: true);
    String? result;

    await _speech.listen(
      onResult: (r) {
        if (r.finalResult) {
          result = r.recognizedWords;
          state = state.copyWith(isListening: false);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_IN',
    );

    return result;
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  void _addSocioMessage(String content) {
    final msg = MessageModel(
      id: _uid(),
      role: MessageRole.socio,
      content: content,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(messages: [...state.messages, msg]);
  }

  void _showError(String msg) {
    state = state.copyWith(errorBanner: msg);
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) state = state.copyWith(clearError: true);
    });
  }

  void clearError() => state = state.copyWith(clearError: true);

  String _uid() =>
      DateTime.now().microsecondsSinceEpoch.toRadixString(36) +
      (state.messages.length).toString();
}

// ── Providers ─────────────────────────────────────────────────────────────────

final chatServiceProvider = Provider<ChatService>((_) => ChatService());

final chatProvider =
    StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref, ref.read(chatServiceProvider));
});

// ── Convenience selectors ──────────────────────────────────────────────────────

final messagesProvider = Provider<List<MessageModel>>(
  (ref) => ref.watch(chatProvider).messages,
);

final isStreamingProvider = Provider<bool>(
  (ref) => ref.watch(chatProvider).isStreaming,
);

final latestMoodProvider = Provider<MoodData?>(
  (ref) => ref.watch(chatProvider).latestMood,
);
