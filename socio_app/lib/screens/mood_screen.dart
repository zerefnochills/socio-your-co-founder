// screens/mood_screen.dart
// Socio — Automated Mood Tracker
// All data is real: auto-logged from chat AI responses + manual check-ins.
// Weekly chart, today's emotion, and SOS mode — zero hardcoded values.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../providers/mood_provider.dart';
import '../navigation/main_navigation.dart';

class MoodScreen extends ConsumerStatefulWidget {
  const MoodScreen({super.key});

  @override
  ConsumerState<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends ConsumerState<MoodScreen> {
  int _selectedScore = 3;
  String _selectedEmotion = 'Focused';
  bool _submitting = false;
  bool _justSubmitted = false;

  final List<Map<String, dynamic>> _emotions = [
    {'name': 'Stressed',  'icon': Icons.sentiment_very_dissatisfied_rounded, 'color': SocioTheme.rose},
    {'name': 'Anxious',   'icon': Icons.sentiment_dissatisfied_rounded,       'color': SocioTheme.amber},
    {'name': 'Focused',   'icon': Icons.sentiment_neutral_rounded,            'color': SocioTheme.violet},
    {'name': 'Excited',   'icon': Icons.sentiment_satisfied_rounded,          'color': SocioTheme.emeraldAccent},
    {'name': 'Peaceful',  'icon': Icons.sentiment_very_satisfied_rounded,     'color': Colors.blue},
  ];

  Future<void> _submitCheckIn() async {
    HapticFeedback.mediumImpact();
    setState(() { _submitting = true; _justSubmitted = false; });

    await ref.read(moodCheckInProvider.notifier).submitCheckIn(
      score: _selectedScore,
      emotion: _selectedEmotion,
    );

    if (mounted) {
      setState(() { _submitting = false; _justSubmitted = true; });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _justSubmitted = false);
      });
    }
  }

  void _triggerSOS() {
    HapticFeedback.vibrate();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: SocioTheme.radiusMd),
        backgroundColor: const Color(0xFFFFF1F2),
        title: Row(
          children: [
            const Icon(Icons.gpp_maybe_rounded, color: SocioTheme.rose, size: 28),
            const SizedBox(width: 8),
            Text(
              'Founder S.O.S. Active',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF991B1B)),
            ),
          ],
        ),
        content: Text(
          'Running a startup alone is incredibly taxing. Socio AI is ready to listen in "Crisis Mode" to stress-test your thoughts or help you decompress.\n\nInitiate a priority SOS session now?',
          style: GoogleFonts.dmSans(color: const Color(0xFF7F1D1D), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Maybe Later', style: GoogleFonts.dmSans(color: SocioTheme.mutedText)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              MainNavigation.tabNotifier.value = 0;
            },
            style: ElevatedButton.styleFrom(backgroundColor: SocioTheme.rose),
            child: Text(
              'Start SOS Chat',
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SocioTheme.creamBg,
      appBar: AppBar(
        title: Text(
          'Founder Wellness',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: SocioTheme.slateText),
        ),
        backgroundColor: SocioTheme.creamBg,
        elevation: 0,
        centerTitle: false,
        shape: const Border(bottom: BorderSide(color: SocioTheme.creamBorder)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLiveInsightBanner(),
            const SizedBox(height: 16),
            _buildCheckInCard(),
            const SizedBox(height: 20),
            _buildWeeklyTrendCard(),
            const SizedBox(height: 20),
            _buildSOSCard(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveInsightBanner() {
    final logsAsync = ref.watch(moodLogsStreamProvider);
    final weeklyAvg = ref.watch(weeklyAverageMoodProvider);
    final todayEmotion = ref.watch(todayEmotionProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: SocioTheme.forestGreen.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SocioTheme.forestGreen.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, size: 16, color: SocioTheme.forestGreen),
          const SizedBox(width: 8),
          Expanded(
            child: logsAsync.when(
              loading: () => Text('Loading your mood analytics…',
                  style: GoogleFonts.dmSans(fontSize: 12, color: SocioTheme.mutedText)),
              error: (_, __) => Text('Mood data unavailable — check connection.',
                  style: GoogleFonts.dmSans(fontSize: 12, color: SocioTheme.rose)),
              data: (logs) {
                final count = logs.length;
                if (count == 0) {
                  return Text('No mood data yet — start chatting with Socio!',
                      style: GoogleFonts.dmSans(fontSize: 12, color: SocioTheme.mutedText));
                }
                return Text(
                  '$count mood signals this week • avg ${weeklyAvg.toStringAsFixed(1)}/5 • today: $todayEmotion',
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: SocioTheme.forestGreen, fontWeight: FontWeight.w500),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: socioCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How is your founder mind today?',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: SocioTheme.slateText)),
          const SizedBox(height: 6),
          Text('Daily check-ins calibrate Socio AI\'s tone. They\'re also auto-logged from every chat response.',
              style: GoogleFonts.dmSans(fontSize: 12, color: SocioTheme.mutedText, height: 1.4)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _emotions.map((emotion) {
              final isSelected = _selectedEmotion == emotion['name'];
              final color = emotion['color'] as Color;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedEmotion = emotion['name'] as String);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.08) : SocioTheme.creamBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: isSelected ? color : SocioTheme.creamBorder,
                        width: isSelected ? 1.5 : 1),
                  ),
                  child: Column(
                    children: [
                      Icon(emotion['icon'] as IconData,
                          color: isSelected ? color : SocioTheme.mutedText, size: 24),
                      const SizedBox(height: 6),
                      Text(emotion['name'] as String,
                          style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? color : SocioTheme.mutedText)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Energy / Mood Level',
                  style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.bold, color: SocioTheme.mutedText)),
              Text('$_selectedScore / 5',
                  style: GoogleFonts.dmSans(fontSize: 12, color: SocioTheme.forestGreen, fontWeight: FontWeight.w600)),
            ],
          ),
          Slider(
            value: _selectedScore.toDouble(),
            min: 1, max: 5, divisions: 4,
            activeColor: SocioTheme.forestGreen,
            inactiveColor: SocioTheme.creamBorder,
            onChanged: (val) => setState(() => _selectedScore = val.toInt()),
          ),
          const SizedBox(height: 12),
          if (_justSubmitted)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: SocioTheme.emeraldAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SocioTheme.emeraldAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, size: 16, color: SocioTheme.emeraldAccent),
                  const SizedBox(width: 8),
                  Text('Check-in saved! Socio will adjust its tone.',
                      style: GoogleFonts.dmSans(
                          fontSize: 12, color: SocioTheme.emeraldAccent, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submitCheckIn,
              child: _submitting
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Log Check-In', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTrendCard() {
    final scoresAsync = ref.watch(moodLogsStreamProvider);
    final weeklyScores = ref.watch(weeklyMoodScoresProvider);
    final weeklyAvg = ref.watch(weeklyAverageMoodProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: socioCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mental Bandwidth Analytics',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: SocioTheme.slateText)),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: SocioTheme.forestGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: Text('Live',
                      style: GoogleFonts.dmSans(
                          color: SocioTheme.forestGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Text('Avg ${weeklyAvg.toStringAsFixed(1)}/5',
                    style: GoogleFonts.dmSans(fontSize: 12, color: SocioTheme.mutedText, fontWeight: FontWeight.w500)),
              ]),
            ],
          ),
          const SizedBox(height: 24),
          scoresAsync.when(
            loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
            error: (_, __) => SizedBox(
                height: 120,
                child: Center(child: Text('Could not load mood chart.',
                    style: GoogleFonts.dmSans(color: SocioTheme.mutedText)))),
            data: (_) => SizedBox(
              height: 120, width: double.infinity,
              child: CustomPaint(painter: _WeeklyLineChartPainter(weeklyScores)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((d) => Text(d,
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: SocioTheme.mutedText, fontWeight: FontWeight.w600)))
                .toList(),
          ),
          const SizedBox(height: 16),
          Row(children: [
            _LegendDot(color: SocioTheme.violet, label: 'Auto (chat)'),
            const SizedBox(width: 16),
            _LegendDot(color: SocioTheme.forestGreen, label: 'Manual check-in'),
          ]),
        ],
      ),
    );
  }

  Widget _buildSOSCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [SocioTheme.rose, Color(0xFF991B1B)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: SocioTheme.rose.withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.gpp_maybe_rounded, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Text('FOUNDER S.O.S.',
                style: GoogleFonts.outfit(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5)),
          ]),
          const SizedBox(height: 12),
          Text(
            'Everything crashing down? Under too much weight? Tap this to put Socio in SOS mode — stress decompression, action mapping, and clear advice. Immediately.',
            style: GoogleFonts.dmSans(color: const Color(0xFFFFE4E6), fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton(
              onPressed: _triggerSOS,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF991B1B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0),
              child: Text('TRIGGER S.O.S.',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: GoogleFonts.dmSans(fontSize: 11, color: SocioTheme.mutedText)),
    ]);
  }
}

