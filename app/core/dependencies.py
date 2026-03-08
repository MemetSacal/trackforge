"""

FastAPI'de Dependency Injection şöyle çalışır:
Bir endpoint'e Depends(get_current_user) yazdığında FastAPI şunu yapıyor:
"Bu endpoint çağrılmadan önce get_current_user fonksiyonunu çalıştır, sonucunu endpoint'e ver."
Yani Spring'deki @Autowired veya constructor injection değil, daha çok SecurityFilterChain'deki
"bu isteği geçmeden önce şu kontrolü yap" mantığı.

"""""
from fastapi import Depends, Header
from jose import JWTError
from app.core.security import decode_token
from app.core.exceptions import UnauthorizedException


async def get_current_user(authorization: str = Header(...)):
    # Her korunan endpoint'in bağımlılığı — Bearer token doğrular
    # Spring'deki SecurityFilterChain .anyRequest().authenticated() ile aynı mantık
    try:
        scheme, token = authorization.split() # Bearer gelen headeri 2 ye böler scheme = "Bearer", token = JWT string.
        if scheme.lower() != "bearer":
            raise UnauthorizedException("Geçersiz token formatı")
        payload = decode_token(token) # Token'ı çöz, içinden sub değerini al — bu bizim user_id'miz.
        user_id: str = payload.get("sub")# JWT standardında sub = subject = kimin tokeni olduğu.
        if user_id is None:
            raise UnauthorizedException("Token içinde kullanıcı bulunamadı")
        return user_id
    except (JWTError, ValueError):
        raise UnauthorizedException("Geçersiz veya süresi dolmuş token")