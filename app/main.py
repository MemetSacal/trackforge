from fastapi import FastAPI
from fastapi.openapi.utils import get_openapi
from app.core.config import get_settings
from app.infrastructure.logging.logger import setup_logging
from app.api.v1.router import router
from fastapi.middleware.cors import CORSMiddleware

settings = get_settings()

# Logları başlangıçta konfigure et
setup_logging()

# FastAPI uygulaması — tüm endpoint'lerin bağlandığı merkez
# Spring'deki @SpringBootApplication ile aynı mantık
app = FastAPI(
    title="TrackForge API",
    description="AI-Powered Body Tracking System",
    version="0.1.0",
    docs_url="/docs",    # Swagger UI — endpoint'leri test etmek için
    redoc_url="/redoc",  # ReDoc — sadece okuma amaçlı dokümantasyon
)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# v1 router'ını uygulamaya bağla
app.include_router(router)


def custom_openapi():
    # Swagger UI'a Bearer token desteği ekler
    # Bu olmadan Swagger'da Authorize butonu gözükmez
    if app.openapi_schema:
        # Schema daha önce oluşturulduysa cache'den döner
        return app.openapi_schema

    schema = get_openapi(
        title=app.title,
        version=app.version,
        description=app.description,
        routes=app.routes,
    )

    # BearerAuth güvenlik şemasını tanımla
    schema["components"]["securitySchemes"] = {
        "BearerAuth": {
            "type": "http",
            "scheme": "bearer",
            "bearerFormat": "JWT",
        }
    }

    # Tüm endpoint'lere BearerAuth uygula
    for path in schema["paths"].values():
        for method in path.values():
            method["security"] = [{"BearerAuth": []}]

    app.openapi_schema = schema
    return schema


# FastAPI'nin default openapi() metodunu bizimkiyle değiştir
app.openapi = custom_openapi


@app.get("/health")
async def health_check():
    # Uygulamanın ayakta olduğunu kontrol eden endpoint
    return {"status": "ok", "version": "0.1.0"}

"""
custom_openapi neden gerekli?
FastAPI Swagger'a otomatik güvenlik şeması eklemiyor.
Bu fonksiyon OpenAPI JSON şemasını override ederek
Swagger UI'a "Bu API Bearer token kullanıyor" bilgisini veriyor.
Böylece Swagger'da Authorize butonu çıkıyor ve token girince
tüm isteklere otomatik Authorization: Bearer <token> header'ı ekleniyor.

Genel akış:
app.openapi() çağrılır → custom_openapi() devreye girer →
schema cache'de yoksa oluşturur, varsa direkt döner (performans)
"""