import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/core/scanners/dependency_scanner.dart';
import 'package:flutter_application_2/services/osv_service.dart';

class MockOSVService extends OSVService {
  @override
  Future<Map<String, List<OSVVulnerabilityDetail>>> queryBatch(
    List<OSVPackageQuery> queries,
  ) async {
    if (queries.isEmpty) return {};
    final pkg = queries.first.name;
    return {
      pkg: [
        OSVVulnerabilityDetail(
          id: 'GHSA-fake-cve-1234',
          summary: 'Arbitrary file write vulnerability in demo package',
          details: 'Detailed CVE advisory',
          severity: 'CRITICAL',
          aliases: ['CVE-2023-99999'],
        ),
      ],
    };
  }
}

void main() {
  group('DependencyScanner', () {
    test('Correctly parses pubspec.yaml and returns CVEs from OSV service', () async {
      final scanner = DependencyScanner(osvService: MockOSVService());

      const pubspec = '''
name: sample_app
dependencies:
  dio: ^5.4.3
  archive: ^3.6.1
''';

      final results = await scanner.scanDependencies(pubspecContent: pubspec);

      expect(results.isNotEmpty, true);
      expect(results.first.title, contains('GHSA-fake-cve-1234'));
      expect(results.first.severity, 'CRITICAL');
      expect(results.first.category, 'Vulnerable Dependency');
    });

    test('Correctly parses package.json and requirements.txt', () async {
      final scanner = DependencyScanner(osvService: MockOSVService());

      const packageJson = '''
{
  "dependencies": {
    "express": "^4.18.2"
  }
}
''';
      const requirementsTxt = '''
requests==2.28.1
flask==2.2.2
''';

      final results = await scanner.scanDependencies(
        packageJsonContent: packageJson,
        requirementsContent: requirementsTxt,
      );

      expect(results.isNotEmpty, true);
      expect(results.first.title, contains('GHSA-fake-cve-1234'));
    });

    test('Handles empty manifests gracefully', () async {
      final scanner = DependencyScanner(osvService: MockOSVService());
      final results = await scanner.scanDependencies();
      expect(results, isEmpty);
    });
  });
}
