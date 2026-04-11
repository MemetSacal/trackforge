from abc import ABC, abstractmethod
from backend.app.domain.entities.user import User


class IUserRepository(ABC):
    # Abstract repository interface — Clean Architecture'da domain katmanı
    # infrastructure'ın nasıl çalıştığını bilmez, sadece ne yapabileceğini bilir
    # Spring'deki JpaRepository interface'i gibi düşün

    @abstractmethod
    async def create(self, user: User) -> User:
        # Yeni kullanıcı oluştur
        pass

    @abstractmethod
    async def get_by_id(self, user_id: str) -> User | None:
        # ID ile kullanıcı getir, bulunamazsa None döner
        pass

    @abstractmethod
    async def get_by_email(self, email: str) -> User | None:
        # Email ile kullanıcı getir, bulunamazsa None döner
        pass

    @abstractmethod
    async def update(self, user: User) -> User:
        # Kullanıcıyı güncelle
        pass

"""
Repository nin ne olduğunu zaten Spring Boot dan biliyoruz 

i_ prefix'i neden var? Interface olduğunu belirtmek için. 
Bu sınıf sadece "ne yapılabilir" diyor, "nasıl yapılır" demiyor. 
@abstractmethod olan her method somut sınıf tarafından implement edilmek zorunda.

Bu yapının işte Stringe uyarlanışı aşağıdaki şekilde olur 

public interface UserRepository extends JpaRepository<User, String> {
    Optional<User> findByEmail(String email);
}

Fark şu: Spring bunu otomatik implement ediyor, bizde infrastructure/repositories/user_repository.py de kendimiz yazacağız.

hatırlatma olarak buraya senkron ve asenkron fonksiyon farkını özetliyorum 

Normal (sync) durumda:
İstek geldi → DB'ye sor → bekle bekle bekle → cevap geldi → devam et
Bu sürede başka hiçbir istek işlenemiyor.
Async durumda:
İstek geldi → DB'ye sor → beklerken başka istekleri işle → cevap geldi → devam et

projemize baktığımız zaman FastAPI kullanıyoruz burada zaten async tabanlı SQLAlchmey de async kurduk 

methodları abstract tanımlama sebebimiz de aslında i_ prefixi kullanmamızla aynı kapıya çıkıyor arada ki temel fark 
i_ prefix'i → "bu bir interface" diye okuyucuya söylüyor
@abstractmethod → "bu metodları implement etmek zorundasın" diye Python'a söylüyor
"""