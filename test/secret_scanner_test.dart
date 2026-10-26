import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/core/scanners/secret_scanner.dart';

void main() {
  group('SecretScanner', () {
    late SecretScanner scanner;

    setUp(() {
      scanner = SecretScanner();
    });

    test('Detects exposed OpenAI API keys', () {
      const code = 'final key = "sk-proj-abcdef1234567890abcdef1234567890";';
      final results = scanner.scanSourceCode(code, 'lib/config.dart');

      expect(results.length, 1);
      expect(results.first.title, contains('OpenAI Key'));
      expect(results.first.severity, 'CRITICAL');
      expect(results.first.location, 'lib/config.dart:1');
    });

    test('Detects exposed AWS Access and Secret Keys', () {
      const code = '''
        const awsKey = "AKIAIOSFODNN7EXAMPLE";
        const awsSecret = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY";
      ''';
      final results = scanner.scanSourceCode(code, 'server/aws.js');

      expect(results.length, 2);
      expect(results.any((r) => r.title.contains('AWS Access Key')), true);
      expect(results.any((r) => r.title.contains('AWS Secret Key')), true);
    });

    test('Detects hardcoded Database URLs and JWT secrets', () {
      const code = '''
        final db = "postgres://root:password123@prod-db.internal:5432/main";
        final jwtSecret = "supersecretkey999";
      ''';
      final results = scanner.scanSourceCode(code, 'backend/env.py');

      expect(results.length, 2);
      expect(results.any((r) => r.title.contains('Database URL')), true);
      expect(results.any((r) => r.title.contains('JWT Secret')), true);
    });

    test('Returns zero vulnerabilities for clean code', () {
      const cleanCode = '''
        import 'package:flutter_dotenv/flutter_dotenv.dart';
        final key = dotenv.get('API_KEY');
      ''';
      final results = scanner.scanSourceCode(cleanCode, 'lib/main.dart');

      expect(results, isEmpty);
    });
  });
}
