import 'package:uuid/uuid.dart';
import '../../data/models/vulnerability.dart';

class RuntimeProtector {
  final _uuid = const Uuid();

  List<Vulnerability> analyzeTelemetry(List<String> logLines, String contextPath) {
    final List<Vulnerability> vulnerabilities = [];

    int authFailures = 0;
    int burstRequests = 0;

    for (final line in logLines) {
      final lower = line.toLowerCase();
      if ((lower.contains('401') || lower.contains('403') || lower.contains('unauthorized')) &&
          (lower.contains('login') || lower.contains('auth') || lower.contains('token'))) {
        authFailures++;
      }
      if (lower.contains('rate limit exceeded') ||
          lower.contains('too many requests') ||
          lower.contains('burst') ||
          lower.contains('flood')) {
        burstRequests++;
      }
    }

    if (authFailures >= 5) {
      vulnerabilities.add(
        Vulnerability(
          id: _uuid.v4(),
          title: 'Runtime Credential Stuffing / Brute Force Threat',
          severity: 'HIGH',
          category: 'Runtime Protection',
          description: 'Detected $authFailures failed authentication requests within short telemetry window.',
          location: contextPath,
          fix: 'Implement exponential backoff, IP lockout, and CAPTCHA challenge on authentication endpoints.',
          detectedAt: DateTime.now(),
        ),
      );
    }

    if (burstRequests >= 3) {
      vulnerabilities.add(
        Vulnerability(
          id: _uuid.v4(),
          title: 'Layer-7 Request Flood / Denial-of-Service Vector',
          severity: 'HIGH',
          category: 'Runtime Protection',
          description: 'Multiple burst thresholds or rate limiting saturation events detected in traffic log.',
          location: contextPath,
          fix: 'Deploy adaptive edge WAF throttling and distributed Cloudflare/Cloud Armor rate limiting.',
          detectedAt: DateTime.now(),
        ),
      );
    }

    return vulnerabilities;
  }
}
