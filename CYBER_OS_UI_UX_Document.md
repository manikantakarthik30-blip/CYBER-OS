# CYBER_OS — Cinematic UI/UX Design Document
## Agent Instruction Set for Flutter UI Implementation

---

## DESIGN IDENTITY

CYBER_OS is not a dashboard. It is a command center.

The visual language borrows from:
- Deep-sea sonar interfaces (radial pulses, depth perception)
- Film noir terminal aesthetics (not generic hacker green — cold blue-white)
- Precision surgical instruments (clean geometry, purposeful lines)

The user should feel like they are operating a classified security system, not using a SaaS tool.

---

## COLOR SYSTEM

Define these exact tokens in `lib/core/theme/app_colors.dart`:

```dart
class AppColors {
  // Base
  static const Color void_black    = Color(0xFF040810); // deepest bg
  static const Color abyss         = Color(0xFF070D1A); // card bg
  static const Color trench        = Color(0xFF0D1525); // elevated surface
  static const Color surface       = Color(0xFF111D33); // interactive surface

  // Accent — Cold Cyan (NOT generic green)
  static const Color signal        = Color(0xFF00D4FF); // primary action
  static const Color signal_dim    = Color(0xFF00D4FF33); // signal at 20% opacity
  static const Color signal_glow   = Color(0xFF00D4FF15); // signal at 8% opacity

  // Severity
  static const Color critical      = Color(0xFFFF2D55); // critical threats
  static const Color critical_dim  = Color(0xFFFF2D5520);
  static const Color high          = Color(0xFFFF6B2D); // high severity
  static const Color high_dim      = Color(0xFFFF6B2D20);
  static const Color medium        = Color(0xFFFFCC00); // medium severity
  static const Color medium_dim    = Color(0xFFFFCC0020);
  static const Color safe          = Color(0xFF00FF94); // safe / pass
  static const Color safe_dim      = Color(0xFF00FF9420);

  // Text
  static const Color text_primary  = Color(0xFFE8F4FF);
  static const Color text_secondary= Color(0xFF6B8BAE);
  static const Color text_ghost    = Color(0xFF2A3F5C);
}
```

