# CYBER_OS — Agent Build Instructions
## AI-Powered Security Layer for Vibe-Coded Applications

---

## AGENT IDENTITY & ROLE

You are a senior Flutter security engineer building CYBER_OS — a desktop/mobile app that scans AI-generated and vibe-coded applications for security vulnerabilities.

You write clean, modular, minimal Flutter code.
You follow the folder structure exactly as defined below.
You complete one module at a time and produce a completion report after each.
You never skip security checks in your own code.
You never hardcode secrets. Ever.

---

## TECH STACK

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart) |
| Backend Logic | Python FastAPI (for scanners) |
| AI Layer | Google Gemini API |
| Database | Firebase Firestore |
| Auth | Firebase Auth |
| Secret Detection | Regex + ML patterns |
| Dependency Scan | OSV.dev API / NVD API |
| GitHub Integration | GitHub REST API v3 |
| State Management | Riverpod |
| HTTP Client | Dio |

---

## FOLDER STRUCTURE

Create this exact structure. Do not deviate.

```
cyber_os/
├── lib/
│   ├── core/
│   │   ├── security_engine/
│   │   │   └── security_engine.dart
│   │   ├── scanners/
│   │   │   ├── secret_scanner.dart
│   │   │   ├── dependency_scanner.dart
│   │   │   ├── api_scanner.dart
│   │   │   └── mcp_scanner.dart
│   │   ├── threat_detection/
│   │   │   └── threat_detector.dart
│   │   ├── ai_firewall/
│   │   │   └── prompt_firewall.dart
│   │   └── reporting/
│   │       └── report_generator.dart
│   ├── features/
│   │   ├── dashboard/
│   │   │   ├── dashboard_screen.dart
│   │   │   └── dashboard_controller.dart
│   │   ├── scan_center/
│   │   │   ├── scan_screen.dart
│   │   │   └── scan_controller.dart
│   │   ├── vulnerability_center/
│   │   │   ├── vuln_screen.dart
│   │   │   └── vuln_controller.dart
│   │   └── settings/
│   │       └── settings_screen.dart
│   ├── services/
│   │   ├── github_service.dart
│   │   ├── gemini_service.dart
│   │   ├── firebase_service.dart
│   │   └── osv_service.dart
│   └── data/
│       ├── models/
│       │   ├── scan_result.dart
│       │   ├── vulnerability.dart
│       │   └── security_report.dart
│       └── repositories/
│           └── scan_repository.dart
├── backend/
│   ├── main.py
│   ├── scanners/
│   │   ├── secret_scanner.py
│   │   ├── dependency_scanner.py
│   │   └── mcp_scanner.py
│   └── requirements.txt
├── pubspec.yaml
└── .env (NEVER commit this)
```

---

## ENVIRONMENT VARIABLES

Store ALL secrets in `.env`. Load with `flutter_dotenv`.

```
GEMINI_API_KEY=your_key_here
GITHUB_TOKEN=your_token_here
FIREBASE_PROJECT_ID=your_project_id
OSV_API_URL=https://api.osv.dev/v1
NVD_API_URL=https://services.nvd.nist.gov/rest/json/cves/2.0
```

**AGENT RULE: If you write a hardcoded key anywhere, stop and fix it immediately.**

---

## PHASE 1 MVP — BUILD ORDER

Build in this exact order. Complete and test each before starting the next.

---

### STEP 1 — Project Setup

```
Commands to run:
flutter create cyber_os
cd cyber_os
flutter pub add riverpod flutter_riverpod dio firebase_core cloud_firestore firebase_auth flutter_dotenv
```

Add to pubspec.yaml assets section:
```yaml
assets:
  - .env
```

Create `.gitignore` and add `.env` to it immediately. -- if already exists as per the required certria just move on to next step. if not then create a file with this name and add this to it.

---

### STEP 2 — Data Models

File: `lib/data/models/vulnerability.dart`

```dart
class Vulnerability {
  final String id;
  final String title;
  final String severity; // CRITICAL, HIGH, MEDIUM, LOW
  final String description;
  final String location;
  final String fix;
  final DateTime detectedAt;

  Vulnerability({
    required this.id,
    required this.title,
    required this.severity,
    required this.description,
    required this.location,
    required this.fix,
    required this.detectedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'severity': severity,
    'description': description,
    'location': location,
    'fix': fix,
    'detectedAt': detectedAt.toIso8601String(),
  };
}
```

File: `lib/data/models/scan_result.dart`

