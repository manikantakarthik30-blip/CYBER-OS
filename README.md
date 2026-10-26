# CYBER_OS — AI-Powered Security Layer for Vibe-Coded Applications

> **Autonomous Multi-Vector Vulnerability Scanner, Threat Detection Engine & Remediation Advisor**

---

## 1. Project Overview & Executive Summary

**CYBER_OS** is an autonomous desktop and web security platform designed to protect modern applications, GitHub repositories, and AI-assisted ("vibe-coded") codebases. As developers build software rapidly using LLMs, they frequently introduce critical vulnerabilities: unvetted third-party dependencies, hardcoded API secrets, insecure Model Context Protocol (MCP) tool configurations, prompt injection vectors, and permissive cloud permissions.

CYBER_OS acts as an automated security engineer. It clones or accepts project files, dispatches multi-vector static and dynamic analysis engines, calculates a standardized composite security score (0–100), outputs an audit verdict (`SAFE_TO_DEPLOY` vs `NOT_SAFE`), and leverages AI to generate one-click unified `.patch` remediations.

---

## 2. Core Capabilities & What We Have Built

### 🛡️ Multi-Vector Security Scanners
1. **Secret Detection Engine (`lib/core/scanners/secret_scanner.dart` & `backend/scanners/secret_scanner.py`)**:
   - Real-time heuristic and regex pattern matching across 11+ credential classes: OpenAI, Google Gemini, AWS Access/Secret keys, GitHub personal access tokens (PAT), Firebase configs, JWT secrets, database connection strings (PostgreSQL, MySQL, MongoDB), Anthropic keys, and private certificates.
   - Every detected key is classified as **CRITICAL** with line-level code attribution.
2. **Dependency & CVE Scanner (`lib/core/scanners/dependency_scanner.dart` & `backend/scanners/dependency_scanner.py`)**:
   - Native parser for Flutter (`pubspec.yaml`), Node.js (`package.json`), and Python (`requirements.txt`).
   - Integrates directly with the **OSV.dev Batch Query API** (`https://api.osv.dev/v1/querybatch`) to map package versions against live Open Source Vulnerability databases and CVSS scores.
3. **MCP (Model Context Protocol) Security Scanner (`lib/core/scanners/mcp_scanner.dart` & `backend/scanners/mcp_scanner.py`)**:
   - Inspects AI agent tool definitions and server configs.
   - Flags dangerous capabilities: unconstrained file access, arbitrary Remote Code Execution (`exec`, `eval`, `subprocess`), unauthenticated public tools, and data exfiltration routes.
4. **AI Prompt Injection Firewall (`lib/core/ai_firewall/prompt_firewall.dart`)**:
   - Defends applications against adversarial LLM attacks, direct jailbreaks ("ignore previous instructions"), role-play manipulation, delimiter hijacking, and hidden instruction injection.
5. **Runtime Anomaly & Threat Detector (`lib/core/threat_detection/threat_detector.dart`)**:
   - Simulates and monitors high-frequency traffic anomalies, credential brute-forcing, and denial-of-service (DDoS) telemetry.
6. **Firebase & Cloud Config Scanner (`lib/core/scanners/firebase_rules_scanner.dart` & `cloud_config_scanner.dart`)**:
   - Identifies open read/write security rules in `firestore.rules` and `storage.rules`.
   - Analyzes Dockerfiles, Docker Compose, and Terraform definitions for root privilege execution, exposed management ports (22, 3389), and insecure container options.

---

### 🧠 Autonomous AI Advisor & Remediation
- **Dual-Model Gemini Engine (`lib/services/gemini_service.dart`)**:
  - Connects to Google's `gemini-2.5-flash` with automatic fallback to `gemini-1.5-flash`.
  - **On-Device Fallback Heuristics**: If offline or if an API key is omitted, an embedded deterministic rule engine generates human-readable explanations and fixes without failure.
