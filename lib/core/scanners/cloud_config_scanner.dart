import 'package:uuid/uuid.dart';
import '../../data/models/vulnerability.dart';

class CloudConfigScanner {
  final _uuid = const Uuid();

  static final List<(RegExp, String, String, String, String)> configPatterns = [
    (
      RegExp(r'0\.0\.0\.0:(22|3306|5432|27017|6379|9200)\b'),
      'Publicly Exposed Sensitive Port',
      'CRITICAL',
      'Cloud Architecture',
      'Bind sensitive database or management ports to 127.0.0.1 or a private VPC network.'
    ),
    (
      RegExp(r'acl\s*=\s*["\x27](public-read|public-read-write)["\x27]', caseSensitive: false),
      'Public S3 Bucket ACL Configuration',
      'CRITICAL',
      'Cloud Architecture',
      'Enforce Block Public Access and configure granular IAM bucket policies.'
    ),
    (
      RegExp(r'privileged\s*:\s*true', caseSensitive: false),
      'Privileged Container Execution',
      'HIGH',
      'Cloud Architecture',
      'Avoid running containers in privileged mode; grant granular Linux capabilities instead.'
    ),
    (
      RegExp(r'["\x27]Action["\x27]\s*:\s*["\x27]\*["\x27].*?["\x27]Resource["\x27]\s*:\s*["\x27]\*["\x27]', caseSensitive: false),
      'Wildcard Administrator IAM Policy',
      'CRITICAL',
      'Cloud Architecture',
      'Follow the principle of least privilege: scope IAM actions and resources to explicit ARNs.'
    ),
    (
      RegExp(r'USER\s+root\b', caseSensitive: false),
      'Root Container User Execution',
      'MEDIUM',
      'Cloud Architecture',
      'Create and switch to a non-root application user in the Dockerfile.'
    ),
  ];

  List<Vulnerability> scanContent(String content, String filePath) {
    final lower = filePath.toLowerCase();
    final isConfigFile = lower.endsWith('.tf') ||
        lower.endsWith('.yml') ||
        lower.endsWith('.yaml') ||
        lower.contains('dockerfile') ||
        lower.contains('compose') ||
        lower.contains('serverless');

    if (!isConfigFile) {
      return [];
    }

    final List<Vulnerability> vulnerabilities = [];
    final lines = content.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineNumber = i + 1;

      for (final (regex, title, severity, category, fix) in configPatterns) {
        if (regex.hasMatch(line)) {
          vulnerabilities.add(
            Vulnerability(
              id: _uuid.v4(),
              title: title,
              severity: severity,
              category: category,
              description: 'Cloud misconfiguration pattern flagged in $filePath at line $lineNumber.',
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
