from fastapi import APIRouter
from app.api.v1.endpoints import (auth, measurements, notes, meal_compliance, files, exercises, water, sleep,
                                  preferences, shopping, reports, ai, onboarding, barcode, gamification, social, steps,
                                  cycle, )

# Tüm v1 endpoint'lerini bir araya toplayan merkezi router
router = APIRouter(prefix="/api/v1")

router.include_router(auth.router, prefix="/auth", tags=["auth"])

router.include_router(measurements.router, prefix="/measurements", tags=["measurements"])

router.include_router(notes.router, prefix="/notes", tags=["notes"])

router.include_router(meal_compliance.router, prefix="/meal-compliance", tags=["meal-compliance"])

router.include_router(files.router, prefix="/files", tags=["files"])

router.include_router(exercises.router, prefix="/exercises", tags=["exercises"])

router.include_router(water.router, prefix="/water", tags=["water"])

router.include_router(sleep.router, prefix="/sleep", tags=["sleep"])

router.include_router(preferences.router, prefix="/preferences", tags=["preferences"])

router.include_router(shopping.router, prefix="/shopping", tags=["shopping"])

router.include_router(reports.router, prefix="/reports", tags=["reports"])

router.include_router(ai.router, prefix="/ai", tags=["ai"])

router.include_router(onboarding.router, prefix="/onboarding", tags=["onboarding"])

router.include_router(barcode.router, prefix="/barcode", tags=["barcode"])

router.include_router(gamification.router, prefix="/gamification", tags=["gamification"])

router.include_router(social.router, prefix="/social", tags=["social"])

router.include_router(steps.router, prefix="/steps", tags=["steps"])

router.include_router(cycle.router, prefix="/cycle", tags=["cycle"])