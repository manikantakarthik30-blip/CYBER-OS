import 'package:uuid/uuid.dart';
import '../../data/models/vulnerability.dart';

class FirebaseRulesScanner {
  final _uuid = const Uuid();

  static final List<(RegExp, String, String, String, String)> rulesPatterns = [
    (
      RegExp(r'allow\s+(read\s*,\s*write|write\s*,\s*read)\s*:\s*if\s+true\s*;', caseSensitive: false),
      'Public Read/Write Firebase Rules Access',
      'CRITICAL',
      'Firebase Security',
      'Remove wildcard "if true;" grants. Require explicit authentication and schema validation checks.'
    ),
    (
      RegExp(r'allow\s+write\s*:\s*if\s+true\s*;', caseSensitive: false),
      'Unauthenticated Firestore/Storage Write Access',
      'CRITICAL',
      'Firebase Security',
      'Restrict write operations to authenticated user IDs matching the target resource document.'
    ),
    (
      RegExp(r'allow\s+read\s*:\s*if\s+true\s*;', caseSensitive: false),
      'Unauthenticated Public Data Exposure',
      'HIGH',
      'Firebase Security',
      'Enforce granular read permissions to prevent scraping of sensitive collections.'
    ),
    (
      RegExp(r'match\s+\/\{document=\*\*\}\s*\{\s*allow\s+write', caseSensitive: false),
      'Global Wildcard Write Permitted',
      'CRITICAL',
      'Firebase Security',
      'Scope match blocks strictly to explicit sub-collections rather than recursive wildcards.'
    ),
  ];

  List<Vulnerability> scanContent(String content, String filePath) {
    final lower = filePath.toLowerCase();
    if (!lower.endsWith('.rules') && !lower.contains('firestore') && !lower.contains('storage')) {
      return [];
    }

    final List<Vulnerability> vulnerabilities = [];
    final lines = content.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineNumber = i + 1;

      for (final (regex, title, severity, category, fix) in rulesPatterns) {
        if (regex.hasMatch(line)) {
          vulnerabilities.add(
            Vulnerability(
              id: _uuid.v4(),
              title: title,
              severity: severity,
              category: category,
              description: 'Insecure Firebase Security Rule identified in $filePath on line $lineNumber.',
              location: '$filePath:$lineNumber',
              codeSnippet: line.trim(),
              fix: fix,
              detectedAt: DateTime.now(),
            ),
          );
        }
      }
    }

    return vulnerabilities;
  }
}
