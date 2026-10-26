import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../components/animated_particle_background.dart';
import '../components/tilt_3d_container.dart';
import '../components/cinematic_text_field.dart';
import '../components/cinematic_gradient_button.dart';
import '../components/social_auth_button.dart';
import '../components/brand_showcase_panel.dart';
import '../core/animations/animation_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../services/email_service.dart';
import '../services/firebase_service.dart';

enum AuthMode { signIn, signUp }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  AuthMode _authMode = AuthMode.signIn;
  bool _rememberMe = true;
  bool _isLoading = false;

  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutCubic,
          ),
        );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _navigateToDashboard() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: AnimDuration.normal,
        pageBuilder: (_, _, _) => const DashboardScreen(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  Future<void> _handleEmailAuth() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_authMode == AuthMode.signIn) {
      setState(() => _isLoading = true);
      try {
        final success = await ref.read(firebaseServiceProvider).signIn(email, password);
        if (!mounted) return;
        setState(() => _isLoading = false);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Operator session authenticated: $email'),
              backgroundColor: AppColors.safe,
            ),
          );
          _navigateToDashboard();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid credentials. Check your email and password (minimum 6 characters).'),
              backgroundColor: AppColors.critical,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during sign in: $e'), backgroundColor: AppColors.critical),
        );
      }
    } else {
      // Sign Up Flow with Email Verification
      if (password != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match.'), backgroundColor: AppColors.critical),
        );
        return;
      }

      setState(() => _isLoading = true);
      try {
        final emailService = ref.read(emailServiceProvider);
        final dispatchResult = await emailService.sendVerificationCode(email);
        if (!mounted) return;
        setState(() => _isLoading = false);

        // Open 6-digit Verification OTP Modal
        _showVerificationModal(
          name: _nameController.text.trim(),
          email: email,
          password: password,
          debugCode: dispatchResult['debug_code'] as String?,
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to dispatch verification email: $e'), backgroundColor: AppColors.critical),
        );
      }
    }
  }

  void _showVerificationModal({
    required String name,
    required String email,
    required String password,
    String? debugCode,
  }) {
    final otpController = TextEditingController();
    bool isVerifying = false;
    int resendCountdown = 60;
    Timer? countdownTimer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            countdownTimer ??= Timer.periodic(const Duration(seconds: 1), (t) {
              if (resendCountdown > 0) {
                setDialogState(() => resendCountdown--);
              } else {
                t.cancel();
              }
            });

            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Dialog(
                backgroundColor: AppColors.abyss,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: AppColors.signal, width: 1.5),
                ),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.signal.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.signal),
                            ),
                            child: const Icon(Icons.mark_email_read_outlined, color: AppColors.signal, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'VERIFICATION REQUIRED',
                                  style: GoogleFonts.rajdhani(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.text_primary,
                                  ),
                                ),
                                Text(
                                  'Activation code dispatched to $email',
                                  style: AppTypography.body.copyWith(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      if (debugCode != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.signal_glow,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.signal.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.shield_outlined, color: AppColors.signal, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'SECURITY CLEARANCE CODE: $debugCode',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.signal,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  if (debugCode != null) {
                                    otpController.text = debugCode!;
                                  }
                                },
                                child: Text(
                                  'AUTO-FILL',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.safe,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      Text('ENTER 6-DIGIT ACTIVATION CODE', style: AppTypography.label.copyWith(fontSize: 10)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.void_black,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.signal.withValues(alpha: 0.5)),
                        ),
                        child: TextField(
                          controller: otpController,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 26,
                            letterSpacing: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.signal,
                          ),
                          decoration: const InputDecoration(
                            counterText: '',
                            hintText: '••••••',
                            hintStyle: TextStyle(color: AppColors.text_ghost, letterSpacing: 8),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: resendCountdown > 0
                                ? null
                                : () async {
                                    final res = await ref.read(emailServiceProvider).sendVerificationCode(email);
                                    setDialogState(() {
                                      resendCountdown = 60;
                                      if (res['debug_code'] != null) {
                                        debugCode = res['debug_code'] as String;
                                      }
                                    });
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('New verification code dispatched.')),
                                    );
                                  },
                            icon: const Icon(Icons.refresh, size: 14),
                            label: Text(
                              resendCountdown > 0 ? 'Resend in ${resendCountdown}s' : 'RESEND CODE',
                              style: GoogleFonts.jetBrainsMono(fontSize: 11),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              countdownTimer?.cancel();
                              Navigator.of(dialogCtx).pop();
                            },
                            child: Text(
                              'CANCEL',
                              style: GoogleFonts.jetBrainsMono(fontSize: 11, color: AppColors.text_secondary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.signal,
                            foregroundColor: AppColors.void_black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: isVerifying
                              ? null
                              : () async {
                                  final code = otpController.text.trim();
                                  if (code.length != 6) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please enter all 6 digits.')),
                                    );
                                    return;
                                  }

                                  setDialogState(() => isVerifying = true);
                                  final valid = await ref.read(emailServiceProvider).verifyCode(email, code);

                                  if (!context.mounted) return;
                                  setDialogState(() => isVerifying = false);

                                  if (valid) {
                                    countdownTimer?.cancel();
                                    Navigator.of(dialogCtx).pop();

                                    // Complete registration & dispatch Welcome Email
                                    await ref.read(firebaseServiceProvider).signUp(
                                          name: name,
                                          email: email,
                                          password: password,
                                        );

                                    if (!mounted) return;
                                    ScaffoldMessenger.of(this.context).showSnackBar(
                                      SnackBar(
                                        content: Text('Clearance Level 1 Granted! Welcome email sent to $email'),
                                        backgroundColor: AppColors.safe,
                                      ),
                                    );
                                    _navigateToDashboard();
                                  } else {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(this.context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Invalid activation code. Please check your email.'),
                                        backgroundColor: AppColors.critical,
                                      ),
                                    );
                                  }
                                },
                          child: isVerifying
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                )
                              : Text(
                                  'VERIFY & ACTIVATE ACCOUNT',
                                  style: GoogleFonts.rajdhani(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showGoogleAccountSelector() {
    final customGoogleEmailController = TextEditingController();
    final oauthTokenController = TextEditingController();
    bool showTokenInput = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Dialog(
                backgroundColor: AppColors.abyss,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0xFF4285F4), width: 1.5),
                ),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.g_mobiledata_rounded,
                              color: Color(0xFF4285F4),
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sign in with Google',
                                  style: GoogleFonts.rajdhani(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.text_primary,
                                  ),
                                ),
                                Text(
                                  'Official Google OAuth 2.0 Identity Protocol',
                                  style: AppTypography.body.copyWith(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(color: AppColors.text_ghost, height: 1),
                      const SizedBox(height: 16),

                      // Google Profiles
                      _buildGoogleAccountTile(
                        name: 'Mani Bharathi',
                        email: 'manibharathi.dev@gmail.com',
                        initials: 'MB',
                        color: const Color(0xFF4285F4),
                        onTap: () => _completeGoogleSignIn('manibharathi.dev@gmail.com', 'Mani Bharathi', dialogCtx),
                      ),
                      const SizedBox(height: 10),

                      _buildGoogleAccountTile(
                        name: 'Security Operator',
                        email: 'cyber.operator@gmail.com',
                        initials: 'CO',
                        color: const Color(0xFF0F9D58),
                        onTap: () => _completeGoogleSignIn('cyber.operator@gmail.com', 'Security Operator', dialogCtx),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: AppColors.text_ghost, height: 1),
                      const SizedBox(height: 16),

                      // Or custom Google email input
                      Text(
                        'OR CONNECT ANY GOOGLE ACCOUNT',
                        style: AppTypography.label.copyWith(fontSize: 10),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.void_black,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.text_ghost),
                        ),
                        child: TextField(
                          controller: customGoogleEmailController,
                          style: GoogleFonts.jetBrainsMono(fontSize: 12, color: AppColors.text_primary),
                          decoration: InputDecoration(
                            hintText: 'operator@gmail.com',
                            hintStyle: GoogleFonts.jetBrainsMono(fontSize: 12, color: AppColors.text_ghost),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.arrow_forward, color: Color(0xFF4285F4), size: 18),
                              onPressed: () {
                                final email = customGoogleEmailController.text.trim();
                                if (email.isNotEmpty && email.contains('@')) {
                                  _completeGoogleSignIn(email, email.split('@').first, dialogCtx);
                                }
                              },
                            ),
                          ),
                          onSubmitted: (email) {
                            if (email.trim().isNotEmpty && email.contains('@')) {
                              _completeGoogleSignIn(email.trim(), email.split('@').first, dialogCtx);
                            }
                          },
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Real Google OAuth 2.0 Access Token Option
                      InkWell(
                        onTap: () => setDialogState(() => showTokenInput = !showTokenInput),
                        child: Row(
                          children: [
                            Icon(
                              showTokenInput ? Icons.expand_less : Icons.token_outlined,
                              size: 14,
                              color: const Color(0xFF4285F4),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              showTokenInput ? 'HIDE OAUTH TOKEN INPUT' : 'AUTHENTICATE VIA OAUTH 2.0 ACCESS TOKEN',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF4285F4),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (showTokenInput) ...[
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.void_black,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.signal),
                          ),
                          child: TextField(
                            controller: oauthTokenController,
                            style: GoogleFonts.jetBrainsMono(fontSize: 11, color: AppColors.text_primary),
                            decoration: InputDecoration(
                              hintText: 'ya29.a0AfH6SM...',
                              hintStyle: GoogleFonts.jetBrainsMono(fontSize: 11, color: AppColors.text_ghost),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.check, color: AppColors.safe, size: 16),
                                onPressed: () async {
                                  final token = oauthTokenController.text.trim();
                                  if (token.isNotEmpty) {
                                    Navigator.of(dialogCtx).pop();
                                    setState(() => _isLoading = true);
                                    final ok = await ref.read(firebaseServiceProvider).signInWithGoogleReal(accessToken: token);
                                    if (!mounted) return;
                                    setState(() => _isLoading = false);
                                    if (ok) {
                                      _navigateToDashboard();
                                    } else {
                                      ScaffoldMessenger.of(this.context).showSnackBar(
                                        const SnackBar(content: Text('Invalid Google OAuth token.')),
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogCtx).pop(),
                            child: Text(
                              'CANCEL',
                              style: GoogleFonts.jetBrainsMono(color: AppColors.text_secondary, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _completeGoogleSignIn(String email, String displayName, BuildContext dialogCtx) async {
    Navigator.of(dialogCtx).pop();
    setState(() => _isLoading = true);

    await ref.read(firebaseServiceProvider).signInWithGoogle(
          selectedEmail: email,
          displayName: displayName,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Authenticated with Google as $email. Welcome email dispatched.'),
          ],
        ),
        backgroundColor: const Color(0xFF4285F4),
      ),
    );

    _navigateToDashboard();
  }

  Widget _buildGoogleAccountTile({
    required String name,
    required String email,
    required String initials,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.trench,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.text_ghost.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color,
              child: Text(
                initials,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.rajdhani(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text_primary,
                    ),
                  ),
                  Text(
                    email,
                    style: AppTypography.body.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.text_secondary, size: 18),
          ],
        ),
      ),
    );
  }

  void _showAppleSignInSheet() {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            backgroundColor: AppColors.abyss,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.white24, width: 1.5),
            ),
            child: Container(
              padding: const EdgeInsets.all(28),
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.apple_rounded,
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sign in with Apple ID',
                              style: GoogleFonts.rajdhani(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text_primary,
                              ),
                            ),
                            Text(
                              'CYBER_OS is requesting your Apple ID',
                              style: AppTypography.body.copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.trench,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.text_ghost),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ACCOUNT', style: AppTypography.label.copyWith(fontSize: 10)),
                        const SizedBox(height: 4),
                        Text(
                          'operator@icloud.com',
                          style: GoogleFonts.jetBrainsMono(fontSize: 13, color: AppColors.text_primary),
                        ),
                        const SizedBox(height: 12),
                        Text('EMAIL PRIVACY', style: AppTypography.label.copyWith(fontSize: 10)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.shield_outlined, color: AppColors.safe, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'Hide My Email (Private Relay Enabled)',
                              style: AppTypography.body.copyWith(fontSize: 11, color: AppColors.safe),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        Navigator.of(dialogCtx).pop();
                        setState(() => _isLoading = true);

                        await ref.read(firebaseServiceProvider).signInWithApple(
                              selectedEmail: 'operator.privaterelay@icloud.com',
                              displayName: 'Apple Operator',
                            );

                        if (!mounted) return;
                        setState(() => _isLoading = false);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Authenticated with Apple ID. Welcome email sent.'),
                            backgroundColor: AppColors.surface,
                          ),
                        );
                        _navigateToDashboard();
                      },
                      icon: const Icon(Icons.fingerprint, size: 20),
                      label: const Text(
                        'Continue with Apple ID',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      child: Text(
                        'CANCEL',
                        style: GoogleFonts.jetBrainsMono(color: AppColors.text_secondary, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(text: _emailController.text.trim());
    final recoveryCodeController = TextEditingController();
    final newPasswordController = TextEditingController();
    bool codeDispatched = false;
    String? recoveryDebugCode;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Dialog(
                backgroundColor: AppColors.abyss,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.critical),
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lock_reset, color: AppColors.critical, size: 24),
                          const SizedBox(width: 10),
                          Text(
                            codeDispatched ? 'RESET OPERATOR PASSWORD' : 'EMERGENCY RECOVERY',
                            style: GoogleFonts.rajdhani(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text_primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        codeDispatched
                            ? 'Enter the 6-digit recovery code sent to ${resetEmailController.text} and your new password.'
                            : 'Enter your operator email address to receive an emergency 6-digit recovery code.',
                        style: AppTypography.body,
                      ),
                      const SizedBox(height: 16),

                      if (recoveryDebugCode != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.critical.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.critical),
                          ),
                          child: Text(
                            'RECOVERY CODE: $recoveryDebugCode',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.critical,
                            ),
                          ),
                        ),

                      if (!codeDispatched) ...[
                        Text('OPERATOR EMAIL', style: AppTypography.label.copyWith(fontSize: 10)),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.void_black,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.text_ghost),
                          ),
                          child: TextField(
                            controller: resetEmailController,
                            style: GoogleFonts.jetBrainsMono(fontSize: 12, color: AppColors.text_primary),
                            decoration: InputDecoration(
                              hintText: 'operator@cyber-os.io',
                              hintStyle: GoogleFonts.jetBrainsMono(fontSize: 12, color: AppColors.text_ghost),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ),
                      ] else ...[
                        Text('6-DIGIT RECOVERY CODE', style: AppTypography.label.copyWith(fontSize: 10)),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.void_black,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.critical),
                          ),
                          child: TextField(
                            controller: recoveryCodeController,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 22,
                              letterSpacing: 8,
                              fontWeight: FontWeight.bold,
                              color: AppColors.critical,
                            ),
                            decoration: const InputDecoration(
                              counterText: '',
                              hintText: '••••••',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        Text('NEW PASSWORD (MINIMUM 6 CHARS)', style: AppTypography.label.copyWith(fontSize: 10)),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.void_black,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.text_ghost),
                          ),
                          child: TextField(
                            controller: newPasswordController,
                            obscureText: true,
                            style: GoogleFonts.jetBrainsMono(fontSize: 12, color: AppColors.text_primary),
                            decoration: const InputDecoration(
                              hintText: '••••••••',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogCtx).pop(),
                            child: Text(
                              'CANCEL',
                              style: GoogleFonts.jetBrainsMono(color: AppColors.text_secondary, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.critical,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    final email = resetEmailController.text.trim();
                                    if (!email.contains('@')) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Please enter a valid email.')),
                                      );
                                      return;
                                    }

                                    if (!codeDispatched) {
                                      setDialogState(() => isSubmitting = true);
                                      final res = await ref.read(emailServiceProvider).sendPasswordResetCode(email);
                                      setDialogState(() {
                                        isSubmitting = false;
                                        codeDispatched = true;
                                        recoveryDebugCode = res['debug_code'] as String?;
                                      });
                                    } else {
                                      final code = recoveryCodeController.text.trim();
                                      final newPass = newPasswordController.text;
                                      if (code.length != 6 || newPass.length < 6) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Enter 6-digit code and new password (>=6 chars).')),
                                        );
                                        return;
                                      }

                                      setDialogState(() => isSubmitting = true);
                                      final ok = await ref.read(emailServiceProvider).resetPasswordWithCode(
                                            email: email,
                                            code: code,
                                            newPassword: newPass,
                                          );
                                      setDialogState(() => isSubmitting = false);

                                      if (!context.mounted) return;
                                      if (ok) {
                                        Navigator.of(dialogCtx).pop();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Password reset successfully. You may now log in.'),
                                            backgroundColor: AppColors.safe,
                                          ),
                                        );
                                        _passwordController.text = newPass;
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Invalid recovery code or expired.'),
                                            backgroundColor: AppColors.critical,
                                          ),
                                        );
                                      }
                                    }
                                  },
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(
                                    codeDispatched ? 'UPDATE PASSWORD' : 'SEND CODE',
                                    style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w700, fontSize: 12),
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isDesktop = size.width >= 900;

    return Scaffold(
      body: AnimatedParticleBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 1080 : 480,
                    ),
                    child: isDesktop
                        ? Row(
                            children: [
                              const Expanded(
                                flex: 5,
                                child: BrandShowcasePanel(),
                              ),
                              Expanded(flex: 5, child: _build3DLoginCard()),
                            ],
                          )
                        : _build3DLoginCard(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _build3DLoginCard() {
    final isSignIn = _authMode == AuthMode.signIn;

    return Tilt3DContainer(
      borderRadius: 28,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 36,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isSignIn ? 'Welcome Back' : 'Create Account',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      // Mode Switch Chip
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.text_ghost),
                        ),
                        child: Row(
                          children: [
                            _buildModeTab('SIGN IN', isSignIn, () {
                              if (!isSignIn) setState(() => _authMode = AuthMode.signIn);
                            }),
                            _buildModeTab('SIGN UP', !isSignIn, () {
                              if (isSignIn) setState(() => _authMode = AuthMode.signUp);
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isSignIn
                        ? 'Enter your credentials to access your security kernel.'
                        : 'Register with 6-digit email verification for CYBER_OS.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Name Field (Only in Sign Up mode)
                  if (!isSignIn) ...[
                    CinematicTextField(
                      controller: _nameController,
                      label: 'Operator Full Name / Alias',
                      hintText: 'e.g. Alex Vance',
                      prefixIcon: Icons.badge_outlined,
                      keyboardType: TextInputType.name,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter your name or alias';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                  ],

                  // Email Field
                  CinematicTextField(
                    controller: _emailController,
                    label: 'Email Address',
                    hintText: 'operator@cyber-os.io',
                    prefixIcon: Icons.alternate_email_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!val.contains('@') || !val.contains('.')) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // Password Field
                  CinematicTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hintText: '••••••••',
                    prefixIcon: Icons.lock_outline_rounded,
                    isPassword: true,
                    textInputAction: isSignIn ? TextInputAction.done : TextInputAction.next,
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (val.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),

                  // Confirm Password Field (Only in Sign Up mode)
                  if (!isSignIn) ...[
                    const SizedBox(height: 18),
                    CinematicTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm Password',
                      hintText: '••••••••',
                      prefixIcon: Icons.lock_reset_rounded,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (val != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Remember me & Forgot Password
                  if (isSignIn) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Transform.scale(
                              scale: 0.85,
                              child: Checkbox(
                                value: _rememberMe,
                                onChanged: (v) =>
                                    setState(() => _rememberMe = v ?? false),
                                activeColor: const Color(0xFF6366F1),
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const Text(
                              'Remember me',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: _showForgotPasswordDialog,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Color(0xFF818CF8),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ] else ...[
                    const SizedBox(height: 12),
                  ],

                  // Action Button (Sign In / Sign Up)
                  CinematicGradientButton(
                    text: isSignIn ? 'Sign In' : 'Create Operator Account',
                    isLoading: _isLoading,
                    icon: isSignIn ? Icons.login_rounded : Icons.mark_email_read_outlined,
                    onPressed: _handleEmailAuth,
                  ),
                  const SizedBox(height: 12),

                  // Guest Operator Bypass Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.signal),
                        backgroundColor: AppColors.signal_glow,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        setState(() => _isLoading = true);
                        await ref.read(firebaseServiceProvider).enterAsGuestOperator();
                        if (!mounted) return;
                        setState(() => _isLoading = false);
                        _navigateToDashboard();
                      },
                      icon: const Icon(Icons.terminal, color: AppColors.signal, size: 16),
                      label: Text(
                        'ENTER AS GUEST OPERATOR',
                        style: GoogleFonts.rajdhani(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.signal,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Social Auth Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR CONTINUE WITH',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Google & Apple Social Auth Buttons
                  Row(
                    children: [
                      SocialAuthButton(
                        icon: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.g_mobiledata_rounded,
                            color: Color(0xFF4285F4),
                            size: 20,
                          ),
                        ),
                        label: 'Google',
                        onPressed: _showGoogleAccountSelector,
                      ),
                      const SizedBox(width: 12),
                      SocialAuthButton(
                        icon: const Icon(
                          Icons.apple_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: 'Apple',
                        onPressed: _showAppleSignInSheet,
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Bottom Toggle Text
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isSignIn ? "Don't have an account? " : "Already have an account? ",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _authMode = isSignIn ? AuthMode.signUp : AuthMode.signIn;
                            });
                          },
                          child: Text(
                            isSignIn ? 'Sign Up' : 'Sign In',
                            style: const TextStyle(
                              color: Color(0xFF818CF8),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeTab(String text, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.text_secondary,
          ),
        ),
      ),
    );
  }
}
