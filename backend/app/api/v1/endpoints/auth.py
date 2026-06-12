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
        "id": user.id,
        "email": user.email,
        "full_name": user.full_name,
        "created_at": user.created_at,
        "is_premium": user.is_premium,
    }

"""
Genel akış:
HTTP Request → Endpoint → Depends(get_auth_service) → AuthService → UserRepository → DB

get_auth_service dependency injection zincirini kurar:
session → UserRepository(session) → AuthService(user_repository)

response_model=TokenResponse — dönen veriyi otomatik TokenResponse şemasına dönüştürür
fazla alan varsa filtreler, eksik alan varsa hata fırlatır
"""

