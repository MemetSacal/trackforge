# Repository sözleşmesi — infrastructure ne yaparsa yapsın bu interface sabit kalır
from abc import ABC, abstractmethod
from typing import Optional, List

from backend.app.domain.entities.shopping_item import ShoppingItem


class IShoppingItemRepository(ABC):

    # Yeni ürün oluştur
    @abstractmethod
    async def create(self, item: ShoppingItem) -> ShoppingItem:
        pass

    # ID ile tek ürün getir — ownership kontrolü için user_id de alır
    @abstractmethod
    async def get_by_id(self, item_id: str, user_id: str) -> Optional[ShoppingItem]:
        pass

    # Kullanıcının tüm alışveriş listesini getir
    # Sıralama: önce tamamlanmayanlar, sonra tamamlananlar
    @abstractmethod
    async def get_all(self, user_id: str) -> List[ShoppingItem]:
        pass

    # Sadece is_recurring=True olan ürünleri getir
    # Kullanım: haftalık alışveriş şablonu oluşturmak için
    @abstractmethod
    async def get_recurring(self, user_id: str) -> List[ShoppingItem]:
        pass

    # Ürün bilgilerini güncelle (name, quantity, price vs.)
    @abstractmethod
    async def update(self, item: ShoppingItem) -> ShoppingItem:
        pass

    # is_completed alanını tersine çevir — True→False, False→True
    # Ayrı bir metod çünkü sadece tek alan değişiyor
    @abstractmethod
    async def toggle_completed(self, item_id: str, user_id: str) -> Optional[ShoppingItem]:
        pass

    # Tek ürün sil
    @abstractmethod
    async def delete(self, item_id: str, user_id: str) -> bool:
        pass

    # Tamamlanan tüm ürünleri toplu sil — "sepeti temizle" butonu için
    # Kaç ürün silindiğini int olarak döndürür
    @abstractmethod
    async def delete_completed(self, user_id: str) -> int:
        pass


"""
DOSYA AKIŞI:
IShoppingItemRepository diğer repository interface'lerinden şu açıdan farklı:
- toggle_completed: sadece is_completed'ı değiştiren özel metod
- delete_completed: toplu silme — "tamamlananları temizle" özelliği için
- get_recurring: haftalık şablon ürünlerini ayrıca sorgulama

Spring Boot karşılığı: JpaRepository'yi extend eden interface + custom query metodları.
"""