import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // ── Design Tokens (Pi AI Cream/Green Aesthetic) ──────────────────────────
  static const _green = Color(0xFF0B3A22); // Deep Forest Green primary
  static const _sageLight = Color(0xFFE5EFE9); // Light Sage
  static const _sageMedium = Color(0xFF4F8F6F); // Medium Sage
  static const _cream = Color(0xFFF7F4EB); // Warm Cream bg
  static const _textPrimary = Color(0xFF15291C); // Dark charcoal/green
  static const _textSecondary = Color(0xFF5E7063); // Muted Sage
  static const _border = Color(0xFFEBE5D8); // Warm beige borders
  static const _white = Color(0xFFFFFFFF);

  final List<SignInOnboardingItem> _items = [
    SignInOnboardingItem(
      title: 'Your AI Co-Founder',
      subtitle: 'Every founder deserves a partner. Meet Socio, your persistent AI co-founder that helps you brainstorm, build, and scale.',
      icon: Icons.rocket_launch_rounded,
      gradientStart: const Color(0xFF0B3A22),
      gradientEnd: const Color(0xFF4F8F6F),
    ),
    SignInOnboardingItem(
      title: 'Adaptive Persona Engine',
      subtitle: 'No complex prompts or mode switching. Socio reads your vibe and dynamically blends Skeptic, Hustler, and Strategist modes.',
      icon: Icons.psychology_rounded,
      gradientStart: const Color(0xFF15291C),
      gradientEnd: const Color(0xFF5E7063),
    ),
    SignInOnboardingItem(
      title: 'Outreach & Funding Pipeline',
      subtitle: 'Draft investor follow-ups, research targets, write hyper-personalized cold emails, and stress-test your startup ideas.',
      icon: Icons.monetization_on_rounded,
      gradientStart: const Color(0xFF0B3A22),
      gradientEnd: const Color(0xFF5E7063),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final signInState = ref.watch(signInNotifierProvider);
    final isLoading = signInState is AsyncLoading;

    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'S',
                          style: TextStyle(
                            color: _cream,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Socio',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                        ),
                      ),
                    ],
                  ),
                  // Bypass Button for Easy Testing
                  if (_currentPage < _items.length - 1)
                    TextButton(
                      onPressed: () {
                        _pageController.animateToPage(
                          _items.length - 1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: _textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),

              // Page View
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Decorative Icon with Gradient Background
                        Container(
                          height: 160,
                          width: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [item.gradientStart, item.gradientEnd],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: item.gradientStart.withOpacity(0.2),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            item.icon,
                            size: 72,
                            color: _cream,
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Title
                        Text(
                          item.title,
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: _textPrimary,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),

                        // Subtitle
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            item.subtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: _textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Bottom Area
              Column(
                children: [
                  // Page Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _items.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? _green
                              : _border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: CircularProgressIndicator(
                        color: _green,
                      ),
                    )
                  else if (_currentPage == _items.length - 1)
                    // final Step Options
                    Column(
                      children: [
                        // Google Sign-In
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final success = await ref
                                  .read(signInNotifierProvider.notifier)
                                  .signInWithGoogle();
                              if (!mounted) return;
                              if (!success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Google Sign-In failed or cancelled.'),
                                    backgroundColor: Color(0xFFDC2626),
                                  ),
                                );
                              }
                            },
                            icon: Image.network(
                              'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                              height: 24,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.login, color: _green),
                            ),
                            label: Text(
                              'Sign In with Google',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _textPrimary,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _white,
                              foregroundColor: _textPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(
                                  color: _border,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Dev/Anonymous Sign-In
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: TextButton(
                            onPressed: () async {
                              final success = await ref
                                  .read(signInNotifierProvider.notifier)
                                  .signInAnonymously();
                              if (!mounted) return;
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Logged in with Dev Account! 🎉'),
                                    backgroundColor: Color(0xFF059669),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Dev Login failed. Make sure Anonymous Auth is enabled.'),
                                    backgroundColor: Color(0xFFDC2626),
                                  ),
                                );
                              }
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: _green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Continue with Dev Account (Bypass)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    // Next Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: _cream,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Get Started',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignInOnboardingItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color gradientStart;
  final Color gradientEnd;

  SignInOnboardingItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientStart,
    required this.gradientEnd,
  });
}

