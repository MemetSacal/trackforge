from pydantic_settings import BaseSettings #Normal BaseModel'den farkı .env dosyasını tanıması.
from pydantic import ConfigDict # Pydantic V2'de ayarları tanımlamak için kullanılan yapı. Eski class Config yerine bu geliyor.
from functools import lru_cache #Python'un built-in cache mekanizması. Bir fonksiyonun sonucunu bellekte tutar, aynı fonksiyon tekrar çağrılınca .env'i tekrar okumak yerine cache'den döner.


class Settings(BaseSettings):
    model_config = ConfigDict(
        env_file=".env",
        env_file_encoding="utf-8"
    )

    # Database
    DATABASE_URL: str # Zorunlu — .env'de tanımlı olması lazım, yoksa uygulama başlamaz.

    # JWT
    SECRET_KEY: str # Zorunlu — .env'de tanımlı olması lazım, yoksa uygulama başlamaz.
    ALGORITHM: str = "HS256" # Default değer var, .env'de tanımlı değilse "HS256" kullanılır.


    ACCESS_TOKEN_EXPIRE_MINUTES: int = 15
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    # Storage
    STORAGE_TYPE: str = "local"
    STORAGE_BASE_PATH: str = "storage/"


@lru_cache()
def get_settings() -> Settings:
    return Settings()
# @lru_cache kısmı Settings nesnesini oluşturup döndüren fonksiyon.
# @lru_cache() sayesinde ilk çağrıda bir kere oluşturulur, sonraki çağrılarda aynı nesne döner.
# Spring'deki @Bean singleton mantığıyla aynı.

# projenin ilk 2 satırında hata var olarak gözüküyor fakat bu bir uyarı gibi düşün kod çalışıyor bir engel değil