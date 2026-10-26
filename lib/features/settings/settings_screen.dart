import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/cyber_card.dart';
import '../../core/widgets/cyber_toggle.dart';
import '../../core/widgets/glitch_text.dart';
import '../../data/repositories/scan_repository.dart';
import '../../screens/login_screen.dart';
import '../../services/firebase_service.dart';
import 'settings_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _enterpriseProxyController =
      TextEditingController(text: 'https://api.osv.dev/v1');
  bool _showAdvanced = false;

  @override
  void dispose() {
    _enterpriseProxyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final scanRepo = ref.watch(scanRepositoryProvider);
    final operatorEmail = ref.watch(currentOperatorEmailProvider) ?? 'operator@cyber-os.internal';
    final operatorName = ref.watch(currentOperatorNameProvider) ?? 'Cyber Operator';
    final authProvider = ref.watch(currentAuthProvider) ?? 'email';

    return Scaffold(
      backgroundColor: AppColors.void_black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            GlitchText(
              text: 'SYSTEM CONFIGURATION',
              style: AppTypography.headline,
            ),
            const SizedBox(height: 4),
            Text(
              'SECURITY ENGINE ARCHITECTURE & SUBSYSTEM STATUS',
              style: AppTypography.label,
            ),
            const SizedBox(height: 28),

            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                children: [
                  // Active Operator Identity & Session Card
                  CyberCard(
                    accentColor: AppColors.signal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.signal.withValues(alpha: 0.5)),
                              ),
                              child: Center(
                                child: Icon(
                                  authProvider == 'google'
                                      ? Icons.g_mobiledata_rounded
                                      : authProvider == 'apple'
                                          ? Icons.apple_rounded
                                          : authProvider == 'guest'
                                              ? Icons.terminal
                                              : Icons.person_outline,
                                  color: authProvider == 'google'
                                      ? const Color(0xFF4285F4)
                                      : authProvider == 'guest'
                                          ? AppColors.signal
                                          : Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      operatorName,
                                      style: GoogleFonts.rajdhani(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.text_primary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.signal.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      child: Text(
                                        authProvider.toUpperCase(),
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.signal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  operatorEmail,
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 12,
                                    color: AppColors.text_secondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await ref.read(firebaseServiceProvider).signOut();
                            if (!context.mounted) return;
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            );
                          },
                          icon: const Icon(Icons.logout, size: 14, color: AppColors.critical),
                          label: Text(
                            'SIGN OUT',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.critical,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.critical),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Subsystem Status Card
                  CyberCard(
                    accentColor: AppColors.signal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.shield, color: AppColors.signal, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'CYBER_OS ENGINE STATUS & ARCHITECTURE',
                              style: GoogleFonts.rajdhani(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text_primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Production deployment mode. The engine operates autonomously on-device with zero developer credential exposure.',
                          style: AppTypography.body,
                        ),
                        const SizedBox(height: 20),

                        // Subsystem status items
                        _buildStatusRow(
                          icon: Icons.memory,
                          title: 'Autonomous AI Security Advisor',
                          status: 'ONLINE (On-Device Neural Intelligence)',
                          description:
                              'Queries are analyzed with zero cloud leakage using local cybersecurity heuristics and safe fallback intelligence.',
                          statusColor: AppColors.signal,
                        ),
                        const Divider(color: AppColors.text_ghost, height: 24),
                        _buildStatusRow(
                          icon: Icons.public,
                          title: 'GitHub Repository Ingestion Engine',
                          status: 'ACTIVE (Public Protocol)',
                          description:
                              'Public repository trees and dependencies are fetched via anonymous rate-paced HTTPS protocol. No user token required.',
                          statusColor: AppColors.safe,
                        ),
                        const Divider(color: AppColors.text_ghost, height: 24),
                        _buildStatusRow(
                          icon: Icons.cloud_done,
                          title: 'Vulnerability Database Feed',
                          status: 'CONNECTED (OSV.dev National & Open Source DB)',
                          description:
                              'Cross-references advisory signatures across CVE, GHSA, PyPI, and Pub database indices.',
                          statusColor: AppColors.safe,
                        ),
                        const Divider(color: AppColors.text_ghost, height: 24),
                        _buildStatusRow(
                          icon: Icons.lock_outline,
                          title: 'Local Enclave & Data Privacy',
                          status: 'ENFORCED',
                          description:
                              'Scan results and source fragments remain strictly on this device. Never uploaded to third-party telemetry.',
                          statusColor: AppColors.signal,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Scanner Engine Toggles Card
                  CyberCard(
                    accentColor: AppColors.safe,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.tune, color: AppColors.safe, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'ACTIVE SECURITY SCANNERS',
                              style: GoogleFonts.rajdhani(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text_primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildToggleRow(
                          title: 'Secret Scanner Engine',
                          description:
                              'Detects exposed AWS keys, private tokens, GCP service accounts, and API credentials.',
                          value: settings.enableSecretScanner,
                          onChanged: controller.toggleSecretScanner,
                        ),
                        const Divider(color: AppColors.text_ghost, height: 20),
                        _buildToggleRow(
                          title: 'Model Context Protocol (MCP) Tool Audit',
                          description:
                              'Flags dangerous exec() calls, unsanitized parameters, and untrusted tool servers.',
                          value: settings.enableMCPScanner,
                          onChanged: controller.toggleMCPScanner,
                        ),
                        const Divider(color: AppColors.text_ghost, height: 20),
                        _buildToggleRow(
                          title: 'Dependency CVE Checker (OSV.dev)',
                          description:
                              'Cross-references pubspec.yaml, package.json, and requirements.txt against known CVEs.',
                          value: settings.enableDependencyScanner,
                          onChanged: controller.toggleDependencyScanner,
                        ),
                        const Divider(color: AppColors.text_ghost, height: 20),
                        _buildToggleRow(
                          title: 'AI Prompt Injection Firewall',
                          description:
                              'Identifies jailbreak patterns, system prompt overrides, and adversarial inputs.',
                          value: settings.enableAIFirewall,
                          onChanged: controller.toggleAIFirewall,
                        ),
                        const Divider(color: AppColors.text_ghost, height: 20),
                        _buildToggleRow(
                          title: 'GitHub API Rate Limit Delay (200ms)',
                          description:
                              'Protects anonymous requests from secondary rate limits with pacing intervals.',
                          value: settings.enableRateLimiting,
                          onChanged: controller.toggleRateLimiting,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Report Export & Storage Management Card
                  CyberCard(
                    accentColor: AppColors.signal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.storage, color: AppColors.signal, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'DATA RETENTION & EXPORT PREFERENCES',
                              style: GoogleFonts.rajdhani(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text_primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Export format selection
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Default Report Export Format',
                                  style: GoogleFonts.rajdhani(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.text_primary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Format used when generating downloadable vulnerability assessments.',
                                  style: AppTypography.body.copyWith(fontSize: 11),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                _buildFormatChip(
                                  label: 'JSON',
                                  isSelected: settings.exportFormat == 'JSON',
                                  onTap: () => controller.setExportFormat('JSON'),
                                ),
                                const SizedBox(width: 8),
                                _buildFormatChip(
                                  label: 'MARKDOWN',
                                  isSelected: settings.exportFormat == 'Markdown',
                                  onTap: () => controller.setExportFormat('Markdown'),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const Divider(color: AppColors.text_ghost, height: 24),

                        // Storage cache clear
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Local Scan History Cache',
                                  style: GoogleFonts.rajdhani(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.text_primary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${scanRepo.getHistory().length} scan(s) stored locally in browser/device sandbox.',
                                  style: AppTypography.body.copyWith(fontSize: 11),
                                ),
                              ],
                            ),
                            OutlinedButton.icon(
                              onPressed: () {
                                scanRepo.clearHistory();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Local scan history cache cleared.'),
                                    backgroundColor: AppColors.surface,
                                  ),
                                );
                                setState(() {});
                              },
                              icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.critical),
                              label: Text(
                                'PURGE CACHE',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.critical,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.critical),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Collapsible Enterprise Gateway (Advanced)
                  CyberCard(
                    accentColor: AppColors.text_secondary,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.dns, color: AppColors.text_secondary, size: 18),
                                  const SizedBox(width: 10),
                                  Text(
                                    'ENTERPRISE PROXY & CVE ENDPOINT (OPTIONAL)',
                                    style: GoogleFonts.rajdhani(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.text_secondary,
                                    ),
                                  ),
                                ],
                              ),
                              Icon(
                                _showAdvanced ? Icons.expand_less : Icons.expand_more,
                                color: AppColors.text_secondary,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                        if (_showAdvanced) ...[
                          const SizedBox(height: 14),
                          Text(
                            'OSV.DEV VULNERABILITY DATABASE URL',
                            style: AppTypography.label,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.void_black,
                              border: Border.all(color: AppColors.text_ghost),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: TextField(
                              controller: _enterpriseProxyController,
                              style: GoogleFonts.jetBrainsMono(fontSize: 12, color: AppColors.text_primary),
                              decoration: InputDecoration(
                                hintText: 'https://api.osv.dev/v1',
                                hintStyle: GoogleFonts.jetBrainsMono(fontSize: 12, color: AppColors.text_ghost),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow({
    required IconData icon,
    required String title,
    required String status,
    required String description,
    required Color statusColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, color: statusColor, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: GoogleFonts.rajdhani(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text_primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      status,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTypography.body.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormatChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.signal.withValues(alpha: 0.2) : AppColors.surface,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: isSelected ? AppColors.signal : AppColors.text_ghost,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? AppColors.signal : AppColors.text_secondary,
          ),
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.rajdhani(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text_primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(description, style: AppTypography.body.copyWith(fontSize: 11)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        CyberToggle(value: value, onChanged: onChanged),
      ],
    );
  }
}
