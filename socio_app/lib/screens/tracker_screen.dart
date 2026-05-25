import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';

/// Socio Tracker Screen — refined premium dashboard.
/// Aesthetic: Warm editorial luxury. Premium metrics and VC checklist.
class TrackerScreen extends ConsumerStatefulWidget {
  const TrackerScreen({super.key});

  @override
  ConsumerState<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends ConsumerState<TrackerScreen> {
  // Mock startup metrics
  int userCount = 1200;
  int mrr = 15990; // Rs.15990
  String stage = 'Pre-Seed';

  // Checklist items
  final List<Map<String, dynamic>> _todoItems = [
    {'task': 'Follow up with Apex Ventures re: demo', 'done': false},
    {'task': 'Set up Firestore Security Rules in Console', 'done': true},
    {'task': 'Deploy FastAPI backend to Render', 'done': true},
    {'task': 'Draft cold outreach sequence for 20 leads', 'done': false},
    {'task': 'Complete daily wellness standup check-in', 'done': false},
  ];

  void _showMetricsEditDialog() {
    final userController = TextEditingController(text: userCount.toString());
    final mrrController = TextEditingController(text: mrr.toString());
    String selectedStage = stage;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: SocioTheme.creamBg,
          shape: const RoundedRectangleBorder(borderRadius: SocioTheme.radiusMd),
          title: Text(
            'Update Startup Metrics',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: SocioTheme.slateText,
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: userController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.dmSans(color: SocioTheme.slateText),
                decoration: const InputDecoration(labelText: 'Total Active Users'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: mrrController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.dmSans(color: SocioTheme.slateText),
                decoration: const InputDecoration(labelText: 'Monthly Recurring Revenue (Rs.)'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedStage,
                dropdownColor: SocioTheme.creamBg,
                style: GoogleFonts.dmSans(color: SocioTheme.slateText),
                items: ['Idea', 'MVP', 'Pre-Seed', 'Seed', 'Series A']
                    .map((val) => DropdownMenuItem(
                          value: val,
                          child: Text(val, style: GoogleFonts.dmSans(color: SocioTheme.slateText)),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) selectedStage = val;
                },
                decoration: const InputDecoration(labelText: 'Startup Stage'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.dmSans(color: SocioTheme.mutedText, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  userCount = int.tryParse(userController.text) ?? userCount;
                  mrr = int.tryParse(mrrController.text) ?? mrr;
                  stage = selectedStage;
                });
                Navigator.pop(context);
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Metrics updated! Socio AI is calibrating... 📊'),
                    backgroundColor: SocioTheme.forestGreen,
                  ),
                );
              },
              child: const Text('Update'),
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
          'Startup Metrics & Tasks',
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
            // Metrics Panel Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Core Dashboard',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: SocioTheme.slateText,
                  ),
                ),
                TextButton.icon(
                  onPressed: _showMetricsEditDialog,
                  icon: const Icon(Icons.edit_rounded, size: 14, color: SocioTheme.forestGreen),
                  label: Text(
                    'Edit Metrics',
                    style: GoogleFonts.dmSans(
                      color: SocioTheme.forestGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Metrics Cards Row
            Row(
              children: [
                _buildMetricCard(
                  'Total Users',
                  userCount.toString(),
                  Icons.people_outline_rounded,
                  SocioTheme.forestGreen,
                ),
                const SizedBox(width: 12),
                _buildMetricCard(
                  'MRR',
                  'Rs.$mrr',
                  Icons.payments_outlined,
                  SocioTheme.violet,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStageCard(),
            
            const SizedBox(height: 24),
            // Tasks Title
            Text(
              'Co-Founder TODO List',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: SocioTheme.slateText,
              ),
            ),
            const SizedBox(height: 12),

            // Todo List items
            Container(
              decoration: socioCardDecoration(),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _todoItems.length,
                separatorBuilder: (context, index) => const Divider(height: 1, color: SocioTheme.creamBorder),
                itemBuilder: (context, index) {
                  final item = _todoItems[index];
                  return CheckboxListTile(
                    value: item['done'],
                    activeColor: SocioTheme.forestGreen,
                    checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    title: Text(
                      item['task'],
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: item['done'] ? SocioTheme.placeholderText : SocioTheme.slateText,
                        decoration: item['done'] ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        item['done'] = val;
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 80), // bottom safe padding for floating navbar
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color themeColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: socioCardDecoration(elevated: true),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: themeColor, size: 18),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: SocioTheme.mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: SocioTheme.slateText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStageCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: socioCardDecoration(),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: SocioTheme.forestGreen.withOpacity(0.08),
              borderRadius: SocioTheme.radiusSm,
            ),
            child: const Icon(Icons.rocket_rounded, color: SocioTheme.forestGreen, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Stage',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: SocioTheme.mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                stage,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: SocioTheme.slateText,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: SocioTheme.violetSurface,
              borderRadius: SocioTheme.radiusFull,
              border: Border.all(color: SocioTheme.violet.withOpacity(0.2)),
            ),
            child: Text(
              'Calibrated Engine',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: SocioTheme.violet,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
