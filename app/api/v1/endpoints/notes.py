from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import date

from app.application.schemas.note import NoteCreateRequest, NoteUpdateRequest, NoteResponse
from app.application.services.note_service import NoteService
from app.core.dependencies import get_current_user
from app.infrastructure.db.session import get_db
from app.infrastructure.repositories.note_repository import NoteRepository

router = APIRouter()


# ── DEPENDENCY ───────────────────────────────────────────────────
def get_note_service(session: AsyncSession = Depends(get_db)) -> NoteService:
    # session → NoteRepository → NoteService
    repo = NoteRepository(session)
    return NoteService(repo)


# ── CREATE ───────────────────────────────────────────────────────
@router.post("", response_model=NoteResponse)
async def create_note(
    request: NoteCreateRequest,
    user_id: str = Depends(get_current_user),
    service: NoteService = Depends(get_note_service),
):
    # POST /api/v1/notes
    return await service.create(user_id, request)


# ── GET BY DATE ──────────────────────────────────────────────────
@router.get("/date/{target_date}", response_model=NoteResponse)
async def get_by_date(
    target_date: date,
    user_id: str = Depends(get_current_user),
    service: NoteService = Depends(get_note_service),
):
    # GET /api/v1/notes/date/2026-03-11
    return await service.get_by_date(user_id, target_date)


# ── GET BY DATE RANGE ────────────────────────────────────────────
@router.get("", response_model=list[NoteResponse])
async def get_by_date_range(
    from_date: date = Query(..., alias="from"),  # ?from=2026-03-01
    to_date: date = Query(..., alias="to"),      # &to=2026-03-31
    user_id: str = Depends(get_current_user),
    service: NoteService = Depends(get_note_service),
):
    # GET /api/v1/notes?from=2026-03-01&to=2026-03-31
    return await service.get_by_date_range(user_id, from_date, to_date)


# ── UPDATE ───────────────────────────────────────────────────────
@router.put("/{note_id}", response_model=NoteResponse)
async def update_note(
    note_id: str,
    request: NoteUpdateRequest,
    user_id: str = Depends(get_current_user),
    service: NoteService = Depends(get_note_service),
):
    # PUT /api/v1/notes/{id}
    return await service.update(user_id, note_id, request)


# ── DELETE ───────────────────────────────────────────────────────
@router.delete("/{note_id}")
async def delete_note(
    note_id: str,
    user_id: str = Depends(get_current_user),
    service: NoteService = Depends(get_note_service),
):
    # DELETE /api/v1/notes/{id}
    await service.delete(user_id, note_id)
    return {"message": "Not silindi"}

"""
Genel akış:
HTTP Request → Endpoint → Depends(get_current_user) → JWT doğrula → user_id al
→ Depends(get_note_service) → session → repo → service
→ service iş mantığını çalıştır → Response döner

measurements endpoint'inden farkı:
/history endpoint'i yok — tarih aralığı sorgusu yeterli
"""