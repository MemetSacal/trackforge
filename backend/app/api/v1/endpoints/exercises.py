from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import date

from backend.app.application.schemas.exercise import (
    ExerciseSessionCreateRequest,
    ExerciseSessionUpdateRequest,
    ExerciseSessionResponse,
    SessionExerciseCreateRequest,
    SessionExerciseUpdateRequest,
    SessionExerciseResponse,
)
from backend.app.application.services.exercise_service import ExerciseService
from backend.app.application.services.gamification_service import GamificationService
from backend.app.core.dependencies import get_current_user
from backend.app.infrastructure.db.session import get_db
from backend.app.infrastructure.repositories.exercise_session_repository import ExerciseSessionRepository
from backend.app.infrastructure.repositories.session_exercise_repository import SessionExerciseRepository

router = APIRouter()


# ── DEPENDENCY ───────────────────────────────────────────────────
def get_exercise_service(session: AsyncSession = Depends(get_db)) -> ExerciseService:
    session_repo = ExerciseSessionRepository(session)
    exercise_repo = SessionExerciseRepository(session)
    return ExerciseService(session_repo, exercise_repo)


def get_gamification_service(session: AsyncSession = Depends(get_db)) -> GamificationService:
    return GamificationService(session)


# ── SESSION CRUD ─────────────────────────────────────────────────

@router.post("/sessions", response_model=ExerciseSessionResponse)
async def create_session(
    request: ExerciseSessionCreateRequest,
    user_id: str = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
    service: ExerciseService = Depends(get_exercise_service),
    gamification: GamificationService = Depends(get_gamification_service),
):
    # POST /api/v1/exercises/sessions
    result = await service.create_session(user_id, request)

    # İlk antrenman mı kontrol et — rozet için
    all_sessions = await service.get_sessions_by_date_range(
        user_id,
        date(2000, 1, 1),  # Tüm geçmiş
        request.date
    )
    is_first = len(all_sessions) == 1  # Yeni oluşturulan dahil 1 tane varsa ilk antrenman

    # Gamification tetikle — streak + XP + rozet
    await gamification.on_workout_created(user_id, request.date, is_first=is_first)

    return result


@router.get("/sessions", response_model=list[ExerciseSessionResponse])
async def get_sessions(
    from_date: date = Query(..., alias="from"),
    to_date: date = Query(..., alias="to"),
    user_id: str = Depends(get_current_user),
    service: ExerciseService = Depends(get_exercise_service),
):
    return await service.get_sessions_by_date_range(user_id, from_date, to_date)


@router.get("/sessions/{session_id}", response_model=ExerciseSessionResponse)
async def get_session(
    session_id: str,
    user_id: str = Depends(get_current_user),
    service: ExerciseService = Depends(get_exercise_service),
):
    return await service.get_session(user_id, session_id)


@router.put("/sessions/{session_id}", response_model=ExerciseSessionResponse)
async def update_session(
    session_id: str,
    request: ExerciseSessionUpdateRequest,
    user_id: str = Depends(get_current_user),
    service: ExerciseService = Depends(get_exercise_service),
):
    return await service.update_session(user_id, session_id, request)


@router.delete("/sessions/{session_id}")
async def delete_session(
    session_id: str,
    user_id: str = Depends(get_current_user),
    service: ExerciseService = Depends(get_exercise_service),
):
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
    return await service.add_exercise(user_id, session_id, request)


@router.get("/sessions/{session_id}/exercises", response_model=list[SessionExerciseResponse])
async def get_exercises(
    session_id: str,
    user_id: str = Depends(get_current_user),
    service: ExerciseService = Depends(get_exercise_service),
):
    return await service.get_exercises(user_id, session_id)


@router.put("/exercises/{exercise_id}", response_model=SessionExerciseResponse)
async def update_exercise(
    exercise_id: str,
    request: SessionExerciseUpdateRequest,
    user_id: str = Depends(get_current_user),
    service: ExerciseService = Depends(get_exercise_service),
):
    return await service.update_exercise(user_id, exercise_id, request)


@router.delete("/exercises/{exercise_id}")
async def delete_exercise(
    exercise_id: str,
    user_id: str = Depends(get_current_user),
    service: ExerciseService = Depends(get_exercise_service),
):
    await service.delete_exercise(user_id, exercise_id)
    return {"message": "Egzersiz silindi"}


"""
DOSYA AKIŞI:
create_session → antrenman oluşturulunca gamification tetiklenir:
  - on_workout_created() → exercise streak +1, +50 XP
  - İlk antrenmanı → "first_workout" rozeti + 100 XP
  - 7 gün serisi → "streak_warrior" rozeti + 100 XP

Spring Boot karşılığı: @RestController + @PostMapping + Event publish.
"""