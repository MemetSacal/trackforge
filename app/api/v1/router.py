from fastapi import APIRouter

# Tüm v1 endpoint'lerini bir araya toplayan merkezi router
# Spring'deki @RequestMapping("/api/v1") ile aynı mantık
router = APIRouter(prefix="/api/v1")

# İleride buraya endpoint'ler eklenecek:
# from app.api.v1.endpoints import auth, measurements, notes
# router.include_router(auth.router, prefix="/auth", tags=["auth"])