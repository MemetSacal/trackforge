from datetime import date
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.domain.entities.meal_compliance import MealCompliance
from app.domain.interfaces.i_meal_compliance_repository import IMealComplianceRepository
from app.infrastructure.db.models.meal_compliance_model import MealComplianceModel


class MealComplianceRepository(IMealComplianceRepository):
    # IMealComplianceRepository interface'inin PostgreSQL + SQLAlchemy implementasyonu

    def __init__(self, session: AsyncSession):
        # Session dışarıdan inject edilir — dependency injection
        self.session = session

    async def create(self, compliance: MealCompliance) -> MealCompliance:
        db_obj = MealComplianceModel(
            id=compliance.id,
            user_id=compliance.user_id,
            date=compliance.date,
            complied=compliance.complied,
            compliance_rate=compliance.compliance_rate,
            notes=compliance.notes,
            calories_consumed=compliance.calories_consumed,
            calories_target=compliance.calories_target,
            calorie_balance=compliance.calorie_balance,
            weekly_bank_balance=compliance.weekly_bank_balance,
            created_at=compliance.created_at,
        )
        self.session.add(db_obj)
        await self.session.flush()  # DB'ye yazar ama commit etmez — transaction açık kalır zaten söylemiştik flush
        return self._to_entity(db_obj)

    async def get_by_id(self, compliance_id: str) -> Optional[MealCompliance]:
        # SELECT * FROM meal_compliance WHERE id = ?
        result = await self.session.execute(
            select(MealComplianceModel).where(MealComplianceModel.id == compliance_id)
        )
        db_obj = result.scalar_one_or_none()  # Bulursa döner, bulamazsa None
        return self._to_entity(db_obj) if db_obj else None

    async def get_by_date(self, user_id: str, target_date: date) -> Optional[MealCompliance]:
        # SELECT * FROM meal_compliance WHERE user_id = ? AND date = ?
        # Aynı gün kontrolü için servis katmanı bunu kullanır
        result = await self.session.execute(
            select(MealComplianceModel).where(
                MealComplianceModel.user_id == user_id,
                MealComplianceModel.date == target_date
            )
        )
        db_obj = result.scalar_one_or_none()
        return self._to_entity(db_obj) if db_obj else None

    async def get_by_date_range(self, user_id: str, from_date: date, to_date: date) -> list[MealCompliance]:
        # SELECT * FROM meal_compliance WHERE user_id = ? AND date BETWEEN ? AND ? ORDER BY date
        result = await self.session.execute(
            select(MealComplianceModel).where(
                MealComplianceModel.user_id == user_id,
                MealComplianceModel.date >= from_date,
                MealComplianceModel.date <= to_date
            ).order_by(MealComplianceModel.date)  # Tarihe göre sıralı
        )
        return [self._to_entity(row) for row in result.scalars().all()]

    async def update(self, compliance: MealCompliance) -> MealCompliance:
        result = await self.session.execute(
            select(MealComplianceModel).where(MealComplianceModel.id == compliance.id)
        )
        db_obj = result.scalar_one_or_none()
        if not db_obj:
            return None
        db_obj.complied = compliance.complied
        db_obj.compliance_rate = compliance.compliance_rate
        db_obj.notes = compliance.notes
        # Kalori bankası alanları
        db_obj.calories_consumed = compliance.calories_consumed
        db_obj.calories_target = compliance.calories_target
        db_obj.calorie_balance = compliance.calorie_balance
        db_obj.weekly_bank_balance = compliance.weekly_bank_balance
        await self.session.flush()
        return self._to_entity(db_obj)

    async def delete(self, compliance_id: str) -> bool:
        result = await self.session.execute(
            select(MealComplianceModel).where(MealComplianceModel.id == compliance_id)
        )
        db_obj = result.scalar_one_or_none()
        if not db_obj:
            return False
        await self.session.delete(db_obj)
        await self.session.flush()
        return True

    def _to_entity(self, db_obj: MealComplianceModel) -> MealCompliance:
        return MealCompliance(
            id=db_obj.id,
            user_id=db_obj.user_id,
            date=db_obj.date,
            complied=db_obj.complied,
            compliance_rate=db_obj.compliance_rate,
            notes=db_obj.notes,
            # Kalori bankası alanları
            calories_consumed=db_obj.calories_consumed,
            calories_target=db_obj.calories_target,
            calorie_balance=db_obj.calorie_balance,
            weekly_bank_balance=db_obj.weekly_bank_balance,
            created_at=db_obj.created_at,
        )

"""
Genel akış:
DB → MealComplianceModel → _to_entity() → MealCompliance → Servis katmanı
Servis katmanı → MealCompliance → create() → MealComplianceModel → DB

NoteRepository'den farkı:
complied (bool) ve compliance_rate (float) alanları var
notes opsiyonel — content gibi zorunlu değil
"""