import os
from typing import Dict, List, Optional
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
import httpx

from scanners.secret_scanner import SecretScanner
from scanners.dependency_scanner import DependencyScanner
from scanners.mcp_scanner import MCPScanner
from services.email_service import EmailService

app = FastAPI(
    title="CYBER_OS Security & Auth Microservice",
    version="1.0.0",
    description="Backend analysis engine and authentication email service for CYBER_OS."
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

secret_scanner = SecretScanner()
dependency_scanner = DependencyScanner()
mcp_scanner = MCPScanner()
email_service = EmailService()

# In-memory account password overrides for reset password flow
account_passwords: Dict[str, str] = {}

class ScanFilesRequest(BaseModel):
    project_name: str = Field(..., example="my-vibe-app")
    files: Dict[str, str] = Field(..., description="Map of relative file paths to file string contents")

class ScanManifestsRequest(BaseModel):
    pubspec_yaml: Optional[str] = None
    package_json: Optional[str] = None
    requirements_txt: Optional[str] = None

class ScanResponse(BaseModel):
    project_name: str
    security_score: int
    deploy_status: str
    vulnerabilities: List[Dict]
    secrets_detected: bool
    mcp_secure: bool
    dependencies_safe: bool

class SendVerificationRequest(BaseModel):
    email: str

class VerifyCodeRequest(BaseModel):
    email: str
    code: str

class SendWelcomeRequest(BaseModel):
    email: str
    operator_name: str

class ForgotPasswordRequest(BaseModel):
    email: str

class ResetPasswordRequest(BaseModel):
    email: str
    code: str
    new_password: str

class GoogleVerifyRequest(BaseModel):
    access_token: str

@app.get("/health")
def health_check():
    return {
        "status": "ONLINE",
        "service": "CYBER_OS Kernel",
        "version": "1.0.0",
        "smtp_configured": email_service.is_smtp_configured
    }

# ================= AUTHENTICATION & EMAIL ENDPOINTS =================

@app.post("/api/v1/auth/send-verification")
def send_verification_endpoint(req: SendVerificationRequest):
    email = req.email.strip().lower()
    if not email or "@" not in email:
        raise HTTPException(status_code=400, detail="Invalid email address format.")

    code = email_service.generate_otp(email, purpose="verification")
    dispatched = email_service.send_verification_email(email, code)

    return {
        "status": "SENT",
        "email": email,
        "code_ttl_seconds": 600,
        "debug_code": code if not email_service.is_smtp_configured else None,
        "message": f"Verification code dispatched to {email}"
    }

@app.post("/api/v1/auth/verify-code")
def verify_code_endpoint(req: VerifyCodeRequest):
    email = req.email.strip().lower()
    code = req.code.strip()

    valid = email_service.verify_otp(email, code, purpose="verification")
    if not valid:
        raise HTTPException(status_code=400, detail="Invalid or expired 6-digit verification code.")

    return {
        "status": "VERIFIED",
        "email": email,
        "verified": True,
        "message": "Operator email successfully verified."
    }

@app.post("/api/v1/auth/send-welcome")
def send_welcome_endpoint(req: SendWelcomeRequest):
    email = req.email.strip().lower()
    name = req.operator_name.strip() or "Operator"

    dispatched = email_service.send_welcome_email(email, name)
    return {
        "status": "DELIVERED",
        "email": email,
        "message": f"Welcome dossier dispatched to {email}"
    }

@app.post("/api/v1/auth/forgot-password")
def forgot_password_endpoint(req: ForgotPasswordRequest):
    email = req.email.strip().lower()
    if not email or "@" not in email:
        raise HTTPException(status_code=400, detail="Invalid email address format.")

    code = email_service.generate_otp(email, purpose="recovery")
    email_service.send_password_reset_email(email, code)

    return {
        "status": "SENT",
        "email": email,
        "debug_code": code if not email_service.is_smtp_configured else None,
        "message": f"Emergency password recovery code dispatched to {email}"
    }

@app.post("/api/v1/auth/reset-password")
def reset_password_endpoint(req: ResetPasswordRequest):
    email = req.email.strip().lower()
    code = req.code.strip()

    if len(req.new_password) < 6:
        raise HTTPException(status_code=400, detail="Password must be at least 6 characters long.")

    valid = email_service.verify_otp(email, code, purpose="recovery")
    if not valid:
        raise HTTPException(status_code=400, detail="Invalid or expired recovery code.")

    account_passwords[email] = req.new_password
    return {
        "status": "UPDATED",
        "email": email,
        "message": "Password successfully reset. You may now log in."
    }

@app.post("/api/v1/auth/google-verify")
async def google_verify_endpoint(req: GoogleVerifyRequest):
    """Verifies a Google OAuth Access Token via Google's OAuth2 UserInfo API."""
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            res = await client.get(
                "https://www.googleapis.com/oauth2/v3/userinfo",
                headers={"Authorization": f"Bearer {req.access_token}"}
            )
            if res.status_code != 200:
                raise HTTPException(status_code=401, detail="Invalid or expired Google OAuth token.")

            data = res.json()
            # Send welcome email on first verification
            email = data.get("email", "")
            name = data.get("name", "Google Operator")
            if email:
                email_service.send_welcome_email(email, name)

            return {
                "status": "AUTHENTICATED",
                "email": email,
                "name": name,
                "picture": data.get("picture"),
                "email_verified": data.get("email_verified", False)
            }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to verify Google token: {e}")

# ================= SECURITY SCANNING ENDPOINTS =================

@app.post("/api/v1/scan/secrets")
def scan_secrets_endpoint(req: ScanFilesRequest):
    all_vulns = []
    for file_path, content in req.files.items():
        all_vulns.extend(secret_scanner.scan_content(content, file_path))
    return {
        "status": "PASS" if not all_vulns else "FAIL",
        "vulnerabilities": all_vulns,
        "count": len(all_vulns)
    }

@app.post("/api/v1/scan/mcp")
def scan_mcp_endpoint(req: ScanFilesRequest):
    all_vulns = []
    for file_path, content in req.files.items():
        all_vulns.extend(mcp_scanner.scan_content(content, file_path))
    return {
        "status": "PASS" if not all_vulns else "FAIL",
        "vulnerabilities": all_vulns,
        "count": len(all_vulns)
    }

@app.post("/api/v1/scan/dependencies")
async def scan_dependencies_endpoint(req: ScanManifestsRequest):
    vulns = await dependency_scanner.scan_manifests(
        pubspec_content=req.pubspec_yaml,
        package_json_content=req.package_json,
        requirements_content=req.requirements_txt
    )
    return {
        "status": "PASS" if not vulns else "FAIL",
        "vulnerabilities": vulns,
        "count": len(vulns)
    }

@app.post("/api/v1/scan/full", response_model=ScanResponse)
async def scan_full_endpoint(req: ScanFilesRequest):
    all_vulns = []

    # 1. Secret scanning
    secret_vulns = []
    for file_path, content in req.files.items():
        secret_vulns.extend(secret_scanner.scan_content(content, file_path))
    all_vulns.extend(secret_vulns)

    # 2. MCP scanning
    mcp_vulns = []
    for file_path, content in req.files.items():
        mcp_vulns.extend(mcp_scanner.scan_content(content, file_path))
    all_vulns.extend(mcp_vulns)

    # 3. Dependency scanning
    pubspec = req.files.get("pubspec.yaml")
    package_json = req.files.get("package.json")
    requirements = req.files.get("requirements.txt")
    dep_vulns = await dependency_scanner.scan_manifests(
        pubspec_content=pubspec,
        package_json_content=package_json,
        requirements_content=requirements
    )
    all_vulns.extend(dep_vulns)

    # Score calculation
    crit_count = sum(1 for v in all_vulns if v.get("severity") == "CRITICAL")
    high_count = sum(1 for v in all_vulns if v.get("severity") == "HIGH")
    med_count = sum(1 for v in all_vulns if v.get("severity") == "MEDIUM")

    score = 100 - min(60, crit_count * 30) - min(45, high_count * 15) - min(20, med_count * 5)
    score = max(0, score)
    deploy_status = "SAFE_TO_DEPLOY" if score >= 70 else "NOT_SAFE"

    return ScanResponse(
        project_name=req.project_name,
        security_score=score,
        deploy_status=deploy_status,
        vulnerabilities=all_vulns,
        secrets_detected=len(secret_vulns) > 0,
        mcp_secure=len(mcp_vulns) == 0,
        dependencies_safe=len(dep_vulns) == 0
    )

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", "8000"))
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=True)
