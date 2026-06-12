import uuid
from datetime import datetime, timezone
from backend.app.domain.entities.user import User
from backend.app.domain.interfaces.i_user_repository import IUserRepository
from backend.app.core.security import hash_password, verify_password, create_access_token, create_refresh_token
from backend.app.core.exceptions import BadRequestException, UnauthorizedException


class AuthService:
    # Auth işlemlerinin iş mantığı burada — register ve login
    # Spring'deki @Service ile aynı mantık

    def __init__(self, user_repository: IUserRepository):
        # Repository dışarıdan inject edilir — interface üzerinden
        # Somut implementasyonu bilmez, sadece interface'i tanır
        self.user_repository = user_repository

    async def register(self, email: str, password: str, full_name: str) -> dict:
        # Aynı email ile kayıt varsa hata fırlat
        existing_user = await self.user_repository.get_by_email(email)
        if existing_user:
            raise BadRequestException("Bu email zaten kayıtlı")

        # Yeni kullanıcı oluştur
        now = datetime.now(timezone.utc)
        user = User(
            id=str(uuid.uuid4()),
            email=email,
            password_hash=hash_password(password),  # Şifreyi hashle
            full_name=full_name,
            created_at=now,
            updated_at=now,
        )
        created_user = await self.user_repository.create(user)

        return self._generate_tokens(created_user)

    async def login(self, email: str, password: str) -> dict:
        # Kullanıcıyı email ile bul
        user = await self.user_repository.get_by_email(email)
        if not user:
            raise UnauthorizedException("Email veya şifre hatalı")

        # Şifreyi doğrula
        if not verify_password(password, user.password_hash):
            raise UnauthorizedException("Email veya şifre hatalı")

        # Token üret ve döndür
        return self._generate_tokens(user)

    def _generate_tokens(self, user: User) -> dict:
        # access ve refresh token üretir — v3: token_version claim'i ile
        ver = getattr(user, "token_version", 0)
        access_token = create_access_token({"sub": user.id}, token_version=ver)
        refresh_token = create_refresh_token({"sub": user.id}, token_version=ver)
        return {
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "bearer",
            "user_id": user.id,
            "is_premium": getattr(user, 'is_premium', False),
        }

    async def refresh(self, refresh_token: str) -> dict:
        from backend.app.core.security import decode_token
        from jose import JWTError
        try:
            payload = decode_token(refresh_token)
            if payload.get("type") != "refresh":
                raise UnauthorizedException("Geçersiz token tipi")
            user_id = payload.get("sub")
            if not user_id:
                raise UnauthorizedException("Token geçersiz")
        except JWTError:
            raise UnauthorizedException("Geçersiz veya süresi dolmuş token")

        user = await self.user_repository.get_by_id(user_id)
        if not user:
            raise UnauthorizedException("Kullanıcı bulunamadı")

        # v3: token versiyonu eşleşmiyorsa bu refresh token logout/şifre
        # değişimi ÖNCESİNDEN kalma demektir — reddet.
        token_ver = payload.get("ver", 0)
        if token_ver != getattr(user, "token_version", 0):
            raise UnauthorizedException("Oturum sonlandırılmış, tekrar giriş yapın")

        return self._generate_tokens(user)

    async def logout(self, user_id: str) -> None:
        """v3: Sunucu tarafı logout — token_version +1.
        Mobildeki prefs.clear() sadece cihazı temizliyordu; refresh token
        sunucuda 7 gün geçerli kalıyordu. Artık gerçekten ölüyor."""
        await self.user_repository.bump_token_version(user_id)

    async def delete_account(self, user_id: str, password: str) -> None:
        """v3: Hesap silme — Play Store zorunluluğu + KVKK m.7 (silme hakkı).
        Şifre doğrulaması ister: çalınan telefonda açık oturumla
        hesap silinememesi için."""
        user = await self.user_repository.get_by_id(user_id)
        if not user:
            raise UnauthorizedException("Kullanıcı bulunamadı")
        if not verify_password(password, user.password_hash):
            raise UnauthorizedException("Şifre hatalı — hesap silinemedi")
        await self.user_repository.delete(user_id)
"""
Clean Architecture'da servis katmanı zaten implementasyon — yani ayrı bir impl sınıfına gerek yok.
Spring Boot'ta şöyle yapıyordun:
javapublic interface UserService { ... }
public class UserServiceImpl implements UserService { ... }
```

Bunu genellikle Spring'in dependency injection sistemi gerektirdiği için yapıyorduk. Python/FastAPI'de bu zorunluluk yok.

Bizim mimaride şöyle:
```
IUserRepository (interface) → UserRepository (impl) ✅ — çünkü ileride farklı DB'ye geçebiliriz
AuthService (direkt impl) ✅ — servis katmanında interface'e gerek yok
Repository'de interface kullanmamızın sebebi storage soyutlaması — yarın MongoDB'ye geçersen sadece yeni bir repository yazarsın, servis değişmez.
"""

"""
_generate_tokens için ise her ikisinde de (`register` ve `login`) token üretiliyor.
`{"sub": user.id}` — JWT standardında `sub` = subject = bu tokenın sahibi kim. 
`_` prefix'i private method olduğunu belirtiyor, sadece bu sınıf içinde kullanılıyor.

---

**Genel akış:**

Register: email/şifre gelir → email kontrolü → User oluştur → DB'ye kaydet → token döndür
Login: email/şifre gelir → kullanıcıyı bul → şifreyi doğrula → token döndür
"""