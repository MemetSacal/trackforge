from abc import ABC, abstractmethod
from typing import Optional
from app.domain.entities.file_upload import FileUpload


class IFileUploadRepository(ABC):
    # Abstract repository interface — dosya metadata'sını DB'de yönetir
    # Dosyanın kendisi disk'te, bilgileri DB'de tutulur

    @abstractmethod
    async def create(self, file_upload: FileUpload) -> FileUpload:
        # Yeni dosya kaydını DB'ye ekle
        pass

    @abstractmethod
    async def get_by_id(self, file_id: str) -> Optional[FileUpload]:
        # ID ile tek dosya kaydını getir
        pass

    @abstractmethod
    async def get_by_user_and_type(self, user_id: str, file_type: str) -> list[FileUpload]:
        # Kullanıcının belirli tipteki tüm dosyalarını getir
        # Örn: user_id + "photo" → tüm fotoğraflar
        pass

    @abstractmethod
    async def delete(self, file_id: str) -> bool:
        # DB'deki dosya kaydını sil — disk'teki dosyayı servis siler
        pass

"""
Genel akış:
Dosya yükleme:
  1. Dosya disk'e kaydedilir (FileStorageService)
  2. Metadata DB'ye kaydedilir (IFileUploadRepository)

Dosya silme:
  1. DB'den metadata silinir (IFileUploadRepository)
  2. Disk'ten dosya silinir (FileStorageService)

Neden ayrı tutulur?
Yarın AWS S3'e geçince sadece FileStorageService değişir,
repository ve entity'ye dokunmak gerekmez.
"""