- **One-Click Unified Patch Generator (`lib/core/reporting/report_generator.dart`)**:
  - Automatically compiles detected issues into unified git `.patch` files ready to apply via `git apply fix.patch`.
- **Interactive Security Advisor (`lib/features/vulnerability_center/vuln_screen.dart`)**:
  - Interactive terminal chat window where operators can question the AI about threat vectors, CVSS scores, and mitigation strategies.

---

### 🔐 Authentication & Operator Management Suite (`lib/screens/login_screen.dart`)
- **Google OAuth 2.0 Integration**:
  - Validates live Google access tokens against the `https://www.googleapis.com/oauth2/v3/userinfo` endpoint with operator test sandboxing.
- **Apple ID Sign-In**:
  - Complete Apple OAuth modal with operator bypass capabilities.
- **Email & Password Authentication**:
  - Secure credential validation with local encrypted session persistence via `SharedPreferences`.
- **6-Digit OTP Email Verification Modal**:
  - Implements a security verification checkpoint with real-time 60-second cooldown timer, auto-fill test badge, and resend mechanics.
- **Emergency Password Recovery Flow**:
  - Dispatches automated 6-digit recovery codes and enables password resets.
- **Automated Cyberpunk HTML Welcome Email**:
  - Dispatches a styled HTML email to new operators via the Python backend or client-side fallback.

---

### 🎨 Visual Identity & HUD (Cyberpunk Terminal)
- **Zero-Standard UI**: Custom high-contrast theme built with JetBrains Mono and Orbitron typography.
- **Interactive Feedback**: Dynamic radar scan line overlays, pulsating threat rings, glitch text animations, animated severity badges, and circular security gauges.
- **Production Secret Hygiene**: Zero hardcoded secrets in the UI. Plain-text token inputs in Settings are replaced with status badges and masked indicators.

---

## 3. Technology Stack

