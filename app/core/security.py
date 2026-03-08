from datetime import datetime, timedelta, timezone
from jose import JWTError, jwt
from passlib.context import CryptContext
from app.core.config import get_settings

settings = get_settings()

# Şifre hashleme için bcrypt kullanıyor
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(password: str) -> str:
    # Düz şifreyi hashler — DB'ye hep hash kaydedilir
    return pwd_context.hash(password)


def verify_password(plain: str, hashed: str) -> bool:
    # Girilen şifre ile hash eşleşiyor mu kontrol eder
    return pwd_context.verify(plain, hashed)


def create_access_token(data: dict) -> str:
    # JWT access token üretir (kısa ömürlü — 15 dk)
    payload = data.copy()
    expire = datetime.now(timezone.utc) + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    payload.update({"exp": expire, "type": "access"})
    return jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.ALGORITHM)


def create_refresh_token(data: dict) -> str:
    # JWT refresh token üretir (uzun ömürlü — 7 gün)
    payload = data.copy()
    expire = datetime.now(timezone.utc) + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    payload.update({"exp": expire, "type": "refresh"})
    return jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.ALGORITHM)


def decode_token(token: str) -> dict:
    # Token'ı çözer ve payload'ı döndürür, geçersizse hata fırlatır
    return jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])

#javadaki mantıkla aynı (bkz libraryapi security config) 