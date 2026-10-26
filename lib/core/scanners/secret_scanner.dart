import 'package:uuid/uuid.dart';
import '../../data/models/vulnerability.dart';

class SecretScanner {
  final _uuid = const Uuid();

  static final Map<String, RegExp> secretPatterns = {
    'OpenAI API Key': RegExp(r'sk-[a-zA-Z0-9_\-]{20,}'),
    'Google / Gemini API Key': RegExp(r'AIza[0-9A-Za-z\-_]{35}'),
    'AWS Access Key': RegExp(r'AKIA[0-9A-Z]{16}'),
    'AWS Secret Key': RegExp(r'(aws_secret_access_key|aws_secret)\s*[:=]\s*["\x27][A-Za-z0-9/+=]{40}["\x27]', caseSensitive: false),
    'GitHub Token': RegExp(r'(ghp|gho|ghu|ghs|ghr)_[a-zA-Z0-9]{36}'),
    'GitHub Fine-Grained PAT': RegExp(r'github_pat_[a-zA-Z0-9_]{50,}'),
    'Anthropic API Key': RegExp(r'sk-ant-[a-zA-Z0-9\-_]{30,}'),
    'Stripe Secret Key': RegExp(r'(sk_live|rk_live|sk_test)_[0-9a-zA-Z]{24,}'),
    'Slack Bot/User Token': RegExp(r'xox[baprs]-[0-9]{10,13}-[0-9]{10,13}-[a-zA-Z0-9]{24,}'),
    'Twilio API Key': RegExp(r'SK[0-9a-fA-F]{32}'),
    'Database Connection String': RegExp(r"(mysql|postgres|postgresql|mongodb|mongodb\+srv|redis|sqlite|mssql)\:\/\/[^\s\x22\x27`]+"),
    'Private Key Header': RegExp(r'-----BEGIN (RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----'),
    'JWT Secret / Key': RegExp(r'jwt[_\s-]?secret["\s]*[:=]["\s]*[a-zA-Z0-9_\-]{8,}', caseSensitive: false),
    'Hardcoded Secret / Token Assignment': RegExp(
      r'(api_key|secret_key|auth_token|access_token|client_secret|api_secret|app_secret|private_key)\s*[:=]\s*["\x27][a-zA-Z0-9_\-]{12,}["\x27]',
      caseSensitive: false,
    ),
    'Hardcoded Password Assignment': RegExp(
      r'(password|passwd|db_pass|user_password|admin_pass)\s*[:=]\s*["\x27][^"\x27\s]{6,}["\x27]',
      caseSensitive: false,
    ),
    'Firebase Config with API Key': RegExp(r'apiKey:\s*["\x27]AIza[0-9A-Za-z\-_]{35}["\x27]'),
  };

  List<Vulnerability> scanSourceCode(String content, String filePath) {
    final List<Vulnerability> vulnerabilities = [];
    final lines = content.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineNumber = i + 1;

      // Skip comments or example files if desired, but flag obvious keys
      for (final entry in secretPatterns.entries) {
        final patternName = entry.key;
        final regex = entry.value;

        if (regex.hasMatch(line)) {
          // Extract masked preview
          final match = regex.firstMatch(line);
          final matchedStr = match != null ? match.group(0) ?? '' : '';
          final masked = _maskSecret(matchedStr);

          vulnerabilities.add(
            Vulnerability(
              id: _uuid.v4(),
              title: 'Hardcoded $patternName Detected',
              severity: 'CRITICAL',
              category: 'Secret Detection',
              description:
                  'Exposed $patternName ($masked) found in source code. Hardcoded credentials can be extracted from compiled binaries or commit history.',
              location: '$filePath:$lineNumber',
              codeSnippet: line.trim(),
              fix:
                  'Move secret to .env file and load via flutter_dotenv, or inject via environment secrets in your CI/CD pipeline.',
              detectedAt: DateTime.now(),
            ),
          );
        }
      }
    }

    return vulnerabilities;
  }

  String _maskSecret(String secret) {
    if (secret.length <= 8) return '****';
    final prefix = secret.substring(0, 4);
    final suffix = secret.substring(secret.length - 4);
    return '$prefix...$suffix';
  }
}
