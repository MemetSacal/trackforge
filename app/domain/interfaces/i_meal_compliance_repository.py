from abc import ABC, abstractmethod
from datetime import date
from typing import Optional
from app.domain.entities.meal_compliance import MealCompliance


class IMealComplianceRepository(ABC):
    # Abstract repository interface — Spring'deki JpaRepository gibi
    # MealComplianceRepository bu interface'i implement eder
    # Service katmanı direkt bu interface'i çağırır, implementasyonu bilmez

    @abstractmethod
    async def create(self, compliance: MealCompliance) -> MealCompliance:
        # Yeni diyet uyum kaydı oluştur
        pass

    @abstractmethod
    async def get_by_id(self, compliance_id: str) -> Optional[MealCompliance]:
        # ID ile tek kayıt getir — update/delete öncesi sahiplik kontrolü için
        pass

    @abstractmethod
    async def get_by_date(self, user_id: str, target_date: date) -> Optional[MealCompliance]:
        # Belirli bir günün kaydını getir
        # Günde 1 kayıt kontrolü için servis katmanı bunu kullanır
        pass

    @abstractmethod
    async def get_by_date_range(self, user_id: str, from_date: date, to_date: date) -> list[MealCompliance]:
        # Tarih aralığındaki tüm kayıtları getir — haftalık/aylık rapor için
        pass

    @abstractmethod
    async def update(self, compliance: MealCompliance) -> MealCompliance:
        # Mevcut kaydı güncelle
        pass

    @abstractmethod
    async def delete(self, compliance_id: str) -> bool:
        # Kaydı sil — True: başarılı, False: kayıt bulunamadı
        pass

"""
Genel akış:
Service → IMealComplianceRepository (interface) → MealComplianceRepository (infrastructure)

Repository pattern avantajı:
Service katmanı sadece bu interface'i bilir.
Yarın PostgreSQL yerine MongoDB kullansak bile
service koduna dokunmadan sadece yeni bir repository yazarız.

WeeklyNote interface ile neredeyse aynı yapı.
Fark: MealCompliance'da complied (bool) ve compliance_rate (float) var.
"""