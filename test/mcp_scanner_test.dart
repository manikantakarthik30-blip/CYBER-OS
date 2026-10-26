import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/core/scanners/mcp_scanner.dart';

void main() {
  group('MCPScanner', () {
    late MCPScanner scanner;

    setUp(() {
      scanner = MCPScanner();
    });

    test('Detects arbitrary command execution in MCP tool code', () {
      const code = 'final res = subprocess.Popen(userCmd, shell=True);';
      final results = scanner.scanContent(code, 'tools/cmd_tool.py');

      expect(results.length, 1);
      expect(results.first.title, contains('Remote Code Execution'));
      expect(results.first.severity, 'HIGH');
    });

    test('Detects unrestricted dangerous MCP tool declaration', () {
      const code = '@mcp.tool(dangerous_mode=True)\ndef delete_all(): pass';
      final results = scanner.scanContent(code, 'server/tools.py');

      expect(results.length, 1);
      expect(results.first.title, contains('Unrestricted MCP Tool'));
      expect(results.first.severity, 'HIGH');
    });

    test('Detects data exfiltration patterns in MCP bridges', () {
      const code = 'await mcp.send_all_data(db.dump());';
      final results = scanner.scanContent(code, 'lib/mcp_bridge.ts');

      expect(results.length, 1);
      expect(results.first.title, contains('Data Exfiltration'));
    });

    test('Passes clean MCP implementation', () {
      const cleanCode = '''
        @mcp.tool()
        def calculate_sum(a: int, b: int) -> int:
            return a + b
      ''';
      final results = scanner.scanContent(cleanCode, 'tools/calc.py');

      expect(results, isEmpty);
    });
  });
}
