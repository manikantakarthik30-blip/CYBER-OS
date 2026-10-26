import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/animations/animation_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glitch_text.dart';
import '../../core/widgets/pulse_ring.dart';
import '../../screens/login_screen.dart';
import '../../services/firebase_service.dart';
import '../dashboard/dashboard_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _linesController;

  final List<String> _bootLogs = [];
  bool _showLogo = false;
  bool _showLines = false;
  bool _showPulse = false;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: AnimDuration.normal,
    );

    _linesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _startBootSequence();
  }

  void _startBootSequence() {
    _fadeController.forward();

    // t=300ms: Show logo
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _showLogo = true);
    });

    // t=600ms: Show lines
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _showLines = true);
        _linesController.forward();
      }
    });

    // t=1000ms: Start pulse
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _showPulse = true);
    });

    // t=1200ms: Boot logs
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() => _bootLogs.add('> Initializing security kernel...'));
      }
    });
    Future.delayed(const Duration(milliseconds: 1450), () {
      if (mounted) {
        setState(() => _bootLogs.add('> Loading threat patterns & CVE index...'));
      }
    });
    Future.delayed(const Duration(milliseconds: 1700), () {
      if (mounted) {
        setState(() => _bootLogs.add('> System initialized. Security Layer ONLINE.'));
      }
    });

    // t=2500ms: Navigate based on operator authentication
    _navTimer = Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      final isAuthenticated = ref.read(authStateProvider);
      final targetScreen = isAuthenticated ? const DashboardScreen() : const LoginScreen();

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: AnimDuration.normal,
          pageBuilder: (_, _, _) => targetScreen,
          transitionsBuilder: (_, animation, _, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: AnimCurve.enter)),
                child: child,
              ),
            );
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _linesController.dispose();
    _navTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.void_black,
      body: Center(
        child: FadeTransition(
          opacity: _fadeController,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pulse Ring & Logo Icon
              PulseRing(
                size: 84,
                color: AppColors.signal,
                isPulsing: _showPulse,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.abyss,
                    border: Border.all(color: AppColors.signal, width: 2),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.signal.withOpacity(0.3),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.shield,
                    size: 32,
                    color: AppColors.signal,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Glitch Logo Text
              if (_showLogo) ...[
                GlitchText(
                  text: 'CYBER_OS',
                  style: GoogleFonts.rajdhani(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4.0,
                    color: AppColors.text_primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'AI-POWERED SECURITY LAYER v1.0',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.5,
                    color: AppColors.signal,
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Expanding Center Line
              if (_showLines)
                AnimatedBuilder(
                  animation: _linesController,
                  builder: (context, child) {
                    return Container(
                      width: 280 * _linesController.value,
                      height: 1,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppColors.signal,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 28),

              // Boot Logs Stream
              SizedBox(
                height: 70,
                child: Column(
                  children: _bootLogs.map((log) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        log,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: AppColors.text_secondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
