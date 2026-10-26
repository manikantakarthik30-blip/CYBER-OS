import 'dart:math';
import '../../data/models/scan_result.dart';
import '../../data/models/vulnerability.dart';
import '../../services/github_service.dart';
import '../ai_firewall/prompt_firewall.dart';
import '../scanners/api_scanner.dart';
import '../scanners/dependency_scanner.dart';
import '../scanners/mcp_scanner.dart';
import '../scanners/secret_scanner.dart';
import '../scanners/firebase_rules_scanner.dart';
import '../scanners/cloud_config_scanner.dart';
import '../threat_detection/threat_detector.dart';
import '../../features/settings/settings_controller.dart';

typedef ScanProgressCallback = void Function({
  required double progress,
  required String currentModule,
  required String currentAction,
  required String logLine,
  String? logType, // INFO, SCANNING, FOUND, PASS, COMPLETE
});

class SecurityEngine {
  final SecretScanner _secretScanner;
  final MCPScanner _mcpScanner;
  final APIScanner _apiScanner;
  final ThreatDetector _threatDetector;
  final PromptFirewall _promptFirewall;
  final DependencyScanner _dependencyScanner;
  final GitHubService _githubService;
  final FirebaseRulesScanner _firebaseRulesScanner;
  final CloudConfigScanner _cloudConfigScanner;

  SecurityEngine({
    SecretScanner? secretScanner,
    MCPScanner? mcpScanner,
    APIScanner? apiScanner,
    ThreatDetector? threatDetector,
    PromptFirewall? promptFirewall,
    DependencyScanner? dependencyScanner,
    GitHubService? githubService,
    FirebaseRulesScanner? firebaseRulesScanner,
    CloudConfigScanner? cloudConfigScanner,
  })  : _secretScanner = secretScanner ?? SecretScanner(),
        _mcpScanner = mcpScanner ?? MCPScanner(),
        _apiScanner = apiScanner ?? APIScanner(),
        _threatDetector = threatDetector ?? ThreatDetector(),
        _promptFirewall = promptFirewall ?? PromptFirewall(),
        _dependencyScanner = dependencyScanner ?? DependencyScanner(),
        _githubService = githubService ?? GitHubService(),
        _firebaseRulesScanner = firebaseRulesScanner ?? FirebaseRulesScanner(),
        _cloudConfigScanner = cloudConfigScanner ?? CloudConfigScanner();

