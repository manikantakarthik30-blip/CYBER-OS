import re
import uuid
from datetime import datetime, timezone
from typing import List, Dict, Any

MCP_PATTERNS = {
    'Unrestricted MCP Tool': (re.compile(r'mcp\.tool\s*\([^)]*dangerous', re.IGNORECASE), 'HIGH', 'Restrict tool capabilities to minimum necessary permissions.'),
    'Remote Code Execution in MCP Context': (re.compile(r'(?:exec|eval|subprocess\.(?:Popen|call|run))\s*\(', re.IGNORECASE), 'CRITICAL', 'Disallow dynamic execution primitives inside AI/MCP tool executors.'),
    'Unauthenticated Public MCP Server': (re.compile(r'mcp_server.*public\s*=\s*true', re.IGNORECASE), 'HIGH', 'Bind MCP server strictly to local sockets or authenticated mutual TLS tunnels.'),
    'Data Exfiltration Risk in Tool Pipeline': (re.compile(r'send_all_data|export_user_data|dump_all_context', re.IGNORECASE), 'HIGH', 'Filter tool payloads to prevent batch memory or database dumps.'),
}

class MCPScanner:
    def scan_content(self, content: str, file_path: str) -> List[Dict[str, Any]]:
        vulnerabilities = []
        lines = content.splitlines()

        for line_idx, line in enumerate(lines, start=1):
            for pattern_name, (pattern, severity, fix) in MCP_PATTERNS.items():
                if pattern.search(line):
                    vulnerabilities.append({
                        'id': str(uuid.uuid4()),
                        'title': pattern_name,
                        'severity': severity,
                        'category': 'MCP Security',
                        'description': f'Risky MCP pattern detected on line {line_idx} of {file_path}.',
                        'location': f'{file_path}:{line_idx}',
                        'fix': fix,
                        'codeSnippet': line.strip(),
                        'detectedAt': datetime.now(timezone.utc).isoformat()
                    })
        return vulnerabilities
