from fastapi import Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError
from backend.app.core.security import decode_token
from backend.app.core.exceptions import UnauthorizedException

# Bearer token şeması — Swagger Authorize butonuyla entegre çalışır
bearer_scheme = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme)
) -> str:
    # Bearer token doğrular ve user_id döndürür
    try:
        token = credentials.credentials  # "Bearer <token>" dan sadece token kısmını alır
        payload = decode_token(token)
        if payload.get("type") != "access":
            raise UnauthorizedException("Geçersiz token tipi")
        user_id: str = payload.get("sub")
        if not user_id:
            raise UnauthorizedException("Token içinde kullanıcı bulunamadı")
        return user_id
    except JWTError:
        raise UnauthorizedException("Geçersiz veya süresi dolmuş token")

"""
HTTPBearer vs Header(...) farkı:
Eski yöntemde Header(...) ile authorization string olarak alıyorduk.
Swagger bunu body field sanıyordu, Authorize butonu çalışmıyordu.

HTTPBearer ile Swagger'ın Authorize butonuyla tam entegre çalışır.
credentials.credentials → sadece token string'ini verir, "Bearer " prefix'i olmadan.
"""