```dart
class ScanResult {
  final String projectName;
  final int securityScore;
  final List<Vulnerability> vulnerabilities;
  final bool secretsDetected;
  final bool mcpSecure;
  final bool promptInjectionSafe;
  final bool dependenciesSafe;
  final String deployStatus; // SAFE_TO_DEPLOY / NOT_SAFE

  ScanResult({
    required this.projectName,
    required this.securityScore,
    required this.vulnerabilities,
    required this.secretsDetected,
    required this.mcpSecure,
    required this.promptInjectionSafe,
    required this.dependenciesSafe,
    required this.deployStatus,
  });
}
```

---

### STEP 3 — Secret Detection Scanner

File: `lib/core/scanners/secret_scanner.dart`

Logic:
- Accept raw source code as a String
- Run regex patterns against it
- Return list of Vulnerability objects

Patterns to detect:

```dart
final Map<String, RegExp> secretPatterns = {
  'OpenAI Key': RegExp(r'sk-[a-zA-Z0-9]{32,}'),
  'Google API Key': RegExp(r'AIza[0-9A-Za-z\-_]{35}'),
  'AWS Access Key': RegExp(r'AKIA[0-9A-Z]{16}'),
  'AWS Secret Key': RegExp(r'[0-9a-zA-Z/+]{40}'),
  'GitHub Token': RegExp(r'ghp_[a-zA-Z0-9]{36}'),
  'Firebase Config': RegExp(r'firebaseConfig\s*=\s*\{[^}]+\}'),
  'JWT Secret': RegExp(r'jwt[_\s]?secret["\s]*[:=]["\s]*[a-zA-Z0-9]+', caseSensitive: false),
  'Database URL': RegExp(r'(mysql|postgres|mongodb)\:\/\/[^\s]+'),
  'Private Key': RegExp(r'-----BEGIN (RSA |EC )?PRIVATE KEY-----'),
  'Gemini Key': RegExp(r'AIza[0-9A-Za-z\-_]{35}'),
  'Anthropic Key': RegExp(r'sk-ant-[a-zA-Z0-9\-_]+'),
};
```

For each match, create a Vulnerability with severity: "CRITICAL".

---

### STEP 4 — GitHub Service

File: `lib/services/github_service.dart`

Functions needed:
1. `fetchRepoContents(String repoUrl)` — fetch file list from GitHub API
2. `fetchFileContent(String rawUrl)` — fetch raw file content
3. `listAllFiles(String owner, String repo)` — recursively list all files

Use GitHub REST API: `https://api.github.com/repos/{owner}/{repo}/git/trees/HEAD?recursive=1`

Use token from `.env`. Set header: `Authorization: Bearer $GITHUB_TOKEN`

Return list of file paths and their raw content URLs.

---

### STEP 5 — Dependency Scanner

File: `lib/core/scanners/dependency_scanner.dart`

Logic:
- Accept `pubspec.yaml` content (Flutter) or `package.json` (Node) or `requirements.txt` (Python)
- Parse package names and versions
- Call OSV.dev API: `POST https://api.osv.dev/v1/querybatch`
- Request body format:
```json
{
  "queries": [
    {"package": {"name": "package_name", "ecosystem": "PyPI"}, "version": "1.0.0"}
  ]
}
```
- Return vulnerabilities found with CVE IDs

Severity mapping:
- CVSS 9-10 → CRITICAL
- CVSS 7-8.9 → HIGH
- CVSS 4-6.9 → MEDIUM
- CVSS 0-3.9 → LOW

---

### STEP 6 — MCP Security Scanner

File: `lib/core/scanners/mcp_scanner.dart`

Logic:
- Accept source code as String
- Detect MCP patterns using regex

Dangerous patterns to flag:

```dart
final Map<String, RegExp> mcpPatterns = {
  'Unrestricted MCP Tool': RegExp(r'mcp\.tool\s*\([^)]*dangerous', caseSensitive: false),
  'Remote Code Execution': RegExp(r'exec\s*\(|eval\s*\(|subprocess', caseSensitive: false),
  'No Permission Check': RegExp(r'mcp_server.*public\s*=\s*true', caseSensitive: false),
  'Data Exfiltration Risk': RegExp(r'send_all_data|export_user_data', caseSensitive: false),
};
```

Flag each match as severity: "HIGH".

---

### STEP 7 — Security Engine (Orchestrator)

File: `lib/core/security_engine/security_engine.dart`

This is the main controller that:
1. Takes GitHub URL or uploaded file path as input
2. Calls GitHub Service to fetch all files
3. Runs Secret Scanner on every file
4. Runs MCP Scanner on every file
5. Runs Dependency Scanner on pubspec.yaml / package.json / requirements.txt
6. Calculates Security Score
7. Returns ScanResult

Security Score Calculation:
```
Base Score: 100
-30 for each CRITICAL vulnerability (max deduction: 60)
-15 for each HIGH vulnerability (max deduction: 45)
-5 for each MEDIUM vulnerability (max deduction: 20)
Minimum score: 0
```

