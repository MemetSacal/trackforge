from fastapi import APIRouter, Depends, UploadFile, File, Form
from fastapi.responses import FileResponse
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional
import os

from backend.app.application.schemas.file_upload import FileUploadResponse
from backend.app.application.services.file_upload_service import FileUploadService
from backend.app.core.dependencies import get_current_user
from backend.app.core.exceptions import NotFoundException
from backend.app.infrastructure.db.session import get_db
from backend.app.infrastructure.repositories.file_upload_repository import FileUploadRepository
from backend.app.infrastructure.storage.file_storage_service import FileStorageService

router = APIRouter()


# ── DEPENDENCY ───────────────────────────────────────────────────
def get_file_upload_service(session: AsyncSession = Depends(get_db)) -> FileUploadService:
    # session → FileUploadRepository → FileUploadService
    # FileStorageService'in DB bağlantısı yok — direkt oluşturulur
    repo = FileUploadRepository(session)
    storage = FileStorageService()
    return FileUploadService(repo, storage)


# ── UPLOAD PHOTO ─────────────────────────────────────────────────
@router.post("/photos", response_model=FileUploadResponse)
async def upload_photo(
    file: UploadFile = File(...),                           # Zorunlu — yüklenecek dosya
    description: Optional[str] = Form(None),               # Opsiyonel — form field olarak gelir
    user_id: str = Depends(get_current_user),
    service: FileUploadService = Depends(get_file_upload_service),
):
    # POST /api/v1/files/photos
    # multipart/form-data ile dosya yüklenir — JSON değil
    return await service.upload_file(user_id, file, "photo", description)


# ── UPLOAD DIET PLAN ─────────────────────────────────────────────
@router.post("/diet-plans", response_model=FileUploadResponse)
async def upload_diet_plan(
    file: UploadFile = File(...),                           # Zorunlu — PDF dosyası
    description: Optional[str] = Form(None),               # Opsiyonel açıklama
    user_id: str = Depends(get_current_user),
    service: FileUploadService = Depends(get_file_upload_service),
):
    # POST /api/v1/files/diet-plans
    return await service.upload_file(user_id, file, "diet_plan", description)


# ── LIST PHOTOS ──────────────────────────────────────────────────
@router.get("/photos", response_model=list[FileUploadResponse])
async def list_photos(
    user_id: str = Depends(get_current_user),
    service: FileUploadService = Depends(get_file_upload_service),
):
    # GET /api/v1/files/photos — kullanıcının tüm fotoğrafları
    return await service.get_files(user_id, "photo")


# ── LIST DIET PLANS ──────────────────────────────────────────────
@router.get("/diet-plans", response_model=list[FileUploadResponse])
async def list_diet_plans(
    user_id: str = Depends(get_current_user),
    service: FileUploadService = Depends(get_file_upload_service),
):
    # GET /api/v1/files/diet-plans — kullanıcının tüm diyet planları
    return await service.get_files(user_id, "diet_plan")


# ── DOWNLOAD FILE ────────────────────────────────────────────────
@router.get("/download/{file_id}")
async def download_file(
    file_id: str,
    user_id: str = Depends(get_current_user),
    service: FileUploadService = Depends(get_file_upload_service),
):
    # GET /api/v1/files/download/{id} — dosyayı indir
    existing = await service.file_upload_repository.get_by_id(file_id)
    if not existing:
        raise NotFoundException("Dosya bulunamadı")
    if existing.user_id != user_id:
        raise NotFoundException("Dosya bulunamadı")    # Güvenlik gereği 404

    # Dosya disk'te var mı kontrol et
    if not os.path.exists(existing.file_path):
        raise NotFoundException("Dosya disk'te bulunamadı")

    # FileResponse → dosyayı direkt HTTP response olarak döner
    return FileResponse(
        path=existing.file_path,
        filename=existing.original_filename,    # Kullanıcıya orijinal adıyla indirir
        media_type=existing.mime_type,
    )


# ── DELETE FILE ──────────────────────────────────────────────────
@router.delete("/{file_id}")
async def delete_file(
    file_id: str,
    user_id: str = Depends(get_current_user),
    service: FileUploadService = Depends(get_file_upload_service),
):
    # DELETE /api/v1/files/{id} — hem DB'den hem disk'ten siler
    await service.delete_file(user_id, file_id)
    return {"message": "Dosya silindi"}

"""
Genel akış:
Upload: multipart/form-data → File() + Form() → validate → disk'e kaydet → DB'ye kaydet
List  : JWT doğrula → DB'den metadata listesi döner
Download: JWT doğrula → DB'den path al → FileResponse ile dosyayı döner
Delete: JWT doğrula → DB'den sil → disk'ten sil

JSON body yerine multipart/form-data neden?
Dosya binary veri — JSON string olarak gönderilemez.
multipart/form-data hem dosyayı hem text field'ları aynı istekte gönderir.
"""