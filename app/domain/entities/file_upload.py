from dataclasses import dataclass
from datetime import datetime
from typing import Optional


@dataclass
class FileUpload:
    # Domain entity — yüklenen dosya kaydı
    # Hem fotoğraf hem PDF diyet planı bu entity üzerinden yönetilir

    id: str
    user_id: str                    # FK — hangi kullanıcıya ait
    file_type: str                  # "photo" veya "diet_plan"
    original_filename: str          # Kullanıcının yüklediği orijinal dosya adı
    stored_filename: str            # Disk'te saklanan dosya adı — UUID ile rename edilir
    file_path: str                  # Dosyanın disk'teki tam yolu
    mime_type: str                  # "image/jpeg", "application/pdf" vs.
    file_size_bytes: int            # Dosya boyutu — MB limitini kontrol için
    description: Optional[str]      # Opsiyonel açıklama — "Mart ayı diyet planı" gibi
    created_at: datetime