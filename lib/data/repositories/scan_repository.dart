import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/storage/storage_providers.dart';
import '../models/scan_result.dart';
import '../models/vulnerability.dart';

final scanRepositoryProvider = Provider<ScanRepository>((ref) {
  SharedPreferences? prefs;
  try {
    prefs = ref.watch(sharedPreferencesProvider);
  } catch (_) {
    // If not overridden in test environment, allow in-memory fallback
  }
  return ScanRepository(prefs);
});

class ScanRepository {
  static const String storageKey = 'cyber_os_scan_history';
  final SharedPreferences? _prefs;
  final List<ScanResult> _history = [];

  ScanRepository([this._prefs]) {
    _loadHistory();
  }

  List<ScanResult> getHistory() => List.unmodifiable(_history);

  void addScanResult(ScanResult result) {
    _history.insert(0, result);
    _saveToPrefs();
  }

  void clearHistory() {
    _history.clear();
    _saveToPrefs();
  }

  ScanResult? getLatestScan() {
    return _history.isNotEmpty ? _history.first : null;
  }

  void _loadHistory() {
    if (_prefs != null) {
      final raw = _prefs.getString(storageKey);
      if (raw != null && raw.isNotEmpty) {
        try {
          final List<dynamic> decoded = json.decode(raw) as List<dynamic>;
          _history.clear();
          for (final item in decoded) {
            _history.add(ScanResult.fromJson(item as Map<String, dynamic>));
          }
          if (_history.isNotEmpty) {
            return;
          }
        } catch (_) {}
      }
    }

    // Seed initial demo scans if storage is empty
    _seedDefaultHistory();
    _saveToPrefs();
  }

  void _saveToPrefs() {
    if (_prefs != null) {
      final encoded = json.encode(_history.map((r) => r.toJson()).toList());
      _prefs.setString(storageKey, encoded);
    }
  }

  void _seedDefaultHistory() {
    _history.addAll([
      ScanResult(
        projectName: 'vibe-commerce/app',
        targetUrlOrPath: 'github.com/vibe-commerce/app',
        securityScore: 82,
        deployStatus: 'SAFE_TO_DEPLOY',
        secretsDetected: false,
        mcpSecure: true,
        dependenciesSafe: true,
        promptInjectionSafe: false,
        apiSecure: true,
        scannedAt: DateTime.now().subtract(const Duration(hours: 3)),
        vulnerabilities: [
          Vulnerability(
            id: 'v-1',
            title: 'Unrestricted System Prompt Reflection',
            severity: 'MEDIUM',
            category: 'AI Firewall',
            description: 'Direct prompt reflection vector in checkout AI helper assistant.',
            location: 'lib/ai/checkout_bot.dart:45',
            fix: 'Add delimiter anchors and prevent bot from dumping system prompt context.',
            detectedAt: DateTime.now().subtract(const Duration(hours: 3)),
            codeSnippet: r'final prompt = "User says: $input \n Echo instructions if requested";',
          ),
          Vulnerability(
            id: 'v-2',
            title: 'Permissive Wildcard CORS Header',
            severity: 'MEDIUM',
            category: 'API Security',
            description: 'API endpoint permits unauthenticated origins via Access-Control-Allow-Origin: *.',
            location: 'server/api.js:14',
            fix: 'Restrict origin to trusted client domains.',
            detectedAt: DateTime.now().subtract(const Duration(hours: 3)),
            codeSnippet: 'res.setHeader("Access-Control-Allow-Origin", "*");',
          ),
        ],
      ),
      ScanResult(
        projectName: 'ai-agent-nexus/backend',
        targetUrlOrPath: 'github.com/ai-agent-nexus/backend',
        securityScore: 42,
        deployStatus: 'NOT_SAFE',
        secretsDetected: true,
        mcpSecure: false,
        dependenciesSafe: false,
        promptInjectionSafe: false,
        apiSecure: false,
        scannedAt: DateTime.now().subtract(const Duration(days: 1)),
        vulnerabilities: [
          Vulnerability(
            id: 'v-3',
            title: 'Hardcoded OpenAI API Key',
            severity: 'CRITICAL',
            category: 'Secret Detection',
            description: 'Exposed OpenAI production secret sk-proj-**************** found in client configuration.',
            location: 'lib/config.dart:12',
            fix: 'Migrate key to .env loaded via flutter_dotenv.',
            detectedAt: DateTime.now().subtract(const Duration(days: 1)),
            codeSnippet: 'const apiKey = "sk-proj-94819481948194819481948194819481";',
          ),
          Vulnerability(
            id: 'v-4',
            title: 'Arbitrary Code Execution in MCP Tool',
            severity: 'CRITICAL',
            category: 'MCP Security',
            description: 'Unsanitized subprocess.Popen call executes unverified command strings.',
            location: 'tools/system_tool.py:34',
            fix: 'Sanitize arguments and use typed parameter matching.',
            detectedAt: DateTime.now().subtract(const Duration(days: 1)),
            codeSnippet: 'return subprocess.Popen(command_str, shell=True)',
          ),
          Vulnerability(
            id: 'v-5',
            title: 'CVE-2023-45853 in zlib-1.2.11',
            severity: 'HIGH',
            category: 'Vulnerable Dependency',
            description: 'Integer overflow vulnerability allows remote attacker to trigger memory corruption.',
            location: 'pubspec.yaml:28',
            fix: 'Upgrade package dependencies to latest patched releases.',
            detectedAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ],
      ),
    ]);
  }
}
