import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/animations/animation_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/cyber_card.dart';
import '../../core/widgets/glitch_text.dart';
import '../../core/widgets/nav_rail_shell.dart';
import '../../core/widgets/pulse_ring.dart';
import '../../core/widgets/severity_badge.dart';
import '../scan_center/scan_screen.dart';
import '../vulnerability_center/vuln_screen.dart';
import '../security_advisor/advisor_screen.dart';
import '../settings/settings_screen.dart';
import '../../data/models/scan_result.dart';
import 'dashboard_controller.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _scoreAnimController;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _scoreAnimController = AnimationController(
      vsync: this,
      duration: AnimDuration.cinematic,
    );
    _scoreAnimation = CurvedAnimation(
      parent: _scoreAnimController,
      curve: AnimCurve.enter,
    );
    _scoreAnimController.forward();
  }

  @override
  void dispose() {
    _scoreAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navIndex = ref.watch(selectedNavIndexProvider);

    return NavRailShell(
      child: IndexedStack(
        index: navIndex,
        children: [
          _buildDashboardContent(),
          const ScanScreen(),
          const VulnScreen(),
          const AdvisorScreen(),
          const SettingsScreen(),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    final dashboardState = ref.watch(dashboardControllerProvider);
    final latestScan = dashboardState.latestScan;
    final score = latestScan?.securityScore ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar / Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GlitchText(
                      text: 'SECURITY OVERVIEW',
                      style: AppTypography.headline,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      latestScan != null
                          ? 'TARGET: ${latestScan.projectName}  •  STATUS: ${latestScan.deployStatus.replaceAll('_', ' ')}'
                          : 'NO TARGET LOADED — INITIATE FIRST AUDIT',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.label,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.signal),
                  backgroundColor: AppColors.signal_glow,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: () {
                  ref.read(selectedNavIndexProvider.notifier).state = 1; // Go to Scan Center
                },
                icon: const Icon(Icons.radar, color: AppColors.signal, size: 18),
                label: Text(
                  'START SCAN',
                  style: GoogleFonts.rajdhani(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                    color: AppColors.signal,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Main Hero Grid: Score Arc on Left, Quick Stats on Right
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 800;
              final heroWidgets = [
                // Score Arc Widget
                CyberCard(
                  accentColor: _getScoreColor(score),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('SYSTEM SECURITY SCORE', style: AppTypography.label),
                          SeverityBadge(severity: score >= 70 ? 'SECURE' : 'CRITICAL'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: 220,
                        height: 190,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            PulseRing(
                              size: 170,
                              color: _getScoreColor(score),
                              child: const SizedBox.shrink(),
                            ),
                            AnimatedBuilder(
                              animation: _scoreAnimation,
                              builder: (context, child) {
                                final animatedVal = score * _scoreAnimation.value;
                                return CustomPaint(
                                  size: const Size(200, 200),
                                  painter: _ScoreArcPainter(
                                    score: animatedVal,
                                    scoreColor: _getScoreColor(score),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        GlitchText(
                                          text: animatedVal.toInt().toString(),
                                          style: GoogleFonts.rajdhani(
                                            fontSize: 54,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.text_primary,
                                            height: 1.0,
                                          ),
                                        ),
                                        Text(
                                          score >= 70 ? 'SAFE TO DEPLOY' : 'NOT SAFE',
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 1.5,
                                            color: _getScoreColor(score),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Threat Matrix Quick Metrics
                CyberCard(
                  accentColor: AppColors.signal,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('THREAT VULNERABILITY BREAKDOWN', style: AppTypography.label),
                          Text(
                            'TOTAL: ${latestScan?.vulnerabilities.length ?? 0}',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.signal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          _buildSeverityStat(
                            title: 'CRITICAL',
                            count: latestScan?.criticalCount ?? 0,
                            color: AppColors.critical,
                          ),
                          const SizedBox(width: 16),
                          _buildSeverityStat(
                            title: 'HIGH',
                            count: latestScan?.highCount ?? 0,
                            color: AppColors.high,
                          ),
                          const SizedBox(width: 16),
                          _buildSeverityStat(
                            title: 'MEDIUM',
                            count: latestScan?.mediumCount ?? 0,
                            color: AppColors.medium,
                          ),
                          const SizedBox(width: 16),
                          _buildSeverityStat(
                            title: 'LOW',
                            count: latestScan?.lowCount ?? 0,
                            color: AppColors.safe,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.void_black,
                          border: Border.all(color: AppColors.text_ghost, width: 1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: AppColors.signal, size: 16),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                latestScan != null && latestScan.deployStatus == 'SAFE_TO_DEPLOY'
                                    ? 'Codebase meets minimum security score threshold (>=70). Safe for production deployment.'
                                    : 'Critical security flaws require immediate remediation before release.',
                                style: AppTypography.body.copyWith(fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ];

              return isNarrow
                  ? Column(children: [
                      heroWidgets[0],
                      const SizedBox(height: 16),
                      heroWidgets[1],
                    ])
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: heroWidgets[0]),
                        const SizedBox(width: 20),
                        Expanded(flex: 3, child: heroWidgets[1]),
                      ],
                    );
            },
          ),

          const SizedBox(height: 32),

          // 6-Module Status Row
          Text('ACTIVE SECURITY MODULE STATUS', style: AppTypography.label),
          const SizedBox(height: 14),
          _buildModuleStatusRow(latestScan),

          const SizedBox(height: 36),

          // Recent Scans List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('RECENT SECURITY SCANS', style: AppTypography.label),
              InkWell(
                onTap: () => ref.read(selectedNavIndexProvider.notifier).state = 2,
                child: Text(
                  'VIEW ALL VULNERABILITIES →',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    letterSpacing: 1.0,
                    color: AppColors.signal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...dashboardState.recentScans.map((scan) => _buildRecentScanCard(scan)),
        ],
      ),
    );
  }

  Widget _buildSeverityStat({
    required String title,
    required int count,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.void_black,
          border: Border.all(color: AppColors.text_ghost.withOpacity(0.3), width: 1),
          borderRadius: BorderRadius.circular(2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 3,
                child: Container(color: color),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count.toString().padLeft(2, '0'),
                      style: GoogleFonts.rajdhani(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.0,
                        color: AppColors.text_secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuleStatusRow(ScanResult? scan) {
    final modules = [
      (
        'Secret Scanner',
        Icons.key_outlined,
        scan != null ? (scan.secretsDetected ? 'FAIL' : 'PASS') : 'READY',
      ),
      (
        'MCP Security',
        Icons.hub_outlined,
        scan != null ? (scan.mcpSecure ? 'PASS' : 'FAIL') : 'READY',
      ),
      (
        'Dependencies',
        Icons.inventory_2_outlined,
        scan != null ? (scan.dependenciesSafe ? 'PASS' : 'FAIL') : 'READY',
      ),
      (
        'API Surface',
        Icons.lan_outlined,
        scan != null ? (scan.apiSecure ? 'PASS' : 'FAIL') : 'READY',
      ),
      (
        'Threat Vector',
        Icons.bug_report_outlined,
        scan != null ? (scan.securityScore >= 70 ? 'PASS' : 'FAIL') : 'READY',
      ),
      (
        'AI Firewall',
        Icons.psychology_outlined,
        scan != null ? (scan.promptInjectionSafe ? 'PASS' : 'FAIL') : 'READY',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: modules.map((m) {
            final isFail = m.$3 == 'FAIL';
            return SizedBox(
              width: max(130, (constraints.maxWidth - (5 * 12)) / 6),
              child: CyberCard(
                accentColor: isFail ? AppColors.critical : AppColors.safe,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(m.$2, size: 20, color: isFail ? AppColors.critical : AppColors.signal),
                    const SizedBox(height: 8),
                    Text(
                      m.$1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.text_primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SeverityBadge(
                      severity: m.$3,
                      fontSize: 8.5,
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildRecentScanCard(ScanResult scan) {
    final highestSeverity = scan.criticalCount > 0
        ? AppColors.critical
        : scan.highCount > 0
            ? AppColors.high
            : scan.mediumCount > 0
                ? AppColors.medium
                : AppColors.safe;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CyberCard(
        accentColor: highestSeverity,
        onTap: () {
          ref.read(selectedNavIndexProvider.notifier).state = 2; // Open Vulnerability center
        },
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.void_black,
                border: Border.all(color: highestSeverity, width: 1),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Center(
                child: Text(
                  scan.securityScore.toString(),
                  style: GoogleFonts.rajdhani(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: highestSeverity,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scan.projectName,
                    style: GoogleFonts.rajdhani(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text_primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Scanned ${DateFormat('MMM dd, yyyy HH:mm').format(scan.scannedAt)}  •  ${scan.vulnerabilities.length} vulnerabilities found',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: AppColors.text_secondary,
                    ),
                  ),
                ],
              ),
            ),
            SeverityBadge(severity: scan.deployStatus == 'SAFE_TO_DEPLOY' ? 'PASS' : 'FAIL'),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.text_ghost),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 85) return AppColors.safe;
    if (score >= 70) return AppColors.signal;
    if (score >= 50) return AppColors.medium;
    return AppColors.critical;
  }
}

class _ScoreArcPainter extends CustomPainter {
  final double score;
  final Color scoreColor;

  _ScoreArcPainter({required this.score, required this.scoreColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    // 270 degree arc, starting at 135 deg (3*pi/4) and sweeping 270 deg (3*pi/2)
    const startAngle = 0.75 * pi;
    const totalSweep = 1.5 * pi;

    // Background Arc
    final bgPaint = Paint()
      ..color = AppColors.text_ghost.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, totalSweep, false, bgPaint);

    // Score Fill Arc
    final fillSweep = totalSweep * (score / 100.0).clamp(0.0, 1.0);
    final fillPaint = Paint()
      ..color = scoreColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, fillSweep, false, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _ScoreArcPainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.scoreColor != scoreColor;
  }
}
