from dataclasses import dataclass
from datetime import datetime
from typing import Optional


@dataclass
class DeviceToken:
    id: str
    user_id: str
    fcm_token: str
    device_type: str  # android / ios
    device_name: Optional[str] = None
    app_version: Optional[str] = None
    is_active: bool = True
    last_seen: Optional[datetime] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


"""
DOSYA AKIŞI:
DeviceToken domain entity — saf Python, hiçbir dış bağımlılık yok.

device_type değerleri: android / ios

Tek bir kullanıcının birden fazla DeviceToken kaydı olabilir (çoklu cihaz desteği).
Aynı (user_id, fcm_token) ikilisi tekrar register edilirse repository
katmanında upsert (varsa güncelle, yoksa oluştur) yapılır.

is_active alanı logout'ta False'a çekilir; token DB'den silinmez,
böylece "bu kullanıcının geçmişte hangi cihazları olmuş" bilgisi de korunur.

Spring Boot karşılığı: @Entity sınıfı ama sadece alan tanımları,
JPA/Hibernate anotasyonu olmadan.
"""
