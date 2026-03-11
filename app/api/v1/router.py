from fastapi import APIRouter
from app.api.v1.endpoints import auth, measurements, notes, meal_compliance

# Tüm v1 endpoint'lerini bir araya toplayan merkezi router
router = APIRouter(prefix="/api/v1")

router.include_router(auth.router, prefix="/auth", tags=["auth"])

router.include_router(measurements.router, prefix="/measurements", tags=["measurements"])

router.include_router(notes.router, prefix="/notes", tags=["notes"])

router.include_router(meal_compliance.router, prefix="/meal-compliance", tags=["meal-compliance"])
