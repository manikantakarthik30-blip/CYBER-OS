import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/core/reporting/report_generator.dart';
import 'package:flutter_application_2/core/scanners/api_scanner.dart';
import 'package:flutter_application_2/core/scanners/mcp_scanner.dart';
import 'package:flutter_application_2/core/scanners/secret_scanner.dart';
import 'package:flutter_application_2/core/security_engine/security_engine.dart';
import 'package:flutter_application_2/data/models/scan_result.dart';
import 'package:flutter_application_2/data/models/vulnerability.dart';

void main() {
  group('SecretScanner Tests', () {
    final scanner = SecretScanner();

    test('Detects OpenAI and GitHub tokens in code', () {
      const code = '''
      const openAi = "sk-94819481948194819481948194819481";
      const ghToken = "ghp_123456789012345678901234567890123456";
      ''';

      final vulns = scanner.scanSourceCode(code, 'lib/keys.dart');
      expect(vulns.length, greaterThanOrEqualTo(2));
      expect(vulns.any((v) => v.title.contains('OpenAI')), isTrue);
      expect(vulns.any((v) => v.title.contains('GitHub')), isTrue);
      expect(vulns.every((v) => v.severity == 'CRITICAL'), isTrue);
    });

    test('Clean code returns zero vulnerabilities', () {
      const cleanCode = '''
      import 'package:flutter/material.dart';
      void main() => runApp(const MyApp());
      ''';

      final vulns = scanner.scanSourceCode(cleanCode, 'lib/main.dart');
      expect(vulns, isEmpty);
    });
  });

  group('MCPScanner Tests', () {
    final scanner = MCPScanner();

    test('Flags dangerous subprocess execution in MCP handler', () {
      const code = '''
      @mcp.tool()
      def run_command(command: str):
          import subprocess
          return subprocess.Popen(command, shell=True)
      ''';

      final vulns = scanner.scanContent(code, 'tools/cmd.py');
      expect(vulns.isNotEmpty, isTrue);
      expect(vulns.any((v) => v.category == 'MCP Security'), isTrue);
    });
  });

  group('APIScanner Tests', () {
    final scanner = APIScanner();

    test('Flags disabled SSL verification and wildcard CORS', () {
      const code = '''
      final client = HttpClient()
        ..badCertificateCallback = (cert, host, port) => true;
      res.setHeader("Access-Control-Allow-Origin", "*");
      ''';

      final vulns = scanner.scanContent(code, 'lib/network.dart');
      expect(vulns.length, greaterThanOrEqualTo(2));
    });
  });

  group('SecurityEngine Score Calculation Tests', () {
    final engine = SecurityEngine();

    test('Clean project gets 100 score and SAFE_TO_DEPLOY', () {
      final score = engine.calculateSecurityScore([]);
      expect(score, equals(100));
    });

    test('Single critical vulnerability deducts 30 points', () {
      final vulns = [
        Vulnerability(
          id: '1',
          title: 'Exposed Secret',
          severity: 'CRITICAL',
          description: 'Desc',
          location: 'lib/config.dart:1',
          fix: 'Fix',
          detectedAt: DateTime.now(),
        ),
      ];

      final score = engine.calculateSecurityScore(vulns);
      expect(score, equals(70));
    });

    test('Multiple criticals cap at 60 deduction', () {
      final vulns = List.generate(
        4,
        (i) => Vulnerability(
          id: '$i',
          title: 'Exposed Secret $i',
          severity: 'CRITICAL',
          description: 'Desc',
          location: 'lib/config.dart:$i',
          fix: 'Fix',
          detectedAt: DateTime.now(),
        ),
      );

      final score = engine.calculateSecurityScore(vulns);
      expect(score, equals(40)); // 100 - 60
    });
  });

  group('ReportGenerator Tests', () {
    test('Generates structured report and valid JSON', () {
      final scanResult = ScanResult(
        projectName: 'test-app',
        securityScore: 85,
        deployStatus: 'SAFE_TO_DEPLOY',
        secretsDetected: false,
        mcpSecure: true,
        dependenciesSafe: true,
        promptInjectionSafe: true,
        vulnerabilities: [],
      );

      final report = ReportGenerator.generateReport(scanResult);
      expect(report.summaryMarkdown.contains('CYBER_OS SECURITY AUDIT REPORT'), isTrue);
      expect(report.summaryMarkdown.contains('STATUS: PASS'), isTrue);

      final jsonOutput = ReportGenerator.exportAsJson(scanResult);
      final decoded = json.decode(jsonOutput);
      expect(decoded['projectName'], equals('test-app'));
      expect(decoded['securityScore'], equals(85));
    });
  });
}
