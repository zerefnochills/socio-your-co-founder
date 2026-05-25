import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../models/message_model.dart';
import '../models/startup_model.dart';
import '../providers/chat_provider.dart';
import '../providers/startup_provider.dart';
import '../services/chat_service.dart';

/// Socio Chat Screen — refined premium chat experience.
/// Upgrades: live persona bar, custom premium bubbles, floating composer with voice, 
/// auto-scrolling, live startup context, and Gemini streaming.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _inputCtrl = TextEditingController();
  bool _isSpeakerOn = false;

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _inputCtrl.dispose();
    super.dispose();
  }

  // ── Scroll to bottom ─────────────────────────────────────────────────────
  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      final target = _scrollCtrl.position.maxScrollExtent;
      if (animated) {
        _scrollCtrl.animateTo(
          target,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      } else {
        _scrollCtrl.jumpTo(target);
      }
    });
  }

  // ── Send ─────────────────────────────────────────────────────────────────
  Future<void> _onSend() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    HapticFeedback.lightImpact();
    await ref.read(chatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  // ── STT ──────────────────────────────────────────────────────────────────
  Future<void> _onMic() async {
    HapticFeedback.mediumImpact();
    final result = await ref.read(chatProvider.notifier).toggleListening();
    if (result != null && result.isNotEmpty) {
      _inputCtrl.text = result;
      _inputCtrl.selection = TextSelection.fromPosition(
        TextPosition(offset: result.length),
      );
    }
  }

  // ── Options Sheet ────────────────────────────────────────────────────────
  void _showOptions() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => _OptionsSheet(
        onStressTest: () {
          Navigator.pop(ctx);
          _stressTest();
        },
        onClearHistory: () {
          Navigator.pop(ctx);
          _clearHistory();
        },
      ),
    );
  }

  void _stressTest() {
    _inputCtrl.text = "Let's run a stress test on my startup! Act as a skeptical VC and ask me the top 3 hardest questions about my business model.";
    _onSend();
  }

  void _clearHistory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chat history is kept persistent for your startup context! ✦'),
        backgroundColor: SocioTheme.forestGreen,
      ),
    );
  }

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

    // Persona weights mapped from the live mood weights or defaults
    final double skeptic = mood?.personaWeights['skeptic'] ?? mood?.personaWeights['S'] ?? 0.6;
    final double hustler = mood?.personaWeights['hustler'] ?? mood?.personaWeights['H'] ?? 0.25;
    final double strategist = mood?.personaWeights['strategist'] ?? mood?.personaWeights['St'] ?? 0.15;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: SocioTheme.creamBg,
        appBar: _buildAppBar(mood),
        body: Column(
          children: [
            if (error != null) _buildErrorBanner(error),
            
            // Messages / Empty state
            Expanded(
              child: messages.isEmpty
                  ? _buildEmptyState()
                  : _buildMessageList(messages, isStreaming),
            ),

            // Composer
            _ChatComposer(
              controller: _inputCtrl,
              isRecording: isListening,
              isSpeakerOn: _isSpeakerOn,
              isThinking: isStreaming,
              onSend: _onSend,
              onMic: _onMic,
              onSpeaker: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
              onOptions: _showOptions,
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(MoodData? mood) {
    return AppBar(
      backgroundColor: SocioTheme.creamBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 20,
      title: Row(
        children: [
          // Socio avatar
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: SocioTheme.forestGreen,
              borderRadius: SocioTheme.radiusSm,
            ),
            child: const Icon(Icons.hub_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Socio',
                style: GoogleFonts.outfit(
                  fontSize: 16, fontWeight: FontWeight.w600,
                  color: SocioTheme.slateText,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: const BoxDecoration(
                      color: SocioTheme.emeraldAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Online · Your co-founder',
                    style: GoogleFonts.dmSans(
                      fontSize: 11, color: SocioTheme.mutedText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              key: ValueKey(_isSpeakerOn),
              size: 20,
              color: _isSpeakerOn ? SocioTheme.forestGreen : SocioTheme.mutedText,
            ),
          ),
          onPressed: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
        ),
        IconButton(
          icon: const Icon(Icons.more_vert_rounded, size: 20, color: SocioTheme.mutedText),
          onPressed: _showOptions,
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: SocioTheme.creamBorder),
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return GestureDetector(
      onTap: () => ref.read(chatProvider.notifier).clearError(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: SocioTheme.rose.withOpacity(0.1),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: SocioTheme.rose, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                error,
                style: GoogleFonts.dmSans(
                    fontSize: 13, color: SocioTheme.rose, fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(Icons.close_rounded, color: SocioTheme.rose, size: 16),
          ],
        ),
      ),
    );
  }

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
                color: SocioTheme.forestGreen,
                borderRadius: SocioTheme.radiusMd,
                boxShadow: SocioTheme.shadowGreen,
              ),
              child: const Center(
                child: Icon(
                  Icons.hub_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Reading startup context…',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: SocioTheme.slateText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Socio is aligning with your co-founder parameters.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: SocioTheme.mutedText,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(List<MessageModel> messages, bool isStreaming) {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: messages.length,
      itemBuilder: (ctx, i) {
        final msg = messages[i];
        final isUser = msg.role == MessageRole.user;
        final isFirst = i == 0 || messages[i - 1].role != msg.role;
        final isLast = i == messages.length - 1 || messages[i + 1].role != msg.role;

        if (msg.isStreaming && msg.content.isEmpty) {
          return const _ThinkingBubble();
        }

        return _ChatBubble(
          isUser: isUser,
          text: msg.content,
          timestamp: msg.timestamp,
          showAvatar: msg.role == MessageRole.socio && isFirst,
          showTimestamp: isLast,
          isActiveStreaming: isStreaming && i == messages.length - 1 && msg.role == MessageRole.socio,
        );
      },
    );
  }

  Color _moodColor(double score) {
    if (score >= 0.7) return SocioTheme.emeraldAccent;
    if (score >= 0.4) return SocioTheme.amber;
    return SocioTheme.rose;
  }

  String _moodEmoji(double score) {
    if (score >= 0.7) return '😊';
    if (score >= 0.4) return '😐';
    return '😔';
  }
}

// ── Persona Bar ───────────────────────────────────────────────────────────────

class _PersonaBar extends StatelessWidget {
  const _PersonaBar({
    required this.skeptic,
    required this.hustler,
    required this.strategist,
  });
  final double skeptic, hustler, strategist;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: SocioTheme.creamBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Active persona mix',
                style: GoogleFonts.dmSans(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: SocioTheme.mutedText, letterSpacing: 0.4,
                ),
              ),
              const Spacer(),
              _PersonaChip('S', skeptic, SocioTheme.skepticColor),
              const SizedBox(width: 6),
              _PersonaChip('H', hustler, SocioTheme.hustlerColor),
              const SizedBox(width: 6),
              _PersonaChip('St', strategist, SocioTheme.strategistColor),
            ],
          ),
          const SizedBox(height: 7),
          // Stacked bar
          ClipRRect(
            borderRadius: SocioTheme.radiusFull,
            child: SizedBox(
              height: 5,
              child: Row(
                children: [
                  Flexible(
                    flex: (skeptic * 100).round(),
                    child: Container(color: SocioTheme.skepticColor),
                  ),
                  Flexible(
                    flex: (hustler * 100).round(),
                    child: Container(color: SocioTheme.hustlerColor),
                  ),
                  Flexible(
                    flex: (strategist * 100).round(),
                    child: Container(color: SocioTheme.strategistColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonaChip extends StatelessWidget {
  const _PersonaChip(this.label, this.value, this.color);
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: SocioTheme.radiusFull,
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Text(
        '$label ${(value * 100).round()}%',
        style: GoogleFonts.dmSans(
          fontSize: 10, fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ── Chat Bubble ───────────────────────────────────────────────────────────────

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.isUser,
    required this.text,
    required this.timestamp,
    this.showAvatar = false,
    this.showTimestamp = false,
    this.isActiveStreaming = false,
  });
  final bool isUser;
  final String text;
  final DateTime timestamp;
  final bool showAvatar;
  final bool showTimestamp;
  final bool isActiveStreaming;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 2),
              child: showAvatar
                  ? Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: SocioTheme.forestGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.hub_rounded, color: Colors.white, size: 15),
                    )
                  : const SizedBox(width: 30),
            ),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isUser && showAvatar)
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 4),
                    child: Text(
                      'Socio',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: SocioTheme.mutedText,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: isUser ? SocioTheme.forestGreen : SocioTheme.creamCard,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
                      bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
                    ),
                    border: isUser ? null : Border.all(color: SocioTheme.creamBorder),
                    boxShadow: isUser ? SocioTheme.shadowSm : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          text,
                          style: GoogleFonts.dmSans(
                            fontSize: 14.5,
                            color: isUser ? Colors.white : SocioTheme.slateText,
                            height: 1.55,
                          ),
                        ),
                      ),
                      if (isActiveStreaming && text.isNotEmpty)
                        const _BlinkingCursor(),
                    ],
                  ),
                ),
                if (showTimestamp)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 2, right: 2),
                    child: Text(
                      _formatTime(timestamp),
                      style: GoogleFonts.dmSans(
                        fontSize: 10.5,
                        color: SocioTheme.mutedText.withOpacity(0.7),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor();

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 530))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.0, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: 2,
          height: 14,
          margin: const EdgeInsets.only(left: 3, bottom: 1),
          color: SocioTheme.forestGreenLt,
        ),
      ),
    );
  }
}

