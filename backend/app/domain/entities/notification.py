from dataclasses import dataclass
from datetime import datetime
from typing import Optional, Dict, Any


@dataclass
class Notification:
    id: str
    user_id: str
    title: str
    body: str
    type: str  # friend_request / friend_accepted / ai_report / streak_warning / premium / system / workout / meal
    data: Optional[Dict[str, Any]] = None
    is_read: bool = False
    created_at: Optional[datetime] = None


"""
DOSYA AKIŞI:
Notification domain entity — saf Python, hiçbir dış bağımlılık yok.

Bu, in-app bildirim GEÇMİŞİNİ tutar (şu ana kadar Flutter tarafında
SharedPreferences'ta tutulan 'in_app_notifications' listesinin backend
karşılığı). Telefon değişse / uygulama silinse bile geçmiş kaybolmaz.

type alanı bilinçli olarak STRING tutuluyor, native DB enum DEĞİL.
Sebep: TrackForge'da yakın zamanda 37 parçalı bir Alembic migration
karmaşası yaşandı (tek baseline'a indirgendi). PostgreSQL native enum'a
yeni bir değer eklemek ALTER TYPE gerektirir ve migration sürtünmesi
yaratır. String + Pydantic Literal (schema katmanında) validasyonu
hem esnek hem de migration-ağrısız bir çözüm.

Geçerli type değerleri (Pydantic Literal ile application/schemas/notification.py'de
sınırlandırılacak):
  friend_request, friend_accepted, ai_report, streak_warning,
  premium, system, workout, meal

data alanı deep-link payload'ı taşır, örn:
  {"type": "friend_request", "user_id": "42", "request_id": "91"}
Flutter tarafında bu type'a göre doğru ekrana yönlendirme yapılır.

Spring Boot karşılığı: @Entity sınıfı ama sadece alan tanımları,
JPA/Hibernate anotasyonu olmadan.
"""
