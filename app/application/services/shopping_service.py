# İş mantığı burada — controller ile repository arasındaki köprü
from typing import List
from collections import Counter

from sqlalchemy.ext.asyncio import AsyncSession

from app.application.schemas.shopping import (
    ShoppingItemCreate, ShoppingItemUpdate,
    ShoppingItemResponse, ShoppingListResponse, ShoppingSummary
)
from app.core.exceptions import NotFoundException
from app.domain.entities.shopping_item import ShoppingItem
from app.infrastructure.repositories.shopping_item_repository import ShoppingItemRepository


class ShoppingService:

    def __init__(self, db: AsyncSession):
        # Repository bağımlılığı — sadece interface üzerinden konuşulur
        self.repo = ShoppingItemRepository(db)
        self.db = db

    # ── Yardımcı: entity → response dönüşümü ──
    def _to_response(self, entity: ShoppingItem) -> ShoppingItemResponse:
        return ShoppingItemResponse(
            id=entity.id,
            user_id=entity.user_id,
            name=entity.name,
            quantity=entity.quantity,
            category=entity.category,
            is_completed=entity.is_completed,
            price=entity.price,
            currency=entity.currency,
            source=entity.source,
            is_recurring=entity.is_recurring,
            notes=entity.notes,
            created_at=entity.created_at,
            updated_at=entity.updated_at,
        )

    # ── Yardımcı: sepet özeti hesapla ──
    def _calculate_summary(self, items: List[ShoppingItem]) -> ShoppingSummary:
        total_items = len(items)

        # Tamamlanan ve kalan sayıları hesapla
        completed_items = sum(1 for i in items if i.is_completed)
        remaining_items = total_items - completed_items

        # Sadece fiyatı girilmiş ürünlerin toplamını al
        # price None olan ürünler hesaplamaya dahil edilmez
        total_price = sum(i.price for i in items if i.price is not None)
        completed_price = sum(i.price for i in items if i.is_completed and i.price is not None)
        remaining_price = total_price - completed_price

        # Baskın para birimini bul — Counter en çok tekrar edeni bulur
        # Örn: [TRY, TRY, USD, TRY] → TRY (3 kez)
        currencies = [i.currency for i in items]
        dominant_currency = Counter(currencies).most_common(1)[0][0] if currencies else "TRY"

        return ShoppingSummary(
            total_items=total_items,
            completed_items=completed_items,
            remaining_items=remaining_items,
            total_price=round(total_price, 2),      # 2 ondalık basamak
            completed_price=round(completed_price, 2),
            remaining_price=round(remaining_price, 2),
            currency=dominant_currency,
        )

    async def create(self, user_id: str, data: ShoppingItemCreate) -> ShoppingItemResponse:
        entity = ShoppingItem(
            id="",          # repository UUID atayacak
            user_id=user_id,
            name=data.name,
            quantity=data.quantity,
            category=data.category,
            is_completed=False,     # Yeni ürün her zaman tamamlanmamış başlar
            price=data.price,
            currency=data.currency,
            source=data.source,
            is_recurring=data.is_recurring,
            notes=data.notes,
        )
        created = await self.repo.create(entity)
        await self.db.commit()
        return self._to_response(created)

    async def get_list(self, user_id: str) -> ShoppingListResponse:
        # Tüm liste + özeti döndür — tek API çağrısıyla her şey gelir
        entities = await self.repo.get_all(user_id)
        items = [self._to_response(e) for e in entities]
        # Summary hesaplamak için entity listesi kullanılır (response değil)
        summary = self._calculate_summary(entities)
        return ShoppingListResponse(items=items, summary=summary)

    async def get_recurring(self, user_id: str) -> List[ShoppingItemResponse]:
        # Tekrar eden ürünler — haftalık şablon oluşturmak için
        entities = await self.repo.get_recurring(user_id)
        return [self._to_response(e) for e in entities]

    async def update(self, item_id: str, user_id: str, data: ShoppingItemUpdate) -> ShoppingItemResponse:
        # Önce mevcut kaydı getir
        entity = await self.repo.get_by_id(item_id, user_id)
        if not entity:
            raise NotFoundException("Ürün bulunamadı.")

        # Partial update — None gönderilmişse mevcut değeri koru
        entity.name = data.name if data.name is not None else entity.name
        entity.quantity = data.quantity if data.quantity is not None else entity.quantity
        entity.category = data.category if data.category is not None else entity.category
        entity.price = data.price if data.price is not None else entity.price
        entity.currency = data.currency if data.currency is not None else entity.currency
        entity.source = data.source if data.source is not None else entity.source
        entity.is_recurring = data.is_recurring if data.is_recurring is not None else entity.is_recurring
        entity.notes = data.notes if data.notes is not None else entity.notes

        updated = await self.repo.update(entity)
        await self.db.commit()
        return self._to_response(updated)

    async def toggle_completed(self, item_id: str, user_id: str) -> ShoppingItemResponse:
        # Tamamlandı durumunu tersine çevir — repository'de not operatörü kullanılır
        entity = await self.repo.toggle_completed(item_id, user_id)
        if not entity:
            raise NotFoundException("Ürün bulunamadı.")
        await self.db.commit()
        return self._to_response(entity)

    async def delete(self, item_id: str, user_id: str) -> None:
        # 404 döndür — güvenlik için ownership gizlenir (403 değil)
        deleted = await self.repo.delete(item_id, user_id)
        if not deleted:
            raise NotFoundException("Ürün bulunamadı.")
        await self.db.commit()

    async def delete_completed(self, user_id: str) -> dict:
        # Tamamlanan tüm ürünleri sil — kaç tane silindiğini döndür
        count = await self.repo.delete_completed(user_id)
        await self.db.commit()
        # {"deleted_count": 5} gibi basit bir response
        return {"deleted_count": count}


"""
DOSYA AKIŞI:
ShoppingService diğer servislerden farklı olan kısımlar:
  _calculate_summary → items listesinden sepet özeti hesaplar (DB çağrısı yok)
  Counter → Python built-in, baskın para birimini bulmak için
  toggle_completed → repository'deki not operatörünü tetikler
  delete_completed → toplu temizlik, int count döner
  get_list → items + summary birlikte döner (tek sorgu, iki bilgi)

Spring Boot karşılığı: @Service anotasyonlu class.
"""