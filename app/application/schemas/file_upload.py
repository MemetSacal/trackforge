from pydantic import BaseModel
from datetime import datetime
from typing import Optional


class FileUploadResponse(BaseModel):
    # API'den dönecek dosya metadata'sı
    # Dosyanın kendisi değil, bilgileri döner
    id: str
    user_id: str
    file_type: str                  # "photo" veya "diet_plan"
    original_filename: str          # Kullanıcının yüklediği orijinal dosya adı
    stored_filename: str            # Disk'teki UUID'li dosya adı
    file_path: str                  # Dosyanın disk'teki yolu
    mime_type: str                  # "image/jpeg", "application/pdf" vs.
    file_size_bytes: int            # Byte cinsinden dosya boyutu
    description: Optional[str]      # Opsiyonel açıklama
    created_at: datetime

    class Config:
        from_attributes = True      # ORM modelinden direkt dönüşüm için

"""
Neden CreateRequest yok?
Dosya yüklemede JSON body değil, multipart/form-data kullanılır.
FastAPI'de bu File() ve Form() ile yapılır — schema gerekmez.
Sadece response schema yeterli.
"""