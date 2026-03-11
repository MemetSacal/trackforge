import uuid
from datetime import date, datetime, timezone
from app.domain.entities.meal_compliance import MealCompliance
from app.domain.interfaces.i_meal_compliance_repository import IMealComplianceRepository
from app.core.exceptions import BadRequestException, NotFoundException


class MealComplianceService:
    # Diyet uyum işlemlerinin iş mantığı burada
    # NoteService ile aynı mantık

    def __init__(self, compliance_repository: IMealComplianceRepository):
        # Repository dışarıdan inject edilir — interface üzerinden
        self.compliance_repository = compliance_repository

    async def create(self, user_id: str, data) -> MealCompliance:
        # Aynı gün zaten kayıt var mı kontrol et
        existing = await self.compliance_repository.get_by_date(user_id, data.date)
        if existing:
            raise BadRequestException(f"{data.date} tarihine ait diyet kaydı zaten mevcut")

        compliance = MealCompliance(
            id=str(uuid.uuid4()),
            user_id=user_id,
            date=data.date,
            complied=data.complied,
            compliance_rate=data.compliance_rate,
            notes=data.notes,
            created_at=datetime.now(timezone.utc),
        )
        return await self.compliance_repository.create(compliance)

    async def get_by_date(self, user_id: str, target_date: date) -> MealCompliance:
        compliance = await self.compliance_repository.get_by_date(user_id, target_date)
        if not compliance:
            raise NotFoundException(f"{target_date} tarihine ait diyet kaydı bulunamadı")
        return compliance

    async def get_by_date_range(self, user_id: str, from_date: date, to_date: date) -> list[MealCompliance]:
        if from_date > to_date:
            raise BadRequestException("Başlangıç tarihi bitiş tarihinden büyük olamaz")
        return await self.compliance_repository.get_by_date_range(user_id, from_date, to_date)

    async def update(self, user_id: str, compliance_id: str, data) -> MealCompliance:
        # Kaydın var olduğunu ve bu kullanıcıya ait olduğunu kontrol et
        existing = await self.compliance_repository.get_by_id(compliance_id)
        if not existing:
            raise NotFoundException("Diyet kaydı bulunamadı")
        if existing.user_id != user_id:
            raise NotFoundException("Diyet kaydı bulunamadı")  # Güvenlik gereği 404

        # Sadece gönderilen alanları güncelle
        existing.complied = data.complied if data.complied is not None else existing.complied
        existing.compliance_rate = data.compliance_rate if data.compliance_rate is not None else existing.compliance_rate
        existing.notes = data.notes if data.notes is not None else existing.notes
        return await self.compliance_repository.update(existing)

    async def delete(self, user_id: str, compliance_id: str) -> bool:
        existing = await self.compliance_repository.get_by_id(compliance_id)
        if not existing:
            raise NotFoundException("Diyet kaydı bulunamadı")
        if existing.user_id != user_id:
            raise NotFoundException("Diyet kaydı bulunamadı")  # Güvenlik gereği 404
        return await self.compliance_repository.delete(compliance_id)

"""
Genel akış:
Endpoint → MealComplianceService → IMealComplianceRepository → DB

NoteService'den farkı:
content zorunluluğu yok — notes tamamen opsiyonel
complied bool kontrolü — None check'te dikkatli olmak gerekir
"""