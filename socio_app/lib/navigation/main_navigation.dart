import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/chat_screen.dart';
import '../screens/outreach_screen.dart';
import '../screens/pipeline_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/startup_provider.dart';
import '../models/startup_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MainNavigation — Bottom Navigation Shell + Custom Settings
// Design: Warm minimal, purple #6D28D9 primary, premium micro-animations
// ─────────────────────────────────────────────────────────────────────────────

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ChatScreen(),
    const OutreachScreen(),
    const PipelineScreen(),
    const _SettingsTab(),
  ];

  static const _primaryGreen = Color(0xFF0B3A22);
  static const _sageLight = Color(0xFFE5EFE9);
  static const _background = Color(0xFFF7F4EB);
  static const _textPrimary = Color(0xFF15291C);
  static const _textSecondary = Color(0xFF5E7063);
  static const _border = Color(0xFFEBE5D8);
  static const _white = Color(0xFFFFFFFF);


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _white,
          border: Border(
            top: BorderSide(color: _border.withOpacity(0.6), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: _textPrimary.withOpacity(0.03),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 'Chat'),
                _buildNavItem(1, Icons.send_outlined, Icons.send_rounded, 'Outreach'),
                _buildNavItem(2, Icons.analytics_outlined, Icons.analytics_rounded, 'Pipeline'),
                _buildNavItem(3, Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData solidIcon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _currentIndex = index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _sageLight : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? solidIcon : outlineIcon,
              color: isSelected ? _primaryGreen : _textSecondary,
              size: 20,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _primaryGreen,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

}

// ── Custom Settings Screen ────────────────────────────────────────────────────

class _SettingsTab extends ConsumerStatefulWidget {
  const _SettingsTab();

  @override
  ConsumerState<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<_SettingsTab> {
  final _nameController = TextEditingController();
  final _ideaController = TextEditingController();
  final _mrrController = TextEditingController();
  final _userController = TextEditingController();
  String _selectedStage = '';
  bool _isSaving = false;

  static const _purple = Color(0xFF0B3A22); // Reused for deep forest green
  static const _purpleLight = Color(0xFFE5EFE9); // Reused for light sage
  static const _white = Color(0xFFFFFFFF);
  static const _textPrimary = Color(0xFF15291C);
  static const _textSecondary = Color(0xFF5E7063);
  static const _border = Color(0xFFEBE5D8);
  static const _background = Color(0xFFF7F4EB);


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final startup = ref.read(startupNotifierProvider).value;
      if (startup != null) {
        _nameController.text = startup.name;
        _ideaController.text = startup.idea;
        _mrrController.text = startup.mrr;
        _userController.text = startup.userCount;
        setState(() => _selectedStage = startup.stage);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ideaController.dispose();
    _mrrController.dispose();
    _userController.dispose();
    super.dispose();
  }

  Future<void> _saveContext() async {
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final current = ref.read(startupNotifierProvider).value;
      final updated = StartupModel(
        id: current?.id ?? '',
        name: _nameController.text.trim(),
        idea: _ideaController.text.trim(),
        stage: _selectedStage.isEmpty ? 'Idea stage' : _selectedStage,
        mrr: _mrrController.text.trim().isEmpty ? '0' : _mrrController.text.trim(),
        userCount: _userController.text.trim().isEmpty ? '0' : _userController.text.trim(),
        updatedAt: DateTime.now(),
      );

      await ref.read(startupNotifierProvider.notifier).save(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Startup context saved successfully!', style: GoogleFonts.dmSans(color: _white)),
            backgroundColor: _purple,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e', style: GoogleFonts.dmSans(color: _white)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final founderName = ref.watch(founderNameProvider);

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Startup Settings',
          style: GoogleFonts.fraunces(
            fontWeight: FontWeight.bold,
            color: _textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              ref.read(signInNotifierProvider.notifier).signOut();
            },
            icon: const Icon(Icons.logout_rounded, color: Colors.red),
            tooltip: 'Log out',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User greeting card
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B5E3A), _purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: _purple.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hey, $founderName 👋',
                    style: GoogleFonts.fraunces(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Keep your startup details fresh so Socio can generate highly accurate insights and responses.',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: _white.withOpacity(0.9),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Form Title
            Text(
              'Startup Profile',
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            _buildField(
              controller: _nameController,
              label: 'Startup Name',
              hint: 'e.g. Socio',
              icon: Icons.business_rounded,
            ),
            const SizedBox(height: 14),

            _buildField(
              controller: _ideaController,
              label: 'One-line Description',
              hint: 'What are you building?',
              icon: Icons.lightbulb_outline_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: 14),

            _buildStageDropdown(),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _mrrController,
                    label: 'MRR (\$)',

                    hint: 'e.g. 1500',
                    icon: Icons.attach_money_rounded,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildField(
                    controller: _userController,
                    label: 'User Count',
                    hint: 'e.g. 240',
                    icon: Icons.people_outline_rounded,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Save button
            GestureDetector(
              onTap: _isSaving ? null : _saveContext,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF164E30), _purple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _purple.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Save Startup Profile',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _white,
                            letterSpacing: 0.3,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.bold, color: _textSecondary),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            minLines: maxLines == 1 ? 1 : 2,
            keyboardType: keyboardType,
            style: GoogleFonts.dmSans(fontSize: 14, color: _textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.dmSans(fontSize: 14, color: _textSecondary.withOpacity(0.5)),
              prefixIcon: Icon(icon, size: 18, color: _purple),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStageDropdown() {
    final stages = [
      'Idea stage',
      'Building MVP',
      'Pre-launch',
      'Live & growing',
      'Raising funds',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Startup Stage',
          style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.bold, color: _textSecondary),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: stages.contains(_selectedStage) ? _selectedStage : 'Idea stage',
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down_rounded, color: _purple),
              style: GoogleFonts.dmSans(fontSize: 14, color: _textPrimary),
              onChanged: (val) {
                if (val != null) setState(() => _selectedStage = val);
              },
              items: stages.map((s) {
                return DropdownMenuItem(
                  value: s,
                  child: Text(s),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
