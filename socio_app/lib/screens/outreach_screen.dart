import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../providers/outreach_provider.dart';
import '../services/outreach_service.dart';

/// Socio Outreach Screen — Cold Outreach Engine.
/// Upgrades: Warm editorial luxury layout, custom fields, responsive tabs, 
/// copy callbacks, and Tavily-researched outreach rendering.
class OutreachScreen extends ConsumerStatefulWidget {
  const OutreachScreen({super.key});

  @override
  ConsumerState<OutreachScreen> createState() => _OutreachScreenState();
}

class _OutreachScreenState extends ConsumerState<OutreachScreen>
    with SingleTickerProviderStateMixin {
  // ── Controllers ───────────────────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();
  final _tractionCtrl = TextEditingController();
  final _askCtrl = TextEditingController();
  late final TabController _tabController;

  bool _showAdvanced = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Sync text controllers → provider state
    _nameCtrl.addListener(
        () => ref.read(outreachProvider.notifier).updateField(
              targetName: _nameCtrl.text,
            ));
    _companyCtrl.addListener(
        () => ref.read(outreachProvider.notifier).updateField(
              targetCompany: _companyCtrl.text,
            ));
    _roleCtrl.addListener(
        () => ref.read(outreachProvider.notifier).updateField(
              targetRole: _roleCtrl.text,
            ));
    _tractionCtrl.addListener(
        () => ref.read(outreachProvider.notifier).updateField(
              traction: _tractionCtrl.text,
            ));
    _askCtrl.addListener(
        () => ref.read(outreachProvider.notifier).updateField(
              ask: _askCtrl.text,
            ));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _companyCtrl.dispose();
    _roleCtrl.dispose();
    _tractionCtrl.dispose();
    _askCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ── Generate ──────────────────────────────────────────────────────────────
  Future<void> _generate() async {
    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();
    await ref.read(outreachProvider.notifier).generate();

    // Jump to email tab on success
    final status = ref.read(outreachProvider).status;
    if (status == OutreachStatus.success) {
      _tabController.animateTo(0);
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied',
            style: GoogleFonts.dmSans(color: Colors.white)),
        backgroundColor: SocioTheme.forestGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: const RoundedRectangleBorder(borderRadius: SocioTheme.radiusMd),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(outreachProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: SocioTheme.creamBg,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildInputCard(state)),
              if (state.status == OutreachStatus.error)
                SliverToBoxAdapter(child: _buildErrorCard(state.error!)),
              if (state.isLoading)
                SliverToBoxAdapter(child: _buildLoadingCard()),
              if (state.hasResult)
                SliverToBoxAdapter(child: _buildResultsCard(state.result!)),
              const SliverToBoxAdapter(child: SizedBox(height: 80)), // bottom safe padding for floating navbar
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: SocioTheme.forestGreen,
              borderRadius: SocioTheme.radiusSm,
              boxShadow: SocioTheme.shadowGreen,
            ),
            child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cold Outreach',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: SocioTheme.slateText,
                ),
              ),
              Text(
                'AI-researched, personalised in seconds',
                style: GoogleFonts.dmSans(
                    fontSize: 12, color: SocioTheme.mutedText),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Input card ────────────────────────────────────────────────────────────
  Widget _buildInputCard(OutreachState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: socioCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Required fields
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel('Target', Icons.person_outline_rounded),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildField(
                          controller: _nameCtrl,
                          hint: 'Full name',
                          icon: Icons.badge_outlined,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildField(
                          controller: _companyCtrl,
                          hint: 'Company',
                          icon: Icons.business_outlined,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Advanced toggle
            GestureDetector(
              onTap: () => setState(() => _showAdvanced = !_showAdvanced),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Row(
                  children: [
                    Text(
                      _showAdvanced ? 'Hide details' : 'Add more context',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: SocioTheme.forestGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: _showAdvanced ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: SocioTheme.forestGreen, size: 18),
                    ),
                  ],
                ),
              ),
            ),

            // Advanced fields
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: _showAdvanced
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildField(
                      controller: _roleCtrl,
                      hint: 'Their role (e.g. Partner, CTO)',
                      icon: Icons.work_outline_rounded,
                    ),
                    const SizedBox(height: 10),
                    _buildField(
                      controller: _tractionCtrl,
                      hint: 'Your traction (e.g. 500 waitlist, 3 pilots)',
                      icon: Icons.trending_up_rounded,
                    ),
                    const SizedBox(height: 10),
                    _buildField(
                      controller: _askCtrl,
                      hint: 'Your ask (e.g. 15-min intro call)',
                      icon: Icons.calendar_today_outlined,
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
              secondChild: const SizedBox.shrink(),
            ),

            //Divider + Generate button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildGenerateButton(state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: SocioTheme.mutedText),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: SocioTheme.mutedText,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: SocioTheme.creamBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SocioTheme.creamBorder),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.dmSans(fontSize: 14, color: SocioTheme.slateText),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.dmSans(
              fontSize: 14, color: SocioTheme.placeholderText),
          prefixIcon: Icon(icon, size: 16, color: SocioTheme.mutedText),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
        ),
      ),
    );
  }

  Widget _buildGenerateButton(OutreachState state) {
    final canGenerate = state.canGenerate && !state.isLoading;
    return AnimatedOpacity(
      opacity: canGenerate ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: canGenerate ? _generate : null,
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: canGenerate ? SocioTheme.forestGreen : SocioTheme.creamBorder,
            borderRadius: BorderRadius.circular(14),
            boxShadow: canGenerate ? SocioTheme.shadowGreen : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 17),
              const SizedBox(width: 8),
              Text(
                'Generate Outreach',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: canGenerate ? Colors.white : SocioTheme.mutedText,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Loading card ──────────────────────────────────────────────────────────
  Widget _buildLoadingCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: socioCardDecoration(),
        child: Column(
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                color: SocioTheme.forestGreen,
                strokeWidth: 2.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Researching target…',
              style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: SocioTheme.slateText),
            ),
            const SizedBox(height: 6),
            Text(
              'Tavily is scanning the web · Gemini is writing your pitch',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: SocioTheme.mutedText, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error card ────────────────────────────────────────────────────────────
  Widget _buildErrorCard(String error) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: SocioTheme.rose, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                error,
                style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: SocioTheme.rose,
                    height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Results card ──────────────────────────────────────────────────────────
  Widget _buildResultsCard(OutreachResult result) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        decoration: socioCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Insight strip
            if (result.tavilyInsight.isNotEmpty)
              _buildInsightStrip(result.tavilyInsight),

            // Tab bar
            _buildTabBar(),

            // Tab views
            SizedBox(
              height: _resultHeight(result),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildEmailTab(result),
                  _buildCallScriptTab(result),
                  _buildFollowUpTab(result),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _resultHeight(OutreachResult r) {
    return 420;
  }

  Widget _buildInsightStrip(String insight) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: SocioTheme.forestGreen.withOpacity(0.06),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          const Icon(Icons.travel_explore_rounded, color: SocioTheme.forestGreen, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              insight,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                  fontSize: 12, color: SocioTheme.forestGreenLt, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: SocioTheme.creamBorder)),
      ),
      child: TabBar(
        controller: _tabController,
        labelStyle: GoogleFonts.dmSans(
            fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500),
        labelColor: SocioTheme.forestGreen,
        unselectedLabelColor: SocioTheme.mutedText,
        indicatorColor: SocioTheme.forestGreen,
        indicatorWeight: 2.5,
        tabs: const [
          Tab(text: 'Email'),
          Tab(text: 'Call Script'),
          Tab(text: 'Follow-ups'),
        ],
      ),
    );
  }

  // ── Email tab ─────────────────────────────────────────────────────────────
  Widget _buildEmailTab(OutreachResult result) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: SocioTheme.creamBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: SocioTheme.creamBorder),
            ),
            child: Row(
              children: [
                Text(
                  'Subject: ',
                  style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: SocioTheme.mutedText),
                ),
                Expanded(
                  child: Text(
                    result.coldEmailSubject,
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: SocioTheme.slateText,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                _copyIcon(result.coldEmailSubject, 'Subject'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          _buildContentBlock(
            content: result.coldEmailBody,
            copyLabel: 'Email',
          ),
        ],
      ),
    );
  }

  // ── Call script tab ───────────────────────────────────────────────────────
  Widget _buildCallScriptTab(OutreachResult result) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: SocioTheme.amber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '~2 min call',
                  style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: SocioTheme.amber,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildContentBlock(
            content: result.callScript,
            copyLabel: 'Call script',
          ),
        ],
      ),
    );
  }

  // ── Follow-up tab ─────────────────────────────────────────────────────────
  Widget _buildFollowUpTab(OutreachResult result) {
    if (result.followUps.isEmpty) {
      return Center(
        child: Text('No follow-ups generated.',
            style: GoogleFonts.dmSans(color: SocioTheme.mutedText)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: result.followUps.map((fu) {
          final colors = _followUpColor(fu.day);
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Container(
              decoration: BoxDecoration(
                color: SocioTheme.creamCard,
                borderRadius: BorderRadius.circular(14),
                border: Border(
                  left: BorderSide(color: colors.$1, width: 3),
                  top: const BorderSide(color: SocioTheme.creamBorder),
                  right: const BorderSide(color: SocioTheme.creamBorder),
                  bottom: const BorderSide(color: SocioTheme.creamBorder),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.$1.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            'Day ${fu.day}',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: colors.$1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            fu.subject,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: SocioTheme.slateText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _copyIcon(fu.body, 'Day ${fu.day} follow-up'),
                      ],
                    ),
                  ),
                  const Divider(color: SocioTheme.creamBorder, height: 1),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      fu.body,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: SocioTheme.slateText,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Shared: content block ─────────────────────────────────────────────────
  Widget _buildContentBlock({
    required String content,
    required String copyLabel,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: SocioTheme.creamBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SocioTheme.creamBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              content,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: SocioTheme.slateText,
                height: 1.65,
              ),
            ),
          ),
          const Divider(color: SocioTheme.creamBorder, height: 1),
          GestureDetector(
            onTap: () => _copyToClipboard(content, copyLabel),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.copy_rounded, size: 14, color: SocioTheme.forestGreen),
                  const SizedBox(width: 6),
                  Text(
                    'Copy $copyLabel',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: SocioTheme.forestGreen,
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

  Widget _copyIcon(String text, String label) {
    return GestureDetector(
      onTap: () => _copyToClipboard(text, label),
      child: const Padding(
        padding: EdgeInsets.only(left: 8),
        child: Icon(Icons.copy_rounded, size: 15, color: SocioTheme.forestGreen),
      ),
    );
  }

  // ── Follow-up day colors ──────────────────────────────────────────────────
  (Color, Color) _followUpColor(int day) {
    if (day <= 1) return (SocioTheme.emeraldAccent, const Color(0xFFDCFCE7));
    if (day <= 3) return (SocioTheme.amber, const Color(0xFFFEF3C7));
    return (SocioTheme.violet, SocioTheme.violetSurface);
  }
}
