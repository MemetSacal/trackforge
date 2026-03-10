from fastapi import APIRouter
from app.api.v1.endpoints import auth

# Tüm v1 endpoint'lerini bir araya toplayan merkezi router
router = APIRouter(prefix="/api/v1")

# Auth endpoint'leri — /api/v1/auth/register ve /api/v1/auth/login
router.include_router(auth.router, prefix="/auth", tags=["auth"])