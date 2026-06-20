import uuid
import re
from datetime import datetime, timezone
from backend.app.domain.entities.user import User
from backend.app.domain.interfaces.i_user_repository import IUserRepository
from backend.app.core.security import hash_password, verify_password, create_access_token, create_refresh_token
from backend.app.core.exceptions import BadRequestException, UnauthorizedException
from backend.app.core.email_service import generate_email_token, token_expiry, send_verification_email

# FIX #2: Tam email doğrulama altyapısı (SMTP) ileride eklenecek.
# Şimdilik bilinen throwaway/geçici email domain'lerini blokla.
# Kaynak: yaygın disposable email sağlayıcıları listesi.
_THROWAWAY_DOMAINS = {
    'mailinator.com','guerrillamail.com','tempmail.com','10minutemail.com',
    'throwaway.email','yopmail.com','sharklasers.com','guerrillamailblock.com',
    'grr.la','guerrillamail.info','guerrillamail.biz','guerrillamail.de',
    'guerrillamail.net','guerrillamail.org','spam4.me','trashmail.com',
    'trashmail.me','trashmail.net','dispostable.com','maildrop.cc',
    'fakeinbox.com','mailnull.com','spamgourmet.com','spamgourmet.net',
    'spamgourmet.org','spamhereplease.com','spam.la','binkmail.com',
    'bobmail.info','chammy.info','devnullmail.com','discard.email',
    'discardmail.com','discardmail.de','dodgit.com','dumpmail.de',
    'e4ward.com','emailias.com','emailsensei.com','emailtemporario.com.br',
    'enterto.com','filzmail.com','fivemail.de','fleckens.hu',
    'getonemail.com','getonemail.net','haltospam.com','ieh-mail.de',
    'imgof.com','imstations.com','inoutmail.de','inoutmail.eu',
    'jetable.com','jetable.fr.nf','jetable.net','jetable.org',
    'kasmail.com','kaspop.com','killmail.com','killmail.net',
    'klassmaster.com','klassmaster.net','link2mail.net','litedrop.com',
    'lol.ovpn.to','lookugly.com','lopl.co.cc','lortemail.dk',
    'lr78.com','maileater.com','mailexpire.com','mailfreeonline.com',
    'mailguard.me','mailin8r.com','mailme.gq','mailme.ir',
    'mailme24.com','mailmetrash.com','mailmoat.com','mailnew.com',
    'mailnull.com','mailsiphon.com','mailslite.com','mailzilla.com',
    'mbx.cc','mega.zik.dj','moncourrier.fr.nf','monemail.fr.nf',
    'monmail.fr.nf','mt2009.com','mx0.wwwnew.eu','my10minutemail.com',
    'mytempemail.com','mytempmail.com','netzidiot.de','noclickemail.com',
    'nogmailspam.info','nomail.pw','nomail.xl.cx','nomail2me.com',
    'nospam.ze.tc','nospam4.us','nospamfor.us','nospammail.net',
    'nowmymail.com','nus.edu.sg','objectmail.com','obobbo.com',
}


class AuthService:
    # Auth işlemlerinin iş mantığı burada — register ve login
    # Spring'deki @Service ile aynı mantık

    def __init__(self, user_repository: IUserRepository):
        # Repository dışarıdan inject edilir — interface üzerinden
        # Somut implementasyonu bilmez, sadece interface'i tanır
        self.user_repository = user_repository

    async def register(self, email: str, password: str, full_name: str) -> dict:
        # Throwaway domain kontrolü
        domain = email.split('@')[-1].lower().strip()
        if domain in _THROWAWAY_DOMAINS:
            raise BadRequestException(
                "Geçici/throwaway email adresleriyle kayıt olunamaz. "
                "Lütfen kalıcı bir email adresi kullanın."
            )

        # Şifre minimum güç kontrolü
        if len(password) < 8:
            raise BadRequestException("Şifre en az 8 karakter olmalıdır.")
        if not re.search(r'[A-Za-z]', password) or not re.search(r'\d', password):
            raise BadRequestException("Şifre en az bir harf ve bir rakam içermelidir.")

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

        # Email doğrulama token'ı oluştur ve gönder
        ev_token  = generate_email_token()
        ev_expiry = token_expiry()
        await self.user_repository.set_email_token(created_user.id, ev_token, ev_expiry)
        await send_verification_email(created_user.email, created_user.full_name, ev_token)

        return self._generate_tokens(created_user)

    async def login(self, email: str, password: str) -> dict:
        user = await self.user_repository.get_by_email(email)
        if not user:
            raise UnauthorizedException("Email veya şifre hatalı")
        if not verify_password(password, user.password_hash):
            raise UnauthorizedException("Email veya şifre hatalı")

        # Email doğrulanmamışsa token döndür ama yanıta flag ekle.
        # Engel koymuyoruz — kullanıcı uygulamayı kullanabilir, banner görür.
        tokens = self._generate_tokens(user)
        tokens["email_verified"] = getattr(user, "email_verified", True)
        return tokens

    async def verify_email_token(self, token: str) -> dict:
        """GET /auth/verify-email?token=... — browser'dan açılır."""
        from datetime import timezone
        user = await self.user_repository.get_by_email_token(token)
        if not user:
            raise BadRequestException("Geçersiz doğrulama linki.")
        expires = getattr(user, "email_token_expires", None)
        if expires:
            # Offset-naive datetime'leri karşılaştırırken UTC'ye normalize et
            now = datetime.now(timezone.utc)
            if expires.tzinfo is None:
                from datetime import timezone as tz
                expires = expires.replace(tzinfo=tz.utc)
            if now > expires:
                raise BadRequestException(
                    "Doğrulama linkinin süresi dolmuş. Yeni link için uygulamadan tekrar talep et."
                )
        await self.user_repository.verify_email(user.id)
        return {"message": "E-posta adresin başarıyla doğrulandı! Uygulamaya dönebilirsin. 🎉"}

    async def resend_verification(self, user_id: str) -> dict:
        """POST /auth/resend-verification — uygulama içinden."""
        from backend.app.core.exceptions import BadRequestException
        user = await self.user_repository.get_by_id(user_id)
        if not user:
            raise BadRequestException("Kullanıcı bulunamadı.")
        if getattr(user, "email_verified", False):
            return {"message": "Email zaten doğrulanmış."}
        ev_token  = generate_email_token()
        ev_expiry = token_expiry()
        await self.user_repository.set_email_token(user.id, ev_token, ev_expiry)
        sent = await send_verification_email(user.email, user.full_name, ev_token)
        if sent:
            return {"message": "Doğrulama emaili tekrar gönderildi."}
        return {"message": "Email gönderilemedi. Lütfen daha sonra tekrar dene."}

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