  Future<ScanResult> runScanOnFiles({
    required String projectName,
    required String targetPathOrUrl,
    required Map<String, String> fileContents,
    ScanProgressCallback? onProgress,
    SettingsState? settings,
  }) async {
    final List<Vulnerability> allVulnerabilities = [];
    final List<String> logs = [];

    void emitLog(String message, {String type = 'INFO', double progress = 0.0, String module = 'Orchestrator'}) {
      final timestamp = DateTime.now().toIso8601String().substring(11, 19);
      final formattedLog = '[$timestamp] $message';
      logs.add(formattedLog);
      if (onProgress != null) {
        onProgress(
          progress: progress,
          currentModule: module,
          currentAction: message,
          logLine: formattedLog,
          logType: type,
        );
      }
    }

    emitLog('Initializing CYBER_OS security kernel...', type: 'INFO', progress: 0.05);
    await Future.delayed(const Duration(milliseconds: 100));

    emitLog('Target loaded: $projectName ($targetPathOrUrl) — ${fileContents.length} files queued',
        type: 'INFO', progress: 0.10);

    // Module 1: Secret Scanner (0.10 -> 0.30)
    final secretVulns = <Vulnerability>[];
    if (settings != null && !settings.enableSecretScanner) {
      emitLog('⊘ Module 1 SKIPPED: Secret Scanner disabled in user settings',
          type: 'INFO', module: 'Secret Detection Engine', progress: 0.30);
    } else {
      emitLog('Initiating Module 1/6: Secret Detection Scanner...',
          type: 'SCANNING', module: 'Secret Detection Engine', progress: 0.15);
      for (final entry in fileContents.entries) {
        final found = _secretScanner.scanSourceCode(entry.value, entry.key);
        if (found.isNotEmpty) {
          secretVulns.addAll(found);
          emitLog('⚠ CRITICAL — Found ${found.length} exposed secrets in ${entry.key}',
              type: 'FOUND', module: 'Secret Detection Engine', progress: 0.25);
        }
      }
      if (secretVulns.isEmpty) {
        emitLog('✓ Module 1 PASS: Zero hardcoded secrets detected',
            type: 'PASS', module: 'Secret Detection Engine', progress: 0.30);
      }
    }
    allVulnerabilities.addAll(secretVulns);

    // Module 2: MCP Security Scanner (0.30 -> 0.45)
    final mcpVulns = <Vulnerability>[];
    if (settings != null && !settings.enableMCPScanner) {
      emitLog('⊘ Module 2 SKIPPED: MCP Scanner disabled in user settings',
          type: 'INFO', module: 'MCP Security Engine', progress: 0.45);
    } else {
      emitLog('Initiating Module 2/6: Model Context Protocol (MCP) Scanner...',
          type: 'SCANNING', module: 'MCP Security Engine', progress: 0.35);
      for (final entry in fileContents.entries) {
        final found = _mcpScanner.scanContent(entry.value, entry.key);
        if (found.isNotEmpty) {
          mcpVulns.addAll(found);
          emitLog('⚠ MCP WARNING — ${found.first.title} in ${entry.key}',
              type: 'FOUND', module: 'MCP Security Engine', progress: 0.40);
        }
      }
      if (mcpVulns.isEmpty) {
        emitLog('✓ Module 2 PASS: All MCP tool bridges conform to security boundary',
            type: 'PASS', module: 'MCP Security Engine', progress: 0.45);
      }
    }
    allVulnerabilities.addAll(mcpVulns);

    // Module 3: Dependency Security (0.45 -> 0.65)
    final depVulns = <Vulnerability>[];
    if (settings != null && !settings.enableDependencyScanner) {
      emitLog('⊘ Module 3 SKIPPED: Dependency Auditor disabled in user settings',
          type: 'INFO', module: 'Dependency Auditor', progress: 0.65);
    } else {
      emitLog('Initiating Module 3/6: Dependency Manifest Scanner & OSV.dev audit...',
          type: 'SCANNING', module: 'Dependency Auditor', progress: 0.50);
      String? pubspecContent = fileContents['pubspec.yaml'] ??
          fileContents.entries.firstWhere((e) => e.key.endsWith('pubspec.yaml'), orElse: () => const MapEntry('', '')).value;
      String? packageJsonContent = fileContents['package.json'] ??
          fileContents.entries.firstWhere((e) => e.key.endsWith('package.json'), orElse: () => const MapEntry('', '')).value;
      String? requirementsContent = fileContents['requirements.txt'] ??
          fileContents.entries.firstWhere((e) => e.key.endsWith('requirements.txt'), orElse: () => const MapEntry('', '')).value;

      final foundDeps = await _dependencyScanner.scanDependencies(
        pubspecContent: pubspecContent.isNotEmpty ? pubspecContent : null,
        packageJsonContent: packageJsonContent.isNotEmpty ? packageJsonContent : null,
        requirementsContent: requirementsContent.isNotEmpty ? requirementsContent : null,
      );
      if (foundDeps.isNotEmpty) {
        for (final v in foundDeps) {
          emitLog('⚠ CVE DETECTED — ${v.title}',
              type: 'FOUND', module: 'Dependency Auditor', progress: 0.60);
        }
        depVulns.addAll(foundDeps);
        allVulnerabilities.addAll(foundDeps);
      } else {
        emitLog('✓ Module 3 PASS: No known CVEs found in dependency manifest',
            type: 'PASS', module: 'Dependency Auditor', progress: 0.65);
      }
    }

    // Module 4: API Scanner (0.65 -> 0.75)
    emitLog('Initiating Module 4/6: API Surface & Protocol Scanner...',
        type: 'SCANNING', module: 'API Scanner', progress: 0.70);
    final apiVulns = <Vulnerability>[];
    for (final entry in fileContents.entries) {
      final found = _apiScanner.scanContent(entry.value, entry.key);
      if (found.isNotEmpty) {
        apiVulns.addAll(found);
      }
    }
    if (apiVulns.isNotEmpty) {
      emitLog('⚠ API WARNING — Found ${apiVulns.length} protocol/CORS flaws',
          type: 'FOUND', module: 'API Scanner', progress: 0.75);
      allVulnerabilities.addAll(apiVulns);
    } else {
      emitLog('✓ Module 4 PASS: Secure transport and origin policies confirmed',
          type: 'PASS', module: 'API Scanner', progress: 0.75);
    }

    // Module 5: Threat Detector (0.75 -> 0.85)
    emitLog('Initiating Module 5/6: Static Threat & Injection Detector...',
        type: 'SCANNING', module: 'Threat Detector', progress: 0.80);
    final threatVulns = <Vulnerability>[];
    for (final entry in fileContents.entries) {
      final found = _threatDetector.scanContent(entry.value, entry.key);
      if (found.isNotEmpty) {
        threatVulns.addAll(found);
      }
    }
    if (threatVulns.isNotEmpty) {
      emitLog('⚠ THREAT VECTOR — ${threatVulns.length} code execution or SQL vectors flagged',
          type: 'FOUND', module: 'Threat Detector', progress: 0.85);
      allVulnerabilities.addAll(threatVulns);
    } else {
      emitLog('✓ Module 5 PASS: No raw code injection or unsafe primitives detected',
          type: 'PASS', module: 'Threat Detector', progress: 0.85);
    }

    // Module 6: Prompt Firewall (0.85 -> 0.95)
    final promptVulns = <Vulnerability>[];
    if (settings != null && !settings.enableAIFirewall) {
      emitLog('⊘ Module 6 SKIPPED: AI Prompt Firewall disabled in user settings',
          type: 'INFO', module: 'AI Prompt Firewall', progress: 0.95);
    } else {
      emitLog('Initiating Module 6/6: AI Prompt Firewall & Jailbreak Analyzer...',
          type: 'SCANNING', module: 'AI Prompt Firewall', progress: 0.90);
      for (final entry in fileContents.entries) {
        final found = _promptFirewall.scanPromptOrCode(entry.value, entry.key);
        if (found.isNotEmpty) {
          promptVulns.addAll(found);
        }
      }
      if (promptVulns.isNotEmpty) {
        emitLog('⚠ PROMPT RISK — ${promptVulns.length} potential jailbreak vectors flagged',
            type: 'FOUND', module: 'AI Prompt Firewall', progress: 0.93);
        allVulnerabilities.addAll(promptVulns);
      } else {
        emitLog('✓ Module 6 PASS: System prompts and LLM interfaces sanitized',
            type: 'PASS', module: 'AI Prompt Firewall', progress: 0.95);
      }
    }

    // Module 7: Firebase Security Rules & Cloud Infrastructure Config
    final configVulns = <Vulnerability>[];
    for (final entry in fileContents.entries) {
      configVulns.addAll(_firebaseRulesScanner.scanContent(entry.value, entry.key));
      configVulns.addAll(_cloudConfigScanner.scanContent(entry.value, entry.key));
    }
    if (configVulns.isNotEmpty) {
      emitLog('⚠ CLOUD/FIREBASE MISCONFIG — ${configVulns.length} infrastructure vulnerabilities flagged',
          type: 'FOUND', module: 'Cloud Auditor', progress: 0.98);
      allVulnerabilities.addAll(configVulns);
    } else {
      emitLog('✓ Module 7 PASS: Firebase rules & infrastructure configs verified',
          type: 'PASS', module: 'Cloud Auditor', progress: 0.98);
    }

    // Calculate score
    final score = calculateSecurityScore(allVulnerabilities);
    final deployStatus = score >= 70 ? 'SAFE_TO_DEPLOY' : 'NOT_SAFE';

    emitLog(
      'Scan analysis complete. Security Score: $score/100 ($deployStatus)',
      type: 'COMPLETE',
      module: 'Kernel Analyzer',
      progress: 1.0,
    );

    return ScanResult(
      projectName: projectName,
      targetUrlOrPath: targetPathOrUrl,
      securityScore: score,
      vulnerabilities: allVulnerabilities,
      secretsDetected: secretVulns.isNotEmpty,
      mcpSecure: mcpVulns.isEmpty,
      promptInjectionSafe: promptVulns.isEmpty,
      dependenciesSafe: depVulns.isEmpty,
      apiSecure: apiVulns.isEmpty,
      deployStatus: deployStatus,
      logs: logs,
    );
  }

