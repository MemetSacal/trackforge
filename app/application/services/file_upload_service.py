import uuid
from datetime import datetime, timezone
from typing import Optional
from fastapi import UploadFile

from app.domain.entities.file_upload import FileUpload
from app.domain.interfaces.i_file_upload_repository import IFileUploadRepository
from app.infrastructure.storage.file_storage_service import FileStorageService
from app.core.exceptions import NotFoundException


class FileUploadService:
    # Dosya yükleme iş mantığı burada
    # FileStorageService (disk) + IFileUploadRepository (DB) birlikte kullanılır

    def __init__(
        self,
        file_upload_repository: IFileUploadRepository,
        storage_service: FileStorageService,
    ):
        # İki dependency inject edilir:
        # 1. repository → metadata DB işlemleri
        # 2. storage_service → fiziksel dosya işlemleri
        self.file_upload_repository = file_upload_repository
        self.storage_service = storage_service

    async def upload_file(
        self,
        user_id: str,
        file: UploadFile,
        file_type: str,
        description: Optional[str] = None,
    ) -> FileUpload:
        # 1. Dosya tipini ve boyutunu kontrol et
        self.storage_service.validate_file(file, file_type)

        # 2. Dosyayı disk'e kaydet — stored_filename, file_path, file_size döner
        stored_filename, file_path, file_size = await self.storage_service.save_file(
            file, file_type
        )

        # 3. Metadata'yı DB'ye kaydet
        file_upload = FileUpload(
            id=str(uuid.uuid4()),
            user_id=user_id,
            file_type=file_type,
            original_filename=file.filename,        # Orijinal adı saklıyoruz — gösterim için
            stored_filename=stored_filename,         # UUID'li ad — disk'teki gerçek ad
            file_path=file_path,
            mime_type=file.content_type,
            file_size_bytes=file_size,
            description=description,
            created_at=datetime.now(timezone.utc),
        )
        return await self.file_upload_repository.create(file_upload)

    async def get_files(self, user_id: str, file_type: str) -> list[FileUpload]:
        # Kullanıcının belirli tipteki dosyalarını getir
        return await self.file_upload_repository.get_by_user_and_type(user_id, file_type)

    async def delete_file(self, user_id: str, file_id: str) -> bool:
        # 1. DB'den kaydı getir — var mı ve bu kullanıcıya mı ait kontrol et
        existing = await self.file_upload_repository.get_by_id(file_id)
        if not existing:
            raise NotFoundException("Dosya bulunamadı")
        if existing.user_id != user_id:
            raise NotFoundException("Dosya bulunamadı")    # Güvenlik gereği 404

        # 2. DB'den metadata'yı sil
        await self.file_upload_repository.delete(file_id)

        # 3. Disk'ten fiziksel dosyayı sil
        self.storage_service.delete_file(existing.file_path)
        return True

"""
Genel akış:
upload_file():
  validate_file() → save_file() → DB'ye kaydet → FileUpload döner

delete_file():
  DB'den getir → sahiplik kontrol → DB'den sil → disk'ten sil

Neden önce DB sonra disk siliyoruz?
Disk silme başarısız olsa bile DB kaydı gitti,
dosya artık orphan (sahipsiz) kalır ama kullanıcıya görünmez.
Önce disk silsek ve DB silme başarısız olsa kullanıcı
var olmayan bir dosyaya erişmeye çalışırdı — daha kötü senaryo.
"""