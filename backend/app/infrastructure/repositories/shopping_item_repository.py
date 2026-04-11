# Interface'in somut implementasyonu — gerçek DB işlemleri burada
import uuid
from datetime import datetime
from typing import Optional, List

from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession

from backend.app.domain.entities.shopping_item import ShoppingItem
from backend.app.domain.interfaces.i_shopping_item_repository import IShoppingItemRepository
from backend.app.infrastructure.db.models.shopping_item_model import ShoppingItemModel


class ShoppingItemRepository(IShoppingItemRepository):

    def __init__(self, db: AsyncSession):
        # AsyncSession inject edilir — her request için yeni session
        self.db = db

    # ── Entity → Model dönüşümü (DB'ye yazarken kullanılır) ──
    def _to_model(self, entity: ShoppingItem) -> ShoppingItemModel:
        return ShoppingItemModel(
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
        )

    # ── Model → Entity dönüşümü (DB'den okurken kullanılır) ──
    def _to_entity(self, model: ShoppingItemModel) -> ShoppingItem:
        return ShoppingItem(
            id=model.id,
            user_id=model.user_id,
            name=model.name,
            quantity=model.quantity,
            category=model.category,
            is_completed=model.is_completed,
            price=model.price,
            currency=model.currency,
            source=model.source,
            is_recurring=model.is_recurring,
            notes=model.notes,
            created_at=model.created_at,
            updated_at=model.updated_at,
        )

    async def create(self, item: ShoppingItem) -> ShoppingItem:
        # UUID ata ve oluşturma zamanını set et
        item.id = str(uuid.uuid4())
        item.created_at = datetime.utcnow()
        model = self._to_model(item)
        self.db.add(model)
        # flush → SQL çalıştır ama commit etme (service commit eder)
        await self.db.flush()
        # refresh → DB'den güncel halini oku (server_default alanlar için)
        await self.db.refresh(model)
        return self._to_entity(model)

    async def get_by_id(self, item_id: str, user_id: str) -> Optional[ShoppingItem]:
        # AND koşulu — hem id hem user_id eşleşmeli (ownership kontrolü)
        result = await self.db.execute(
            select(ShoppingItemModel).where(
                and_(ShoppingItemModel.id == item_id, ShoppingItemModel.user_id == user_id)
            )
        )
        model = result.scalar_one_or_none()
        return self._to_entity(model) if model else None

    async def get_all(self, user_id: str) -> List[ShoppingItem]:
        # is_completed ASC → önce False (tamamlanmayanlar), sonra True (tamamlananlar)
        # created_at ASC → eklenme sırasına göre
        result = await self.db.execute(
            select(ShoppingItemModel)
            .where(ShoppingItemModel.user_id == user_id)
            .order_by(
                ShoppingItemModel.is_completed.asc(),
                ShoppingItemModel.created_at.asc()
            )
        )
        return [self._to_entity(m) for m in result.scalars().all()]

    async def get_recurring(self, user_id: str) -> List[ShoppingItem]:
        # Sadece is_recurring=True olan ürünler — haftalık şablon için
        result = await self.db.execute(
            select(ShoppingItemModel).where(
                and_(
                    ShoppingItemModel.user_id == user_id,
                    ShoppingItemModel.is_recurring == True     # noqa: E712
                )
            )
        )
        return [self._to_entity(m) for m in result.scalars().all()]

    async def update(self, item: ShoppingItem) -> Optional[ShoppingItem]:
        # Önce kaydı bul — hem id hem user_id ile (güvenlik)
        result = await self.db.execute(
            select(ShoppingItemModel).where(
                and_(ShoppingItemModel.id == item.id, ShoppingItemModel.user_id == item.user_id)
            )
        )
        model = result.scalar_one_or_none()
        if not model:
            return None
        # Güncellenebilir alanları tek tek set et
        model.name = item.name
        model.quantity = item.quantity
        model.category = item.category
        model.price = item.price
        model.currency = item.currency
        model.source = item.source
        model.is_recurring = item.is_recurring
        model.notes = item.notes
        # is_completed burada değiştirilmez — toggle_completed metodu var
        await self.db.flush()
        await self.db.refresh(model)
        return self._to_entity(model)

    async def toggle_completed(self, item_id: str, user_id: str) -> Optional[ShoppingItem]:
        result = await self.db.execute(
            select(ShoppingItemModel).where(
                and_(ShoppingItemModel.id == item_id, ShoppingItemModel.user_id == user_id)
            )
        )
        model = result.scalar_one_or_none()
        if not model:
            return None
        # not operatörü ile mevcut durumu tersine çevir
        # True → False (geri al), False → True (tamamlandı işaretle)
        model.is_completed = not model.is_completed
        await self.db.flush()
        await self.db.refresh(model)
        return self._to_entity(model)

    async def delete(self, item_id: str, user_id: str) -> bool:
        result = await self.db.execute(
            select(ShoppingItemModel).where(
                and_(ShoppingItemModel.id == item_id, ShoppingItemModel.user_id == user_id)
            )
        )
        model = result.scalar_one_or_none()
        if not model:
            return False
        await self.db.delete(model)
        await self.db.flush()
        return True

    async def delete_completed(self, user_id: str) -> int:
        # Tamamlanan tüm ürünleri bul
        result = await self.db.execute(
            select(ShoppingItemModel).where(
                and_(
                    ShoppingItemModel.user_id == user_id,
                    ShoppingItemModel.is_completed == True     # noqa: E712
                )
            )
        )
        models = result.scalars().all()
        # Kaç tane silineceğini kaydet — response için döndürülecek
        count = len(models)
        # Her birini tek tek sil (cascade yoksa bu şekilde yapılır)
        for model in models:
            await self.db.delete(model)
        await self.db.flush()
        return count


"""
DOSYA AKIŞI:
ShoppingItemRepository, IShoppingItemRepository interface'ini implement eder.
_to_model / _to_entity → domain ile infrastructure arasındaki köprü
toggle_completed → sadece is_completed alanını tersine çevirir, diğer alanlar dokunulmaz
delete_completed → toplu silme, kaç tane silindiğini int olarak döndürür
get_all sıralaması: is_completed ASC → tamamlanmayanlar üstte görünür (UX)

Spring Boot karşılığı: @Repository anotasyonlu class.
"""