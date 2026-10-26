import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/core/security_engine/security_engine.dart';
import 'package:flutter_application_2/data/models/vulnerability.dart';

void main() {
  group('SecurityEngine', () {
    late SecurityEngine engine;

    setUp(() {
      engine = SecurityEngine();
    });

    test('Score calculation: Perfect 100 on clean repo', () {
      final score = engine.calculateSecurityScore([]);
      expect(score, 100);
    });

    test('Score calculation: Deducts per severity rules and caps deductions', () {
      final vulns = [
        Vulnerability(
          id: '1',
          title: 'Critical Secret',
          severity: 'CRITICAL',
          description: 'desc',
          location: 'lib/main.dart:1',
          fix: 'fix',
          detectedAt: DateTime.now(),
        ),
        Vulnerability(
          id: '2',
          title: 'High MCP execution',
          severity: 'HIGH',
          description: 'desc',
          location: 'lib/main.dart:2',
          fix: 'fix',
          detectedAt: DateTime.now(),
        ),
        Vulnerability(
          id: '3',
          title: 'Medium CORS header',
          severity: 'MEDIUM',
          description: 'desc',
          location: 'lib/main.dart:3',
          fix: 'fix',
          detectedAt: DateTime.now(),
        ),
      ];

      // 100 - 30 (CRITICAL) - 15 (HIGH) - 5 (MEDIUM) = 50
      final score = engine.calculateSecurityScore(vulns);
      expect(score, 50);
    });

    test('Full runScanOnFiles executes multiple modules and returns deploy verdict', () async {
      final files = {
        'lib/secrets.dart': 'const token = "ghp_123456789012345678901234567890123456";',
        'server/api.js': 'res.setHeader("Access-Control-Allow-Origin", "*");',
        'tools/agent.py': 'exec(untrusted_code)',
      };

      final result = await engine.runScanOnFiles(
        projectName: 'vibe-project',
        targetPathOrUrl: 'local',
        fileContents: files,
      );

      expect(result.projectName, 'vibe-project');
      expect(result.secretsDetected, true);
      expect(result.mcpSecure, false);
      expect(result.vulnerabilities.length, greaterThanOrEqualTo(3));
      expect(result.deployStatus, 'NOT_SAFE');
      expect(result.logs.isNotEmpty, true);
    });
  });
}
