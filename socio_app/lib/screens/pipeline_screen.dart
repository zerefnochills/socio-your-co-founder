// screens/pipeline_screen.dart
// Socio — Investor Pipeline Screen
// Features: Kanban board, list view, add investor, AI follow-up, overdue alerts

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../app_theme.dart';
import '../models/investor_model.dart';
import '../providers/pipeline_provider.dart';
import '../providers/startup_provider.dart';
import '../services/firestore_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens mapped to Socio Design System
// ─────────────────────────────────────────────────────────────────────────────
Color get _purple => SocioTheme.forestGreen;
Color get _purpleLight => SocioTheme.forestGreen.withOpacity(0.08);
Color get _bg => SocioTheme.creamBg;
Color get _text => SocioTheme.slateText;
Color get _textMuted => SocioTheme.mutedText;
Color get _success => SocioTheme.emeraldAccent;
Color get _warning => SocioTheme.amber;
Color get _error => SocioTheme.rose;
Color get _border => SocioTheme.creamBorder;

Color _statusColor(InvestorStatus s) {
  switch (s) {
    case InvestorStatus.identified:   return const Color(0xFF64748B);
    case InvestorStatus.contacted:    return SocioTheme.violet;
    case InvestorStatus.responded:    return const Color(0xFF2563EB);
    case InvestorStatus.meeting:      return const Color(0xFF0891B2);
    case InvestorStatus.dueDiligence: return SocioTheme.amber;
    case InvestorStatus.termSheet:    return SocioTheme.violetLight;
    case InvestorStatus.closed:       return SocioTheme.emeraldAccent;
    case InvestorStatus.passed:       return SocioTheme.rose;
    case InvestorStatus.ghosted:      return const Color(0xFF94A3B8);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────────────────────────────────────

class PipelineScreen extends ConsumerStatefulWidget {
  const PipelineScreen({super.key});

  @override
  ConsumerState<PipelineScreen> createState() => _PipelineScreenState();
}

class _PipelineScreenState extends ConsumerState<PipelineScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _isKanban = false; // false = list, true = kanban board

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pipelineAsync = ref.watch(pipelineProvider);
    final overdue = ref.watch(overdueInvestorsProvider);
    final stats = ref.watch(pipelineStatsProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              isKanban: _isKanban,
              onToggleView: () => setState(() => _isKanban = !_isKanban),
            ),

            // Overdue banner
            if (overdue.isNotEmpty)
              _OverdueBanner(overdue: overdue),

            // Stats row
            _StatsRow(stats: stats),

            // Filter chips
            const _FilterChips(),

            // Main content
            Expanded(
              child: pipelineAsync.when(
                loading: () => Center(
                  child: CircularProgressIndicator(color: _purple),
                ),
                error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: TextStyle(color: _error)),
                ),
                data: (_) => _isKanban
                    ? const _KanbanBoard()
                    : const _InvestorList(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _purple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text('Add Investor',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
        onPressed: () => _showAddInvestorSheet(context),
      ),
    );
  }

  void _showAddInvestorSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddInvestorSheet(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final bool isKanban;
  final VoidCallback onToggleView;

  const _Header({required this.isKanban, required this.onToggleView});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Investor Pipeline',
                  style: GoogleFonts.dmSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _text,
                  )),
              Text('Track your fundraising funnel',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: _textMuted,
                  )),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: onToggleView,
            icon: Icon(
              isKanban ? Icons.view_list_rounded : Icons.view_column_rounded,
              color: _purple,
            ),
            tooltip: isKanban ? 'List view' : 'Kanban view',
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.tune_rounded, color: _textMuted),
            tooltip: 'Sort & filter',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overdue Banner
// ─────────────────────────────────────────────────────────────────────────────

class _OverdueBanner extends StatelessWidget {
  final List<InvestorModel> overdue;

