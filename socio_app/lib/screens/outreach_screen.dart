import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../models/lead_model.dart';
import '../providers/outreach_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/startup_provider.dart';

class OutreachScreen extends ConsumerStatefulWidget {
  const OutreachScreen({super.key});

  @override
  ConsumerState<OutreachScreen> createState() => _OutreachScreenState();
}

class _OutreachScreenState extends ConsumerState<OutreachScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _targetCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SocioTheme.creamBg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _AutoDiscoverTab(targetCtrl: _targetCtrl),
                const _LeadsQueueTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: SocioTheme.creamBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 20,
      title: Text(
        'Outreach',
        style: GoogleFonts.outfit(
          fontSize: 20, fontWeight: FontWeight.w600,
          color: SocioTheme.slateText, letterSpacing: -0.3,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: SocioTheme.creamBorder),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: SocioTheme.creamBg,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: SocioTheme.creamCard,
          borderRadius: SocioTheme.radiusFull,
          border: Border.all(color: SocioTheme.creamBorder),
        ),
        child: TabBar(
          controller: _tabs,
          indicator: BoxDecoration(
            color: SocioTheme.forestGreen,
            borderRadius: SocioTheme.radiusFull,
            boxShadow: SocioTheme.shadowGreen,
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          labelStyle: GoogleFonts.outfit(
            fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.1,
          ),
          unselectedLabelStyle: GoogleFonts.outfit(
            fontSize: 13, fontWeight: FontWeight.w500,
          ),
          labelColor: Colors.white,
          unselectedLabelColor: SocioTheme.mutedText,
          tabs: const [
            Tab(text: 'Auto-Discover'),
            Tab(text: 'Lead Queue'),
          ],
        ),
      ),
    );
  }
}

// ── AUTO DISCOVER TAB ─────────────────────────────────────────────────────────

class _AutoDiscoverTab extends ConsumerStatefulWidget {
  const _AutoDiscoverTab({required this.targetCtrl});
  final TextEditingController targetCtrl;

  @override
  ConsumerState<_AutoDiscoverTab> createState() => _AutoDiscoverTabState();
}

class _AutoDiscoverTabState extends ConsumerState<_AutoDiscoverTab> {

