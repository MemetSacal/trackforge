from datetime import date
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.domain.entities.weekly_note import WeeklyNote
from app.domain.interfaces.i_note_repository import INoteRepository
from app.infrastructure.db.models.note_model import NoteModel


class NoteRepository(INoteRepository):
    # INoteRepository interface'inin PostgreSQL + SQLAlchemy implementasyonu
    # MeasurementRepository ile aynı mantık

    def __init__(self, session: AsyncSession):
        # Session dışarıdan inject edilir — dependency injection
        self.session = session

    async def create(self, note: WeeklyNote) -> WeeklyNote:
        db_obj = NoteModel(
            id=note.id,
            user_id=note.user_id,
            date=note.date,
            title=note.title,
            content=note.content,
            energy_level=note.energy_level,
            mood_score=note.mood_score,
            created_at=note.created_at,
        )
        self.session.add(db_obj)
        await self.session.flush()  # DB'ye yazar ama commit etmez — transaction açık kalır
        return self._to_entity(db_obj)

    async def get_by_id(self, note_id: str) -> Optional[WeeklyNote]:
        # SELECT * FROM weekly_notes WHERE id = ?
        result = await self.session.execute(
            select(NoteModel).where(NoteModel.id == note_id)
        )
        db_obj = result.scalar_one_or_none()  # Bulursa döner, bulamazsa None
        return self._to_entity(db_obj) if db_obj else None

    async def get_by_date(self, user_id: str, target_date: date) -> Optional[WeeklyNote]:
        # SELECT * FROM weekly_notes WHERE user_id = ? AND date = ?
        # Aynı gün kontrolü için servis katmanı bunu kullanır
        result = await self.session.execute(
            select(NoteModel).where(
                NoteModel.user_id == user_id,
                NoteModel.date == target_date
            )
        )
        db_obj = result.scalar_one_or_none()
        return self._to_entity(db_obj) if db_obj else None

    async def get_by_date_range(self, user_id: str, from_date: date, to_date: date) -> list[WeeklyNote]:
        # SELECT * FROM weekly_notes WHERE user_id = ? AND date BETWEEN ? AND ? ORDER BY date
        result = await self.session.execute(
            select(NoteModel).where(
                NoteModel.user_id == user_id,
                NoteModel.date >= from_date,
                NoteModel.date <= to_date
            ).order_by(NoteModel.date)  # Tarihe göre sıralı — liste dönerken düzen önemli
        )
        return [self._to_entity(row) for row in result.scalars().all()]

    async def update(self, note: WeeklyNote) -> WeeklyNote:
        result = await self.session.execute(
            select(NoteModel).where(NoteModel.id == note.id)
        )
        db_obj = result.scalar_one_or_none()
        if not db_obj:
            return None
        # id, user_id, date değişmez — sadece içerik alanları güncellenir
        db_obj.title = note.title
        db_obj.content = note.content
        db_obj.energy_level = note.energy_level
        db_obj.mood_score = note.mood_score
        await self.session.flush()
        return self._to_entity(db_obj)

    async def delete(self, note_id: str) -> bool:
        result = await self.session.execute(
            select(NoteModel).where(NoteModel.id == note_id)
        )
        db_obj = result.scalar_one_or_none()
        if not db_obj:
            return False
        await self.session.delete(db_obj)
        await self.session.flush()
        return True

    def _to_entity(self, db_obj: NoteModel) -> WeeklyNote:
        # NoteModel (SQLAlchemy) → WeeklyNote (domain entity) dönüşümü
        # Servis katmanı NoteModel'i hiç görmez, sadece WeeklyNote görür
        return WeeklyNote(
            id=db_obj.id,
            user_id=db_obj.user_id,
            date=db_obj.date,
            title=db_obj.title,
            content=db_obj.content,
            energy_level=db_obj.energy_level,
            mood_score=db_obj.mood_score,
            created_at=db_obj.created_at,
        )

"""
Genel akış:
DB → NoteModel → _to_entity() → WeeklyNote → Servis katmanı
Servis katmanı → WeeklyNote → create() → NoteModel → DB

MeasurementRepository'den farkı:
get_all yok — notlar için tarih aralığı sorgusu yeterli.
get_by_date_range'de order_by var — liste dönerken tarihe göre sıralı olması önemli.
"""