### **Frontend (Client Application)**
| Component | Technology | Version / Specification |
|---|---|---|
| **Framework** | [Flutter](https://flutter.dev) | 3.x+ (Dart SDK ^3.13.2) |
| **State Management** | [Flutter Riverpod](https://pub.dev/packages/flutter_riverpod) | ^2.5.1 (Reactive, decoupled providers) |
| **Networking** | [Dio](https://pub.dev/packages/dio) | ^5.4.3+1 (Interceptors, timeouts, custom headers) |
| **Typography** | [Google Fonts](https://pub.dev/packages/google_fonts) | ^6.2.1 (JetBrains Mono & Orbitron) |
| **Data Visualization** | [FL Chart](https://pub.dev/packages/fl_chart) | ^0.68.0 (Security dial & trend analytics) |
| **Micro-Animations** | [Flutter Animate](https://pub.dev/packages/flutter_animate) | ^4.5.0 & Custom Shimmer |
| **File Handling** | [File Picker](https://pub.dev/packages/file_picker) & [Archive](https://pub.dev/packages/archive) | File ingestion and ZIP extraction |
| **YAML Engine** | [YAML](https://pub.dev/packages/yaml) | Dependency file parsing |
| **Local Persistence** | [Shared Preferences](https://pub.dev/packages/shared_preferences) | Auth tokens & engine preferences |

### **Backend Service (Python Microservice)**
| Component | Technology | Version / Specification |
|---|---|---|
| **Framework** | [FastAPI](https://fastapi.tiangolo.com) | >=0.110.0 (Asynchronous REST API) |
| **ASGI Server** | [Uvicorn](https://www.uvicorn.org) | >=0.28.0 (High-throughput async execution) |
| **Data Validation** | [Pydantic](https://docs.pydantic.dev) | >=2.6.0 (Strict request/response schemas) |
| **Async HTTP Client** | [HTTPX](https://www.python-httpx.org) | >=0.27.0 (OSV.dev batch querying) |
| **Configuration** | [python-dotenv](https://pypi.org/project/python-dotenv) | Environment variable orchestration |
| **Email Transport** | [smtplib & email.mime] | Live SMTP delivery with mock fallback |

### **External APIs & Protocol Integrations**
- **Google Gemini API**: `gemini-2.5-flash` / `gemini-1.5-flash` for security remediation.
- **OSV.dev Batch API**: `https://api.osv.dev/v1/querybatch` for CVE lookups across PyPI, npm, and Pub.
- **Google OAuth 2.0 UserInfo API**: `https://www.googleapis.com/oauth2/v3/userinfo`.
- **GitHub REST API v3**: `https://api.github.com/repos/{owner}/{repo}/git/trees/HEAD?recursive=1` with 200ms rate pacing.

---

## 4. Architectural Analysis & Directory Structure

```
c:/Users/manib/flutter_projects/flutter_application_2/
├── lib/
│   ├── core/
│   │   ├── ai_firewall/          # Prompt injection & jailbreak defense
│   │   ├── reporting/            # Markdown, JSON & .patch report generator
│   │   ├── scanners/             # Secret, Dependency, MCP, Firebase, Cloud scanners
│   │   ├── security_engine/      # Central SecurityEngine orchestrator
│   │   ├── theme/                # Cyberpunk color tokens & typography
│   │   ├── threat_detection/     # Runtime anomaly & DDoS detection
│   │   └── widgets/              # CyberCard, SeverityBadge, PulseRing, GlitchText
│   ├── data/
│   │   ├── models/               # Vulnerability, ScanResult, SecurityReport
│   │   └── repositories/         # ScanRepository & historical persistence
│   ├── features/
│   │   ├── dashboard/            # Score gauge, scanner status, vulnerability list
│   │   ├── scan_center/          # GitHub repo scanning, ZIP upload, live console
│   │   ├── settings/             # Masked security toggles & engine configuration
│   │   ├── splash/               # Animated terminal bootloader
│   │   └── vulnerability_center/ # Detailed remediation & AI Advisor chat
│   ├── screens/
│   │   └── login_screen.dart     # Google OAuth, Apple, Email/Pass, OTP modal, Reset
│   ├── services/
│   │   ├── email_service.dart    # Cyberpunk HTML template dispatcher
│   │   ├── firebase_service.dart # Auth state & token storage
│   │   ├── gemini_service.dart   # Dual-model AI advisor with on-device heuristics
│   │   ├── github_service.dart   # Rate-limited GitHub repo fetcher
│   │   └── osv_service.dart      # OSV.dev vulnerability lookup client
│   └── main.dart                 # App entry point & Riverpod Scope
├── backend/
│   ├── main.py                   # FastAPI REST gateway & CORS configuration
│   ├── requirements.txt          # Python dependencies
│   ├── scanners/                 # Python counterparts for Secret, Dependency, MCP
│   └── services/                 # Backend email & template rendering
├── pubspec.yaml                  # Flutter package manifest
├── .env.example                  # Environment variable reference
└── .gitignore                    # Ensures .env & secrets are excluded from Git
```

---

## 5. Security & Scoring Algorithm

The Security Score starts at a baseline of **100 points** and applies composite deductions:

$$\text{Score} = \max\left(0, 100 - (\text{Critical} \times 30) - (\text{High} \times 15) - (\text{Medium} \times 5)\right)$$

- **Cap Constraints**:
  - Critical deductions capped at $-60$
  - High deductions capped at $-45$
  - Medium deductions capped at $-20$
- **Deployment Verdict**:
  - $\ge 70$: **`SAFE_TO_DEPLOY`**
  - $< 70$: **`NOT_SAFE`**

---

## 6. How to Run the Project

### Running the Flutter Client
```bash
# 1. Install dependencies
flutter pub get

# 2. Launch on Chrome (or Windows desktop)
flutter run -d chrome
```

### Running the Python Backend (Optional)
```bash
# 1. Navigate to backend directory
cd backend

# 2. Install dependencies
pip install -r requirements.txt

# 3. Start the FastAPI ASGI server
uvicorn main:app --reload --port 8000
```
