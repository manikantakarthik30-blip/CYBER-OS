import 'package:uuid/uuid.dart';
import '../../data/models/vulnerability.dart';

class APIScanner {
  final _uuid = const Uuid();

  static final Map<String, (RegExp, String, String)> apiPatterns = {
    'Unencrypted HTTP Protocol': (
      RegExp(r'http:\/\/(?!localhost|127\.0\.0\.1|0\.0\.0\.0)[a-zA-Z0-9_\-\.]+', caseSensitive: false),
      'MEDIUM',
      'Upgrade cleartext HTTP connections to HTTPS with TLS 1.3 encryption.'
    ),
    'Permissive CORS Wildcard': (
      RegExp(r'(Access-Control-Allow-Origin.*?\*|cors\s*\(\s*\{\s*origin\s*:\s*["\x27]\*["\x27]\s*\}\s*\))', caseSensitive: false),
      'MEDIUM',
      'Restrict CORS headers to explicit trusted origins rather than wildcard (*).'
    ),
    'Disabled SSL Certificate Verification': (
      RegExp(r'(rejectUnauthorized\s*:\s*false|badCertificateCallback|verify\s*=\s*False|NODE_TLS_REJECT_UNAUTHORIZED\s*=\s*["\x27]0["\x27])', caseSensitive: false),
      'CRITICAL',
      'Never disable TLS certificate validation in production. Remove certificate bypass callbacks.'
    ),
    'Hardcoded Administrative Route': (
      RegExp(r'["\x27]\/api\/v1\/admin\/(override|dump|delete-all)["\x27]', caseSensitive: false),
      'HIGH',
      'Ensure high-privilege administrative endpoints are strictly gated by multi-factor role authorization.'
    ),
  };

  List<Vulnerability> scanContent(String content, String filePath) {
    final List<Vulnerability> vulnerabilities = [];
    final lines = content.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineNumber = i + 1;

      for (final entry in apiPatterns.entries) {
        final title = entry.key;
        final (regex, severity, fixRecommendation) = entry.value;

        if (regex.hasMatch(line)) {
          vulnerabilities.add(
            Vulnerability(
              id: _uuid.v4(),
              title: title,
              severity: severity,
              category: 'API Security',
              description:
                  'Found insecure API pattern ($title) on line $lineNumber.',
              location: '$filePath:$lineNumber',
              codeSnippet: line.trim(),
              fix: fixRecommendation,
              detectedAt: DateTime.now(),
            ),
          );
        }
      }
    }

    return vulnerabilities;
  }
}
