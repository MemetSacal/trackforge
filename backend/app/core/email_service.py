"""Email gönderimi — Resend API üzerinden.

Resend kurulumu:
1. resend.com'da ücretsiz hesap aç (3.000 email/ay ücretsiz)
2. Domain doğrula (veya onboarding email'ini kullan: resend.dev)
3. API key al → Render > Environment Variables > RESEND_API_KEY
4. FROM_EMAIL'i Resend'de doğrulanmış domain'e göre ayarla

RESEND_API_KEY yoksa email sessizce atlanır (geliştirme ortamı için).
"""
import secrets
import logging
from datetime import datetime, timezone, timedelta

import httpx

from backend.app.core.config import get_settings

logger = logging.getLogger(__name__)


def generate_email_token() -> str:
    """Kriptografik olarak güvenli 64 karakterlik URL-safe token üretir."""
    return secrets.token_urlsafe(48)  # 48 byte → 64 char base64url


def token_expiry(hours: int | None = None) -> datetime:
    """Token son kullanma tarihi (UTC)."""
    cfg = get_settings()
    h = hours or cfg.EMAIL_VERIFY_EXPIRE_HOURS
    return datetime.now(timezone.utc) + timedelta(hours=h)


async def send_verification_email(to_email: str, full_name: str, token: str) -> bool:
    """Doğrulama emaili gönderir. Başarıda True, hata veya API key yoksa False."""
    cfg = get_settings()

    if not cfg.RESEND_API_KEY:
        # Geliştirme ortamı — konsola yaz, gönderme
        link = f"{cfg.APP_BASE_URL}/api/v1/auth/verify-email?token={token}"
        logger.warning(
            "RESEND_API_KEY tanımlı değil. Doğrulama linki (DEV): %s", link
        )
        return False

    verify_url = f"{cfg.APP_BASE_URL}/api/v1/auth/verify-email?token={token}"

    html_body = f"""
<!DOCTYPE html>
<html lang="tr">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head>
<body style="margin:0;padding:0;background:#0C0D10;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif">
  <table width="100%" cellpadding="0" cellspacing="0">
    <tr><td align="center" style="padding:40px 20px">
      <table width="480" cellpadding="0" cellspacing="0"
             style="background:#141620;border-radius:20px;border:1px solid rgba(255,255,255,0.07);overflow:hidden">
        <!-- Header -->
        <tr><td align="center" style="padding:32px 32px 24px;background:linear-gradient(135deg,#4ADE80 0%,#22D3EE 100%)">
          <div style="font-size:28px;font-weight:800;color:#0C0D10;letter-spacing:-1px">TRACKFORGE</div>
          <div style="font-size:13px;color:#0C0D10;opacity:.7;margin-top:4px">Sağlığını takip et, hedefine ulaş</div>
        </td></tr>
        <!-- Body -->
        <tr><td style="padding:32px">
          <p style="margin:0 0 8px;font-size:20px;font-weight:700;color:#F0EEF8">
            Merhaba {full_name} 👋
          </p>
          <p style="margin:0 0 24px;font-size:14px;color:#8A88A8;line-height:1.6">
            TrackForge hesabını oluşturdun, harika! E-posta adresini doğrulamak için
            aşağıdaki butona tıkla. Bu link <strong style="color:#F0EEF8">{cfg.EMAIL_VERIFY_EXPIRE_HOURS} saat</strong> geçerlidir.
          </p>
          <!-- CTA Button -->
          <table cellpadding="0" cellspacing="0" style="margin:0 auto 24px">
            <tr><td align="center"
                    style="background:linear-gradient(135deg,#4ADE80,#22D3EE);border-radius:14px;padding:1px">
              <a href="{verify_url}"
                 style="display:block;padding:14px 32px;background:#141620;border-radius:13px;
                        font-size:15px;font-weight:700;color:#4ADE80;text-decoration:none;white-space:nowrap">
                ✉️ E-postamı Doğrula
              </a>
            </td></tr>
          </table>
          <p style="margin:0 0 8px;font-size:12px;color:#4A4860;line-height:1.5">
            Buton çalışmıyorsa aşağıdaki linki tarayıcına kopyala:
          </p>
          <p style="margin:0;font-size:11px;color:#4ADE80;word-break:break-all">{verify_url}</p>
        </td></tr>
        <!-- Footer -->
        <tr><td style="padding:20px 32px;border-top:1px solid rgba(255,255,255,0.05)">
          <p style="margin:0;font-size:11px;color:#4A4860;line-height:1.5;text-align:center">
            Bu emaili sen almadıysan güvenle yoksayabilirsin. Hesabın güvende.
          </p>
        </td></tr>
      </table>
    </td></tr>
  </table>
</body>
</html>
"""

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.post(
                "https://api.resend.com/emails",
                headers={
                    "Authorization": f"Bearer {cfg.RESEND_API_KEY}",
                    "Content-Type": "application/json",
                },
                json={
                    "from":    cfg.FROM_EMAIL,
                    "to":      [to_email],
                    "subject": "TrackForge — E-posta adresini doğrula",
                    "html":    html_body,
                },
            )
        if resp.status_code in (200, 201):
            logger.info("Doğrulama emaili gönderildi → %s", to_email)
            return True
        logger.error("Resend hata %s: %s", resp.status_code, resp.text[:200])
        return False
    except Exception as exc:
        logger.exception("Email gönderilemedi: %s", exc)
        return False
