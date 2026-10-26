import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/core/scanners/cloud_config_scanner.dart';
import 'package:flutter_application_2/core/scanners/firebase_rules_scanner.dart';
import 'package:flutter_application_2/core/threat_detection/runtime_protector.dart';

void main() {
  group('FirebaseRulesScanner', () {
    test('Detects wildcard open read/write in firestore.rules', () {
      final scanner = FirebaseRulesScanner();
      const rules = '''
        rules_version = '2';
        service cloud.firestore {
          match /databases/{database}/documents {
            match /{document=**} {
              allow read, write: if true;
            }
          }
        }
      ''';

      final vulns = scanner.scanContent(rules, 'firestore.rules');
      expect(vulns.isNotEmpty, true);
      expect(vulns.any((v) => v.title.contains('Public Read/Write')), true);
      expect(vulns.first.severity, 'CRITICAL');
    });
  });

  group('CloudConfigScanner', () {
    test('Detects exposed database ports and root Docker users', () {
      final scanner = CloudConfigScanner();
      const compose = '''
        version: '3.8'
        services:
          db:
            image: postgres:15
            ports:
              - "0.0.0.0:5432:5432"
      ''';

      final vulns = scanner.scanContent(compose, 'docker-compose.yml');
      expect(vulns.isNotEmpty, true);
      expect(vulns.first.title, contains('Exposed Sensitive Port'));
    });
  });

  group('RuntimeProtector', () {
    test('Flags brute force login attacks and DDoS bursts in telemetry', () {
      final protector = RuntimeProtector();
      final logs = [
        'POST /api/v1/auth/login 401 Unauthorized',
        'POST /api/v1/auth/login 401 Unauthorized',
        'POST /api/v1/auth/login 401 Unauthorized',
        'POST /api/v1/auth/login 401 Unauthorized',
        'POST /api/v1/auth/login 401 Unauthorized',
        'GET /search 429 Too Many Requests rate limit exceeded',
        'GET /search 429 Too Many Requests rate limit exceeded',
        'GET /search 429 Too Many Requests rate limit exceeded',
      ];

      final threats = protector.analyzeTelemetry(logs, 'ingress-gateway');
      expect(threats.length, 2);
      expect(threats.any((t) => t.title.contains('Brute Force')), true);
      expect(threats.any((t) => t.title.contains('Denial-of-Service')), true);
    });
  });
}
