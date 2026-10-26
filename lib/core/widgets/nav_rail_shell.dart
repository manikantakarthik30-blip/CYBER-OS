import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../animations/animation_constants.dart';
import '../theme/app_colors.dart';
import '../../screens/login_screen.dart';
import '../../services/firebase_service.dart';

final selectedNavIndexProvider = StateProvider<int>((ref) => 0);

class NavRailShell extends ConsumerStatefulWidget {
  final Widget child;

  const NavRailShell({super.key, required this.child});

  @override
  ConsumerState<NavRailShell> createState() => _NavRailShellState();
}

class _NavRailShellState extends ConsumerState<NavRailShell> {
  bool _isExpanded = false;

  final List<NavItemData> _navItems = const [
    NavItemData(
      index: 0,
      icon: Icons.dashboard_customize_outlined,
      activeIcon: Icons.dashboard_customize,
      label: 'DASHBOARD',
    ),
    NavItemData(
      index: 1,
      icon: Icons.radar_outlined,
      activeIcon: Icons.radar,
      label: 'SCAN CENTER',
    ),
    NavItemData(
      index: 2,
      icon: Icons.security_outlined,
      activeIcon: Icons.security,
      label: 'VULNERABILITIES',
    ),
    NavItemData(
      index: 3,
      icon: Icons.psychology_outlined,
      activeIcon: Icons.psychology,
      label: 'AI ADVISOR',
    ),
    NavItemData(
      index: 4,
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'SETTINGS',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(selectedNavIndexProvider);
    final operatorEmail = ref.watch(currentOperatorEmailProvider) ?? 'operator@cyber-os.internal';
    final operatorName = ref.watch(currentOperatorNameProvider) ?? 'Operator';
    final authProvider = ref.watch(currentAuthProvider) ?? 'email';

    return Scaffold(
      backgroundColor: AppColors.void_black,
      body: Row(
        children: [
          // Left Command Rail
          MouseRegion(
            onEnter: (_) => setState(() => _isExpanded = true),
            onExit: (_) => setState(() => _isExpanded = false),
            child: AnimatedContainer(
              duration: AnimDuration.fast,
              curve: AnimCurve.enter,
              width: _isExpanded ? 210 : 72,
              decoration: const BoxDecoration(
                color: AppColors.abyss,
                border: Border(
                  right: BorderSide(color: AppColors.text_ghost, width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  // App Brand Symbol
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.void_black,
                            border: Border.all(color: AppColors.signal, width: 1.5),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.signal.withOpacity(0.2),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.shield_outlined,
                              color: AppColors.signal,
                              size: 20,
                            ),
                          ),
                        ),
                        if (_isExpanded) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CYBER_OS',
                                  style: GoogleFonts.rajdhani(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 2.0,
                                    color: AppColors.text_primary,
                                  ),
                                ),
                                Text(
                                  'SECURITY KERNEL',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 9,
                                    letterSpacing: 1.0,
                                    color: AppColors.signal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  const Divider(color: AppColors.text_ghost, height: 1),
                  const SizedBox(height: 16),

                  // Nav items list
                  Expanded(
                    child: ListView.builder(
                      itemCount: _navItems.length,
                      itemBuilder: (context, i) {
                        final item = _navItems[i];
                        final isSelected = selectedIndex == item.index;

                        return InkWell(
                          onTap: () {
                            ref.read(selectedNavIndexProvider.notifier).state = item.index;
                          },
                          child: AnimatedContainer(
                            duration: AnimDuration.fast,
                            height: 48,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.signal_glow : Colors.transparent,
                              border: Border(
                                left: BorderSide(
                                  color: isSelected ? AppColors.signal : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: _isExpanded ? 56 : 66,
                                  child: Center(
                                    child: Icon(
                                      isSelected ? item.activeIcon : item.icon,
                                      color: isSelected ? AppColors.signal : AppColors.text_secondary,
                                      size: 22,
                                    ),
                                  ),
                                ),
                                if (_isExpanded)
                                  Expanded(
                                    child: Text(
                                      item.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 11,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                        letterSpacing: 1.5,
                                        color: isSelected ? AppColors.text_primary : AppColors.text_secondary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Bottom System Status indicator
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.safe,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.safe,
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        if (_isExpanded) ...[
                          const SizedBox(width: 10),
                          Text(
                            'KERNEL ONLINE',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9,
                              letterSpacing: 1.2,
                              color: AppColors.text_secondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Active Operator Profile & Sign Out
                  Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.text_ghost.withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 13,
                          backgroundColor: AppColors.void_black,
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
                            size: 16,
                          ),
                        ),
                        if (_isExpanded) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  operatorName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.rajdhani(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.text_primary,
                                  ),
                                ),
                                Text(
                                  operatorEmail,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 9,
                                    color: AppColors.text_secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout, size: 16, color: AppColors.critical),
                            tooltip: 'Sign Out',
                            onPressed: () async {
                              await ref.read(firebaseServiceProvider).signOut();
                              if (!context.mounted) return;
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // Main View Content
          Expanded(
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

class NavItemData {
  final int index;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const NavItemData({
    required this.index,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