**RULE: Never use pure white (#FFFFFF) or pure black (#000000). Never use generic blue (#2196F3 or Material defaults).**

---

## TYPOGRAPHY

Install and use only these two fonts. Add to `pubspec.yaml`:

```yaml
fonts:
  - family: Rajdhani
    fonts:
      - asset: assets/fonts/Rajdhani-SemiBold.ttf
        weight: 600
      - asset: assets/fonts/Rajdhani-Bold.ttf
        weight: 700
  - family: JetBrains Mono
    fonts:
      - asset: assets/fonts/JetBrainsMono-Regular.ttf
      - asset: assets/fonts/JetBrainsMono-Medium.ttf
        weight: 500
```

Download from Google Fonts — both are free.

Type scale in `lib/core/theme/app_typography.dart`:

```dart
class AppTypography {
  // Display — Rajdhani Bold — used for score numbers, hero text
  static const TextStyle display = TextStyle(
    fontFamily: 'Rajdhani',
    fontSize: 72,
    fontWeight: FontWeight.w700,
    letterSpacing: -2,
    color: AppColors.text_primary,
    height: 1.0,
  );

  // Headline — Rajdhani SemiBold — screen titles
  static const TextStyle headline = TextStyle(
    fontFamily: 'Rajdhani',
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: AppColors.text_primary,
  );

  // Label — JetBrains Mono — module names, status tags, file paths
  static const TextStyle label = TextStyle(
    fontFamily: 'JetBrains Mono',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.5,
    color: AppColors.text_secondary,
  );

  // Body — JetBrains Mono — vulnerability descriptions, scan logs
  static const TextStyle body = TextStyle(
    fontFamily: 'JetBrains Mono',
    fontSize: 13,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.3,
    color: AppColors.text_secondary,
    height: 1.6,
  );

  // Code — JetBrains Mono — file paths, code snippets
  static const TextStyle code = TextStyle(
    fontFamily: 'JetBrains Mono',
    fontSize: 11,
    color: AppColors.signal,
    letterSpacing: 0.5,
  );
}
```

---

## ANIMATION SYSTEM

Create `lib/core/animations/animation_constants.dart`:

```dart
class AnimDuration {
  static const micro    = Duration(milliseconds: 120);  // instant feedback
  static const fast     = Duration(milliseconds: 250);  // button press response
  static const normal   = Duration(milliseconds: 400);  // screen transitions
  static const slow     = Duration(milliseconds: 700);  // reveal animations
  static const cinematic = Duration(milliseconds: 1200); // hero entrance
  static const pulse    = Duration(milliseconds: 2000);  // idle pulse loop
}

class AnimCurve {
  static const enter   = Curves.easeOutCubic;
  static const exit    = Curves.easeInCubic;
  static const bounce  = Curves.elasticOut;
  static const sharp   = Curves.easeInOutQuart;
  static const signal  = Curves.easeInOutSine; // for pulse/glow loops
}
```

**ANIMATION PHILOSOPHY:**
- Every state change is animated. Nothing snaps.
- Animations respond to what the user DID, not just decorate the screen.
- Idle animations (pulse, glow) run slow and subtle. Never distracting.
- Scan animations are dramatic. This is the product's hero moment.

---

## SHARED COMPONENTS

### 1. CyberCard

Base container for all cards. File: `lib/core/widgets/cyber_card.dart`

```dart
// Visual spec:
// Background: AppColors.abyss
// Border: 1px solid AppColors.text_ghost (0.3 opacity)
// Border radius: 4px (sharp — not rounded SaaS cards)
// Inner left border accent: 2px solid [severity color] on left edge
// Subtle inner glow on hover: BoxShadow with signal_glow
// Entry animation: FadeTransition + SlideTransition (slide up 20px, fade in)
//   Duration: AnimDuration.slow
//   Curve: AnimCurve.enter
```

Implementation pattern:
```dart
AnimatedContainer(
  duration: AnimDuration.fast,
  decoration: BoxDecoration(
    color: AppColors.abyss,
    border: Border(
      left: BorderSide(color: accentColor, width: 2),
      top: BorderSide(color: AppColors.text_ghost.withOpacity(0.3), width: 1),
      right: BorderSide(color: AppColors.text_ghost.withOpacity(0.3), width: 1),
      bottom: BorderSide(color: AppColors.text_ghost.withOpacity(0.3), width: 1),
    ),
    borderRadius: BorderRadius.circular(4),
    boxShadow: isHovered ? [
      BoxShadow(color: accentColor.withOpacity(0.08), blurRadius: 20, spreadRadius: 0),
    ] : [],
  ),
  child: child,
)
```

---

### 2. SeverityBadge

File: `lib/core/widgets/severity_badge.dart`

```dart
// CRITICAL → background: critical_dim, text: critical, border: critical at 60%
// HIGH     → background: high_dim,     text: high,     border: high at 60%
// MEDIUM   → background: medium_dim,   text: medium,   border: medium at 60%
// LOW      → background: safe_dim,     text: safe,     border: safe at 60%

// Shape: sharp rectangle, border-radius: 2px
// Text: JetBrains Mono, 10px, weight 500, letter-spacing 2.0
// Padding: 4px vertical, 10px horizontal
// Entry: Scale from 0.7 → 1.0, opacity 0 → 1, duration: 200ms, curve: bounce
```

---

### 3. GlitchText

File: `lib/core/widgets/glitch_text.dart`

Used for: screen titles, score display during scan.

Effect: Text renders, then briefly shows a 2-frame offset clone in signal color, then snaps back. Runs once on widget entry. Never loops unless triggered.

```dart
// Implementation:
// Layer 1: original text at full opacity
// Layer 2: same text, offset +3px right, signal color, opacity 0.4, duration 80ms
// Layer 3: same text, offset -2px left, critical color, opacity 0.3, duration 60ms
// Trigger: AnimationController, runs once, total duration 300ms
// Do NOT loop this. One glitch on appearance only.
```

---

### 4. PulseRing

File: `lib/core/widgets/pulse_ring.dart`

A circular ring that slowly expands and fades. Used around the security score, active scan indicators, and critical vulnerability markers.

```dart
// Implementation:
// CustomPainter draws concentric circles
// Scale: 1.0 → 1.4 over 2000ms, then resets
// Opacity: 0.6 → 0.0 over same duration
// Curve: Curves.easeOut
// Loop: yes — this is an idle animation, runs continuously
// Color: matches context (signal for score, critical for critical vuln)
// Ring thickness: 1px
```

---

### 5. ScanLineOverlay

File: `lib/core/widgets/scan_line_overlay.dart`

A horizontal line that sweeps top-to-bottom over any widget during active scanning.

```dart
// Implementation:
// Position: absolute overlay, full width, 1px height
// Color: signal at 60% opacity
// Shadow: signal color, blurRadius 8
// Animation: translate Y from -100% to +100% over 1500ms
// Loop: yes during scanning only — stop when scan completes
// Behind line: content has a subtle brightness boost (shader or opacity trick)
```

---

### 6. TerminalLogWidget

File: `lib/core/widgets/terminal_log.dart`

Shows scan progress as a live terminal log stream.

```dart
// Visual:
// Background: void_black
// Border: 1px signal_dim
// Font: JetBrains Mono 12px
// Text color alternates by log type:
//   INFO → text_secondary
//   SCANNING → signal
//   FOUND → critical or high (based on severity)
//   PASS → safe
//   COMPLETE → text_primary

// Animation:
// Each new line slides in from left (translateX -10px → 0) + fade in
// Duration: 120ms per line
// Lines appear with 80ms stagger between them
// Cursor: blinking block cursor at end of last line (500ms on/off)
// Scrolls automatically to latest line (ScrollController.animateTo)

// Example log format:
// [00:00.01] Initializing security engine...
// [00:00.03] Connecting to GitHub API...
// [00:00.12] Fetching repository tree...
// [00:00.45] Scanning lib/config.dart...
// [00:00.46] ⚠ CRITICAL — Hardcoded API key detected
// [00:01.02] Scanning pubspec.yaml...
// [00:01.15] ✓ No secrets found
```

---

## SCREEN-BY-SCREEN SPECIFICATIONS

---

### SCREEN 1 — Splash / Boot Screen

File: `lib/features/splash/splash_screen.dart`

Duration: 2.5 seconds then auto-navigate to Dashboard.

Sequence (run in order, not simultaneously):

```
t=0ms    Background fades in (void_black) — 300ms
t=300ms  CYBER_OS logo text renders with GlitchText effect
         Font: Rajdhani Bold, 48px, color: text_primary
         Below it: "Security Layer v1.0" in JetBrains Mono 12px signal color
t=600ms  Three horizontal lines (1px, signal color) extend from center outward
         Animation: scaleX 0 → 1, duration 400ms, stagger 100ms each
t=1000ms PulseRing starts around logo mark
t=1200ms Boot log appears below logo:
         Lines appear one by one, 150ms apart:
         "> Initializing security modules..."
         "> Loading threat database..."
         "> System ready."
t=2000ms All elements fade out simultaneously — 400ms
t=2400ms Navigate to Dashboard
```

No skip button. 2.5 seconds is fast enough.

---

### SCREEN 2 — Dashboard

File: `lib/features/dashboard/dashboard_screen.dart`

Layout (vertical scroll, left-aligned content):

```
┌─────────────────────────────────────────────┐
│  [nav rail left]  │  [main content]          │
│                   │                          │
│  ◈ Dashboard      │  SECURITY OVERVIEW       │
│  ◈ Scan           │  ┌──────┐  ┌──────────┐ │
│  ◈ Vulnerabilities│  │SCORE │  │MODULES   │ │
│  ◈ Settings       │  │  82  │  │12 active │ │
│                   │  └──────┘  └──────────┘ │
│                   │                          │
│                   │  RECENT SCANS            │
│                   │  [scan card]             │
│                   │  [scan card]             │
│                   │  [scan card]             │
└─────────────────────────────────────────────┘
```

**Nav Rail (left side):**
- Width: 72px (icon only) — expands to 200px on hover with label
- Background: abyss
- Right border: 1px text_ghost
- Active item: left border 2px signal, icon color signal
- Inactive: icon color text_ghost
- Hover expansion: AnimatedContainer, duration 250ms, curve easeOutCubic
- Icons: use flutter_svg with custom SVG icons (shield, scan, warning, gear)

**Security Score Widget:**
- Circular arc (not a full circle — 270 degree arc, gap at bottom)
- Arc drawn with CustomPainter
- Background arc: text_ghost color
- Filled arc: gradient from signal → safe (for 70+) or critical → high (for below 50)
- Center: score number in Rajdhani Bold 72px with GlitchText on load
- Below number: status label — "SECURE" / "WARNING" / "CRITICAL"
- PulseRing behind the arc — slow, 3s loop, subtle
- Entry animation: arc draws from 0 → final value over 1200ms, curve: easeOutCubic
- Score counter: animates from 0 → actual score, same duration

**Module Status Row:**
- Horizontal row of 6 module cards
- Each card: 100px × 80px, CyberCard base
- Shows: icon, module name (Mono 10px), PASS/FAIL badge
- Entry: stagger slide-up animation, 80ms delay between cards

**Recent Scans List:**
- Each scan: CyberCard with left accent color = highest severity found
- Shows: repo name, score, date, vulnerability count
- Tap: navigate to that scan's full report

---

### SCREEN 3 — Scan Center

File: `lib/features/scan_center/scan_screen.dart`

This is the most cinematic screen. Treat it as the hero experience.

**Pre-Scan State:**

```
Center of screen:
┌──────────────────────────────┐
│                              │
│   ◈  SCAN TARGET             │
│                              │
│   [GitHub URL input]         │
│         — or —               │
│   [Upload Project button]    │
│                              │
│   [INITIATE SCAN button]     │
│                              │
└──────────────────────────────┘
```

Input field styling:
```dart
// Background: void_black
// Border: 1px text_ghost — on focus: 1px signal with signal_glow box shadow
// Font: JetBrains Mono 13px
// Placeholder: "github.com/username/repo" in text_ghost
// Border radius: 2px
// Focus animation: border color transition 200ms + glow appears 300ms
// Cursor: signal color
```

INITIATE SCAN button:
```dart
// Background: transparent
// Border: 1px signal
// Text: Rajdhani SemiBold 16px, signal color, letter-spacing 3
// Text content: "INITIATE SCAN"
// On hover: background fills with signal_glow, border brightens
// On press: scale 0.97 for 100ms (tactile feedback) then release
// Disabled state: border text_ghost, text text_ghost, no hover effects
```

**Active Scan State:**

When scan starts, the pre-scan UI exits and scan UI enters:

```
Transition:
- Input field + button fade out (200ms)
- Scan UI fades in (400ms) + slides up 30px
```

Scan UI layout:
```
┌──────────────────────────────────────────┐
│  SCANNING: github.com/user/repo          │
│                                          │
│  [large animated scan ring]              │
│       Scanning module 3 of 6            │
│       Secret Detection Engine           │
│                                          │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━         │
│  [terminal log stream]                   │
│                                          │
│  ████████████░░░░░░░░░░  48%            │
└──────────────────────────────────────────┘
```

Scan ring animation:
```dart
// Large circle, 160px diameter
// Outer ring: 2px signal, rotates continuously (360deg per 2s)
// Middle ring: 1px text_ghost, rotates opposite direction (360deg per 3s)
// Inner ring: 2px stroke, draws arc from 0 → scan progress % (animated)
// Center: current module icon (40px, signal color)
// All three rings use separate AnimationControllers
```

Progress bar:
```dart
// Background: text_ghost at 20%
// Fill: gradient signal → safe
// Height: 2px (thin, precise — not a fat progress bar)
// Border radius: 0 (sharp)
// Leading edge: 4px bright white dot (the "cursor" of progress)
// Animation: linear interpolation to each new value, 300ms
```

**Scan Complete State:**

When scan finishes, dramatic reveal sequence:

```
t=0ms    Scan ring stops rotating — final pulse expands and fades (600ms)
t=400ms  TerminalLog shows: "> Scan complete. Analyzing results..."
t=800ms  Log fades out
t=1000ms Security score flies in from top — GlitchText on number
t=1200ms Score arc draws itself (easeOutCubic, 1200ms)
t=1600ms Vulnerability list items appear, staggered (80ms each)
t=2400ms "View Full Report" button appears with fade
```

---

### SCREEN 4 — Vulnerability Center

File: `lib/features/vulnerability_center/vuln_screen.dart`

Layout:

```
┌──────────────────────────────────────────┐
│  VULNERABILITIES  [filter: ALL▾]         │
│  23 found  ■ 4 Critical  ■ 8 High        │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │ [CRITICAL] Hardcoded API Key       │  │
│  │ lib/config.dart, line 12          │  │
│  │ > Tap to expand                   │  │
│  └────────────────────────────────────┘  │
│  ┌────────────────────────────────────┐  │
│  │ [HIGH] Missing Rate Limiting       │  │
│  │ services/api_service.dart, line 45│  │
│  └────────────────────────────────────┘  │
└──────────────────────────────────────────┘
```

Filter bar:
```dart
// Horizontal row of filter chips: ALL / CRITICAL / HIGH / MEDIUM / LOW
// Active chip: border signal, background signal_glow, text signal
// Inactive chip: border text_ghost, background transparent, text text_secondary
// Selection animation: background fills 200ms, text color changes 150ms
// Filtering: list animates — removed items slide left + fade out (200ms),
//            new items slide in from right + fade in (200ms)
```

Vulnerability card expanded state:
```dart
// Tap to expand: AnimatedSize widget, curve easeOutCubic, 300ms
// Expanded shows:
//   - Description text (JetBrains Mono 12px, text_secondary)
//   - File path + line number (signal color, code style)
//   - Recommended fix section (safe color border on left)
//   - "Copy Fix" button (minimal, text only, safe color)
// Left border: 3px solid severity color (thicker when expanded)
// Expanded card has subtle background: severity_dim color
```

---

### SCREEN 5 — Settings

File: `lib/features/settings/settings_screen.dart`

Keep this minimal. Security engineers don't need flashy settings screens.

Sections:
- API Keys (masked input fields)
- Scan preferences (toggle switches)
- Notification settings
- Export format (PDF / JSON)

Toggle switch styling:
```dart
// Use a custom CyberToggle widget
// OFF: track color text_ghost, thumb color surface
// ON: track color signal at 40%, thumb color signal
// Transition: 200ms smooth slide + color change
// No ripple effect — security tools feel precise, not Material
```

---

## PAGE TRANSITIONS

Override default Flutter transitions. Use these for all navigation:

```dart
// Navigator push — new screen slides up from bottom 40px + fades in
// Duration: 400ms, curve: easeOutCubic

// Navigator pop — current screen slides down 40px + fades out
// Duration: 300ms, curve: easeInCubic

// Tab switches in bottom nav — crossfade only, no slide
// Duration: 250ms

// Implementation: use PageRouteBuilder for all navigation
PageRouteBuilder(
  transitionDuration: Duration(milliseconds: 400),
  pageBuilder: (_, __, ___) => TargetScreen(),
  transitionsBuilder: (_, animation, __, child) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, 0.04), // subtle — not dramatic slide
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
  },
)
```

---

## LOADING STATES

Never show a spinner. These are the loading patterns:

**Shimmer skeleton:**
```dart
// Use shimmer package or custom implementation
// Skeleton color: surface
// Shimmer color: trench
// Direction: left to right, 1500ms loop
// Use for: vulnerability list loading, scan history loading
```

**Scan module loading:**
```dart
// Show ScanLineOverlay on each module card while it processes
// Module card border pulses: opacity 0.4 → 1.0 → 0.4, 1000ms loop
// When complete: border snaps to solid, PulseRing emits once and fades
```

---

## ERROR STATES

**API Error:**
```dart
// Card with left border: critical color
// Icon: warning triangle (SVG, critical color)
// Title: "Connection failed" — Rajdhani SemiBold 16px
// Message: exact error in JetBrains Mono 12px (technical users want this)
// Button: "Retry" — minimal, signal color border
// Entry: shake animation — translate X -6px → +6px → 0, 3 cycles, 400ms total
```

**Empty state (no scans yet):**
```dart
// Center of screen
// Large icon: security shield outline, text_ghost color, 80px
// Text: "No scans yet" — Rajdhani SemiBold 20px, text_secondary
// Sub: "Scan a GitHub repo or upload a project to begin" — Mono 12px, text_ghost
// CTA button: "Start First Scan" — signal border, signal text
// No illustrations. No confetti. Just precise, quiet emptiness.
```

---

## HAPTIC FEEDBACK

Add haptics for key moments (mobile):

```dart
import 'package:flutter/services.dart';

// Scan initiated:     HapticFeedback.mediumImpact()
// Critical found:     HapticFeedback.heavyImpact()
// Scan complete:      HapticFeedback.lightImpact() x2 with 100ms gap
// Module pass:        HapticFeedback.selectionClick()
// Button tap:         HapticFeedback.selectionClick()
```

---

## ACCESSIBILITY RULES

These must be followed even though the aesthetic is dark:

1. All text contrast ratio minimum 4.5:1 against background
2. All interactive elements minimum 44×44px tap target
3. All animations respect `MediaQuery.of(context).disableAnimations`
4. Add `Semantics` wrapper to SeverityBadge, ScoreWidget, and all icon-only buttons
5. Never convey severity by color alone — always include text label

Check contrast:
- text_primary (#E8F4FF) on abyss (#070D1A) → ratio: 14.8:1 ✓
- text_secondary (#6B8BAE) on abyss (#070D1A) → ratio: 4.9:1 ✓
- signal (#00D4FF) on abyss (#070D1A) → ratio: 11.2:1 ✓

---

## FLUTTER PACKAGES REQUIRED

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter_animate: ^4.5.0     # declarative animations
  shimmer: ^3.0.0             # loading skeletons
  fl_chart: ^0.68.0           # security score arc chart
  flutter_svg: ^2.0.10+1      # SVG icons
  lottie: ^3.1.0              # for complex animations if needed
  google_fonts: ^6.2.1        # backup if bundling fonts fails
```

---

## AGENT ANIMATION RULES

These rules must be followed when implementing every widget:

1. NEVER use `setState()` to trigger animations — use `AnimationController` + `Riverpod`
2. NEVER use default Material page transitions — always use custom `PageRouteBuilder`
3. NEVER show a spinner — use skeleton loading or animated scan ring
4. NEVER use `Colors.blue`, `Colors.red` or any Material color directly — only AppColors tokens
5. NEVER animate more than 3 things simultaneously — stagger everything
6. ALWAYS dispose `AnimationController` in `dispose()` method
7. ALWAYS check `MediaQuery.of(context).disableAnimations` before starting any animation loop
8. ALWAYS use `flutter_animate` package for simple fade/slide — reserve `AnimationController` for complex custom animations
9. NEVER use `Hero` widget for transitions — it breaks the cinematic timing control
10. ALWAYS test on both light and dark system themes (though UI is always dark, system overlays vary)

---

## WHAT NOT TO BUILD

Avoid these generic patterns completely:

- No bottom navigation bar (use nav rail on all screen sizes)
- No `Card` widget with default Material elevation shadow
- No `CircularProgressIndicator` (spinner) anywhere
- No default `AppBar` — build custom top bar or no top bar
- No `Scaffold` backgroundColor as default grey or white
- No `ElevatedButton` default styling — always custom
- No `ListTile` default styling — always custom
- No rounded corners above 4px radius on any container
- No gradient backgrounds on the app shell (only on specific accent elements)
- No particle systems or matrix rain — this is surgical precision, not hacker movie

---

## FINAL QUALITY CHECK

Before marking UI complete, verify:

- [ ] App launches with boot sequence (2.5s splash)
- [ ] Score widget animates from 0 on first render
- [ ] Scan animation plays end-to-end without jank (test on mid-range device)
- [ ] All cards have stagger entry animations
- [ ] Vulnerability list filters animate correctly
- [ ] Page transitions are consistent across all routes
- [ ] Terminal log auto-scrolls during scan
- [ ] No white flash between navigation
- [ ] Haptics fire at correct moments (test on physical device)
- [ ] App looks identical in dark mode and light mode system settings (always dark)
```
