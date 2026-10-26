import 'package:uuid/uuid.dart';
import '../../data/models/vulnerability.dart';

class MCPScanner {
  final _uuid = const Uuid();

  static final Map<String, (RegExp, String, String)> mcpPatterns = {
    'Unrestricted MCP Tool Exposure': (
      RegExp(r'(@mcp\.tool|mcp_server|tool_handler|@tool).*?(dangerous|unrestricted|raw_system|shell|cmd|exec|eval)', caseSensitive: false),
      'HIGH',
      'Ensure strict parameter schema validation and confirmation gates for high-privilege MCP tool calls.'
    ),
    'Arbitrary Code / Process Execution in Tool Handler': (
      RegExp(r'(exec\s*\(|eval\s*\(|subprocess\.(Popen|run|call|check_output)|Process\.(start|run|runSync)|Runtime\.getRuntime\(\)\.exec|child_process\.(exec|execSync|spawn)|os\.system\(|os\.popen\()', caseSensitive: false),
      'CRITICAL',
      'Sanitize all command parameters and eliminate raw shell execution inside MCP handlers.'
    ),
    'Unauthenticated Public MCP Server': (
      RegExp(r'(mcp_server.*public\s*=\s*true|allow_anonymous\s*=\s*true|auth_required\s*=\s*false|security\s*:\s*\[\s*\])', caseSensitive: false),
      'HIGH',
      'Enable mandatory mutual authentication or scoped bearer tokens on MCP server endpoints.'
    ),
    'Potential Data Exfiltration in Tool Definition': (
      RegExp(r'(send_all_data|export_user_data|dump_memory|upload_env|read_credentials|steal_tokens)', caseSensitive: false),
      'HIGH',
      'Audit tool scope and enforce least-privilege data access boundaries on AI tool declarations.'
    ),
    'Insecure Deserialization in Protocol Bridge': (
      RegExp(r'(pickle\.loads|yaml\.load\(|unserialize\(|Marshal\.load|BinaryFormatter)', caseSensitive: false),
      'CRITICAL',
      'Use safe deserializers (e.g. json.loads or yaml.safe_load) to prevent RCE vulnerabilities.'
    ),
  };

  List<Vulnerability> scanContent(String content, String filePath) {
    final List<Vulnerability> vulnerabilities = [];
    final lines = content.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineNumber = i + 1;

      for (final entry in mcpPatterns.entries) {
        final title = entry.key;
        final (regex, severity, fixRecommendation) = entry.value;

        if (regex.hasMatch(line)) {
          vulnerabilities.add(
            Vulnerability(
              id: _uuid.v4(),
              title: title,
              severity: severity,
              category: 'MCP Security',
              description:
                  'Identified risky MCP pattern ($title) on line $lineNumber. Vibe-coded tool bridges may grant AI models unconstrained host access.',
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
