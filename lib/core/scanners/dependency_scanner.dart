import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:yaml/yaml.dart';
import '../../data/models/vulnerability.dart';
import '../../services/osv_service.dart';

class DependencyScanner {
  final OSVService _osvService;
  final _uuid = const Uuid();

  DependencyScanner({OSVService? osvService})
      : _osvService = osvService ?? OSVService();

  Future<List<Vulnerability>> scanDependencies({
    String? pubspecContent,
    String? packageJsonContent,
    String? requirementsContent,
  }) async {
    final List<OSVPackageQuery> queries = [];
    final List<Vulnerability> vulnerabilities = [];

    // 1. Parse pubspec.yaml (Flutter / Dart)
    if (pubspecContent != null && pubspecContent.isNotEmpty) {
      try {
        final doc = loadYaml(pubspecContent);
        if (doc is YamlMap) {
          final deps = doc['dependencies'];
          if (deps is YamlMap) {
            for (final entry in deps.entries) {
              final pkgName = entry.key.toString();
              if (pkgName == 'flutter') continue;
              final val = entry.value;
              String? version;
              if (val is String) {
                version = val.replaceAll('^', '').replaceAll('>=', '').trim();
              }
              queries.add(
                OSVPackageQuery(
                  name: pkgName,
                  ecosystem: 'Pub',
                  version: version,
                ),
              );
            }
          }
        }
      } catch (_) {}
    }

    // 2. Parse package.json (Node.js)
    if (packageJsonContent != null && packageJsonContent.isNotEmpty) {
      try {
        final decoded = json.decode(packageJsonContent);
        if (decoded is Map<String, dynamic>) {
          final deps = decoded['dependencies'];
          if (deps is Map<String, dynamic>) {
            for (final entry in deps.entries) {
              final version = entry.value.toString().replaceAll('^', '').replaceAll('~', '').trim();
              queries.add(
                OSVPackageQuery(
                  name: entry.key,
                  ecosystem: 'npm',
                  version: version,
                ),
              );
            }
          }
        }
      } catch (_) {}
    }

    // 3. Parse requirements.txt (Python)
    if (requirementsContent != null && requirementsContent.isNotEmpty) {
      final lines = requirementsContent.split('\n');
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
        if (trimmed.contains('==')) {
          final parts = trimmed.split('==');
          queries.add(
            OSVPackageQuery(
              name: parts[0].trim(),
              ecosystem: 'PyPI',
              version: parts[1].trim(),
            ),
          );
        } else if (trimmed.contains('>=')) {
          final parts = trimmed.split('>=');
          queries.add(
            OSVPackageQuery(
              name: parts[0].trim(),
              ecosystem: 'PyPI',
              version: parts[1].trim(),
            ),
          );
        } else {
          final name = trimmed.split(RegExp(r'[<>=~]'))[0].trim();
          if (name.isNotEmpty) {
            queries.add(
              OSVPackageQuery(
                name: name,
                ecosystem: 'PyPI',
              ),
            );
          }
        }
      }
    }

    if (queries.isEmpty) return [];

    // Query OSV in batch
    final osvResults = await _osvService.queryBatch(queries);

    for (final entry in osvResults.entries) {
      for (final vuln in entry.value) {
        final aliasStr = vuln.aliases.isNotEmpty ? ' (${vuln.aliases.join(', ')})' : '';
        vulnerabilities.add(
          Vulnerability(
            id: _uuid.v4(),
            title: '${vuln.id}$aliasStr in ${entry.key}',
            severity: vuln.severity,
            category: 'Vulnerable Dependency',
            description: vuln.summary.isNotEmpty ? vuln.summary : vuln.details,
            location: 'Manifest dependency: ${entry.key}',
            codeSnippet: entry.key,
            fix: vuln.fixedVersion != null
                ? 'Upgrade ${entry.key.split('@')[0]} to version >= ${vuln.fixedVersion}'
                : 'Check upstream security advisories for patched versions.',
            detectedAt: DateTime.now(),
          ),
        );
      }
    }

    return vulnerabilities;
  }
}