class _WeeklyLineChartPainter extends CustomPainter {
  final List<double> scores;
  _WeeklyLineChartPainter(this.scores);

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.isEmpty) return;
    const maxScore = 5.0;
    const minScore = 0.0;

    final paintLine = Paint()
      ..color = SocioTheme.violet..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    final paintArea = Paint()
      ..shader = LinearGradient(
        colors: [SocioTheme.violet.withOpacity(0.3), SocioTheme.violet.withOpacity(0.0)],
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    final gridPaint = Paint()..color = SocioTheme.creamBorder..strokeWidth = 1.0;

    for (int i = 1; i <= 3; i++) {
      final y = size.height * (i / 4);
      _dash(canvas, Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final pathLine = Path();
    final pathArea = Path();
    final stepX = size.width / (scores.length - 1);
    bool first = true;

    for (int i = 0; i < scores.length; i++) {
      if (scores[i] <= 0) continue;
      final y = size.height - ((scores[i] - minScore) / (maxScore - minScore)) * size.height;
      final x = i * stepX;
      if (first) {
        pathLine.moveTo(x, y); pathArea.moveTo(x, size.height); pathArea.lineTo(x, y); first = false;
      } else {
        pathLine.lineTo(x, y); pathArea.lineTo(x, y);
      }
    }

    if (!first) {
      pathArea.lineTo(size.width, size.height); pathArea.close();
      canvas.drawPath(pathArea, paintArea);
      canvas.drawPath(pathLine, paintLine);
    }

    final dot = Paint()..color = SocioTheme.violet..style = PaintingStyle.fill;
    final dotBorder = Paint()..color = Colors.white..strokeWidth = 2.0..style = PaintingStyle.stroke;
    final noData = Paint()..color = SocioTheme.creamBorder..style = PaintingStyle.stroke..strokeWidth = 1.5;

    for (int i = 0; i < scores.length; i++) {
      final x = i * stepX;
      if (scores[i] > 0) {
        final y = size.height - ((scores[i] - minScore) / (maxScore - minScore)) * size.height;
        canvas.drawCircle(Offset(x, y), 5.0, dot);
        canvas.drawCircle(Offset(x, y), 5.0, dotBorder);
      } else {
        canvas.drawCircle(Offset(x, size.height / 2), 3.0, noData);
      }
    }
  }

  void _dash(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    double x = p1.dx;
    while (x < p2.dx) {
      canvas.drawLine(Offset(x, p1.dy), Offset(x + 4, p1.dy), paint);
      x += 8;
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyLineChartPainter old) => old.scores != scores;
}