  const _OverdueBanner({required this.overdue});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded, color: _warning, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${overdue.length} investor${overdue.length > 1 ? 's' : ''} need a follow-up — ${overdue.map((i) => i.name).take(2).join(', ')}${overdue.length > 2 ? ' +${overdue.length - 2}' : ''}',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: const Color(0xFF92400E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: _warning,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
            ),
            child: Text('View',
                style: GoogleFonts.dmSans(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats Row
// ─────────────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final Map<InvestorStatus, int> stats;

  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final total = stats.values.fold(0, (a, b) => a + b);
    final active = stats.entries
        .where((e) => e.key.isActive)
        .fold(0, (a, e) => a + e.value);
    final meetings = (stats[InvestorStatus.meeting] ?? 0) +
        (stats[InvestorStatus.dueDiligence] ?? 0);
    final closed = stats[InvestorStatus.closed] ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          _StatChip(label: 'Total', value: '$total', color: _textMuted),
          const SizedBox(width: 8),
          _StatChip(label: 'Active', value: '$active', color: _purple),
          const SizedBox(width: 8),
          _StatChip(label: 'In talks', value: '$meetings', color: _warning),
          const SizedBox(width: 8),
          _StatChip(
              label: 'Closed',
              value: '$closed',
              color: _success,
              solid: closed > 0),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool solid;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    this.solid = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: solid ? color.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color)),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.dmSans(fontSize: 12, color: _textMuted)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter Chips
// ─────────────────────────────────────────────────────────────────────────────

class _FilterChips extends ConsumerWidget {
  const _FilterChips();

