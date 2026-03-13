from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import date

from app.application.schemas.exercise import (
    ExerciseSessionCreateRequest,
    ExerciseSessionUpdateRequest,
    ExerciseSessionResponse,
    SessionExerciseCreateRequest,
    SessionExerciseUpdateRequest,
    SessionExerciseResponse,
)
from app.application.services.exercise_service import ExerciseService
from app.core.dependencies import get_current_user
from app.infrastructure.db.session import get_db
from app.infrastructure.repositories.exercise_session_repository import ExerciseSessionRepository
from app.infrastructure.repositories.session_exercise_repository import SessionExerciseRepository

router = APIRouter()


# ── DEPENDENCY ───────────────────────────────────────────────────
def get_exercise_service(session: AsyncSession = Depends(get_db)) -> ExerciseService:
    # session → iki repository → ExerciseService
    session_repo = ExerciseSessionRepository(session)
    exercise_repo = SessionExerciseRepository(session)
    return ExerciseService(session_repo, exercise_repo)


# ── SESSION CRUD ─────────────────────────────────────────────────

@router.post("/sessions", response_model=ExerciseSessionResponse)
async def create_session(
    request: ExerciseSessionCreateRequest,
    user_id: str = Depends(get_current_user),
    service: ExerciseService = Depends(get_exercise_service),
):
    # POST /api/v1/exercises/sessions
    return await service.create_session(user_id, request)


@router.get("/sessions", response_model=list[ExerciseSessionResponse])
async def get_sessions(
    from_date: date = Query(..., alias="from"),  # ?from=2026-03-01
    to_date: date = Query(..., alias="to"),      # &to=2026-03-31
    user_id: str = Depends(get_current_user),
    service: ExerciseService = Depends(get_exercise_service),
):
    # GET /api/v1/exercises/sessions?from=2026-03-01&to=2026-03-31
    return await service.get_sessions_by_date_range(user_id, from_date, to_date)


@router.get("/sessions/{session_id}", response_model=ExerciseSessionResponse)
async def get_session(
    session_id: str,
    user_id: str = Depends(get_current_user),
    service: ExerciseService = Depends(get_exercise_service),
):
    # GET /api/v1/exercises/sessions/{id}
    return await service.get_session(user_id, session_id)


@router.put("/sessions/{session_id}", response_model=ExerciseSessionResponse)
async def update_session(
    session_id: str,
    request: ExerciseSessionUpdateRequest,
    user_id: str = Depends(get_current_user),
    service: ExerciseService = Depends(get_exercise_service),
):
    # PUT /api/v1/exercises/sessions/{id}
    return await service.update_session(user_id, session_id, request)


@router.delete("/sessions/{session_id}")
async def delete_session(
    session_id: str,
    user_id: str = Depends(get_current_user),
    service: ExerciseService = Depends(get_exercise_service),
):
    # DELETE /api/v1/exercises/sessions/{id}
    # cascade sayesinde seansa bağlı tüm egzersizler de silinir
    await service.delete_session(user_id, session_id)
    return {"message": "Seans ve tüm egzersizler silindi"}


# ── SESSION EXERCISE CRUD ────────────────────────────────────────

@router.post("/sessions/{session_id}/exercises", response_model=SessionExerciseResponse)
async def add_exercise(
    session_id: str,
    request: SessionExerciseCreateRequest,
    user_id: str = Depends(get_current_user),
    service: ExerciseService = Depends(get_exercise_service),
):
    # POST /api/v1/exercises/sessions/{session_id}/exercises
    # Seansa yeni egzersiz ekle
    return await service.add_exercise(user_id, session_id, request)


@router.get("/sessions/{session_id}/exercises", response_model=list[SessionExerciseResponse])
async def get_exercises(
    session_id: str,
    user_id: str = Depends(get_current_user),
    service: ExerciseService = Depends(get_exercise_service),
):
    # GET /api/v1/exercises/sessions/{session_id}/exercises
    # Seansın tüm egzersizlerini getir
    return await service.get_exercises(user_id, session_id)


@router.put("/exercises/{exercise_id}", response_model=SessionExerciseResponse)
async def update_exercise(
    exercise_id: str,
    request: SessionExerciseUpdateRequest,
    user_id: str = Depends(get_current_user),
    service: ExerciseService = Depends(get_exercise_service),
):
    # PUT /api/v1/exercises/{exercise_id}
    return await service.update_exercise(user_id, exercise_id, request)


@router.delete("/exercises/{exercise_id}")
async def delete_exercise(
    exercise_id: str,
    user_id: str = Depends(get_current_user),
    service: ExerciseService = Depends(get_exercise_service),
):
    # DELETE /api/v1/exercises/{exercise_id}
    await service.delete_exercise(user_id, exercise_id)
    return {"message": "Egzersiz silindi"}

"""
Genel akış:
Seans endpoint'leri: /exercises/sessions/...
Egzersiz endpoint'leri: /exercises/sessions/{id}/exercises (ekle/listele)
                        /exercises/exercises/{id} (güncelle/sil)

Neden iç içe URL?
POST /exercises/sessions/{session_id}/exercises → hangi seansa eklendiği URL'den belli
PUT/DELETE /exercises/exercises/{id} → egzersiz ID'si yeterli, session_id'ye gerek yok
"""