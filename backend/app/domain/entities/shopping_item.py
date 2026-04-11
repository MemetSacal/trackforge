# Domain katmanındaki saf Python entity — hiçbir dış bağımlılık yok
from dataclasses import dataclass
from datetime import datetime
from typing import Optional


@dataclass
class ShoppingItem:
    # Zorunlu kimlik alanları
    id: str
    user_id: str

    # Ürün temel bilgisi — sadece name zorunlu
    name: str                               # "Yulaf", "Tavuk göğsü", "Zeytinyağı"

    # Miktar bilgisi — esnek string çünkü "500g", "2 adet", "1 paket" olabilir
    quantity: Optional[str] = None

    # Kategori — "protein", "karbonhidrat", "sebze", "meyve", "süt ürünleri"
    category: Optional[str] = None

    # Alındı mı? — Flutter'da checkbox, toggle endpoint ile değiştirilir
    is_completed: bool = False

    # Fiyat bilgisi — opsiyonel, girilirse sepet tutarı hesaplanır
    price: Optional[float] = None

    # Para birimi — varsayılan TRY, USD/EUR de desteklenir
    currency: str = "TRY"

    # Nereden alınacak — "market", "getir", "yemeksepeti", "migros", "a101"
    source: Optional[str] = None

    # Her hafta tekrar eden ürün mü? — True ise "alışveriş şablonu" olarak kullanılır
    is_recurring: bool = False

    # Ek not — "organik olsun", "light versiyonu al" gibi
    notes: Optional[str] = None

    # Zaman damgaları
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


"""
DOSYA AKIŞI:
ShoppingItem entity'si saf Python dataclass'ıdır, ORM veya FastAPI'ye bağımlı değil.
is_completed → kullanıcı markette ürünü sepete atınca toggle eder
is_recurring → "her hafta yulaf alıyorum" gibi kalıcı ürünler için True
price + currency → sepet toplam tutarı bu entity'lerden service katmanında hesaplanır
DB'ye hiç yazılmayan summary (total_price, remaining_price vs.) service'de hesaplanır.

Spring Boot karşılığı: @Entity sınıfı ama Hibernate/JPA anotasyonu olmadan.
"""