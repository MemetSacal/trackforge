from pydantic import BaseModel, EmailStr


class RegisterRequest(BaseModel):
    # API'ye gelen register isteğinin şeması — Pydantic otomatik validate eder
    email: EmailStr  # Geçerli email formatı zorunlu
    password: str
    full_name: str


class LoginRequest(BaseModel):
    # API'ye gelen login isteğinin şeması
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    # Login/register sonrası dönen token şeması
    access_token: str
    refresh_token: str
    token_type: str = "bearer"  # Default "bearer"


class UserResponse(BaseModel):
    # Kullanıcı bilgilerini dönerken kullanılan şema
    # password_hash burada yok — dışarıya asla şifre gitmez
    id: str
    email: str
    full_name: str

"""
Genel akış:
Request gelir → Pydantic şema validate eder → Servis katmanına gider → Response şemasına dönüşür → Client'a gider

EmailStr — geçerli email formatı değilse Pydantic otomatik 422 Unprocessable Entity döner
UserResponse'da password_hash yok — güvenlik gereği dışarıya şifre bilgisi gitmez
"""