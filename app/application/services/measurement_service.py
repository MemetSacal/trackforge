import uuid
from datetime import date, datetime, timezone
from typing import Optional # noqa
from app.domain.entities.body_measurement import BodyMeasurement
from app.domain.interfaces.i_measurement_repository import IMeasurementRepository
from app.core.exceptions import BadRequestException, NotFoundException


class MeasurementService:
    # Ölçüm işlemlerinin iş mantığı burada
    # AuthService ile aynı mantık — direkt implementasyon, interface'e gerek yok

    def __init__(self, measurement_repository: IMeasurementRepository):
        # Repository dışarıdan inject edilir — interface üzerinden
        self.measurement_repository = measurement_repository

    async def create(self, user_id: str, data) -> BodyMeasurement:
        # Aynı gün zaten ölçüm var mı kontrol et
        existing = await self.measurement_repository.get_by_date(user_id, data.date)
        if existing:
            raise BadRequestException(f"{data.date} tarihine ait ölçüm zaten mevcut")

        measurement = BodyMeasurement(
            id=str(uuid.uuid4()),
            user_id=user_id,
            date=data.date,
            weight_kg=data.weight_kg,
            body_fat_pct=data.body_fat_pct,
            muscle_mass_kg=data.muscle_mass_kg,
            waist_cm=data.waist_cm,
            chest_cm=data.chest_cm,
            hip_cm=data.hip_cm,
            arm_cm=data.arm_cm,
            leg_cm=data.leg_cm,
            created_at=datetime.now(timezone.utc),
        )
        return await self.measurement_repository.create(measurement)

    async def get_by_date(self, user_id: str, target_date: date) -> BodyMeasurement:
        measurement = await self.measurement_repository.get_by_date(user_id, target_date)
        if not measurement:
            raise NotFoundException(f"{target_date} tarihine ait ölçüm bulunamadı")
        return measurement

    async def get_by_date_range(self, user_id: str, from_date: date, to_date: date) -> list[BodyMeasurement]:
        # from_date to_date'den büyükse mantık hatası
        if from_date > to_date:
            raise BadRequestException("Başlangıç tarihi bitiş tarihinden büyük olamaz")
        return await self.measurement_repository.get_by_date_range(user_id, from_date, to_date)

    async def get_history(self, user_id: str) -> list[BodyMeasurement]:
        # Tüm geçmiş — grafik için
        return await self.measurement_repository.get_all(user_id)

    async def update(self, user_id: str, measurement_id: str, data) -> BodyMeasurement:
        # Önce kaydın var olduğunu ve bu kullanıcıya ait olduğunu kontrol et
        existing = await self.measurement_repository.get_by_id(measurement_id)
        if not existing:
            raise NotFoundException("Ölçüm bulunamadı")
        if existing.user_id != user_id:
            raise NotFoundException("Ölçüm bulunamadı")  # 403 değil 404 — güvenlik gereği

        # Sadece gönderilen alanları güncelle, None gelenleri mevcut değerde bırak
        existing.weight_kg = data.weight_kg if data.weight_kg is not None else existing.weight_kg
        existing.body_fat_pct = data.body_fat_pct if data.body_fat_pct is not None else existing.body_fat_pct
        existing.muscle_mass_kg = data.muscle_mass_kg if data.muscle_mass_kg is not None else existing.muscle_mass_kg
        existing.waist_cm = data.waist_cm if data.waist_cm is not None else existing.waist_cm
        existing.chest_cm = data.chest_cm if data.chest_cm is not None else existing.chest_cm
        existing.hip_cm = data.hip_cm if data.hip_cm is not None else existing.hip_cm
        existing.arm_cm = data.arm_cm if data.arm_cm is not None else existing.arm_cm
        existing.leg_cm = data.leg_cm if data.leg_cm is not None else existing.leg_cm
        return await self.measurement_repository.update(existing)

    async def delete(self, user_id: str, measurement_id: str) -> bool:
        existing = await self.measurement_repository.get_by_id(measurement_id)
        if not existing:
            raise NotFoundException("Ölçüm bulunamadı")
        if existing.user_id != user_id:
            raise NotFoundException("Ölçüm bulunamadı")  # Güvenlik gereği 404
        return await self.measurement_repository.delete(measurement_id)

"""
Genel akış:
Endpoint → MeasurementService → IMeasurementRepository → DB

Neden update'de 404 dönüyoruz, 403 değil?
Başkasının ölçümüne erişmeye çalışıyorsa "bu kayıt yok" diyoruz.
403 versek saldırgan "bu ID var ama senin değil" bilgisini öğrenir.
404 ile ID'nin varlığını da gizlemiş oluruz.

Partial update mantığı:
data.weight_kg if data.weight_kg is not None else existing.weight_kg
→ Kullanıcı sadece weight_kg gönderdiyse diğer alanlar silinmez, mevcut değerleri kalır.
"""