// ── Thinking Indicator ────────────────────────────────────────────────────────

class _ThinkingBubble extends StatefulWidget {
  const _ThinkingBubble();

  @override
  State<_ThinkingBubble> createState() => _ThinkingBubbleState();
}

class _ThinkingBubbleState extends State<_ThinkingBubble>
    with TickerProviderStateMixin {
  final List<AnimationController> _dotCtrls = [];
  final List<Animation<double>> _dotAnims = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 3; i++) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      );
      final anim = Tween<double>(begin: 0, end: -5)
          .animate(CurvedAnimation(parent: ctrl, curve: Curves.easeInOut));
      _dotCtrls.add(ctrl);
      _dotAnims.add(anim);
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) ctrl.repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _dotCtrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 30, height: 30,
            margin: const EdgeInsets.only(right: 8, bottom: 2),
            decoration: BoxDecoration(
              color: SocioTheme.forestGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.hub_rounded, color: Colors.white, size: 15),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: SocioTheme.creamCard,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: SocioTheme.creamBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _dotAnims[i],
                  builder: (ctx, _) => Transform.translate(
                    offset: Offset(0, _dotAnims[i].value),
                    child: Container(
                      width: 6, height: 6,
                      margin: EdgeInsets.only(right: i < 2 ? 5 : 0),
                      decoration: BoxDecoration(
                        color: SocioTheme.forestGreen.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chat Composer ─────────────────────────────────────────────────────────────

class _ChatComposer extends StatefulWidget {
  const _ChatComposer({
    required this.controller,
    required this.isRecording,
    required this.isSpeakerOn,
    required this.isThinking,
    required this.onSend,
    required this.onMic,
    required this.onSpeaker,
    required this.onOptions,
  });
  final TextEditingController controller;
  final bool isRecording, isSpeakerOn, isThinking;
  final VoidCallback onSend, onMic, onSpeaker, onOptions;

  @override
  State<_ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<_ChatComposer> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      final ht = widget.controller.text.trim().isNotEmpty;
      if (ht != _hasText) setState(() => _hasText = ht);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: SocioTheme.creamBg,
        border: Border(top: BorderSide(color: SocioTheme.creamBorder)),
      ),
      padding: EdgeInsets.fromLTRB(
        12, 10, 12,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Input field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: SocioTheme.creamCard,
                borderRadius: const BorderRadius.all(Radius.circular(18)),
                border: Border.all(
                  color: widget.isRecording
                      ? SocioTheme.rose.withOpacity(0.5)
                      : SocioTheme.creamBorder,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      style: GoogleFonts.dmSans(
                        fontSize: 14.5, color: SocioTheme.slateText, height: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.isRecording
                            ? 'Listening…'
                            : 'Ask Socio anything…',
                        hintStyle: GoogleFonts.dmSans(
                          fontSize: 14.5,
                          color: widget.isRecording
                              ? SocioTheme.rose.withOpacity(0.6)
                              : SocioTheme.placeholderText,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.fromLTRB(16, 10, 4, 10),
                        filled: false,
                      ),
                    ),
                  ),
                  // Mic button (inside field)
                  Padding(
                    padding: const EdgeInsets.only(right: 6, bottom: 6),
                    child: GestureDetector(
                      onTap: widget.onMic,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: widget.isRecording
                              ? SocioTheme.rose.withOpacity(0.12)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.isRecording
                              ? Icons.stop_rounded
                              : Icons.mic_none_rounded,
                          size: 18,
                          color: widget.isRecording
                              ? SocioTheme.rose
                              : SocioTheme.mutedText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Send / Thinking button
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: widget.isThinking
                ? _SpinningButton(key: const ValueKey('thinking'))
                : GestureDetector(
                    key: const ValueKey('send'),
                    onTap: _hasText ? widget.onSend : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: _hasText ? SocioTheme.forestGreen : SocioTheme.creamBorder,
                        shape: BoxShape.circle,
                        boxShadow: _hasText ? SocioTheme.shadowGreen : null,
                      ),
                      child: Icon(
                        Icons.arrow_upward_rounded,
                        size: 20,
                        color: _hasText ? Colors.white : SocioTheme.mutedText,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SpinningButton extends StatefulWidget {
  const _SpinningButton({super.key});

  @override
  State<_SpinningButton> createState() => _SpinningButtonState();
}

class _SpinningButtonState extends State<_SpinningButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: SocioTheme.forestGreen.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: RotationTransition(
          turns: _ctrl,
          child: Container(
            width: 18, height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: SocioTheme.forestGreen,
                width: 2.5,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: 3, height: 5,
                decoration: const BoxDecoration(
                  color: SocioTheme.forestGreen,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Options Sheet ─────────────────────────────────────────────────────────────

class _OptionsSheet extends StatelessWidget {
  const _OptionsSheet({required this.onStressTest, required this.onClearHistory});
  final VoidCallback onStressTest, onClearHistory;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: SocioTheme.creamBorder,
              borderRadius: SocioTheme.radiusFull,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Chat options',
            style: GoogleFonts.outfit(
              fontSize: 17, fontWeight: FontWeight.w600,
              color: SocioTheme.slateText,
            ),
          ),
          const SizedBox(height: 16),
          _OptionTile(
            icon: Icons.psychology_outlined,
            iconColor: SocioTheme.rose,
            label: 'Stress test my startup',
            subtitle: 'Socio attacks your model like a skeptical VC',
            onTap: onStressTest,
          ),
          const SizedBox(height: 10),
          _OptionTile(
            icon: Icons.delete_outline_rounded,
            iconColor: SocioTheme.mutedText,
            label: 'Clear history',
            subtitle: 'Start a fresh conversation',
            onTap: onClearHistory,
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final Color iconColor;
  final String label, subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: socioCardDecoration(),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.10),
                borderRadius: SocioTheme.radiusSm,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.outfit(
                    fontSize: 14, fontWeight: FontWeight.w600, color: SocioTheme.slateText,
                  )),
                  Text(subtitle, style: GoogleFonts.dmSans(
                    fontSize: 12, color: SocioTheme.mutedText, height: 1.4,
                  )),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: SocioTheme.mutedText),
          ],
        ),
      ),
    );
  }
}
