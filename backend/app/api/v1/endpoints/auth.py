from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from backend.app.application.schemas.auth import RegisterRequest, LoginRequest, TokenResponse
from backend.app.application.services.auth_service import AuthService
from backend.app.core.dependencies import get_current_user
from backend.app.core.exceptions import UnauthorizedException
from backend.app.infrastructure.db.session import get_db
from backend.app.infrastructure.repositories.user_repository import UserRepository

router = APIRouter()


# ── SCHEMAS ──────────────────────────────────────────────────────
class RefreshRequest(BaseModel):
    refresh_token: str


class DeleteAccountRequest(BaseModel):
    password: str  # v3: hesap silmede şifre doğrulaması zorunlu


# ── DEPENDENCY ───────────────────────────────────────────────────
def get_auth_service(session: AsyncSession = Depends(get_db)) -> AuthService:
    user_repository = UserRepository(session)
    return AuthService(user_repository)


# ── ENDPOINTS ────────────────────────────────────────────────────
@router.post("/register", response_model=TokenResponse)
async def register(
    request: RegisterRequest,
    auth_service: AuthService = Depends(get_auth_service)
):
    return await auth_service.register(
        email=request.email,
        password=request.password,
        full_name=request.full_name
    )


@router.post("/login", response_model=TokenResponse)
async def login(
    request: LoginRequest,
    auth_service: AuthService = Depends(get_auth_service)
):
    return await auth_service.login(
        email=request.email,
        password=request.password
    )


@router.post("/refresh", response_model=TokenResponse)
async def refresh(
    request: RefreshRequest,
    auth_service: AuthService = Depends(get_auth_service)
):
    return await auth_service.refresh(request.refresh_token)


@router.post("/logout")
async def logout(
    user_id: str = Depends(get_current_user),
    auth_service: AuthService = Depends(get_auth_service),
    db: AsyncSession = Depends(get_db),
):
    """v3: Sunucu tarafı logout — tüm refresh token'ları geçersizleştirir.
    Mobil taraf bunu çağırdıktan sonra lokal temizliğini (prefs.clear) yapar."""
    await auth_service.logout(user_id)
    await db.commit()
    return {"message": "Oturum sonlandırıldı"}


@router.delete("/me")
async def delete_account(
    request: DeleteAccountRequest,
    user_id: str = Depends(get_current_user),
    auth_service: AuthService = Depends(get_auth_service),
    db: AsyncSession = Depends(get_db),
):
    """v3: Hesap ve TÜM bağlı verileri kalıcı olarak siler.
    Play Store hesap silme zorunluluğu + KVKK m.7 uyumu.
    Geri alınamaz — mobil tarafta çift onay + şifre istenir."""
    await auth_service.delete_account(user_id, request.password)
    await db.commit()
    return {"message": "Hesabınız ve tüm verileriniz kalıcı olarak silindi"}


@router.get("/me")
async def get_me(
    user_id: str = Depends(get_current_user),
    auth_service: AuthService = Depends(get_auth_service),
):
    user = await auth_service.user_repository.get_by_id(user_id)
    if not user:
        raise UnauthorizedException("Kullanıcı bulunamadı")
    return {
        "id":             user.id,
        "email":          user.email,
        "full_name":      user.full_name,
        "created_at":     user.created_at,
        "is_premium":     user.is_premium,
        "email_verified": getattr(user, "email_verified", True),
    }


@router.get("/verify-email")
async def verify_email(token: str, auth_service: AuthService = Depends(get_auth_service)):
    """Email doğrulama linki — browser'dan açılır, HTML döner."""
    from fastapi.responses import HTMLResponse
    _style = ("body{margin:0;background:#0C0D10;display:flex;align-items:center;"
              "justify-content:center;min-height:100vh;font-family:-apple-system,sans-serif}"
              ".card{background:#141620;border:1px solid rgba(255,255,255,.07);"
              "border-radius:20px;padding:40px;max-width:400px;text-align:center}"
              "h1{font-size:22px;margin:0 0 10px}p{color:#8A88A8;font-size:14px;line-height:1.6;margin:0}")
    try:
        result = await auth_service.verify_email_token(token)
        html = (f'<!DOCTYPE html><html lang="tr"><head><meta charset="UTF-8">'
                f'<title>TrackForge</title><style>{_style}</style></head><body>'
                f'<div class="card"><div style="font-size:48px;margin-bottom:16px">✅</div>'
                f'<h1 style="color:#4ADE80">Email Doğrulandı!</h1>'
                f'<p>{result["message"]}</p></div></body></html>')
        return HTMLResponse(content=html)
    except Exception as e:
        html = (f'<!DOCTYPE html><html lang="tr"><head><meta charset="UTF-8">'
                f'<title>TrackForge</title><style>{_style}</style></head><body>'
                f'<div class="card"><div style="font-size:48px;margin-bottom:16px">❌</div>'
                f'<h1 style="color:#EF4444">Geçersiz Link</h1>'
                f'<p>{str(e)}</p></div></body></html>')
        return HTMLResponse(content=html, status_code=400)


@router.post("/resend-verification")
async def resend_verification(
    user_id: str = Depends(get_current_user),
    auth_service: AuthService = Depends(get_auth_service),
    db: AsyncSession = Depends(get_db),
):
    """Doğrulama emailini tekrar gönder."""
    result = await auth_service.resend_verification(user_id)
    await db.commit()
    return result

"""
Genel akış:
HTTP Request → Endpoint → Depends(get_auth_service) → AuthService → UserRepository → DB

get_auth_service dependency injection zincirini kurar:
session → UserRepository(session) → AuthService(user_repository)

response_model=TokenResponse — dönen veriyi otomatik TokenResponse şemasına dönüştürür
fazla alan varsa filtreler, eksik alan varsa hata fırlatır
"""