  void _runDiscovery() {
    final input = widget.targetCtrl.text.trim();
    if (input.isEmpty) return;
    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();

    final founderName = ref.read(founderNameProvider);
    ref.read(leadDiscoveryProvider.notifier).discoverAndGenerate(
      targetCustomer: input,
      founderName: founderName,
      generateEmailsImmediately: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final discoveryAsync = ref.watch(leadDiscoveryProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header card ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: socioGreenDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'AI Lead Engine',
                      style: GoogleFonts.outfit(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Describe your ideal customer.\nSocio finds real companies and writes the emails.',
                  style: GoogleFonts.dmSans(
                    fontSize: 14, color: Colors.white, height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Input ──────────────────────────────────────────────────
          Text(
            'Who should you be selling to?',
            style: GoogleFonts.outfit(
              fontSize: 15, fontWeight: FontWeight.w600, color: SocioTheme.slateText,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: widget.targetCtrl,
            maxLines: 3,
            style: GoogleFonts.dmSans(fontSize: 14, color: SocioTheme.slateText, height: 1.5),
            decoration: InputDecoration(
              hintText: 'e.g. "B2B SaaS startups with 10-50 employees scaling their sales team"',
              hintStyle: GoogleFonts.dmSans(
                fontSize: 13.5, color: SocioTheme.placeholderText, height: 1.5,
              ),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),

          // ── CTA ────────────────────────────────────────────────────
          discoveryAsync.when(
            data: (state) => state.isLoading
                ? _ProgressCard(
                    emailsGenerated: state.emailsGenerated,
                    totalLeads: state.totalLeads,
                  )
                : _DiscoverButton(onTap: _runDiscovery),
            loading: () => _DiscoverButton(onTap: null),
            error: (e, _) => Column(
              children: [
                _DiscoverButton(onTap: _runDiscovery),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SocioTheme.rose.withOpacity(0.08),
                    borderRadius: SocioTheme.radiusMd,
                    border: Border.all(color: SocioTheme.rose.withOpacity(0.25)),
                  ),
                  child: Text(
                    e.toString(),
                    style: GoogleFonts.dmSans(
                      fontSize: 12, color: SocioTheme.rose, height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Result preview (after completion) ─────────────────────
          discoveryAsync.when(
            data: (state) {
              if (state.discoveredLeads.isEmpty || state.isLoading) {
                return const SizedBox.shrink();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _SectionHeader(
                    title: 'Found ${state.discoveredLeads.length} leads',
                    subtitle: '${state.emailsGenerated} emails ready — see Lead Queue',
                  ),
                  const SizedBox(height: 8),
                  ...state.discoveredLeads.take(5).map(
                    (lead) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _MiniLeadTile(lead: lead),
                    ),
                  ),
                  if (state.discoveredLeads.length > 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '+ ${state.discoveredLeads.length - 5} more in Lead Queue',
                        style: GoogleFonts.dmSans(
                          fontSize: 13, color: SocioTheme.mutedText,
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _DiscoverButton extends StatelessWidget {
  const _DiscoverButton({required this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.travel_explore_rounded, size: 18),
        label: const Text('Find Real Leads + Write Emails'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: SocioTheme.radiusMd),
          backgroundColor: onTap != null ? SocioTheme.forestGreen : SocioTheme.creamBorder,
          foregroundColor: onTap != null ? Colors.white : SocioTheme.mutedText,
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.emailsGenerated, required this.totalLeads});
  final int emailsGenerated, totalLeads;

  @override
  Widget build(BuildContext context) {
    final phase = totalLeads == 0 ? 'Searching the web...' : 'Writing emails...';
    final pct   = totalLeads == 0 ? 0.0 : emailsGenerated / totalLeads;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: socioCardDecoration(elevated: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: SocioTheme.forestGreen,
                  value: totalLeads > 0 ? pct : null,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                phase,
                style: GoogleFonts.outfit(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: SocioTheme.slateText,
                ),
              ),
            ],
          ),
          if (totalLeads > 0) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: SocioTheme.radiusFull,
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 4,
                backgroundColor: SocioTheme.creamBorder,
                valueColor: const AlwaysStoppedAnimation(SocioTheme.forestGreen),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$emailsGenerated of $totalLeads emails written',
              style: GoogleFonts.dmSans(
                fontSize: 12, color: SocioTheme.mutedText,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniLeadTile extends StatelessWidget {
  const _MiniLeadTile({required this.lead});
  final LeadModel lead;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: socioCardDecoration(),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _priorityColor(lead.priorityScore).withOpacity(0.1),
              borderRadius: SocioTheme.radiusSm,
            ),
            child: Center(
              child: Text(
                lead.company.isNotEmpty ? lead.company[0].toUpperCase() : '?',
                style: GoogleFonts.outfit(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: _priorityColor(lead.priorityScore),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lead.company, style: GoogleFonts.outfit(
                  fontSize: 14, fontWeight: FontWeight.w600, color: SocioTheme.slateText,
                )),
                Text(lead.decisionMakerTitle, style: GoogleFonts.dmSans(
                  fontSize: 12, color: SocioTheme.mutedText,
                )),
              ],
            ),
          ),
          _ScoreBadge(score: lead.priorityScore),
        ],
      ),
    );
  }

  Color _priorityColor(int score) {
    if (score >= 75) return SocioTheme.emeraldAccent;
    if (score >= 50) return SocioTheme.amber;
    return SocioTheme.mutedText;
  }
}

// ── LEADS QUEUE TAB ───────────────────────────────────────────────────────────

class _LeadsQueueTab extends ConsumerWidget {
  const _LeadsQueueTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leadsAsync = ref.watch(leadsStreamProvider);

    return leadsAsync.when(
      data: (leads) {
        if (leads.isEmpty) {
          return _EmptyQueue();
        }

        // Group by status
        final ready   = leads.where((l) => l.status == LeadStatus.emailReady).toList();
        final sent    = leads.where((l) => l.status == LeadStatus.sent).toList();
        final replied = leads.where((l) => l.status == LeadStatus.replied).toList();
        final other   = leads.where((l) => ![
          LeadStatus.emailReady, LeadStatus.sent, LeadStatus.replied
        ].contains(l.status)).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Stats row
            _StatsRow(leads: leads),
            const SizedBox(height: 16),

            if (ready.isNotEmpty) ...[
              _SectionHeader(title: 'Ready to Send', subtitle: '${ready.length} emails written'),
              const SizedBox(height: 8),
              ...ready.map((l) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _LeadCard(lead: l),
              )),
              const SizedBox(height: 12),
            ],
            if (replied.isNotEmpty) ...[
              _SectionHeader(title: 'Got a Reply', subtitle: '${replied.length} conversations'),
              const SizedBox(height: 8),
              ...replied.map((l) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _LeadCard(lead: l),
              )),
              const SizedBox(height: 12),
            ],
            if (sent.isNotEmpty) ...[
              _SectionHeader(title: 'Sent', subtitle: '${sent.length} waiting'),
              const SizedBox(height: 8),
              ...sent.map((l) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _LeadCard(lead: l),
              )),
              const SizedBox(height: 12),
            ],
            if (other.isNotEmpty) ...[
              _SectionHeader(title: 'Discovering...', subtitle: '${other.length} leads'),
              const SizedBox(height: 8),
              ...other.map((l) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _LeadCard(lead: l),
              )),
            ],
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: SocioTheme.forestGreen),
      ),
      error: (e, _) => Center(
        child: Text('Error: $e', style: GoogleFonts.dmSans(color: SocioTheme.rose)),
      ),
    );
  }
}

class _LeadCard extends ConsumerWidget {
  const _LeadCard({required this.lead});
  final LeadModel lead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showLeadDetail(context, ref),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: socioCardDecoration(elevated: true),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Company avatar
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: SocioTheme.violetSurface,
                    borderRadius: SocioTheme.radiusSm,
                  ),
                  child: Center(
                    child: Text(
                      lead.company.isNotEmpty ? lead.company[0].toUpperCase() : '?',
                      style: GoogleFonts.outfit(
                        fontSize: 16, fontWeight: FontWeight.w700,
                        color: SocioTheme.violet,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lead.company, style: GoogleFonts.outfit(
                        fontSize: 15, fontWeight: FontWeight.w600, color: SocioTheme.slateText,
                      )),
                      Text(
                        '${lead.decisionMakerTitle} · ${lead.companySize}',
                        style: GoogleFonts.dmSans(fontSize: 12, color: SocioTheme.mutedText),
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: lead.status),
              ],
            ),
            const SizedBox(height: 10),
            // Budget signal
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: SocioTheme.amber.withOpacity(0.08),
                borderRadius: SocioTheme.radiusSm,
                border: Border.all(color: SocioTheme.amber.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded, size: 13, color: SocioTheme.amber),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      lead.budgetSignal,
                      style: GoogleFonts.dmSans(
                        fontSize: 12, color: SocioTheme.slateText, height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (lead.emailSubject != null && lead.emailSubject!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.mail_outline_rounded, size: 13, color: SocioTheme.emeraldAccent),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      lead.emailSubject!,
                      style: GoogleFonts.dmSans(
                        fontSize: 12, color: SocioTheme.emeraldAccent, fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showLeadDetail(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => _LeadDetailSheet(lead: lead, ref: ref),
    );
  }
}

class _LeadDetailSheet extends ConsumerStatefulWidget {
  const _LeadDetailSheet({required this.lead, required this.ref});
  final LeadModel lead;
  final WidgetRef ref;

  @override
  ConsumerState<_LeadDetailSheet> createState() => _LeadDetailSheetState();
}

class _LeadDetailSheetState extends ConsumerState<_LeadDetailSheet> {
  bool _emailCopied = false;

  @override
  Widget build(BuildContext context) {
    final lead = widget.lead;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (ctx, sc) => Container(
        decoration: const BoxDecoration(
          color: SocioTheme.creamBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: SocioTheme.creamBorder, borderRadius: SocioTheme.radiusFull,
              ),
            ),
            Expanded(
              child: ListView(
                controller: sc,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  Text(lead.company, style: GoogleFonts.outfit(
                    fontSize: 22, fontWeight: FontWeight.w700, color: SocioTheme.slateText,
                  )),
                  Text(
                    '${lead.decisionMakerTitle} · ${lead.domain}',
                    style: GoogleFonts.dmSans(fontSize: 13, color: SocioTheme.mutedText),
                  ),
                  const SizedBox(height: 16),

                  // Fit reason
                  _InfoBlock('Why this lead', lead.fitReason, Icons.check_circle_outline_rounded),
                  const SizedBox(height: 10),
                  _InfoBlock('Budget signal', lead.budgetSignal, Icons.bolt_rounded),
                  const SizedBox(height: 20),

                  if (lead.emailSubject != null && lead.emailBody != null) ...[
                    Row(
                      children: [
                        Text('Generated email', style: GoogleFonts.outfit(
                          fontSize: 16, fontWeight: FontWeight.w600, color: SocioTheme.slateText,
                        )),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(
                              text: 'Subject: ${lead.emailSubject}\n\n${lead.emailBody}',
                            ));
                            setState(() => _emailCopied = true);
                            Future.delayed(const Duration(seconds: 2), () {
                              if (mounted) setState(() => _emailCopied = false);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _emailCopied
                                  ? SocioTheme.emeraldAccent.withOpacity(0.1)
                                  : SocioTheme.violetSurface,
                              borderRadius: SocioTheme.radiusFull,
                            ),
                            child: Row(children: [
                              Icon(
                                _emailCopied ? Icons.check_rounded : Icons.copy_rounded,
                                size: 13,
                                color: _emailCopied ? SocioTheme.emeraldAccent : SocioTheme.violet,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _emailCopied ? 'Copied' : 'Copy',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12, fontWeight: FontWeight.w600,
                                  color: _emailCopied ? SocioTheme.emeraldAccent : SocioTheme.violet,
                                ),
                              ),
                            ]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: socioCardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: SocioTheme.forestGreen.withOpacity(0.08),
                              borderRadius: SocioTheme.radiusSm,
                            ),
                            child: Text(
                              lead.emailSubject!,
                              style: GoogleFonts.outfit(
                                fontSize: 13, fontWeight: FontWeight.w600,
                                color: SocioTheme.forestGreen,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            lead.emailBody!,
                            style: GoogleFonts.dmSans(
                              fontSize: 14, color: SocioTheme.slateText, height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Status actions
                  _StatusActions(lead: lead),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusActions extends ConsumerWidget {
  const _StatusActions({required this.lead});
  final LeadModel lead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user    = ref.read(authStateProvider).value;
    final startup = ref.read(startupNotifierProvider).value;
    if (user == null || startup == null) return const SizedBox.shrink();

    final service = ref.read(leadServiceProvider);

    Future<void> markAs(LeadStatus status) async {
      await service.updateLeadStatus(
        uid: user.uid,
        startupId: startup.id,
        leadId: lead.id,
        status: status,
      );
      if (context.mounted) Navigator.pop(context);
    }

    return Column(
      children: [
        if (lead.status == LeadStatus.emailReady)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => markAs(LeadStatus.sent),
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('Mark as Sent'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SocioTheme.forestGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        if (lead.status == LeadStatus.sent) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => markAs(LeadStatus.replied),
              icon: const Icon(Icons.reply_rounded, size: 16),
              label: const Text('Got a Reply'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SocioTheme.emeraldAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => markAs(LeadStatus.notInterested),
              child: Text('No Reply / Not Interested',
                style: GoogleFonts.dmSans(color: SocioTheme.mutedText),
              ),
            ),
          ),
        ],
        if (lead.status == LeadStatus.replied)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => markAs(LeadStatus.converted),
              icon: const Icon(Icons.handshake_outlined, size: 16),
              label: const Text('Mark as Converted'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SocioTheme.violet,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});
  final String title, subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.outfit(
                fontSize: 15, fontWeight: FontWeight.w600, color: SocioTheme.slateText,
              )),
              Text(subtitle, style: GoogleFonts.dmSans(
                fontSize: 12, color: SocioTheme.mutedText,
              )),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.leads});
  final List<LeadModel> leads;

  @override
  Widget build(BuildContext context) {
    final ready    = leads.where((l) => l.status == LeadStatus.emailReady).length;
    final sent     = leads.where((l) => l.status == LeadStatus.sent).length;
    final replied  = leads.where((l) => l.status == LeadStatus.replied).length;

    return Row(
      children: [
        _StatTile('Total', leads.length.toString(), SocioTheme.mutedText),
        const SizedBox(width: 8),
        _StatTile('Ready', ready.toString(), SocioTheme.forestGreen),
        const SizedBox(width: 8),
        _StatTile('Sent', sent.toString(), SocioTheme.amber),
        const SizedBox(width: 8),
        _StatTile('Replies', replied.toString(), SocioTheme.violet),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(this.label, this.value, this.color);
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: SocioTheme.radiusMd,
          border: Border.all(color: color.withOpacity(0.20)),
        ),
        child: Column(children: [
          Text(value, style: GoogleFonts.outfit(
            fontSize: 20, fontWeight: FontWeight.w700, color: color,
          )),
          Text(label, style: GoogleFonts.dmSans(
            fontSize: 11, color: SocioTheme.mutedText,
          )),
        ]),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final LeadStatus status;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case LeadStatus.emailReady:   color = SocioTheme.forestGreen; break;
      case LeadStatus.sent:         color = SocioTheme.amber; break;
      case LeadStatus.replied:      color = SocioTheme.violet; break;
      case LeadStatus.converted:    color = SocioTheme.emeraldAccent; break;
      case LeadStatus.notInterested: color = SocioTheme.mutedText; break;
      default:                      color = SocioTheme.mutedText;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: SocioTheme.radiusFull,
        border: Border.all(color: color.withOpacity(0.30)),
      ),
      child: Text(
        status.label,
        style: GoogleFonts.dmSans(
          fontSize: 10.5, fontWeight: FontWeight.w700, color: color,
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    final color = score >= 75
        ? SocioTheme.emeraldAccent
        : score >= 50 ? SocioTheme.amber : SocioTheme.mutedText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: SocioTheme.radiusFull,
      ),
      child: Text(
        '$score',
        style: GoogleFonts.outfit(
          fontSize: 13, fontWeight: FontWeight.w700, color: color,
        ),
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock(this.label, this.content, this.icon);
  final String label, content;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: socioCardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: SocioTheme.mutedText),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.dmSans(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: SocioTheme.mutedText, letterSpacing: 0.3,
                )),
                const SizedBox(height: 3),
                Text(content, style: GoogleFonts.dmSans(
                  fontSize: 13, color: SocioTheme.slateText, height: 1.5,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyQueue extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: SocioTheme.creamBorder),
            const SizedBox(height: 16),
            Text('No leads yet', style: GoogleFonts.outfit(
              fontSize: 18, fontWeight: FontWeight.w600, color: SocioTheme.slateText,
            )),
            const SizedBox(height: 8),
            Text(
              'Use Auto-Discover to find real companies\nand generate outreach emails.',
              style: GoogleFonts.dmSans(
                fontSize: 14, color: SocioTheme.mutedText, height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
