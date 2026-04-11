from abc import ABC, abstractmethod
from datetime import date
from typing import Optional
from backend.app.domain.entities.body_measurement import BodyMeasurement


class IMeasurementRepository(ABC):
    # Abstract repository interface — infrastructure'ın nasıl çalıştığını bilmez
    # IUserRepository ile aynı mantık, sadece BodyMeasurement entity'si için

    @abstractmethod
    async def create(self, measurement: BodyMeasurement) -> BodyMeasurement:
        # Yeni ölçüm kaydı oluştur
        pass

    @abstractmethod
    async def get_by_id(self, measurement_id: str) -> Optional[BodyMeasurement]:
        # ID ile tek ölçüm getir
        pass

    @abstractmethod
    async def get_by_date(self, user_id: str, date: date) -> Optional[BodyMeasurement]:
        # Belirli bir günün ölçümü — kullanıcı başına günde 1 ölçüm mantığı
        # Aynı gün tekrar ölçüm girilirse servis katmanı bunu kontrol edecek
        pass

    @abstractmethod
    async def get_by_date_range(self, user_id: str, from_date: date, to_date: date) -> list[BodyMeasurement]:
        # Tarih aralığı sorgusu — grafik ve haftalık rapor için kullanılacak
        # GET /measurements?from=2026-03-01&to=2026-03-31
        pass

    @abstractmethod
    async def get_all(self, user_id: str) -> list[BodyMeasurement]:
        # Tüm ölçüm geçmişi — GET /measurements/history endpoint'i için
        pass

    @abstractmethod
    async def update(self, measurement: BodyMeasurement) -> BodyMeasurement:
        # Mevcut ölçümü güncelle
        pass

    @abstractmethod
    async def delete(self, measurement_id: str) -> bool:
        # Ölçümü sil — başarılıysa True döner
        pass

"""
Genel akış:
Service katmanı bu interface'i çağırır → UserRepository'de olduğu gibi
infrastructure/repositories/measurement_repository.py bu interface'i implement edecek

get_by_date neden önemli?
Aynı kullanıcı aynı gün iki kez ölçüm giremez — servis katmanı önce
get_by_date ile kontrol yapacak, kayıt varsa BadRequestException fırlatacak.
"""