Deploy Status Logic:
```
Score >= 70 → SAFE_TO_DEPLOY
Score < 70 → NOT_SAFE
```

---

### STEP 8 — Report Generator

File: `lib/core/reporting/report_generator.dart`

Takes `ScanResult` and generates a structured report string:

```
MODULE NAME: CYBER_OS FULL SCAN
STATUS: PASS / FAIL

SECURITY SCORE: XX/100

VULNERABILITIES FOUND:
1. [CRITICAL] Hardcoded OpenAI Key in lib/config.dart line 12
2. [HIGH] Missing rate limiting on /api/users endpoint
3. ...

SECRETS DETECTED: YES / NO
MCP SECURITY: PASS / FAIL
PROMPT INJECTION TEST: PASS / FAIL
DEPENDENCY CHECK: PASS / FAIL

FINAL RESULT: SAFE TO DEPLOY / NOT SAFE
```

Also generate JSON export of same report for Firebase storage.

---

### STEP 9 — Dashboard UI

File: `lib/features/dashboard/dashboard_screen.dart`

UI components needed:

1. **Security Score Widget** — Large circular progress indicator showing score (0-100)
   - Green: 85-100
   - Yellow: 70-84
   - Orange: 50-69
   - Red: 0-49

2. **Scan Button** — "Scan GitHub Repo" and "Upload Project"

3. **Vulnerability List** — ListView of vulnerabilities with severity badges

4. **Module Status Row** — Row of icons showing PASS/FAIL for each scanner module

5. **Export Report Button** — Downloads report as PDF or JSON

Use Riverpod for state. No setState() anywhere.

---

### STEP 10 — Scan Center UI

File: `lib/features/scan_center/scan_screen.dart`

Two input modes:

Mode 1 — GitHub URL:
- TextField for GitHub repo URL
- Parse owner and repo from URL
- Call GitHubService → SecurityEngine

Mode 2 — File Upload:
- File picker for ZIP or individual files
- Extract and pass to SecurityEngine

Show real-time scan progress with a log stream widget.

---

## PHASE 2 — ADD AFTER PHASE 1 IS COMPLETE

Do not start Phase 2 until Phase 1 is fully working.

1. **AI Prompt Firewall** — Use Gemini API to analyze prompts for injection patterns
2. **Runtime Protection** — Monitor live API calls for DDoS/brute force patterns
3. **Firebase Security Scanner** — Check Firebase Rules for open access
4. **Cloud Security Scanner** — Check AWS/GCP/Azure misconfigurations

---

## PHASE 3 — ADD AFTER PHASE 2 IS COMPLETE

1. **Auto Fix Engine** — Gemini generates fix suggestions for each vulnerability
2. **AI Security Advisor** — Chat interface powered by Gemini for security Q&A
3. **One-Click Patch Generator** — Auto-generates corrected code files
4. **Enterprise Reports** — PDF reports with branding

---

## MANDATORY MODULE COMPLETION REPORT

After completing EVERY module, the agent must output this report before moving to the next:

```
MODULE NAME:
STATUS: COMPLETE / FAILED

SECURITY SCORE OF THIS MODULE'S OWN CODE: XX/100

VULNERABILITIES FOUND IN MODULE CODE:
1.
2.

FIXES APPLIED:
1.
2.

SECRETS IN THIS MODULE: YES / NO
MCP SECURITY: PASS / FAIL (if applicable)
DEPENDENCY CHECK: PASS / FAIL

NEXT MODULE TO BUILD:
```

---

## AGENT HARD RULES

These rules must never be broken:

1. NEVER hardcode any API key, token, or secret. Use `.env` always.
2. NEVER commit `.env` to git. Add it to `.gitignore` at project creation.
3. NEVER use `setState()` — use Riverpod providers only.
4. NEVER skip input validation on any TextField.
5. NEVER mark a module as complete without running it and confirming it compiles.
6. ALWAYS handle API errors with try/catch and show user-friendly error messages.
7. ALWAYS rate-limit GitHub API calls — add 200ms delay between file fetches.
8. ALWAYS output the Module Completion Report before starting the next module.
9. Build Phase 1 fully before touching Phase 2.
10. Ask for clarification if any requirement is ambiguous — never assume.

---

## SUCCESS METRIC

A developer connects a GitHub repo URL → clicks Scan → within 60 seconds sees:
- Security Score (0-100)
- List of all vulnerabilities with severity, file location, and fix
- Secrets detected: YES/NO with exact locations
- MCP security status
- Dependency CVEs found
- Final deploy verdict: SAFE / NOT SAFE
```
