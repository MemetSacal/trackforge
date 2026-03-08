from fastapi import FastAPI
from app.core.config import get_settings
from app.infrastructure.logging.logger import setup_logging
from app.api.v1.router import router

settings = get_settings()

# Logları başlangıçta konfigure et
setup_logging()

# FastAPI uygulaması — tüm endpoint'lerin bağlandığı merkez
# Spring'deki @SpringBootApplication ile aynı mantık
app = FastAPI(
    title="TrackForge API",
    description="AI-Powered Body Tracking System",
    version="0.1.0",
    docs_url="/docs",    # Swagger UI adresi İnteraktif arayüz. Endpoint'leri görürsün, direkt oradan istek atabilirsin, response görürsün. Geliştirme sırasında çok kullanacağız.
    redoc_url="/redoc",  # ReDoc adresi Sadece okuma amaçlı, daha şık ve düzenli bir dokümantasyon görünümü. API'yi başkasına göstermek istediğinde daha profesyonel duruyor.

)

# v1 router'ını uygulamaya bağla
app.include_router(router)

@app.get("/health")
async def health_check():
    # Uygulamanın ayakta olduğunu kontrol eden endpoint
    return {"status": "ok", "version": "0.1.0"}