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
    }

"""
Genel akış:
HTTP Request → Endpoint → Depends(get_auth_service) → AuthService → UserRepository → DB

get_auth_service dependency injection zincirini kurar:
session → UserRepository(session) → AuthService(user_repository)

response_model=TokenResponse — dönen veriyi otomatik TokenResponse şemasına dönüştürür
fazla alan varsa filtreler, eksik alan varsa hata fırlatır
"""

