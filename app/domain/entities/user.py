from dataclasses import dataclass
from datetime import datetime


@dataclass
class User:
    # Domain entity — SQLAlchemy'den bağımsız, saf Python sınıfı
    # Clean Architecture'da domain katmanı hiçbir framework'e bağımlı değil
    # Spring'deki @Entity değil, saf bir POJO gibi düşün

    id: str #
    email: str
    password_hash: str
    full_name: str
    created_at: datetime
    updated_at: datetime

"""
id UUID olarak üretiliyor ve str(uuid.uuid4()) ile stringe çevriliyor — "796258c6-8f96-4a2f-..." formatında.
Hash değil ama string çünkü UUID'yi string olarak saklıyoruz. Geriye kalanlar zaten direkt String olarak yazılacağı için 
str tanımladık 

UUID nin tanımına bakarsak : UUID: Benzersiz kimlik üretme sistemi. uuid4() tamamen rastgele bir ID üretiyor eşsiz
Hash dediğimiz olayda ise : Hash (bcrypt): Tek yönlü şifreleme. "1234" → "$2b$12$xyz..." oluyor, geri döndürülemez.
Amacı "bu veriyi güvenli sakla, orijinaline ulaşılamasın."
Kısaca:

UUID = "Bu kim?" sorusuna cevap
Hash = "Bu veriyi kimse okuyamasın"

Datetime tarihi tutmak için pythonun built-in tarih/saat tipi
"""