import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/animations/animation_constants.dart';
import '../../core/reporting/report_generator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/cyber_card.dart';
import '../../core/widgets/glitch_text.dart';
import '../../core/widgets/nav_rail_shell.dart';
import '../../core/widgets/scan_line_overlay.dart';
import '../../core/widgets/severity_badge.dart';
import '../../core/widgets/terminal_log.dart';
import 'scan_controller.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> with TickerProviderStateMixin {
  final TextEditingController _urlController = TextEditingController(text: 'https://github.com/flutter/samples');
  final FocusNode _focusNode = FocusNode();

  late AnimationController _ring1Controller;
  late AnimationController _ring2Controller;

  @override
  void initState() {
    super.initState();
    _ring1Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _ring2Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _focusNode.dispose();
    _ring1Controller.dispose();
    _ring2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.void_black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Screen Header
            GlitchText(
              text: 'SECURITY SCAN CENTER',
              style: AppTypography.headline,
            ),
            const SizedBox(height: 4),
            Text(
              'AUDIT VIBE-CODED APPS & AI CODEBASES FOR ZERO-DAY EXPLOITS',
              style: AppTypography.label,
            ),
            const SizedBox(height: 32),

            // Switch view depending on state
            AnimatedSwitcher(
              duration: AnimDuration.normal,
              child: _buildCurrentStateView(scanState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStateView(ScanState state) {
    switch (state.status) {
      case ScanStateStatus.idle:
        return _buildPreScanView();
      case ScanStateStatus.scanning:
        return _buildActiveScanView(state);
      case ScanStateStatus.complete:
        return _buildScanCompleteView(state);
      case ScanStateStatus.error:
        return _buildErrorView(state);
    }
  }

  Widget _buildPreScanView() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: CyberCard(
          accentColor: AppColors.signal,
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.radar, color: AppColors.signal, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'SPECIFY SCAN TARGET',
                    style: GoogleFonts.rajdhani(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: AppColors.text_primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Enter a public or private GitHub repository URL, or upload local project directory files.',
                style: AppTypography.body,
              ),
              const SizedBox(height: 28),

              // Mode 1: GitHub URL Input
              Text('GITHUB REPOSITORY URL', style: AppTypography.label),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.void_black,
                  border: Border.all(
                    color: _focusNode.hasFocus ? AppColors.signal : AppColors.text_ghost,
                    width: 1.2,
                  ),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: _focusNode.hasFocus
                      ? [
                          BoxShadow(
                            color: AppColors.signal.withOpacity(0.25),
                            blurRadius: 10,
                          ),
                        ]
                      : [],
                ),
                child: TextField(
                  controller: _urlController,
                  focusNode: _focusNode,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    color: AppColors.text_primary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'https://github.com/username/repo',
                    hintStyle: GoogleFonts.jetBrainsMono(
                      fontSize: 13,
                      color: AppColors.text_ghost,
                    ),
                    prefixIcon: const Icon(Icons.link, color: AppColors.signal, size: 18),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Mode 2: Upload Files Button
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.text_ghost)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR', style: AppTypography.label),
                  ),
                  const Expanded(child: Divider(color: AppColors.text_ghost)),
                ],
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.text_secondary),
                    backgroundColor: AppColors.trench,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    ref.read(scanControllerProvider.notifier).pickAndScanFiles();
                  },
                  icon: const Icon(Icons.folder_zip_outlined, color: AppColors.text_primary, size: 20),
                  label: Text(
                    'UPLOAD PROJECT (ZIP OR FILES)',
                    style: GoogleFonts.rajdhani(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.0,
                      color: AppColors.text_primary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Primary Initiate Scan Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.signal_dim,
                    side: const BorderSide(color: AppColors.signal, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 0,
                  ),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    ref.read(scanControllerProvider.notifier).scanGitHubRepo(_urlController.text);
                  },
                  icon: const Icon(Icons.flash_on, color: AppColors.signal, size: 22),
                  label: Text(
                    'INITIATE SECURITY SCAN',
                    style: GoogleFonts.rajdhani(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3.0,
                      color: AppColors.signal,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveScanView(ScanState state) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ScanLineOverlay(
          isScanning: true,
          child: CyberCard(
            accentColor: AppColors.signal,
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Text(
                  'SCAN IN PROGRESS',
                  style: GoogleFonts.rajdhani(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3.0,
                    color: AppColors.signal,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  state.currentAction,
                  style: AppTypography.code,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                // Multi-Ring Rotating Radar Animation
                SizedBox(
                  width: 170,
                  height: 170,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer Rotating Ring
                      RotationTransition(
                        turns: _ring1Controller,
                        child: CustomPaint(
                          size: const Size(160, 160),
                          painter: _OuterRingPainter(color: AppColors.signal),
                        ),
                      ),
                      // Middle Counter-Rotating Ring
                      RotationTransition(
                        turns: _ring2Controller,
                        child: CustomPaint(
                          size: const Size(125, 125),
                          painter: _OuterRingPainter(color: AppColors.text_ghost, strokeWidth: 1.0),
                        ),
                      ),
                      // Inner Progress Arc
                      CustomPaint(
                        size: const Size(95, 95),
                        painter: _ProgressArcPainter(
                          progress: state.progress,
                          color: AppColors.safe,
                        ),
                        child: Center(
                          child: Icon(
                            _getModuleIcon(state.currentModule),
                            color: AppColors.signal,
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                Text(
                  'MODULE: ${state.currentModule.toUpperCase()}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    color: AppColors.text_primary,
                  ),
                ),

                const SizedBox(height: 24),

                // 2px Sharp Progress Bar with Cursor Dot
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final fillWidth = (width * state.progress).clamp(0.0, width);

                    return Column(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: width,
                              height: 3,
                              color: AppColors.text_ghost.withOpacity(0.3),
                            ),
                            Container(
                              width: fillWidth,
                              height: 3,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.signal, AppColors.safe],
                                ),
                              ),
                            ),
                            Positioned(
                              left: fillWidth - 3,
                              top: -2.5,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.signal,
                                      blurRadius: 6,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('SCAN COMPLETION', style: AppTypography.label),
                            Text(
                              '${(state.progress * 100).toInt()}%',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.signal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Live Terminal Log Stream
                TerminalLogWidget(rawLogs: state.logs, height: 160),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanCompleteView(ScanState state) {
    final result = state.result!;
    final score = result.securityScore;
    final isSafe = result.deployStatus == 'SAFE_TO_DEPLOY';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: CyberCard(
          accentColor: isSafe ? AppColors.safe : AppColors.critical,
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                isSafe ? Icons.verified_user : Icons.warning_amber_rounded,
                color: isSafe ? AppColors.safe : AppColors.critical,
                size: 48,
              ),
              const SizedBox(height: 16),
              GlitchText(
                text: 'AUDIT COMPLETE — SCORE $score/100',
                style: GoogleFonts.rajdhani(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text_primary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'TARGET: ${result.projectName}',
                style: AppTypography.code,
              ),
              const SizedBox(height: 16),
              SeverityBadge(
                severity: isSafe ? 'SAFE_TO_DEPLOY' : 'NOT_SAFE_FOR_PRODUCTION',
                fontSize: 12,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              ),
              const SizedBox(height: 28),

              // Metrics Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMetricPill('VULNERABILITIES', result.vulnerabilities.length.toString(),
                      result.vulnerabilities.isEmpty ? AppColors.safe : AppColors.critical),
                  _buildMetricPill('CRITICALS', result.criticalCount.toString(),
                      result.criticalCount == 0 ? AppColors.safe : AppColors.critical),
                  _buildMetricPill('SECRETS', result.secretsDetected ? 'FOUND' : 'CLEAN',
                      result.secretsDetected ? AppColors.critical : AppColors.safe),
                  _buildMetricPill('MCP STATUS', result.mcpSecure ? 'PASS' : 'FAIL',
                      result.mcpSecure ? AppColors.safe : AppColors.critical),
                ],
              ),

              const SizedBox(height: 28),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.signal_dim,
                        side: const BorderSide(color: AppColors.signal),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        ref.read(selectedNavIndexProvider.notifier).state = 2; // Vulnerabilities tab
                      },
                      icon: const Icon(Icons.list_alt, color: AppColors.signal, size: 18),
                      label: Text(
                        'INSPECT VULNERABILITIES',
                        style: GoogleFonts.rajdhani(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: AppColors.signal,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.text_ghost),
                      backgroundColor: AppColors.trench,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    ),
                    onPressed: () {
                      final jsonStr = ReportGenerator.exportAsJson(result);
                      Clipboard.setData(ClipboardData(text: jsonStr));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Report copied to clipboard as JSON format'),
                          backgroundColor: AppColors.surface,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, color: AppColors.text_primary, size: 18),
                    label: Text(
                      'EXPORT JSON',
                      style: GoogleFonts.rajdhani(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                        color: AppColors.text_primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  IconButton(
                    tooltip: 'New Scan',
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.void_black,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: AppColors.text_ghost),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    onPressed: () => ref.read(scanControllerProvider.notifier).reset(),
                    icon: const Icon(Icons.refresh, color: AppColors.signal),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(ScanState state) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: CyberCard(
          accentColor: AppColors.critical,
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.critical, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'SCAN ERROR OCCURRED',
                    style: GoogleFonts.rajdhani(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.critical,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                state.errorMessage ?? 'An unexpected network or file parsing error occurred.',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  color: AppColors.text_primary,
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.signal),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: () => ref.read(scanControllerProvider.notifier).reset(),
                icon: const Icon(Icons.arrow_back, color: AppColors.signal, size: 16),
                label: Text(
                  'RETURN TO SCAN CENTER',
                  style: GoogleFonts.rajdhani(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: AppColors.signal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.void_black,
        border: Border.all(color: AppColors.text_ghost),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.rajdhani(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              letterSpacing: 1.0,
              color: AppColors.text_secondary,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getModuleIcon(String module) {
    final lower = module.toLowerCase();
    if (lower.contains('secret')) return Icons.key_outlined;
    if (lower.contains('mcp')) return Icons.hub_outlined;
    if (lower.contains('depend')) return Icons.inventory_2_outlined;
    if (lower.contains('api')) return Icons.lan_outlined;
    if (lower.contains('firewall') || lower.contains('prompt')) return Icons.psychology_outlined;
    return Icons.shield_outlined;
  }
}

class _OuterRingPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _OuterRingPainter({required this.color, this.strokeWidth = 2.0});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // Draw dashed 3-segment ring
    const segments = 4;
    for (int i = 0; i < segments; i++) {
      final startAngle = i * (2 * pi / segments);
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, (pi / segments) * 1.3, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OuterRingPainter oldDelegate) => oldDelegate.color != color;
}

class _ProgressArcPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ProgressArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bgPaint = Paint()
      ..color = AppColors.text_ghost.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(center, radius, bgPaint);

    final sweep = 2 * pi * progress.clamp(0.0, 1.0);
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2, sweep, false, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _ProgressArcPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