  static const _stages = [
    null, // All
    InvestorStatus.contacted,
    InvestorStatus.responded,
    InvestorStatus.meeting,
    InvestorStatus.dueDiligence,
    InvestorStatus.termSheet,
    InvestorStatus.closed,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(pipelineFilterProvider);

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _stages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final stage = _stages[i];
          final isSelected = current == stage;
          final label = stage?.label ?? 'All';
          final color = stage != null ? _statusColor(stage) : _purple;

          return GestureDetector(
            onTap: () =>
                ref.read(pipelineFilterProvider.notifier).state = stage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.white,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: isSelected ? color : _border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? Colors.white : _textMuted,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// List View
// ─────────────────────────────────────────────────────────────────────────────

class _InvestorList extends ConsumerWidget {
  const _InvestorList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final investors = ref.watch(filteredInvestorsProvider);

    if (investors.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline_rounded,
                size: 48, color: _border),
            const SizedBox(height: 12),
            Text('No investors here yet',
                style: GoogleFonts.dmSans(color: _textMuted, fontSize: 15)),
            const SizedBox(height: 4),
            Text('Tap + Add Investor to start tracking',
                style: GoogleFonts.dmSans(
                    color: _border, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: investors.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _InvestorCard(investor: investors[i]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Investor Card
// ─────────────────────────────────────────────────────────────────────────────

class _InvestorCard extends ConsumerWidget {
  final InvestorModel investor;

  const _InvestorCard({required this.investor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _statusColor(investor.status);

    return GestureDetector(
      onTap: () {
        ref.read(selectedInvestorProvider.notifier).state = investor;
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _InvestorDetailSheet(investor: investor),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      investor.name.isNotEmpty
                          ? investor.name[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(investor.name,
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _text,
                          )),
                      Text('${investor.firm}${investor.role.isNotEmpty ? ' · ${investor.role}' : ''}',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: _textMuted,
                          )),
                    ],
                  ),
                ),
                // Status badge
                _StatusBadge(status: investor.status),
              ],
            ),
            if (investor.notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                investor.notes,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(fontSize: 13, color: _textMuted),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                if (investor.checkSize.isNotEmpty) ...[
                  Icon(Icons.currency_rupee_rounded,
                      size: 13, color: _textMuted),
                  Text(investor.checkSize,
                      style: GoogleFonts.dmSans(
                          fontSize: 12, color: _textMuted)),
                ],
                const Spacer(),
                if (investor.daysSinceContact >= 0) ...[
                  Icon(
                    investor.isOverdue
                        ? Icons.warning_amber_rounded
                        : Icons.schedule_rounded,
                    size: 14,
                    color: investor.isOverdue ? _warning : _textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    investor.daysSinceContact == 0
                        ? 'Today'
                        : '${investor.daysSinceContact}d ago',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: investor.isOverdue ? _warning : _textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final InvestorStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            status.label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Kanban Board
// ─────────────────────────────────────────────────────────────────────────────

class _KanbanBoard extends ConsumerWidget {
  const _KanbanBoard();

  static const _activeStages = [
    InvestorStatus.identified,
    InvestorStatus.contacted,
    InvestorStatus.responded,
    InvestorStatus.meeting,
    InvestorStatus.dueDiligence,
    InvestorStatus.termSheet,
    InvestorStatus.closed,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(pipelineProvider).value ?? [];

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: _activeStages.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (_, i) {
        final stage = _activeStages[i];
        final stageInvestors =
            all.where((inv) => inv.status == stage).toList();
        return _KanbanColumn(stage: stage, investors: stageInvestors);
      },
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  final InvestorStatus stage;
  final List<InvestorModel> investors;

  const _KanbanColumn(
      {required this.stage, required this.investors});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(stage);

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Text(stage.label,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color,
                    )),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text('${investors.length}',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color,
                      )),
                ),
              ],
            ),
          ),
          // Cards
          Expanded(
            child: investors.isEmpty
                ? Center(
                    child: Text('Empty',
                        style: GoogleFonts.dmSans(
                            fontSize: 12, color: _border)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    itemCount: investors.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 6),
                    itemBuilder: (_, i) =>
                        _KanbanCard(investor: investors[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _KanbanCard extends ConsumerWidget {
  final InvestorModel investor;

  const _KanbanCard({required this.investor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        ref.read(selectedInvestorProvider.notifier).state = investor;
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _InvestorDetailSheet(investor: investor),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(investor.name,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _text,
                )),
            Text(investor.firm,
                style: GoogleFonts.dmSans(
                    fontSize: 12, color: _textMuted)),
            if (investor.daysSinceContact >= 0) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.schedule_rounded,
                      size: 11,
                      color:
                          investor.isOverdue ? _warning : _textMuted),
                  const SizedBox(width: 3),
                  Text(
                    '${investor.daysSinceContact}d',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: investor.isOverdue ? _warning : _textMuted,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Investor Detail Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _InvestorDetailSheet extends ConsumerStatefulWidget {
  final InvestorModel investor;

  const _InvestorDetailSheet({required this.investor});

  @override
  ConsumerState<_InvestorDetailSheet> createState() =>
      _InvestorDetailSheetState();
}

class _InvestorDetailSheetState
    extends ConsumerState<_InvestorDetailSheet> {
  bool _generatingFollowUp = false;
  String? _followUpEmail;
  String? _followUpError;

  Future<void> _generateFollowUp() async {
    setState(() {
      _generatingFollowUp = true;
      _followUpError = null;
      _followUpEmail = null;
    });

    try {
      final startup = ref.read(startupNotifierProvider).value;
      final dio = Dio();
      final host = kIsWeb ? 'localhost:8000' : '10.0.2.2:8000';
      final resp = await dio.post(
        'http://$host/investor-followup',
        data: {
          'investor_name': widget.investor.name,
          'investor_firm': widget.investor.firm,
          'meeting_notes': widget.investor.notes,
          'days_since_contact': widget.investor.daysSinceContact,
          'status': widget.investor.status.label,
          'startup_name': startup?.name ?? 'My Startup',
          'traction': startup != null
              ? 'MRR: ₹${startup.mrr}, Users: ${startup.userCount}'
              : 'Early stage, building MVP',
        },
      );


      final email = resp.data['email'] ?? resp.data['follow_up_email'] ?? '';
      setState(() {
        _followUpEmail = email;
        _generatingFollowUp = false;
      });
    } catch (e) {
      setState(() {
        _followUpError = 'Failed to generate follow-up. Check backend.';
        _generatingFollowUp = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final investor = widget.investor;
    final color = _statusColor(investor.status);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            investor.name[0].toUpperCase(),
                            style: GoogleFonts.dmSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(investor.name,
                                style: GoogleFonts.dmSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: _text,
                                )),
                            Text(
                              '${investor.firm}${investor.role.isNotEmpty ? ' · ${investor.role}' : ''}',
                              style: GoogleFonts.dmSans(
                                  fontSize: 14, color: _textMuted),
                            ),
                          ],
                        ),
                      ),
                      _StatusBadge(status: investor.status),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Quick actions row
                  Row(
                    children: [
                      _ActionButton(
                        icon: Icons.auto_awesome_rounded,
                        label: 'AI Follow-up',
                        color: _purple,
                        onTap: _generateFollowUp,
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'Mark contacted',
                        color: _success,
                        onTap: () async {
                          await ref
                              .read(pipelineProvider.notifier)
                              .recordFollowUp(investor.id);
                          if (context.mounted) Navigator.pop(context);
                        },
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        icon: Icons.edit_outlined,
                        label: 'Edit',
                        color: _textMuted,
                        onTap: () {
                          Navigator.pop(context);
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) =>
                                _AddInvestorSheet(existing: investor),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Move status
                  _SectionLabel('Pipeline Stage'),
                  const SizedBox(height: 8),
                  _StatusPicker(
                    current: investor.status,
                    onChanged: (newStatus) async {
                      await ref
                          .read(pipelineProvider.notifier)
                          .updateStatus(investor.id, newStatus);
                    },
                  ),

                  const SizedBox(height: 20),

                  // Details
                  _SectionLabel('Details'),
                  const SizedBox(height: 8),
                  _DetailRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: investor.email.isNotEmpty
                          ? investor.email
                          : '—'),
                  _DetailRow(
                      icon: Icons.attach_money_rounded,
                      label: 'Check size',
                      value: investor.checkSize.isNotEmpty
                          ? investor.checkSize
                          : '—'),
                  _DetailRow(
                      icon: Icons.business_center_outlined,
                      label: 'Stage',
                      value: investor.stage.isNotEmpty
                          ? investor.stage
                          : '—'),
                  _DetailRow(
                      icon: Icons.category_outlined,
                      label: 'Sector',
                      value: investor.sector.isNotEmpty
                          ? investor.sector
                          : '—'),
                  if (investor.lastContactDate != null)
                    _DetailRow(
                        icon: Icons.schedule_rounded,
                        label: 'Last contact',
                        value:
                            '${investor.daysSinceContact}d ago'),

                  if (investor.notes.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _SectionLabel('Notes'),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _border),
                      ),
                      child: Text(investor.notes,
                          style: GoogleFonts.dmSans(
                              fontSize: 14, color: _text, height: 1.5)),
                    ),
                  ],

                  // AI Follow-up result
                  if (_generatingFollowUp) ...[
                    const SizedBox(height: 24),
                    Center(
                      child: CircularProgressIndicator(color: _purple),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text('Socio AI is crafting your follow-up…',
                          style: GoogleFonts.dmSans(
                              fontSize: 13, color: _textMuted)),
                    ),
                  ],

                  if (_followUpEmail != null) ...[
                    const SizedBox(height: 24),
                    _SectionLabel('AI-Generated Follow-up'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _purpleLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _purple.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_followUpEmail!,
                              style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  color: _text,
                                  height: 1.6)),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () {
                              // Copy to clipboard
                            },
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.end,
                              children: [
                                Icon(Icons.copy_rounded,
                                    size: 14, color: _purple),
                                const SizedBox(width: 4),
                                Text('Copy',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      color: _purple,
                                      fontWeight: FontWeight.w600,
                                    )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_followUpError != null) ...[
                    const SizedBox(height: 16),
                    Text(_followUpError!,
                        style: GoogleFonts.dmSans(
                            fontSize: 13, color: _error)),
                  ],

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 4),
              Text(label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: color,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPicker extends StatelessWidget {
  final InvestorStatus current;
  final ValueChanged<InvestorStatus> onChanged;

  static const _stages = [
    InvestorStatus.identified,
    InvestorStatus.contacted,
    InvestorStatus.responded,
    InvestorStatus.meeting,
    InvestorStatus.dueDiligence,
    InvestorStatus.termSheet,
    InvestorStatus.closed,
    InvestorStatus.passed,
    InvestorStatus.ghosted,
  ];

  const _StatusPicker(
      {required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _stages.map((s) {
        final isSelected = s == current;
        final color = _statusColor(s);
        return GestureDetector(
          onTap: () => onChanged(s),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? color : Colors.transparent,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: isSelected ? color : _border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  s.label,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: isSelected ? Colors.white : _textMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _textMuted,
          letterSpacing: 0.5,
        ));
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _textMuted),
          const SizedBox(width: 8),
          Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: _textMuted)),
          const Spacer(),
          Text(value,
              style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _text)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add / Edit Investor Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AddInvestorSheet extends ConsumerStatefulWidget {
  final InvestorModel? existing;

  const _AddInvestorSheet({this.existing});

  @override
  ConsumerState<_AddInvestorSheet> createState() =>
      _AddInvestorSheetState();
}

class _AddInvestorSheetState extends ConsumerState<_AddInvestorSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _firm;
  late final TextEditingController _role;
  late final TextEditingController _email;
  late final TextEditingController _checkSize;
  late final TextEditingController _stage;
  late final TextEditingController _sector;
  late final TextEditingController _notes;

  InvestorStatus _status = InvestorStatus.identified;
  int _warmth = 3;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _firm = TextEditingController(text: e?.firm ?? '');
    _role = TextEditingController(text: e?.role ?? '');
    _email = TextEditingController(text: e?.email ?? '');
    _checkSize = TextEditingController(text: e?.checkSize ?? '');
    _stage = TextEditingController(text: e?.stage ?? '');
    _sector = TextEditingController(text: e?.sector ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
    _status = e?.status ?? InvestorStatus.identified;
    _warmth = e?.warmthScore ?? 3;
  }

  @override
  void dispose() {
    for (final c in [
      _name, _firm, _role, _email, _checkSize, _stage, _sector, _notes
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final investor = InvestorModel(
        id: widget.existing?.id ?? '',
        name: _name.text.trim(),
        firm: _firm.text.trim(),
        role: _role.text.trim(),
        email: _email.text.trim(),
        checkSize: _checkSize.text.trim(),
        stage: _stage.text.trim(),
        sector: _sector.text.trim(),
        notes: _notes.text.trim(),
        status: _status,
        warmthScore: _warmth,
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
      );

      if (_isEdit) {
        await ref.read(pipelineProvider.notifier).updateInvestor(investor);
      } else {
        await ref.read(pipelineProvider.notifier).addInvestor(investor);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Drag handle + title
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Text(
                      _isEdit ? 'Edit Investor' : 'Add Investor',
                      style: GoogleFonts.dmSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _text,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded, color: _textMuted),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _FormField(
                        controller: _name,
                        label: 'Investor Name *',
                        hint: 'e.g. Sequoia Capital Partner',
                        validator: (v) =>
                            v!.isEmpty ? 'Name is required' : null),
                    _FormField(
                        controller: _firm,
                        label: 'Firm *',
                        hint: 'e.g. Sequoia Capital',
                        validator: (v) =>
                            v!.isEmpty ? 'Firm is required' : null),
                    _FormField(
                        controller: _role,
                        label: 'Role',
                        hint: 'e.g. Partner, Managing Director'),
                    _FormField(
                        controller: _email,
                        label: 'Email',
                        hint: 'investor@firm.com',
                        keyboardType: TextInputType.emailAddress),
                    _FormField(
                        controller: _checkSize,
                        label: 'Check Size',
                        hint: 'e.g. ₹50L – ₹1Cr'),
                    _FormField(
                        controller: _stage,
                        label: 'Investment Stage',
                        hint: 'e.g. Pre-Seed, Seed'),
                    _FormField(
                        controller: _sector,
                        label: 'Sector Focus',
                        hint: 'e.g. B2B SaaS, AI/ML'),

                    // Status
                    const SizedBox(height: 16),
                    _SectionLabel('Initial Status'),
                    const SizedBox(height: 8),
                    _StatusPicker(
                      current: _status,
                      onChanged: (s) => setState(() => _status = s),
                    ),

                    // Warmth
                    const SizedBox(height: 16),
                    _SectionLabel('Lead Warmth'),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (i) {
                        final filled = i < _warmth;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _warmth = i + 1),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              filled
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: filled ? _warning : _border,
                              size: 28,
                            ),
                          ),
                        );
                      }),
                    ),

                    // Notes
                    const SizedBox(height: 16),
                    _FormField(
                      controller: _notes,
                      label: 'Notes / Meeting context',
                      hint:
                          'What happened in the last meeting? What do they care about?',
                      maxLines: 4,
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _purple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _isEdit ? 'Save Changes' : 'Add Investor',
                                style: GoogleFonts.dmSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    if (_isEdit) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: TextButton(
                          onPressed: () async {
                            await ref
                                .read(pipelineProvider.notifier)
                                .deleteInvestor(widget.existing!.id);
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: Text(
                            'Delete Investor',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: _error,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(label),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style:
                GoogleFonts.dmSans(fontSize: 14, color: _text),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  GoogleFonts.dmSans(fontSize: 14, color: _border),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              filled: true,
              fillColor: _bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: _purple, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
