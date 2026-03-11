from dataclasses import dataclass
from datetime import date, datetime
from typing import Optional


@dataclass
class BodyMeasurement:
    # Domain entity — SQLAlchemy'den bağımsız, saf Python sınıfı
    # User entity ile aynı mantık, hiçbir framework'e bağımlı değil

    id: str                             # UUID — str olarak saklıyoruz
    user_id: str                        # FK — hangi kullanıcıya ait
    date: date                          # Zaman referansı — DATE_BASED mimari, hafta bu tarihten hesaplanır
    weight_kg: Optional[float]          # Zorunlu değil — sadece belirli ölçümler girilmiş olabilir
    body_fat_pct: Optional[float]       # Vücut yağ yüzdesi
    muscle_mass_kg: Optional[float]     # Kas kütlesi
    waist_cm: Optional[float]           # Bel
    chest_cm: Optional[float]           # Göğüs
    hip_cm: Optional[float]             # Kalça
    arm_cm: Optional[float]             # Kol
    leg_cm: Optional[float]             # Bacak
    created_at: datetime                # Kaydın oluşturulma zamanı

"""
Neden tüm ölçüm alanları Optional?
Kullanıcı her ölçümü her seferinde girmek zorunda değil.
Sadece kilosunu girmek isteyebilir, bel ölçüsünü girmeyebilir.
None olan alanlar DB'de NULL olarak saklanır.

DATE_BASED yaklaşım:
Hafta numarası DB'de saklanmıyor, date alanından Python'da hesaplanıyor.
Örnek: date=2026-03-10 → bu tarihin hangi hafta olduğu servis katmanında bulunur.
Bu sayede hafta tanımı değişse bile migration gerekmez.

Genel akış:
API Request → Schema validate → Service → BodyMeasurement entity oluştur → Repository → DB
"""