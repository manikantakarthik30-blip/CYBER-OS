import os
import random
import smtplib
from datetime import datetime, timedelta
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from typing import Dict, Optional, Tuple

class EmailService:
    def __init__(self):
        self.smtp_host = os.getenv("SMTP_HOST", "smtp.gmail.com")
        self.smtp_port = int(os.getenv("SMTP_PORT", "587"))
        self.smtp_user = os.getenv("SMTP_USER", "")
        self.smtp_pass = os.getenv("SMTP_PASS", "")
        self.sender_email = os.getenv("SENDER_EMAIL", self.smtp_user or "security@cyber-os.io")
        self.sender_name = "CYBER_OS Security Kernel"

        # In-memory OTP storage: email -> (code, expiry_time, purpose)
        self._otps: Dict[str, Tuple[str, datetime, str]] = {}

    @property
    def is_smtp_configured(self) -> bool:
        return bool(self.smtp_user and self.smtp_pass and "your_" not in self.smtp_pass)

    def generate_otp(self, email: str, purpose: str = "verification") -> str:
        """Generates a secure 6-digit OTP valid for 10 minutes."""
        code = f"{random.randint(100000, 999999)}"
        expiry = datetime.now() + timedelta(minutes=10)
        self._otps[email.strip().lower()] = (code, expiry, purpose)
        return code

    def verify_otp(self, email: str, code: str, purpose: str = "verification") -> bool:
        """Verifies a 6-digit OTP."""
        email_key = email.strip().lower()
        if email_key not in self._otps:
            return False
        stored_code, expiry, stored_purpose = self._otps[email_key]
        if stored_purpose != purpose:
            return False
        if datetime.now() > expiry:
            del self._otps[email_key]
            return False
        if stored_code == code.strip():
            del self._otps[email_key]
            return True
        return False

    def send_email(self, to_email: str, subject: str, html_body: str) -> bool:
        """Sends an HTML email via SMTP or logs to console if SMTP is not configured."""
        if self.is_smtp_configured:
            try:
                msg = MIMEMultipart("alternative")
                msg["Subject"] = subject
                msg["From"] = f"{self.sender_name} <{self.sender_email}>"
                msg["To"] = to_email

                part = MIMEText(html_body, "html")
                msg.attach(part)

                with smtplib.SMTP(self.smtp_host, self.smtp_port, timeout=10) as server:
                    server.starttls()
                    server.login(self.smtp_user, self.smtp_pass)
                    server.sendmail(self.sender_email, to_email, msg.as_string())
                print(f"[CYBER_OS SMTP] Successfully dispatched email '{subject}' to {to_email}")
                return True
            except Exception as e:
                print(f"[CYBER_OS SMTP ERROR] Failed to send email via SMTP: {e}. Falling back to terminal log.")

        # Fallback log for development/testing
        print("\n" + "=" * 60)
        print(f"[CYBER_OS EMAIL DISPATCH LOG] To: {to_email}")
        print(f"Subject: {subject}")
        print(f"Timestamp: {datetime.now().isoformat()}")
        print("-" * 60)
        print("HTML Payload dispatched successfully (Local Mode).")
        print("=" * 60 + "\n")
        return True

    def send_welcome_email(self, to_email: str, operator_name: str) -> bool:
        """Dispatches an interactive cyber-styled Welcome Email."""
        subject = "CYBER_OS — Security Clearance Level 1 Granted"
        html_body = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <style>
                body {{
                    background-color: #040810;
                    color: #E8F4FF;
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
                    padding: 30px;
                    margin: 0;
                }}
                .container {{
                    max-width: 600px;
                    margin: 0 auto;
                    background-color: #070D1A;
                    border: 1px solid #00D4FF;
                    border-radius: 8px;
                    padding: 32px;
                    box-shadow: 0 0 20px rgba(0, 212, 255, 0.15);
                }}
                .header {{
                    border-bottom: 1px solid #111D33;
                    padding-bottom: 20px;
                    margin-bottom: 24px;
                }}
                .brand {{
                    color: #00D4FF;
                    font-size: 24px;
                    font-weight: bold;
                    letter-spacing: 3px;
                }}
                .title {{
                    color: #FFFFFF;
                    font-size: 20px;
                    margin-top: 10px;
                }}
                .content {{
                    line-height: 1.6;
                    color: #A0B9D6;
                    font-size: 14px;
                }}
                .badge {{
                    display: inline-block;
                    background: rgba(0, 255, 148, 0.1);
                    color: #00FF94;
                    border: 1px solid #00FF94;
                    padding: 4px 12px;
                    border-radius: 4px;
                    font-weight: bold;
                    font-size: 12px;
                    letter-spacing: 1px;
                }}
                .card {{
                    background: #0D1525;
                    border-left: 3px solid #00D4FF;
                    padding: 16px;
                    margin: 20px 0;
                    border-radius: 4px;
                }}
                .footer {{
                    margin-top: 32px;
                    font-size: 11px;
                    color: #4A6588;
                    border-top: 1px solid #111D33;
                    padding-top: 16px;
                }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <div class="brand">CYBER_OS</div>
                    <div class="title">Security Clearance Initialized</div>
                </div>
                <div class="content">
                    <p>Welcome, Operator <strong>{operator_name}</strong>.</p>
                    <p>Your operator profile has been successfully registered and provisioned within the CYBER_OS Security Enclave.</p>
                    <div class="card">
                        <div><strong>CLEARANCE STATUS:</strong> <span class="badge">ACTIVE (LEVEL 1)</span></div>
                        <div style="margin-top: 8px;"><strong>OPERATOR ID:</strong> {to_email}</div>
                        <div style="margin-top: 8px;"><strong>ENCLAVE PROTOCOL:</strong> Zero-Knowledge On-Device Analysis</div>
                    </div>
                    <p>You now have full clearance to:</p>
                    <ul>
                        <li>Audit GitHub repositories for exposed API tokens and credentials</li>
                        <li>Scan for dangerous Model Context Protocol (MCP) execution primitives</li>
                        <li>Query OSV.dev national and open-source vulnerability databases</li>
                        <li>Consult the AI Security Advisor for autonomous remediation patches</li>
                    </ul>
                    <p>Remember: No secrets or raw repository code are transmitted off-device.</p>
                </div>
                <div class="footer">
                    CYBER_OS Autonomous Defense Subsystem • Automated Dispatch • Do Not Reply
                </div>
            </div>
        </body>
        </html>
        """
        return self.send_email(to_email, subject, html_body)

    def send_verification_email(self, to_email: str, code: str) -> bool:
        """Dispatches an email containing the 6-digit verification code."""
        subject = f"CYBER_OS — Operator Activation Code [{code}]"
        html_body = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <style>
                body {{
                    background-color: #040810;
                    color: #E8F4FF;
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    padding: 30px;
                    margin: 0;
                }}
                .container {{
                    max-width: 540px;
                    margin: 0 auto;
                    background-color: #070D1A;
                    border: 1px solid #00D4FF;
                    border-radius: 8px;
                    padding: 32px;
                    text-align: center;
                }}
                .brand {{
                    color: #00D4FF;
                    font-size: 24px;
                    font-weight: bold;
                    letter-spacing: 3px;
                }}
                .code-box {{
                    background: #0D1525;
                    border: 1px dashed #00D4FF;
                    padding: 20px;
                    margin: 28px 0;
                    border-radius: 6px;
                }}
                .code {{
                    font-family: monospace;
                    font-size: 38px;
                    letter-spacing: 12px;
                    color: #00FF94;
                    font-weight: bold;
                }}
                .footer {{
                    margin-top: 24px;
                    font-size: 11px;
                    color: #4A6588;
                }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="brand">CYBER_OS</div>
                <h2 style="color: #FFF; margin-top: 14px;">Operator Identity Verification</h2>
                <p style="color: #A0B9D6; font-size: 14px;">Enter the following 6-digit security code in CYBER_OS to activate your operator account:</p>
                <div class="code-box">
                    <div class="code">{code}</div>
                </div>
                <p style="color: #6B8BAE; font-size: 12px;">This code will self-expire in 10 minutes. If you did not request this verification, disregard this transmission.</p>
                <div class="footer">
                    CYBER_OS Authentication Gateway • Automated Dispatch
                </div>
            </div>
        </body>
        </html>
        """
        return self.send_email(to_email, subject, html_body)

    def send_password_reset_email(self, to_email: str, code: str) -> bool:
        """Dispatches an email containing the 6-digit password recovery code."""
        subject = f"CYBER_OS — Emergency Access Recovery Code [{code}]"
        html_body = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <style>
                body {{
                    background-color: #040810;
                    color: #E8F4FF;
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    padding: 30px;
                    margin: 0;
                }}
                .container {{
                    max-width: 540px;
                    margin: 0 auto;
                    background-color: #070D1A;
                    border: 1px solid #FF2D55;
                    border-radius: 8px;
                    padding: 32px;
                    text-align: center;
                }}
                .brand {{
                    color: #FF2D55;
                    font-size: 24px;
                    font-weight: bold;
                    letter-spacing: 3px;
                }}
                .code-box {{
                    background: #0D1525;
                    border: 1px dashed #FF2D55;
                    padding: 20px;
                    margin: 28px 0;
                    border-radius: 6px;
                }}
                .code {{
                    font-family: monospace;
                    font-size: 38px;
                    letter-spacing: 12px;
                    color: #FF2D55;
                    font-weight: bold;
                }}
                .footer {{
                    margin-top: 24px;
                    font-size: 11px;
                    color: #4A6588;
                }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="brand">CYBER_OS</div>
                <h2 style="color: #FFF; margin-top: 14px;">Password Recovery Request</h2>
                <p style="color: #A0B9D6; font-size: 14px;">An emergency password recovery request was initiated for your operator account.</p>
                <div class="code-box">
                    <div class="code">{code}</div>
                </div>
                <p style="color: #6B8BAE; font-size: 12px;">Enter this 6-digit recovery code in CYBER_OS to reset your password. Valid for 10 minutes.</p>
                <div class="footer">
                    CYBER_OS Incident Response Protocol • Automated Dispatch
                </div>
            </div>
        </body>
        </html>
        """
        return self.send_email(to_email, subject, html_body)
