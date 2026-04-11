from datetime import date
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from backend.app.domain.entities.body_measurement import BodyMeasurement
from backend.app.domain.interfaces.i_measurement_repository import IMeasurementRepository
from backend.app.infrastructure.db.models.measurement_model import MeasurementModel


class MeasurementRepository(IMeasurementRepository):
    # IMeasurementRepository interface'inin PostgreSQL + SQLAlchemy implementasyonu
    # UserRepository ile aynı mantık

    def __init__(self, session: AsyncSession):
        # Session dışarıdan inject edilir
        self.session = session

    async def create(self, measurement: BodyMeasurement) -> BodyMeasurement:
        db_obj = MeasurementModel(
            id=measurement.id,
            user_id=measurement.user_id,
            date=measurement.date,
            weight_kg=measurement.weight_kg,
            body_fat_pct=measurement.body_fat_pct,
            muscle_mass_kg=measurement.muscle_mass_kg,
            waist_cm=measurement.waist_cm,
            chest_cm=measurement.chest_cm,
            hip_cm=measurement.hip_cm,
            arm_cm=measurement.arm_cm,
            leg_cm=measurement.leg_cm,
            created_at=measurement.created_at,
        )
        self.session.add(db_obj)
        await self.session.flush()
        return self._to_entity(db_obj)

    async def get_by_id(self, measurement_id: str) -> Optional[BodyMeasurement]:
        # SELECT * FROM body_measurements WHERE id = ?
        result = await self.session.execute(
            select(MeasurementModel).where(MeasurementModel.id == measurement_id)
        )
        db_obj = result.scalar_one_or_none()
        return self._to_entity(db_obj) if db_obj else None

    async def get_by_date(self, user_id: str, target_date: date) -> Optional[BodyMeasurement]:
        # SELECT * FROM body_measurements WHERE user_id = ? AND date = ?
        # Aynı gün kontrolü için servis katmanı bunu kullanır
        result = await self.session.execute(
            select(MeasurementModel).where(
                MeasurementModel.user_id == user_id,
                MeasurementModel.date == target_date
            )
        )
        db_obj = result.scalar_one_or_none()
        return self._to_entity(db_obj) if db_obj else None

    async def get_by_date_range(self, user_id: str, from_date: date, to_date: date) -> list[BodyMeasurement]:
        # SELECT * FROM body_measurements WHERE user_id = ? AND date BETWEEN ? AND ? ORDER BY date
        result = await self.session.execute(
            select(MeasurementModel).where(
                MeasurementModel.user_id == user_id,
                MeasurementModel.date >= from_date,
                MeasurementModel.date <= to_date
            ).order_by(MeasurementModel.date)
        )
        return [self._to_entity(row) for row in result.scalars().all()]

    async def get_all(self, user_id: str) -> list[BodyMeasurement]:
        # Tüm ölçüm geçmişi — tarihe göre sıralı
        result = await self.session.execute(
            select(MeasurementModel)
            .where(MeasurementModel.user_id == user_id)
            .order_by(MeasurementModel.date)
        )
        return [self._to_entity(row) for row in result.scalars().all()]

    async def update(self, measurement: BodyMeasurement) -> BodyMeasurement:
        result = await self.session.execute(
            select(MeasurementModel).where(MeasurementModel.id == measurement.id)
        )
        db_obj = result.scalar_one_or_none()
        if not db_obj:
            return None
        # Sadece ölçüm alanlarını güncelle, id/user_id/date değişmez
        db_obj.weight_kg = measurement.weight_kg
        db_obj.body_fat_pct = measurement.body_fat_pct
        db_obj.muscle_mass_kg = measurement.muscle_mass_kg
        db_obj.waist_cm = measurement.waist_cm
        db_obj.chest_cm = measurement.chest_cm
        db_obj.hip_cm = measurement.hip_cm
        db_obj.arm_cm = measurement.arm_cm
        db_obj.leg_cm = measurement.leg_cm
        await self.session.flush()
        return self._to_entity(db_obj)

    async def delete(self, measurement_id: str) -> bool:
        result = await self.session.execute(
            select(MeasurementModel).where(MeasurementModel.id == measurement_id)
        )
        db_obj = result.scalar_one_or_none()
        if not db_obj:
            return False
        await self.session.delete(db_obj)
        await self.session.flush()
        return True

    def _to_entity(self, db_obj: MeasurementModel) -> BodyMeasurement:
        # MeasurementModel (SQLAlchemy) → BodyMeasurement (domain entity)
        # Servis katmanı SQLAlchemy'yi hiç görmez
        return BodyMeasurement(
            id=db_obj.id,
            user_id=db_obj.user_id,
            date=db_obj.date,
            weight_kg=db_obj.weight_kg,
            body_fat_pct=db_obj.body_fat_pct,
            muscle_mass_kg=db_obj.muscle_mass_kg,
            waist_cm=db_obj.waist_cm,
            chest_cm=db_obj.chest_cm,
            hip_cm=db_obj.hip_cm,
            arm_cm=db_obj.arm_cm,
            leg_cm=db_obj.leg_cm,
            created_at=db_obj.created_at,
        )

"""
Genel akış:
DB → MeasurementModel → _to_entity() → BodyMeasurement → Servis katmanı
Servis katmanı → BodyMeasurement → create() → MeasurementModel → DB

get_by_date_range neden order_by var?
Grafik çizerken tarihe göre sıralı veri lazım.
Sırasız veri gelirse Flutter tarafında grafik bozulur.
"""