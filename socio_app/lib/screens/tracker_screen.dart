import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../models/startup_model.dart';
import '../providers/startup_provider.dart';
import '../providers/auth_provider.dart';
import '../navigation/main_navigation.dart';
import '../services/standup_service.dart';
import 'competitor_radar_screen.dart';

/// Socio Tracker Screen — refined premium dashboard.
/// Aesthetic: Warm editorial luxury. Premium metrics and VC checklist.
class TrackerScreen extends ConsumerStatefulWidget {
  const TrackerScreen({super.key});

  @override
  ConsumerState<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends ConsumerState<TrackerScreen> {
  // Checklist items
  final List<Map<String, dynamic>> _todoItems = [
    {'task': 'Follow up with Apex Ventures re: demo', 'done': false},
    {'task': 'Set up Firestore Security Rules in Console', 'done': true},
    {'task': 'Deploy FastAPI backend to Render', 'done': true},
    {'task': 'Draft cold outreach sequence for 20 leads', 'done': false},
    {'task': 'Complete daily wellness standup check-in', 'done': false},
  ];

  void _showMetricsEditDialog(StartupModel startup) {
    final nameController = TextEditingController(text: startup.name);
    final ideaController = TextEditingController(text: startup.idea);
    final userController = TextEditingController(text: startup.userCount);
    final mrrController = TextEditingController(text: startup.mrr);
    final customPersonaController = TextEditingController(text: startup.customPersona);
    String selectedStage = startup.stage;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: SocioTheme.creamBg,
          shape: const RoundedRectangleBorder(borderRadius: SocioTheme.radiusMd),
          title: Text(
            'Update Startup Profile',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: SocioTheme.slateText,
              fontSize: 18,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: GoogleFonts.dmSans(color: SocioTheme.slateText),
                  decoration: const InputDecoration(labelText: 'Startup Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ideaController,
                  maxLines: 2,
                  style: GoogleFonts.dmSans(color: SocioTheme.slateText),
                  decoration: const InputDecoration(labelText: 'Startup Description (Idea)'),
                ),
                const SizedBox(height: 12),
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
                  value: ['Idea stage', 'Building MVP', 'Pre-launch', 'Live & growing', 'Raising funds'].contains(selectedStage) 
                      ? selectedStage 
                      : 'Idea stage',
                  dropdownColor: SocioTheme.creamBg,
                  style: GoogleFonts.dmSans(color: SocioTheme.slateText),
                  items: ['Idea stage', 'Building MVP', 'Pre-launch', 'Live & growing', 'Raising funds']
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
                const SizedBox(height: 12),
                TextField(
                  controller: customPersonaController,
                  maxLines: 3,
                  style: GoogleFonts.dmSans(color: SocioTheme.slateText),
                  decoration: const InputDecoration(
                    labelText: 'Custom Co-Founder Persona',
                    hintText: 'e.g. Ex-Stripe CTO, direct, extremely technical...',
                  ),
                ),
              ],
            ),
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
              onPressed: () async {
                final updated = startup.copyWith(
                  name: nameController.text.trim(),
                  idea: ideaController.text.trim(),
                  userCount: userController.text.trim().isEmpty ? '0' : userController.text.trim(),
                  mrr: mrrController.text.trim().isEmpty ? '0' : mrrController.text.trim(),
                  stage: selectedStage,
                  customPersona: customPersonaController.text.trim(),
                );
                await ref.read(startupNotifierProvider.notifier).save(updated);
                if (mounted) {
                  Navigator.pop(context);
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile and Custom Persona updated!'),
                      backgroundColor: SocioTheme.forestGreen,
                    ),
                  );
                }
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
    final startupAsync = ref.watch(startupNotifierProvider);
    final startup = startupAsync.value ?? StartupModel.empty();

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
                  onPressed: () => _showMetricsEditDialog(startup),
                  icon: const Icon(Icons.edit_rounded, size: 14, color: SocioTheme.forestGreen),
                  label: Text(
                    'Edit Profile',
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
                  startup.userCount,
                  Icons.people_outline_rounded,
                  SocioTheme.forestGreen,
                ),
                const SizedBox(width: 12),
                _buildMetricCard(
                  'MRR',
                  'Rs.${startup.mrr}',
                  Icons.payments_outlined,
                  SocioTheme.violet,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStageCard(startup.stage),
            
            const SizedBox(height: 24),
            // Competitor Radar Card
            _buildRadarCard(),
            
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
            const SizedBox(height: 24),
            _buildStandupCard(),
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

  Widget _buildStageCard(String currentStage) {
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
                currentStage,
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

  Widget _buildRadarCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: socioCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: SocioTheme.forestGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.radar_rounded, color: SocioTheme.forestGreen, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Competitor Radar',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: SocioTheme.slateText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Scan real-time market intelligence',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: SocioTheme.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Keep an eye on who is building in your space. Socio researches the latest updates and products using Tavily search API.',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: SocioTheme.slateText.withOpacity(0.85),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CompetitorRadarScreen()),
                );
              },
              icon: const Icon(Icons.radar_rounded, size: 16),
              label: const Text('Open Competitor Radar'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandupCard() {
    final founderName = ref.watch(founderNameProvider);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: socioCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.notifications_active_outlined,
                    color: Color(0xFFD97706), size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Standup Prompt',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: SocioTheme.slateText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '9:00 AM morning + 9:00 PM evening',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: SocioTheme.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Morning prompt preview
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: SocioTheme.creamBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SocioTheme.creamBorder.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Morning',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFD97706),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '"$founderName, what is the single biggest blocker keeping you from growing today?"',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: SocioTheme.slateText.withOpacity(0.85),
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Evening prompt preview
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: SocioTheme.creamBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SocioTheme.creamBorder.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Evening',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: SocioTheme.violet,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '"What got done? What got blocked? Socio is ready to debrief."',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: SocioTheme.slateText.withOpacity(0.85),
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // CHANGE: Reply button now actually switches to Chat tab
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                // Switch to Chat tab (index 0)
                MainNavigation.tabNotifier.value = 0;
              },
              child: const Text('Reply to Standup'),
            ),
          ),
          const SizedBox(height: 8),
          // CHANGE: Test button fires a real notification immediately (for demo)
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton.icon(
              onPressed: () async {
                HapticFeedback.lightImpact();
                await StandupService().showTestMorningStandup();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Test notification sent — check your notification tray'),
                      backgroundColor: SocioTheme.forestGreen,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.notifications_outlined, size: 16),
              label: const Text('Send Test Notification'),
            ),
          ),
        ],
      ),
    );
  }
}