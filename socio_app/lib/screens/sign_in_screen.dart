import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../providers/auth_provider.dart';

/// Socio Sign In — warm editorial luxury aesthetic.
/// Full-screen forest green upper half, cream card bottom half. 
/// No gradient slop. Strong typography. One clear CTA.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic));
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final signInState = ref.watch(signInNotifierProvider);
    final isLoading = signInState is AsyncLoading || _isLoading;

    return Scaffold(
      backgroundColor: SocioTheme.forestGreen,
      body: Stack(
        children: [
          // ── Background noise texture (subtle depth) ─────────────────
          Positioned.fill(
            child: CustomPaint(painter: _NoisePatternPainter()),
          ),

          // ── Top hero section ────────────────────────────────────────
          FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 52,
                  left: 32,
                  right: 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo lockup
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: SocioTheme.radiusSm,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25), width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.hub_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'socio',
                          style: GoogleFonts.outfit(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Hero headline
                    Text(
                      'Every founder\ndeserves a\nco-founder.',
                      style: GoogleFonts.outfit(
                        fontSize: 42,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.05,
                        letterSpacing: -1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Now you have one.',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.65),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom card ─────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  28, 32, 28,
                  MediaQuery.of(context).padding.bottom + 32,
                ),
                decoration: const BoxDecoration(
                  color: SocioTheme.creamBg,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    Text(
                      'Sign in to continue',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: SocioTheme.slateText,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your startup context is saved and synced across sessions.',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: SocioTheme.mutedText,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Google Sign In button
                    _GoogleSignInButton(
                      isLoading: isLoading,
                      onTap: _handleGoogleSignIn,
                    ),

                    const SizedBox(height: 12),

                    // Offline mode
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _handleOfflineMode,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: SocioTheme.radiusMd,
                            side: const BorderSide(color: SocioTheme.creamBorder, width: 1.5),
                          ),
                        ),
                        child: Text(
                          'Continue with Dev Account (Bypass)',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: SocioTheme.forestGreen,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Trust signals
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _TrustBadge(Icons.lock_outline_rounded, 'Private'),
                        const SizedBox(width: 20),
                        _TrustBadge(Icons.cloud_off_outlined, 'No cold storage'),
                        const SizedBox(width: 20),
                        _TrustBadge(Icons.bolt_outlined, 'Sub-2s response'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
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
    } catch (e) {
      // error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleOfflineMode() async {
    setState(() => _isLoading = true);
    try {
      final success = await ref
          .read(signInNotifierProvider.notifier)
          .signInAnonymously();
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged in with Dev Account!'),
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
    } catch (e) {
      // error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// ── Sub-components ──────────────────────────────────────────────────────────

class _GoogleSignInButton extends StatefulWidget {
  const _GoogleSignInButton({required this.isLoading, required this.onTap});
  final bool isLoading;
  final VoidCallback onTap;

  @override
  State<_GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<_GoogleSignInButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: SocioTheme.forestGreen,
            borderRadius: SocioTheme.radiusMd,
            boxShadow: SocioTheme.shadowGreen,
          ),
          child: widget.isLoading
              ? const Center(
                  child: SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Google G icon
                    Container(
                      width: 22, height: 22,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          'G',
                          style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: Color(0xFF4285F4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Continue with Google',
                      style: GoogleFonts.outfit(
                        fontSize: 15, fontWeight: FontWeight.w600,
                        color: Colors.white, letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  const _TrustBadge(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: SocioTheme.mutedText),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11, color: SocioTheme.mutedText,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

/// Subtle dot-grid pattern painted on the green background for depth.
class _NoisePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.fill;

    const spacing = 24.0;
    const radius = 1.2;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height * 0.65; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
