import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/message_model.dart';
import '../models/startup_model.dart';
import '../providers/chat_provider.dart';
import '../providers/startup_provider.dart';
import '../services/chat_service.dart';


// ─────────────────────────────────────────────────────────────────────────────
// ChatScreen — Socio AI Co-Founder
// Features: SSE word-by-word streaming · mood indicator · STT voice input
//           startup context injection · streaming cursor · error banner
// ─────────────────────────────────────────────────────────────────────────────

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  late final AnimationController _micPulseController;
  late final Animation<double> _micPulse;
  late final AnimationController _cursorBlinkController;
  late final Animation<double> _cursorBlink;

  // ── Design tokens (matches Pi AI style) ───────────────────────
  static const _purple = Color(0xFF0B3A22);
  static const _purpleLight = Color(0xFFE5EFE9);
  static const _purpleMid = Color(0xFF4F8F6F);
  static const _background = Color(0xFFF7F4EB);
  static const _bubbleSocio = Colors.transparent; // Frameless bubbles for Socio!
  static const _textPrimary = Color(0xFF15291C);
  static const _textSecondary = Color(0xFF5E7063);
  static const _border = Color(0xFFEBE5D8);
  static const _white = Color(0xFFFFFFFF);

  static const _error = Color(0xFFDC2626);
  static const _success = Color(0xFF059669);

  bool _hasText = false;

  @override
  void initState() {
    super.initState();

    _micPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _micPulse = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _micPulseController, curve: Curves.easeInOut),
    );

    _cursorBlinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);

    _cursorBlink = Tween<double>(begin: 0.0, end: 1.0).animate(
      _cursorBlinkController,
    );

    _inputController.addListener(() {
      final has = _inputController.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _micPulseController.dispose();
    _cursorBlinkController.dispose();
    super.dispose();
  }

  // ── Scroll to bottom ─────────────────────────────────────────────────────
  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  // ── Send ─────────────────────────────────────────────────────────────────
  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    _focusNode.unfocus();
    HapticFeedback.lightImpact();
    await ref.read(chatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  // ── STT ──────────────────────────────────────────────────────────────────
  Future<void> _toggleMic() async {
    HapticFeedback.mediumImpact();
    final result =
        await ref.read(chatProvider.notifier).toggleListening();
    if (result != null && result.isNotEmpty) {
      _inputController.text = result;
      _inputController.selection = TextSelection.fromPosition(
        TextPosition(offset: result.length),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final messages = chatState.messages;
    final isStreaming = chatState.isStreaming;
    final isListening = chatState.isListening;
    final mood = chatState.latestMood;
    final error = chatState.errorBanner;

    // Load and listen to live startup context
    ref.listen<AsyncValue<StartupModel>>(
      startupNotifierProvider,
      (_, nextState) {
        final startup = nextState.value;
        if (startup != null) {
          ref.read(chatProvider.notifier).setStartupContext(startup);
        }
      },
    );

    // Seed the initial value if already loaded
    final startup = ref.watch(startupNotifierProvider).value;
    if (startup != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(chatProvider.notifier).setStartupContext(startup);
      });
    }


    // Auto-scroll when new messages arrive
    ref.listen<List<MessageModel>>(
      messagesProvider,
      (_, __) => _scrollToBottom(),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _white,
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(mood),
              if (error != null) _buildErrorBanner(error),
              Expanded(
                child: messages.isEmpty
                    ? _buildEmptyState()
                    : _buildMessageList(messages, isStreaming),
              ),
              _buildInputBar(isStreaming, isListening),
            ],
          ),
        ),
      ),
    );
  }

  // ── App bar ───────────────────────────────────────────────────────────────
  Widget _buildAppBar(MoodData? mood) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _white,
        border: Border(bottom: BorderSide(color: _border.withOpacity(0.6))),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), _purple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: _purple.withOpacity(0.28),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'S',
                style: GoogleFonts.fraunces(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Socio',
                  style: GoogleFonts.fraunces(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: _success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Your AI co-founder',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Mood chip
          if (mood != null)
            AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _moodColor(mood.score).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  children: [
                    Text(
                      _moodEmoji(mood.score),
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      mood.emotion,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: _moodColor(mood.score),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Error banner ──────────────────────────────────────────────────────────
  Widget _buildErrorBanner(String error) {
    return GestureDetector(
      onTap: () => ref.read(chatProvider.notifier).clearError(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: _error.withOpacity(0.1),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: _error, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                error,
                style: GoogleFonts.dmSans(
                    fontSize: 13, color: _error, fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(Icons.close_rounded, color: _error, size: 16),
          ],
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), _purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: _purple.withOpacity(0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'S',
                  style: GoogleFonts.fraunces(
                      fontSize: 32, fontWeight: FontWeight.w700, color: _white),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Loading your co-founder…',
              style: GoogleFonts.fraunces(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Socio is reading your startup context.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                  fontSize: 14, color: _textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // ── Message list ──────────────────────────────────────────────────────────
  Widget _buildMessageList(List<MessageModel> messages, bool isStreaming) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: messages.length,
      itemBuilder: (context, i) {
        final msg = messages[i];
        final isFirst = i == 0 ||
            messages[i - 1].role != msg.role;
        final isLast = i == messages.length - 1 ||
            messages[i + 1].role != msg.role;

        return _buildBubble(
          msg: msg,
          showAvatar: msg.role == MessageRole.socio && isFirst,
          showTimestamp: isLast,
          isActiveStreaming:
              isStreaming && i == messages.length - 1 && msg.role == MessageRole.socio,
        );
      },
    );
  }

  Widget _buildBubble({
    required MessageModel msg,
    required bool showAvatar,
    required bool showTimestamp,
    required bool isActiveStreaming,
  }) {
    final isUser = msg.role == MessageRole.user;

    return Padding(
      padding: EdgeInsets.only(
        top: showAvatar ? 12 : 2,
        bottom: showTimestamp ? 4 : 0,
      ),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Socio avatar
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 2),
              child: showAvatar
                  ? Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), _purple],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'S',
                          style: GoogleFonts.fraunces(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _white),
                        ),
                      ),
                    )
                  : const SizedBox(width: 30),
            ),

          // Bubble
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isUser && showAvatar)
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 4),
                    child: Text(
                      'Socio',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _textSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: isUser ? _purpleLight : _bubbleSocio,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(22),
                      topRight: const Radius.circular(22),
                      bottomLeft: Radius.circular(isUser ? 22 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 22),
                    ),
                    boxShadow: isUser
                        ? [
                            BoxShadow(
                              color: _purple.withOpacity(0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: msg.isStreaming &&
                          msg.content.isEmpty
                      ? _buildTypingDots()
                      : _buildBubbleText(msg, isUser, isActiveStreaming),
                ),
                if (showTimestamp)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 2, right: 2),
                    child: Text(
                      _formatTime(msg.timestamp),
                      style: GoogleFonts.dmSans(
                          fontSize: 10, color: _textSecondary.withOpacity(0.6)),
                    ),
                  ),
              ],
            ),
          ),

          // Spacer for user messages
          if (isUser) const SizedBox(width: 38),
        ],
      ),
    );
  }

  Widget _buildBubbleText(
      MessageModel msg, bool isUser, bool isActiveStreaming) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Text(
            msg.content,
            style: GoogleFonts.dmSans(
              fontSize: 15,
              color: isUser ? _purple : _textPrimary,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),

        // Blinking cursor while streaming
        if (isActiveStreaming && msg.content.isNotEmpty)
          AnimatedBuilder(
            animation: _cursorBlink,
            builder: (_, __) => Opacity(
              opacity: _cursorBlink.value,
              child: Container(
                width: 2,
                height: 15,
                margin: const EdgeInsets.only(left: 2, bottom: 1),
                decoration: BoxDecoration(
                  color: _purpleMid,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTypingDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (i) => _BouncingDot(
          delay: Duration(milliseconds: i * 150),
          color: _textSecondary,
        ),
      ),
    );
  }

  // ── Input bar ─────────────────────────────────────────────────────────────
  Widget _buildInputBar(bool isStreaming, bool isListening) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      decoration: BoxDecoration(
        color: _white,
        border: Border(top: BorderSide(color: _border.withOpacity(0.6))),
        boxShadow: [
          BoxShadow(
            color: _textPrimary.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Mic button
          GestureDetector(
            onTap: _toggleMic,
            child: AnimatedBuilder(
              animation: _micPulse,
              builder: (_, child) => Transform.scale(
                scale: isListening ? _micPulse.value : 1.0,
                child: child,
              ),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isListening
                      ? _error.withOpacity(0.12)
                      : _purpleLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isListening ? Icons.stop_rounded : Icons.mic_rounded,
                  color: isListening ? _error : _purple,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Text field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
              ),
              child: TextField(
                controller: _inputController,
                focusNode: _focusNode,
                maxLines: 5,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                style: GoogleFonts.dmSans(
                    fontSize: 15, color: _textPrimary, height: 1.4),
                decoration: InputDecoration(
                  hintText: isListening
                      ? 'Listening…'
                      : 'Ask your co-founder anything…',
                  hintStyle: GoogleFonts.dmSans(
                    fontSize: 15,
                    color: _textSecondary.withOpacity(0.6),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Send button
          GestureDetector(
            onTap: (!isStreaming && _hasText) ? _send : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: (!isStreaming && _hasText)
                    ? const LinearGradient(
                        colors: [Color(0xFF7C3AED), _purple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: (!isStreaming && _hasText) ? null : _border,
                borderRadius: BorderRadius.circular(14),
                boxShadow: (!isStreaming && _hasText)
                    ? [
                        BoxShadow(
                          color: _purple.withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: isStreaming
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      Icons.arrow_upward_rounded,
                      color: (!isStreaming && _hasText)
                          ? _white
                          : _textSecondary,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Color _moodColor(double score) {
    if (score >= 0.7) return _success;
    if (score >= 0.4) return const Color(0xFFD97706);
    return _error;
  }

  String _moodEmoji(double score) {
    if (score >= 0.7) return '😊';
    if (score >= 0.4) return '😐';
    return '😔';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ── Bouncing dot widget (typing indicator) ────────────────────────────────────
class _BouncingDot extends StatefulWidget {
  final Duration delay;
  final Color color;

  const _BouncingDot({required this.delay, required this.color});

  @override
  State<_BouncingDot> createState() => _BouncingDotState();
}

class _BouncingDotState extends State<_BouncingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bounce = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    Future.delayed(widget.delay, () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounce,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _bounce.value),
        child: Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