  Future<ScanResult> runScanOnGitHubRepo({
    required String repoUrl,
    ScanProgressCallback? onProgress,
    SettingsState? settings,
  }) async {
    final parsed = _githubService.parseRepoUrl(repoUrl);
    if (parsed == null) {
      throw Exception('Invalid GitHub repository URL. Format: github.com/owner/repo');
    }

    if (onProgress != null) {
      onProgress(
        progress: 0.05,
        currentModule: 'GitHub Client',
        currentAction: 'Resolving repository tree for ${parsed.owner}/${parsed.repo}...',
        logLine: '[${DateTime.now().toIso8601String().substring(11, 19)}] Connecting to GitHub REST API...',
        logType: 'INFO',
      );
    }

    final allTreeFiles = await _githubService.listAllFiles(parsed.owner, parsed.repo);

    // Filter out binary assets, dependency vendor trees, and build output clutter
    final filtered = allTreeFiles.where((f) {
      final p = f.path.toLowerCase();
      if (p.contains('node_modules/') ||
          p.contains('.dart_tool/') ||
          p.contains('.git/') ||
          p.contains('build/') ||
          p.contains('dist/') ||
          p.contains('.gradle/') ||
          p.contains('ios/pods/')) {
        return false;
      }
      return p.endsWith('.dart') ||
          p.endsWith('.js') ||
          p.endsWith('.jsx') ||
          p.endsWith('.ts') ||
          p.endsWith('.tsx') ||
          p.endsWith('.py') ||
          p.endsWith('.go') ||
          p.endsWith('.java') ||
          p.endsWith('.php') ||
          p.endsWith('.rb') ||
          p.endsWith('.sh') ||
          p.endsWith('.json') ||
          p.endsWith('.yaml') ||
          p.endsWith('.yml') ||
          p.endsWith('.env') ||
          p.contains('.env') ||
          p.endsWith('.txt');
    }).toList();

    // Sort by security inspection priority
    filtered.sort((a, b) {
      final aScore = _getFilePriorityScore(a.path);
      final bScore = _getFilePriorityScore(b.path);
      return bScore.compareTo(aScore); // Higher priority first
    });

    final eligibleFiles = filtered.take(60).toList();

    final Map<String, String> fileContents = {};
    for (int i = 0; i < eligibleFiles.length; i++) {
      final f = eligibleFiles[i];
      if (onProgress != null) {
        onProgress(
          progress: 0.05 + (0.15 * (i / max(1, eligibleFiles.length))),
          currentModule: 'GitHub Ingestion',
          currentAction: 'Fetching ${f.path}...',
          logLine: '[${DateTime.now().toIso8601String().substring(11, 19)}] Ingesting ${f.path}',
          logType: 'INFO',
        );
      }

      // Respect rate limiting toggle (defaults to true for GitHub API safety)
      if (settings?.enableRateLimiting ?? true) {
        await Future.delayed(const Duration(milliseconds: 200));
      }

      final content = await _githubService.fetchFileContent(parsed.owner, parsed.repo, f.path);
      if (content.isNotEmpty) {
        fileContents[f.path] = content;
      }
    }

    return runScanOnFiles(
      projectName: '${parsed.owner}/${parsed.repo}',
      targetPathOrUrl: repoUrl,
      fileContents: fileContents,
      onProgress: onProgress,
      settings: settings,
    );
  }

