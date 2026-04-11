import os
import uuid
import aiofiles
from fastapi import UploadFile
from backend.app.core.config import get_settings

settings = get_settings()


class FileStorageService:
    # Dosyaların disk'e kaydedilmesi ve silinmesinden sorumlu servis
    # Sadece fiziksel dosya işlemleri burada — metadata işleri FileUploadService'de

    def __init__(self):
        # Uygulama başlarken uploads klasörlerini oluştur
        # Klasör zaten varsa hata vermez — exist_ok=True
        os.makedirs(f"{settings.UPLOAD_DIR}/photos", exist_ok=True)
        os.makedirs(f"{settings.UPLOAD_DIR}/diet_plans", exist_ok=True)

    async def save_file(self, file: UploadFile, file_type: str) -> tuple[str, str, int]:
        """
        Dosyayı disk'e kaydeder.

        Parametreler:
            file      : FastAPI'nin UploadFile objesi — gelen dosya
            file_type : "photo" veya "diet_plan" — hangi klasöre kaydedileceği

        Döndürür:
            tuple(stored_filename, file_path, file_size_bytes)
        """

        # Orijinal dosya uzantısını al — "foto.jpg" → ".jpg"
        extension = os.path.splitext(file.filename)[1].lower()

        # UUID ile benzersiz dosya adı oluştur — güvenlik için orijinal adı kullanmıyoruz
        stored_filename = f"{uuid.uuid4()}{extension}"

        # Dosya tipine göre klasör belirle
        sub_folder = "photos" if file_type == "photo" else "diet_plans"
        file_path = f"{settings.UPLOAD_DIR}/{sub_folder}/{stored_filename}"

        # Dosyayı asenkron olarak disk'e yaz
        # aiofiles → async file I/O — uvicorn'u bloklamaz
        file_size = 0
        async with aiofiles.open(file_path, "wb") as f:
            while chunk := await file.read(1024 * 1024):  # 1MB'lık parçalar halinde oku
                await f.write(chunk)
                file_size += len(chunk)

        return stored_filename, file_path, file_size

    def delete_file(self, file_path: str) -> bool:
        """
        Dosyayı disk'ten siler.

        Döndürür:
            True  : dosya başarıyla silindi
            False : dosya zaten yoktu
        """
        if os.path.exists(file_path):
            os.remove(file_path)
            return True
        return False

    def validate_file(self, file: UploadFile, file_type: str) -> None:
        """
        Dosya tipini ve boyutunu kontrol eder.
        Hatalı dosyada BadRequestException fırlatır.

        Kontroller:
            1. MIME type izin listesinde mi?
            2. Dosya boyutu MAX_FILE_SIZE_MB'ı geçiyor mu?
        """
        from backend.app.core.exceptions import BadRequestException

        # İzin verilen MIME type'ları belirle
        if file_type == "photo":
            allowed_types = settings.ALLOWED_IMAGE_TYPES
            type_label = "Fotoğraf"
        else:
            allowed_types = settings.ALLOWED_PDF_TYPES
            type_label = "Diyet planı"

        # MIME type kontrolü — "image/jpeg" izin listesinde mi?
        if file.content_type not in allowed_types:
            raise BadRequestException(
                f"{type_label} için geçersiz dosya tipi: {file.content_type}. "
                f"İzin verilenler: {', '.join(allowed_types)}"
            )

        # Boyut kontrolü — content_type header'dan gelir, güvenilir değil
        # Gerçek boyut save_file() sırasında hesaplanır
        # Burada sadece Content-Length header varsa kontrol ederiz
        max_bytes = settings.MAX_FILE_SIZE_MB * 1024 * 1024  # MB → byte
        if file.size and file.size > max_bytes:
            raise BadRequestException(
                f"Dosya boyutu {settings.MAX_FILE_SIZE_MB}MB'ı geçemez"
            )

"""
Genel akış:
1. validate_file() → MIME type ve boyut kontrolü
2. save_file()     → disk'e yaz, stored_filename ve file_path döndür
3. delete_file()   → disk'ten sil

aiofiles neden kullandık?
Normal open() ile dosya yazarsak uvicorn thread'i bloklanır.
aiofiles ile async I/O yaparak diğer request'lerin beklemesini önleriz.

1. Neden chunk chunk okuyoruz?
Kullanıcı 10MB fotoğraf yüklese, file.read() ile bir anda okusaydık 10MB RAM'e yüklenirdi. 100 kullanıcı aynı anda yüklese 1GB RAM. Chunk ile okuyunca her seferinde sadece 1MB RAM'de.
2. Neden UUID ile rename ediyoruz?
Kullanıcı ../../config.py diye bir dosya yüklemeye çalışabilir — klasik path traversal attack. UUID ile rename edince orijinal isim tamamen yok sayılır.
3. validate_file() neden save_file()'dan önce çağrılmalı?
MIME type kontrolünü dosyayı diske yazmadan önce yapmalıyız. Yoksa zararlı bir dosya önce diske yazılır, sonra silinir — gereksiz disk I/O ve güvenlik riski.
Doğru sıra:
validate_file() → save_file() → metadata DB'ye kaydet

Yanlış sıra:
save_file() → validate_file() → hata → dosyayı sil (gereksiz)

chunk := await file.read(1024 * 1024) ne demek?
Walrus operator (:=) — okuma ve atama aynı anda yapılır.
1MB'lık parçalar halinde okur — büyük dosyaları RAM'e tamamen yüklemez.
chunk boş gelince (dosya bitti) döngü durur.

"""