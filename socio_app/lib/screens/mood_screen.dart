import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';

/// Socio Wellness/Mood Screen — refined premium daily wellness standup.
/// Aesthetic: Warm editorial luxury.
class MoodScreen extends ConsumerStatefulWidget {
  const MoodScreen({super.key});

  @override
  ConsumerState<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends ConsumerState<MoodScreen> {
  int _selectedScore = 3;
  String _selectedEmotion = 'Focused';

  final List<Map<String, dynamic>> _emotions = [
    {'name': 'Stressed', 'icon': Icons.sentiment_very_dissatisfied_rounded, 'color': SocioTheme.rose},
    {'name': 'Anxious', 'icon': Icons.sentiment_dissatisfied_rounded, 'color': SocioTheme.amber},
    {'name': 'Focused', 'icon': Icons.sentiment_neutral_rounded, 'color': SocioTheme.violet},
    {'name': 'Excited', 'icon': Icons.sentiment_satisfied_rounded, 'color': SocioTheme.emeraldAccent},
    {'name': 'Peaceful', 'icon': Icons.sentiment_very_satisfied_rounded, 'color': Colors.blue},
  ];

  final List<double> _weeklyScores = [4.0, 3.5, 2.0, 3.0, 4.5, 3.0, 3.8];

  void _submitCheckIn() {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Daily standup check-in completed! Feel: $_selectedEmotion ($_selectedScore/5) 🧠'),
        backgroundColor: SocioTheme.forestGreen,
      ),
    );
  }

  void _triggerSOS() {
    HapticFeedback.vibrate();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: SocioTheme.radiusMd),
          backgroundColor: const Color(0xFFFFF1F2), // Light red warning tone
          title: Row(
            children: [
              const Icon(Icons.gpp_maybe_rounded, color: SocioTheme.rose, size: 28),
              const SizedBox(width: 8),
              Text(
                'Founder SOS Active',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF991B1B)),
              ),
            ],
          ),
          content: Text(
            'Running a startup alone is incredibly taxing. Socio AI is ready to listen in "Crisis Mode" (Devil\'s Advocate + Strategist dynamic hybrid) to stress-test your thoughts or help you decompress. \n\nWould you like to initiate a priority SOS session now?',
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('SOS dynamic session loaded. Go to Chat tab! ⚡'),
                    backgroundColor: SocioTheme.rose,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: SocioTheme.rose,
              ),
              child: Text(
                'Start SOS Chat',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Daily Check-in Card
            _buildCheckInCard(),
            const SizedBox(height: 20),

            // Weekly Trend
            _buildWeeklyTrendCard(),
            const SizedBox(height: 20),

            // SOS Alert Panel
            _buildSOSCard(),
            const SizedBox(height: 80), // bottom safe padding for floating navbar
          ],
        ),
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
          Text(
            'How is your founder mind today?',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: SocioTheme.slateText),
          ),
          const SizedBox(height: 8),
          Text(
            'Daily check-ins calibrate Socio AI\'s tone and thinking styles to match your current mental bandwidth.',
            style: GoogleFonts.dmSans(fontSize: 12, color: SocioTheme.mutedText, height: 1.4),
          ),
          const SizedBox(height: 20),
          
          // Emotion Buttons grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _emotions.map((emotion) {
              final isSelected = _selectedEmotion == emotion['name'];
              final color = emotion['color'] as Color;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedEmotion = emotion['name'];
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.08) : SocioTheme.creamBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? color : SocioTheme.creamBorder,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        emotion['icon'] as IconData,
                        color: isSelected ? color : SocioTheme.mutedText,
                        size: 24,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        emotion['name'] as String,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? color : SocioTheme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Stress/Energy Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Energy / Mood Level', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.bold, color: SocioTheme.mutedText)),
              Text('Scale: 1 (Critical) to 5 (Peak)', style: GoogleFonts.dmSans(fontSize: 10, color: SocioTheme.placeholderText)),
            ],
          ),
          Slider(
            value: _selectedScore.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            activeColor: SocioTheme.forestGreen,
            inactiveColor: SocioTheme.creamBorder,
            onChanged: (val) {
              setState(() {
                _selectedScore = val.toInt();
              });
            },
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _submitCheckIn,
              child: const Text('Check In Standup'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTrendCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: socioCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mental Bandwidth Analytics',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: SocioTheme.slateText),
          ),
          const SizedBox(height: 16),
          // Graphical bar representation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (index) {
              final score = _weeklyScores[index];
              final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

              return Column(
                children: [
                  Container(
                    height: score * 24,
                    width: 24,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: score < 3.0
                            ? [SocioTheme.rose, SocioTheme.rose.withOpacity(0.5)]
                            : [SocioTheme.forestGreen, SocioTheme.forestGreenLt],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    days[index],
                    style: GoogleFonts.dmSans(fontSize: 10, color: SocioTheme.mutedText, fontWeight: FontWeight.w600),
                  ),
                ],
              );
            }),
          ),
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: SocioTheme.rose.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.gpp_maybe_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                'FOUNDER S.O.S.',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Is everything crashing down? Under too much weight? Press this to put Socio in protective "SOS mode" immediately to prioritize stress decompression, action items mapping, and clear advice.',
            style: GoogleFonts.dmSans(color: const Color(0xFFFFE4E6), fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _triggerSOS,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF991B1B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                'TRIGGER S.O.S.',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
