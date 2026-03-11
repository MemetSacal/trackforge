from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.domain.entities.file_upload import FileUpload
from app.domain.interfaces.i_file_upload_repository import IFileUploadRepository
from app.infrastructure.db.models.file_upload_model import FileUploadModel


class FileUploadRepository(IFileUploadRepository):
    # IFileUploadRepository interface'inin PostgreSQL + SQLAlchemy implementasyonu

    def __init__(self, session: AsyncSession):
        # Session dışarıdan inject edilir — dependency injection
        self.session = session

    async def create(self, file_upload: FileUpload) -> FileUpload:
        db_obj = FileUploadModel(
            id=file_upload.id,
            user_id=file_upload.user_id,
            file_type=file_upload.file_type,
            original_filename=file_upload.original_filename,
            stored_filename=file_upload.stored_filename,
            file_path=file_upload.file_path,
            mime_type=file_upload.mime_type,
            file_size_bytes=file_upload.file_size_bytes,
            description=file_upload.description,
            created_at=file_upload.created_at,
        )
        self.session.add(db_obj)
        await self.session.flush()
        return self._to_entity(db_obj)

    async def get_by_id(self, file_id: str) -> Optional[FileUpload]:
        # SELECT * FROM file_uploads WHERE id = ?
        result = await self.session.execute(
            select(FileUploadModel).where(FileUploadModel.id == file_id)
        )
        db_obj = result.scalar_one_or_none()
        return self._to_entity(db_obj) if db_obj else None

    async def get_by_user_and_type(self, user_id: str, file_type: str) -> list[FileUpload]:
        # SELECT * FROM file_uploads WHERE user_id = ? AND file_type = ? ORDER BY created_at DESC
        result = await self.session.execute(
            select(FileUploadModel).where(
                FileUploadModel.user_id == user_id,
                FileUploadModel.file_type == file_type
            ).order_by(FileUploadModel.created_at.desc())  # En yeni dosya önce gelir
        )
        return [self._to_entity(row) for row in result.scalars().all()]

    async def delete(self, file_id: str) -> bool:
        result = await self.session.execute(
            select(FileUploadModel).where(FileUploadModel.id == file_id)
        )
        db_obj = result.scalar_one_or_none()
        if not db_obj:
            return False
        await self.session.delete(db_obj)
        await self.session.flush()
        return True

    def _to_entity(self, db_obj: FileUploadModel) -> FileUpload:
        # FileUploadModel (SQLAlchemy) → FileUpload (domain entity) dönüşümü
        return FileUpload(
            id=db_obj.id,
            user_id=db_obj.user_id,
            file_type=db_obj.file_type,
            original_filename=db_obj.original_filename,
            stored_filename=db_obj.stored_filename,
            file_path=db_obj.file_path,
            mime_type=db_obj.mime_type,
            file_size_bytes=db_obj.file_size_bytes,
            description=db_obj.description,
            created_at=db_obj.created_at,
        )

"""
Genel akış:
DB → FileUploadModel → _to_entity() → FileUpload → Servis katmanı

Diğer repository'lerden farkı:
update() yok — dosyalar güncellenmez, silinip tekrar yüklenir
get_by_date_range() yok — dosyalar için tarih filtresi yerine tip filtresi var
created_at.desc() — en yeni dosya önce gelsin
"""