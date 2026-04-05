from typing import Optional
from pydantic import BaseModel


class BarcodeResponse(BaseModel):
    barcode: str
    product_name: str
    brand: Optional[str] = None
    quantity: Optional[str] = None          # "500g", "1L" gibi

    # Besin değerleri — 100g başına
    calories_per_100g: Optional[float] = None
    protein_per_100g: Optional[float] = None
    carbs_per_100g: Optional[float] = None
    fat_per_100g: Optional[float] = None
    fiber_per_100g: Optional[float] = None
    sugar_per_100g: Optional[float] = None

    # Porsiyon bilgisi — varsa
    serving_size: Optional[str] = None
    calories_per_serving: Optional[float] = None

    # Ürün görseli
    image_url: Optional[str] = None


"""
DOSYA AKIŞI:
BarcodeResponse Open Food Facts API'den gelen veriyi temizlenmiş
formatta döndürür.

100g bazında değerler her zaman standart karşılaştırma için kullanılır.
serving_size varsa Flutter porsiyon hesabı yapabilir.
image_url → Flutter'da ürün görseli göstermek için kullanılır.

Spring Boot karşılığı: DTO sınıfı.
"""