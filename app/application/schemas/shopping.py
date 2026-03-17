# Pydantic şemaları — HTTP request/response veri doğrulaması
from datetime import datetime
from typing import Optional, List

from pydantic import BaseModel, Field


# ── İstek şemaları (request) ──

class ShoppingItemCreate(BaseModel):
    # name zorunlu — min 1, max 200 karakter
    name: str = Field(..., min_length=1, max_length=200)
    quantity: Optional[str] = None                                  # "500g", "2 adet", "1 paket"
    category: Optional[str] = None                                  # "protein", "karbonhidrat", "sebze"
    price: Optional[float] = Field(None, ge=0)                      # ge=0 → negatif fiyat olamaz
    currency: str = Field(default="TRY", pattern="^(TRY|USD|EUR)$") # Sadece bu 3 değer kabul edilir
    source: Optional[str] = None                                    # "market", "getir", "migros"
    is_recurring: bool = False                                      # Varsayılan False
    notes: Optional[str] = None


class ShoppingItemUpdate(BaseModel):
    # Tüm alanlar opsiyonel — partial update (None ise service eskiyi korur)
    name: Optional[str] = Field(None, min_length=1, max_length=200)
    quantity: Optional[str] = None
    category: Optional[str] = None
    price: Optional[float] = Field(None, ge=0)
    currency: Optional[str] = Field(None, pattern="^(TRY|USD|EUR)$")
    source: Optional[str] = None
    is_recurring: Optional[bool] = None
    notes: Optional[str] = None
    # is_completed burada yok — toggle endpoint ile değiştirilir


# ── Yanıt şemaları (response) ──

class ShoppingItemResponse(BaseModel):
    # Tek ürün response'u
    id: str
    user_id: str
    name: str
    quantity: Optional[str] = None
    category: Optional[str] = None
    is_completed: bool
    price: Optional[float] = None
    currency: str
    source: Optional[str] = None
    is_recurring: bool
    notes: Optional[str] = None
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True  # ORM modelinden doğrudan oluşturulabilir


class ShoppingSummary(BaseModel):
    # Sepet özeti — DB'ye yazılmaz, her sorguda service'de hesaplanır
    total_items: int        # Toplam ürün sayısı
    completed_items: int    # Tamamlanan ürün sayısı
    remaining_items: int    # Henüz alınmayan ürün sayısı
    total_price: float      # Tüm ürünlerin fiyat toplamı
    completed_price: float  # Tamamlananların fiyat toplamı
    remaining_price: float  # Henüz alınmayanların fiyat toplamı
    currency: str           # Listedeki baskın para birimi


class ShoppingListResponse(BaseModel):
    # GET /shopping endpoint'inin döndürdüğü tam response
    # items listesi + summary birlikte döner — tek API çağrısıyla her şey gelir
    items: List[ShoppingItemResponse]
    summary: ShoppingSummary


"""
DOSYA AKIŞI:
ShoppingItemCreate  → POST /shopping body
ShoppingItemUpdate  → PUT /shopping/{id} body (is_completed dahil değil)
ShoppingItemResponse → tekil ürün response
ShoppingSummary     → DB'ye yazılmayan hesaplanmış özet
ShoppingListResponse → GET /shopping tam response (items + summary)

currency pattern → regex ile sadece TRY/USD/EUR kabul edilir
price ge=0 → Pydantic validasyonu, negatif değer hata verir

Spring Boot karşılığı: DTO (Data Transfer Object) sınıfları.
"""