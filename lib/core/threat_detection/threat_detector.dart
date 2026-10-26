import 'package:uuid/uuid.dart';
import '../../data/models/vulnerability.dart';

class ThreatDetector {
  final _uuid = const Uuid();

  static final Map<String, (RegExp, String, String)> threatPatterns = {
    'SQL Injection Vulnerability': (
      RegExp(r'(SELECT|INSERT|UPDATE|DELETE|DROP|UNION)\s+.*?(FROM|INTO|SET|TABLE|WHERE).*?(\+|\$|\%s|\{|\bconcat\b)', caseSensitive: false),
      'CRITICAL',
      'Use parameterized queries or ORM prepared statements instead of string interpolation in SQL.'
    ),
    'Command / Shell Injection Vector': (
      RegExp(r'(child_process|execSync|os\.system|shell_exec|system\(|passthru).*?(\+|\$|req\.|params|input|args)', caseSensitive: false),
      'CRITICAL',
      'Never pass unsanitized user arguments to host shell commands. Use strict argument array execution.'
    ),
    'Direct Eval / Dynamic Code Execution': (
      RegExp(r'(\beval\s*\(|\bFunction\s*\([^)]*\)\s*\(|new\s+Function\(|vm\.runInThisContext)', caseSensitive: false),
      'CRITICAL',
      'Avoid dynamic code evaluation. Use static lookup tables or typed interpreters.'
    ),
    'Cross-Site Scripting (XSS) / Unsafe DOM Injection': (
      RegExp(r'(dangerouslySetInnerHTML|innerHTML\s*=|v-html\s*=|document\.write\()', caseSensitive: false),
      'HIGH',
      'Sanitize HTML inputs using DOMPurify or framework-native escaping before DOM rendering.'
    ),
    'Weak Cryptographic Hash Function': (
      RegExp(r'(createHash\s*\(\s*["\x27](md5|sha1)["\x27]\)|MD5\s*\(|SHA1\s*\(|CryptoJS\.MD5)', caseSensitive: false),
      'MEDIUM',
      'Upgrade deprecated MD5/SHA-1 hashing to SHA-256 or bcrypt/argon2 for password storage.'
    ),
    'Insecure Random Number Generator for Crypto': (
      RegExp(r'(Math\.random\(\)|Random\(\)\.nextInt|rand\(\))', caseSensitive: false),
      'MEDIUM',
      'Use cryptographically secure pseudorandom number generators (Random.secure() or crypto.getRandomValues).'
    ),
  };

  List<Vulnerability> scanContent(String content, String filePath) {
    final List<Vulnerability> vulnerabilities = [];
    final lines = content.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineNumber = i + 1;

      for (final entry in threatPatterns.entries) {
        final title = entry.key;
        final (regex, severity, fixRecommendation) = entry.value;

        if (regex.hasMatch(line)) {
          vulnerabilities.add(
            Vulnerability(
              id: _uuid.v4(),
              title: title,
              severity: severity,
              category: 'Threat Detection',
              description:
                  'Identified high-risk threat vector ($title) in $filePath on line $lineNumber.',
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
