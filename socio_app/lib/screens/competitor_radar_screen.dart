// screens/competitor_radar_screen.dart
// Socio — Competitor Radar Screen
// Premium radar-style competitive intelligence display

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../app_theme.dart';
import '../providers/startup_provider.dart';
import '../providers/outreach_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Competitor Data Model
// ─────────────────────────────────────────────────────────────────────────────

class CompetitorInfo {
  final String name;
  final String description;
  final String threatLevel; // Low, Medium, High
  final String recentMove;

  CompetitorInfo({
    required this.name,
    required this.description,
    required this.threatLevel,
    required this.recentMove,
  });

  factory CompetitorInfo.fromJson(Map<String, dynamic> json) {
    return CompetitorInfo(
      name: json['name'] ?? 'Unknown',
      description: json['description'] ?? '',
      threatLevel: json['threat_level'] ?? 'Medium',
      recentMove: json['recent_move'] ?? 'No recent activity detected.',
    );
  }

  Color get threatColor {
    switch (threatLevel.toLowerCase()) {
      case 'high':
        return SocioTheme.rose;
      case 'medium':
        return SocioTheme.amber;
      case 'low':
        return SocioTheme.emeraldAccent;
      default:
        return SocioTheme.mutedText;
    }
  }

  IconData get threatIcon {
    switch (threatLevel.toLowerCase()) {
      case 'high':
        return Icons.warning_rounded;
      case 'medium':
        return Icons.shield_rounded;
      case 'low':
        return Icons.check_circle_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────────────────────────────────────

class CompetitorRadarScreen extends ConsumerStatefulWidget {
  const CompetitorRadarScreen({super.key});

  @override
  ConsumerState<CompetitorRadarScreen> createState() =>
      _CompetitorRadarScreenState();
}

class _CompetitorRadarScreenState extends ConsumerState<CompetitorRadarScreen>
    with SingleTickerProviderStateMixin {
  List<CompetitorInfo> _competitors = [];
  bool _loading = false;
  String? _error;
  late AnimationController _radarCtrl;
  String _filterThreat = 'all'; // 'all', 'high', 'medium', 'low'

  @override
  void initState() {
    super.initState();
    _radarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _fetchCompetitors();
  }

  @override
  void dispose() {
    _radarCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchCompetitors() async {
    final startup = ref.read(startupNotifierProvider).value;
    if (startup == null || startup.idea.isEmpty) {
      setState(() => _error = 'Set your startup idea first in onboarding.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final competitorList = await ref.read(leadServiceProvider).fetchCompetitors(
        idea: startup.idea,
        companyName: startup.name,
      );

      setState(() {
        _competitors =
            competitorList.map((c) => CompetitorInfo.fromJson(c as Map<String, dynamic>)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to scan for competitors. Is the backend running?';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SocioTheme.creamBg,
      appBar: AppBar(
        title: Text(
          'Competitor Radar',
          style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600, color: SocioTheme.slateText),
        ),
        backgroundColor: SocioTheme.creamBg,
        elevation: 0,
        centerTitle: false,
        shape: const Border(
            bottom: BorderSide(color: SocioTheme.creamBorder)),
        actions: [
          IconButton(
            onPressed: _loading ? null : _fetchCompetitors,
            icon: Icon(
              Icons.refresh_rounded,
              color: _loading ? SocioTheme.placeholderText : SocioTheme.forestGreen,
            ),
            tooltip: 'Rescan',
          ),
        ],
      ),
      body: _loading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : _competitors.isEmpty
                  ? _buildEmptyState()
                  : _buildRadarView(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Radar animation
          SizedBox(
            width: 140,
            height: 140,
            child: AnimatedBuilder(
              animation: _radarCtrl,
              builder: (context, child) {
                return CustomPaint(
                  painter: _RadarPainter(
                    sweepAngle: _radarCtrl.value * 2 * pi,
                    color: SocioTheme.forestGreen,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Scanning the competitive landscape…',
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: SocioTheme.slateText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Socio AI is researching your market with Tavily',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: SocioTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 48, color: SocioTheme.rose.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                  fontSize: 14, color: SocioTheme.mutedText, height: 1.5),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchCompetitors,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text('Retry',
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.radar_rounded,
              size: 48, color: SocioTheme.creamBorder),
          const SizedBox(height: 12),
          Text(
            'No competitors found',
            style: GoogleFonts.dmSans(
                fontSize: 15, color: SocioTheme.mutedText),
          ),
          const SizedBox(height: 4),
          Text(
            'Try refining your startup idea for better results',
            style: GoogleFonts.dmSans(
                fontSize: 13, color: SocioTheme.placeholderText),
          ),
        ],
      ),
    );
  }

  void _showStrategySheet(BuildContext context, CompetitorInfo competitor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: SocioTheme.creamBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: SocioTheme.creamBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      competitor.name,
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: SocioTheme.slateText,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: competitor.threatColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: competitor.threatColor.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(competitor.threatIcon, size: 12, color: competitor.threatColor),
                        const SizedBox(width: 4),
                        Text(
                          competitor.threatLevel.toUpperCase(),
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: competitor.threatColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                competitor.description,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: SocioTheme.mutedText,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              const Divider(color: SocioTheme.creamBorder),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.psychology_outlined, color: SocioTheme.forestGreen, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Socio Co-Founder Advice',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: SocioTheme.slateText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: SocioTheme.creamCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: SocioTheme.creamBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HOW TO COMPETE & DEFEND:',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: SocioTheme.forestGreen,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getStrategyAdvice(competitor),
                      style: GoogleFonts.dmSans(
                        fontSize: 13.5,
                        color: SocioTheme.slateText,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getStrategyAdvice(CompetitorInfo competitor) {
    switch (competitor.threatLevel.toLowerCase()) {
      case 'high':
        return 'This competitor poses a high threat. Focus on rapid execution and high developer touch. Do not try to match them feature-for-feature; corporate giants move slow. Double down on your specific niche community, customer support, and close user relationship to out-pace them.';
      case 'medium':
        return 'A medium threat level. Monitor their product updates closely. Carve out a distinct product positioning (e.g. premium experience, integrations, or lower cost) to maintain your unique moat.';
      case 'low':
      default:
        return 'A low threat level. Their existence validates active market demand. Treat their presence as validation, but keep your head down and focus on your core roadmap rather than reacting to their releases.';
    }
  }

  Widget _buildRadarView() {
    final highThreats =
        _competitors.where((c) => c.threatLevel.toLowerCase() == 'high').length;
    final medThreats = _competitors
        .where((c) => c.threatLevel.toLowerCase() == 'medium')
        .length;
    final lowThreats =
        _competitors.where((c) => c.threatLevel.toLowerCase() == 'low').length;

    final filteredCompetitors = _filterThreat == 'all'
        ? _competitors
        : _competitors.where((c) => c.threatLevel.toLowerCase() == _filterThreat).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary stats
          Row(
            children: [
              _ThreatSummaryChip(
                label: 'High Threat',
                count: highThreats,
                color: SocioTheme.rose,
                isSelected: _filterThreat == 'high',
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _filterThreat = _filterThreat == 'high' ? 'all' : 'high';
                  });
                },
              ),
              const SizedBox(width: 8),
              _ThreatSummaryChip(
                label: 'Medium',
                count: medThreats,
                color: SocioTheme.amber,
                isSelected: _filterThreat == 'medium',
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _filterThreat = _filterThreat == 'medium' ? 'all' : 'medium';
                  });
                },
              ),
              const SizedBox(width: 8),
              _ThreatSummaryChip(
                label: 'Low',
                count: lowThreats,
                color: SocioTheme.emeraldAccent,
                isSelected: _filterThreat == 'low',
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _filterThreat = _filterThreat == 'low' ? 'all' : 'low';
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Radar visual header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: socioGreenDecoration(
                borderRadius: SocioTheme.radiusMd),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: AnimatedBuilder(
                    animation: _radarCtrl,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _RadarPainter(
                          sweepAngle: _radarCtrl.value * 2 * pi,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${filteredCompetitors.length} Competitors Shown',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _filterThreat == 'all'
                            ? 'AI-powered market intelligence via Tavily'
                            : 'Filtered landscape by ${_filterThreat.toUpperCase()} threat level',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Competitor cards
          Text(
            _filterThreat == 'all' ? 'COMPETITIVE LANDSCAPE' : 'FILTERED COMPETITORS (${_filterThreat.toUpperCase()})',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: SocioTheme.mutedText,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          filteredCompetitors.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'No competitors match this filter.',
                      style: GoogleFonts.dmSans(color: SocioTheme.mutedText),
                    ),
                  ),
                )
              : Column(
                  children: List.generate(filteredCompetitors.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CompetitorCard(
                        competitor: filteredCompetitors[i],
                        index: i,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _showStrategySheet(context, filteredCompetitors[i]);
                        },
                      ),
                    );
                  }),
                ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated Radar Painter
// ─────────────────────────────────────────────────────────────────────────────

class _RadarPainter extends CustomPainter {
  final double sweepAngle;
  final Color color;

  _RadarPainter({required this.sweepAngle, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Concentric rings
    final ringPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var i = 1; i <= 3; i++) {
      canvas.drawCircle(center, radius * (i / 3), ringPaint);
    }

    // Cross lines
    final crossPaint = Paint()
      ..color = color.withOpacity(0.08)
      ..strokeWidth = 0.5;
    canvas.drawLine(
        Offset(center.dx, 0), Offset(center.dx, size.height), crossPaint);
    canvas.drawLine(
        Offset(0, center.dy), Offset(size.width, center.dy), crossPaint);

    // Sweep gradient
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: sweepAngle - 0.8,
        endAngle: sweepAngle,
        colors: [color.withOpacity(0.0), color.withOpacity(0.35)],
        tileMode: TileMode.clamp,
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, sweepPaint);

    // Center dot
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 3, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) =>
      sweepAngle != oldDelegate.sweepAngle;
}

// ─────────────────────────────────────────────────────────────────────────────
// Threat Summary Chip
// ─────────────────────────────────────────────────────────────────────────────

class _ThreatSummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThreatSummaryChip({
    required this.label,
    required this.count,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.12) : color.withOpacity(0.04),
            borderRadius: SocioTheme.radiusMd,
            border: Border.all(
              color: isSelected ? color : color.withOpacity(0.15),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                '$count',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? color : SocioTheme.mutedText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Competitor Card
// ─────────────────────────────────────────────────────────────────────────────

class _CompetitorCard extends StatelessWidget {
  final CompetitorInfo competitor;
  final int index;
  final VoidCallback onTap;

  const _CompetitorCard({
    required this.competitor,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SocioTheme.creamCard,
          borderRadius: SocioTheme.radiusMd,
          border: Border.all(color: SocioTheme.creamBorder),
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
              // Index avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: competitor.threatColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    competitor.name.isNotEmpty
                        ? competitor.name[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: competitor.threatColor,
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
                      competitor.name,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: SocioTheme.slateText,
                      ),
                    ),
                    Text(
                      competitor.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: SocioTheme.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              // Threat badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: competitor.threatColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(99),
                  border:
                      Border.all(color: competitor.threatColor.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(competitor.threatIcon,
                        size: 12, color: competitor.threatColor),
                    const SizedBox(width: 4),
                    Text(
                      competitor.threatLevel,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: competitor.threatColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Recent move section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SocioTheme.creamBg,
              borderRadius: SocioTheme.radiusSm,
              border: Border.all(color: SocioTheme.creamBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RECENT MOVE',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: SocioTheme.mutedText,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  competitor.recentMove,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: SocioTheme.slateText,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
}