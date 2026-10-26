import re
import uuid
from datetime import datetime, timezone
from typing import List, Dict, Any

SECRET_PATTERNS = {
    'OpenAI Key': re.compile(r'sk-[a-zA-Z0-9]{32,}'),
    'Google API Key': re.compile(r'AIza[0-9A-Za-z\-_]{35}'),
    'AWS Access Key': re.compile(r'AKIA[0-9A-Z]{16}'),
    'AWS Secret Key': re.compile(r'[0-9a-zA-Z/+]{40}'),
    'GitHub Token': re.compile(r'ghp_[a-zA-Z0-9]{36}'),
    'Firebase Config': re.compile(r'firebaseConfig\s*=\s*\{[^}]+\}'),
    'JWT Secret': re.compile(r'jwt[_\s]?secret["\s]*[:=]["\s]*[a-zA-Z0-9]+', re.IGNORECASE),
    'Database URL': re.compile(r'(mysql|postgres|mongodb)\:\/\/[^\s]+'),
    'Private Key': re.compile(r'-----BEGIN (RSA |EC )?PRIVATE KEY-----'),
    'Gemini Key': re.compile(r'AIza[0-9A-Za-z\-_]{35}'),
    'Anthropic Key': re.compile(r'sk-ant-[a-zA-Z0-9\-_]+'),
}

class SecretScanner:
    def scan_content(self, content: str, file_path: str) -> List[Dict[str, Any]]:
        vulnerabilities = []
        lines = content.splitlines()

        for line_idx, line in enumerate(lines, start=1):
            for secret_name, pattern in SECRET_PATTERNS.items():
                match = pattern.search(line)
                if match:
                    # Mask secret value for safe reporting
                    matched_text = match.group(0)
                    masked = matched_text[:6] + '*' * (len(matched_text) - 10) + matched_text[-4:] if len(matched_text) > 10 else '******'
                    
                    vulnerabilities.append({
                        'id': str(uuid.uuid4()),
                        'title': f'Hardcoded {secret_name}',
                        'severity': 'CRITICAL',
                        'category': 'Secret Detection',
                        'description': f'Exposed credential pattern detected ({masked}) in {file_path} line {line_idx}.',
                        'location': f'{file_path}:{line_idx}',
                        'fix': 'Migrate sensitive credentials to environment variables or a secure key management vault.',
                        'codeSnippet': line.strip(),
                        'detectedAt': datetime.now(timezone.utc).isoformat()
                    })
        return vulnerabilities
