from fastapi import FastAPI
from fastapi.openapi.utils import get_openapi
from fastapi.responses import FileResponse
from backend.app.core.config import get_settings
from backend.app.infrastructure.logging.logger import setup_logging
from backend.app.api.v1.router import router
from fastapi.middleware.cors import CORSMiddleware
import os

settings = get_settings()
setup_logging()

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

app = FastAPI(
    title="TrackForge API",
    description="AI-Powered Body Tracking System",
    version="0.1.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
    max_age=3600,
)

app.include_router(router)


@app.get("/", include_in_schema=False)
async def landing():
    return FileResponse(os.path.join(BASE_DIR, "..", "static", "index.html"))


def custom_openapi():
    if app.openapi_schema:
        return app.openapi_schema
    schema = get_openapi(
        title=app.title,
        version=app.version,
        description=app.description,
        routes=app.routes,
    )
    schema["components"]["securitySchemes"] = {
        "BearerAuth": {
            "type": "http",
            "scheme": "bearer",
            "bearerFormat": "JWT",
        }
    }
    for path in schema["paths"].values():
        for method in path.values():
            method["security"] = [{"BearerAuth": []}]
    app.openapi_schema = schema
    return schema


app.openapi = custom_openapi


@app.get("/health")
async def health_check():
    return {"status": "ok", "version": "0.1.0"}