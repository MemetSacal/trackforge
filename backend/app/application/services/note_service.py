import uuid
from datetime import date, datetime, timezone
from backend.app.domain.entities.weekly_note import WeeklyNote
from backend.app.domain.interfaces.i_note_repository import INoteRepository
from backend.app.core.exceptions import BadRequestException, NotFoundException


class NoteService:
    # Not işlemlerinin iş mantığı burada
    # MeasurementService ile aynı mantık

    def __init__(self, note_repository: INoteRepository):
        # Repository dışarıdan inject edilir — interface üzerinden
        self.note_repository = note_repository

    async def create(self, user_id: str, data) -> WeeklyNote:
        # Aynı gün zaten not var mı kontrol et
        existing = await self.note_repository.get_by_date(user_id, data.date)
        if existing:
            raise BadRequestException(f"{data.date} tarihine ait not zaten mevcut")

        note = WeeklyNote(
            id=str(uuid.uuid4()),
            user_id=user_id,
            date=data.date,
            title=data.title,
            content=data.content,
            energy_level=data.energy_level,
            mood_score=data.mood_score,
            created_at=datetime.now(timezone.utc),
        )
        return await self.note_repository.create(note)

    async def get_by_date(self, user_id: str, target_date: date) -> WeeklyNote:
        note = await self.note_repository.get_by_date(user_id, target_date)
        if not note:
            raise NotFoundException(f"{target_date} tarihine ait not bulunamadı")
        return note

    async def get_by_date_range(self, user_id: str, from_date: date, to_date: date) -> list[WeeklyNote]:
        if from_date > to_date:
            raise BadRequestException("Başlangıç tarihi bitiş tarihinden büyük olamaz")
        return await self.note_repository.get_by_date_range(user_id, from_date, to_date)

    async def update(self, user_id: str, note_id: str, data) -> WeeklyNote:
        # Kaydın var olduğunu ve bu kullanıcıya ait olduğunu kontrol et
        existing = await self.note_repository.get_by_id(note_id)
        if not existing:
            raise NotFoundException("Not bulunamadı")
        if existing.user_id != user_id:
            raise NotFoundException("Not bulunamadı")  # Güvenlik gereği 404

        # Sadece gönderilen alanları güncelle
        existing.title = data.title if data.title is not None else existing.title
        existing.content = data.content if data.content is not None else existing.content
        existing.energy_level = data.energy_level if data.energy_level is not None else existing.energy_level
        existing.mood_score = data.mood_score if data.mood_score is not None else existing.mood_score
        return await self.note_repository.update(existing)

    async def delete(self, user_id: str, note_id: str) -> bool:
        existing = await self.note_repository.get_by_id(note_id)
        if not existing:
            raise NotFoundException("Not bulunamadı")
        if existing.user_id != user_id:
            raise NotFoundException("Not bulunamadı")  # Güvenlik gereği 404
        return await self.note_repository.delete(note_id)

"""
Genel akış:
Endpoint → NoteService → INoteRepository → DB

MeasurementService'den farkı:
get_history yok — tarih aralığı sorgusu yeterli.
content zorunlu — boş not kabul edilmiyor.
"""