from fastapi import Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError
from sqlalchemy.ext.asyncio import AsyncSession
from backend.app.core.security import decode_token
from backend.app.core.exceptions import UnauthorizedException
from backend.app.infrastructure.db.session import get_db
from backend.app.infrastructure.repositories.user_repository import UserRepository

# Bearer token şeması — Swagger Authorize butonuyla entegre çalışır
bearer_scheme = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme)
) -> str:
    """Bearer token doğrular ve user_id döndürür."""
    try:
        token = credentials.credentials
        payload = decode_token(token)
        if payload.get("type") != "access":
            raise UnauthorizedException("Geçersiz token tipi")
        user_id: str = payload.get("sub")
        if not user_id:
            raise UnauthorizedException("Token içinde kullanıcı bulunamadı")
        return user_id
    except JWTError:
        raise UnauthorizedException("Geçersiz veya süresi dolmuş token")


async def get_current_user_premium(
    user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> tuple[str, bool]:
    """user_id ve is_premium döndürür — AI rate limit kontrolü için."""
    user_repo = UserRepository(db)
    user = await user_repo.get_by_id(user_id)
    is_premium = user.is_premium if user else False
    return user_id, is_premium


"""
HTTPBearer vs Header(...) farkı:
Eski yöntemde Header(...) ile authorization string olarak alıyorduk.
Swagger bunu body field sanıyordu, Authorize butonu çalışmıyordu.

HTTPBearer ile Swagger'ın Authorize butonuyla tam entegre çalışır.
credentials.credentials → sadece token string'ini verir, "Bearer " prefix'i olmadan.
"""