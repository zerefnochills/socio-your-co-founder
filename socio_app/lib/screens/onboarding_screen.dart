import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../models/startup_model.dart';
import '../providers/startup_provider.dart';
import '../navigation/main_navigation.dart';

/// OnboardingScreen — Socio AI Co-Founder App
/// Design: Warm minimal editorial luxury, responsive steps, strong typography.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  // ── Controllers ─────────────────────────────────────────────────────────────
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ideaController = TextEditingController();

  // ── State ────────────────────────────────────────────────────────────────────
  int _currentStep = 0;
  String _selectedStage = '';
  bool _isLoading = false;

  // ── Animation controllers ────────────────────────────────────────────────────
  late final AnimationController _avatarPulseController;
  late final AnimationController _fadeInController;
  late final Animation<double> _avatarPulse;
  late final Animation<double> _fadeIn;

  // ── Stage options ────────────────────────────────────────────────────────────
  final List<_StageOption> _stages = [
    _StageOption(label: 'Just an idea', emoji: '💡', value: 'Idea stage'),
    _StageOption(label: 'Building MVP', emoji: '🔨', value: 'Building MVP'),
    _StageOption(label: 'Pre-launch', emoji: '🚀', value: 'Pre-launch'),
    _StageOption(label: 'Live & growing', emoji: '📈', value: 'Live & growing'),
    _StageOption(label: 'Raising funds', emoji: '💰', value: 'Raising funds'),
  ];

  @override
  void initState() {
    super.initState();

    _avatarPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _avatarPulse = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _avatarPulseController, curve: Curves.easeInOut),
    );

    _fadeIn = CurvedAnimation(parent: _fadeInController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ideaController.dispose();
    _avatarPulseController.dispose();
    _fadeInController.dispose();
    super.dispose();
  }

  // ── Navigation ───────────────────────────────────────────────────────────────
  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        return _nameController.text.trim().isNotEmpty;
      case 1:
        return _ideaController.text.trim().isNotEmpty;
      case 2:
        return _selectedStage.isNotEmpty;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (!_canProceed) return;
    HapticFeedback.lightImpact();

    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
      _fadeInController
        ..reset()
        ..forward();
    } else {
      _finishOnboarding();
    }
  }

  void _prevStep() {
    if (_currentStep == 0) return;
    HapticFeedback.selectionClick();
    setState(() => _currentStep--);
    _pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
    _fadeInController
      ..reset()
      ..forward();
  }

  Future<void> _finishOnboarding() async {
    setState(() => _isLoading = true);

    try {
      final currentStartup = ref.read(startupNotifierProvider).value;
      final updated = StartupModel(
        id: currentStartup?.id ?? '',
        name: _nameController.text.trim(),
        idea: _ideaController.text.trim(),
        stage: _selectedStage,
        mrr: '0',
        userCount: '0',
        updatedAt: DateTime.now(),
      );

      await ref.read(startupNotifierProvider.notifier).save(updated);

      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Welcome to Socio, ${_nameController.text.trim()}!',
              style: GoogleFonts.dmSans(color: Colors.white),
            ),
            backgroundColor: SocioTheme.forestGreen,
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(borderRadius: SocioTheme.radiusMd),
          ),
        );

        // Transition to Main Navigation
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigation()),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Error: $e',
              style: GoogleFonts.dmSans(color: Colors.white),
            ),
            backgroundColor: SocioTheme.rose,
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(borderRadius: SocioTheme.radiusMd),
          ),
        );
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: SocioTheme.creamBg,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              _buildProgressBar(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep0(),
                    _buildStep1(),
                    _buildStep2(),
                  ],
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top bar (back + step indicator) ─────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          AnimatedOpacity(
            opacity: _currentStep > 0 ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: GestureDetector(
              onTap: _prevStep,
              child: Container(
                width: 40,
                height: 40,
                decoration: socioCardDecoration(),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 16, color: SocioTheme.slateText),
              ),
            ),
          ),
          const Spacer(),
          Text(
            '${_currentStep + 1} of 3',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: SocioTheme.mutedText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Progress bar ─────────────────────────────────────────────────────────────
  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(3, (i) {
          final isComplete = i < _currentStep;
          final isCurrent = i == _currentStep;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < 2 ? 6 : 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                height: 4,
                decoration: BoxDecoration(
                  color: isComplete || isCurrent
                      ? isCurrent
                          ? SocioTheme.forestGreen
                          : SocioTheme.forestGreenLt
                      : SocioTheme.creamBorder,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Step 0: Startup name ──────────────────────────────────────────────────────
  Widget _buildStep0() {
    return FadeTransition(
      opacity: _fadeIn,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 36),
            _buildSocioAvatar(),
            const SizedBox(height: 32),
            Text(
              'Meet Socio.',
              style: GoogleFonts.outfit(
                fontSize: 38,
                fontWeight: FontWeight.w700,
                color: SocioTheme.slateText,
                height: 1.1,
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your AI co-founder, available 24/7.\nLet\'s start with your startup.',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                color: SocioTheme.mutedText,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 36),
            _buildFieldLabel('What\'s your startup called?'),
            const SizedBox(height: 10),
            _buildTextField(
              controller: _nameController,
              hint: 'e.g. Socio, Stripe, Notion…',
              maxLines: 1,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            _buildHintChip('💡 Don\'t have a name yet? Just write your first name + idea'),
          ],
        ),
      ),
    );
  }

  // ── Step 1: One-line idea ─────────────────────────────────────────────────────
  Widget _buildStep1() {
    return FadeTransition(
      opacity: _fadeIn,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 36),
            _buildSocioAvatar(),
            const SizedBox(height: 32),
            Text(
              'What are you\nbuilding?',
              style: GoogleFonts.outfit(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: SocioTheme.slateText,
                height: 1.15,
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'One clear sentence. Your co-founder\nneeds to understand your vision.',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                color: SocioTheme.mutedText,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 36),
            _buildFieldLabel('One-line description'),
            const SizedBox(height: 10),
            _buildTextField(
              controller: _ideaController,
              hint: 'e.g. AI that helps solo founders make better decisions',
              maxLines: 3,
              textInputAction: TextInputAction.newline,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            _buildHintChip('✏️ Think: "We help [who] do [what] so they can [outcome]"'),
          ],
        ),
      ),
    );
  }

  // ── Step 2: Stage picker ──────────────────────────────────────────────────────
  Widget _buildStep2() {
    return FadeTransition(
      opacity: _fadeIn,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 36),
            _buildSocioAvatar(),
            const SizedBox(height: 32),
            Text(
              'Where are you\nright now?',
              style: GoogleFonts.outfit(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: SocioTheme.slateText,
                height: 1.15,
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Socio adapts its advice to your\nexact stage. No fluff, just signal.',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                color: SocioTheme.mutedText,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            ..._stages.map((stage) => _buildStageCard(stage)),
          ],
        ),
      ),
    );
  }

  // ── Reusable widgets ──────────────────────────────────────────────────────────

  Widget _buildSocioAvatar() {
    return ScaleTransition(
      scale: _avatarPulse,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: SocioTheme.forestGreen,
              borderRadius: BorderRadius.circular(18),
              boxShadow: SocioTheme.shadowGreen,
            ),
            child: Center(
              child: Text(
                'S',
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: SocioTheme.forestGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              'Socio AI',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: SocioTheme.forestGreen,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: SocioTheme.slateText,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required int maxLines,
    required TextInputAction textInputAction,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      decoration: socioCardDecoration(elevated: true),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        minLines: maxLines == 1 ? 1 : 2,
        textInputAction: textInputAction,
        onChanged: onChanged,
        style: GoogleFonts.dmSans(
          fontSize: 15,
          color: SocioTheme.slateText,
          height: 1.5,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.dmSans(
            fontSize: 15,
            color: SocioTheme.placeholderText,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
        ),
      ),
    );
  }

  Widget _buildHintChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: SocioTheme.forestGreen.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.dmSans(
          fontSize: 13,
          color: SocioTheme.forestGreenLt,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildStageCard(_StageOption stage) {
    final isSelected = _selectedStage == stage.value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedStage = stage.value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? SocioTheme.forestGreen : SocioTheme.creamCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? SocioTheme.forestGreen : SocioTheme.creamBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? SocioTheme.shadowGreen : SocioTheme.shadowSm,
        ),
        child: Row(
          children: [
            Text(stage.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Text(
              stage.label,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : SocioTheme.slateText,
              ),
            ),
            const Spacer(),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.white : Colors.transparent,
                border: Border.all(
                  color: isSelected ? Colors.white : SocioTheme.creamBorder,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, size: 13, color: SocioTheme.forestGreen)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom CTA bar ────────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    final isLastStep = _currentStep == 2;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: SocioTheme.creamBg,
        border: Border(top: BorderSide(color: SocioTheme.creamBorder.withOpacity(0.6))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedOpacity(
            opacity: _canProceed ? 1.0 : 0.45,
            duration: const Duration(milliseconds: 200),
            child: GestureDetector(
              onTap: _canProceed ? _nextStep : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: _canProceed ? SocioTheme.forestGreen : SocioTheme.creamBorder,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _canProceed ? SocioTheme.shadowGreen : null,
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isLastStep
                                  ? 'Start with Socio'
                                  : 'Continue',
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _canProceed ? Colors.white : SocioTheme.mutedText,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isLastStep
                                  ? Icons.rocket_launch_rounded
                                  : Icons.arrow_forward_rounded,
                              color: _canProceed ? Colors.white : SocioTheme.mutedText,
                              size: 18,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
          if (!isLastStep) ...[
            const SizedBox(height: 14),
            Text(
              'Takes about 30 seconds ✦',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: SocioTheme.mutedText.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Data model ───────────────────────────────────────────────────────────────
class _StageOption {
  final String label;
  final String emoji;
  final String value;

  const _StageOption({
    required this.label,
    required this.emoji,
    required this.value,
  });
}