  int _getFilePriorityScore(String path) {
    final p = path.toLowerCase();
    // Rank 1: Manifests, Environment & Configurations
    if (p.endsWith('.env') || p.contains('.env.') || p.contains('secret') || p.contains('credential')) return 100;
    if (p.endsWith('pubspec.yaml') || p.endsWith('package.json') || p.endsWith('requirements.txt')) return 90;
    if (p.contains('config') || p.contains('settings') || p.contains('mcp') || p.contains('docker-compose')) return 80;
    // Rank 2: Core source directories
    if (p.startsWith('lib/') || p.startsWith('src/') || p.startsWith('server/') || p.startsWith('app/') || p.startsWith('tools/') || p.startsWith('routes/')) return 70;
    // Rank 3: Root code files
    if (!p.contains('/')) return 60;
    return 10;
  }

  int calculateSecurityScore(List<Vulnerability> vulnerabilities) {
    if (vulnerabilities.isEmpty) return 100;

    int score = 100;
    int criticalCount = vulnerabilities.where((v) => v.severity == 'CRITICAL').length;
    int highCount = vulnerabilities.where((v) => v.severity == 'HIGH').length;
    int mediumCount = vulnerabilities.where((v) => v.severity == 'MEDIUM').length;
    int lowCount = vulnerabilities.where((v) => v.severity == 'LOW').length;

    // Deductions per specification:
    // -30 for each CRITICAL (max deduction: 60)
    int criticalDeduction = min(60, criticalCount * 30);
    // -15 for each HIGH (max deduction: 45)
    int highDeduction = min(45, highCount * 15);
    // -5 for each MEDIUM (max deduction: 20)
    int mediumDeduction = min(20, mediumCount * 5);
    // -2 for each LOW (max deduction: 10)
    int lowDeduction = min(10, lowCount * 2);

    score -= (criticalDeduction + highDeduction + mediumDeduction + lowDeduction);

    return max(0, score);
  }
}
