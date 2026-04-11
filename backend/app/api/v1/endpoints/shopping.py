# HTTP katmanı — route tanımları ve dependency injection
from typing import List

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from backend.app.application.schemas.shopping import (
    ShoppingItemCreate, ShoppingItemUpdate,
    ShoppingItemResponse, ShoppingListResponse
)
from backend.app.application.services.shopping_service import ShoppingService
from backend.app.infrastructure.db.session import get_db
from backend.app.core.dependencies import get_current_user

router = APIRouter()


# ── Dependency: her request'te ShoppingService oluştur ──
def get_shopping_service(db: AsyncSession = Depends(get_db)) -> ShoppingService:
    return ShoppingService(db)


@router.post("", response_model=ShoppingItemResponse, status_code=status.HTTP_201_CREATED)
async def create_item(
    data: ShoppingItemCreate,
    current_user: str = Depends(get_current_user),
    service: ShoppingService = Depends(get_shopping_service),
):
    """Yeni alışveriş ürünü ekle."""
    return await service.create(current_user, data)


@router.get("", response_model=ShoppingListResponse)
async def get_shopping_list(
    current_user: str = Depends(get_current_user),
    service: ShoppingService = Depends(get_shopping_service),
):
    """Tüm alışveriş listesini ve sepet özetini getir."""
    return await service.get_list(current_user)


@router.get("/recurring", response_model=List[ShoppingItemResponse])
async def get_recurring_items(
    current_user: str = Depends(get_current_user),
    service: ShoppingService = Depends(get_shopping_service),
):
    """Tekrar eden ürünleri getir — haftalık şablon için."""
    return await service.get_recurring(current_user)


@router.put("/{item_id}", response_model=ShoppingItemResponse)
async def update_item(
    item_id: str,
    data: ShoppingItemUpdate,
    current_user: str = Depends(get_current_user),
    service: ShoppingService = Depends(get_shopping_service),
):
    """Ürün bilgilerini güncelle."""
    return await service.update(item_id, current_user, data)


# PATCH → kısmi güncelleme — sadece is_completed değişiyor
# PUT değil çünkü tüm kaynağı değiştirmiyoruz
@router.patch("/{item_id}/toggle", response_model=ShoppingItemResponse)
async def toggle_completed(
    item_id: str,
    current_user: str = Depends(get_current_user),
    service: ShoppingService = Depends(get_shopping_service),
):
    """Ürünü tamamlandı/tamamlanmadı olarak işaretle."""
    return await service.toggle_completed(item_id, current_user)


@router.delete("/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_item(
    item_id: str,
    current_user: str = Depends(get_current_user),
    service: ShoppingService = Depends(get_shopping_service),
):
    """Tek ürünü sil."""
    await service.delete(item_id, current_user)


@router.delete("/completed/clear", response_model=dict)
async def clear_completed(
    current_user: str = Depends(get_current_user),
    service: ShoppingService = Depends(get_shopping_service),
):
    """Tamamlanan tüm ürünleri temizle — sepeti sıfırla."""
    return await service.delete_completed(current_user)


"""
DOSYA AKIŞI:
POST   /shopping                    → ürün ekle (201)
GET    /shopping                    → tüm liste + özet tutar
GET    /shopping/recurring          → tekrar eden ürünler
PUT    /shopping/{id}               → ürün bilgilerini güncelle
PATCH  /shopping/{id}/toggle        → tamamlandı işaretle/kaldır
DELETE /shopping/{id}               → tek ürün sil (204)
DELETE /shopping/completed/clear    → tamamlananları toplu sil

HTTP Method farkı:
PUT   → tüm kaynağı günceller (name, price, category vs.)
PATCH → sadece bir özelliği değiştirir (is_completed toggle)
Bu ayrım REST standartlarına uygun ve Swagger'da daha okunabilir görünür.

Spring Boot karşılığı: @RestController + @RequestMapping + @PatchMapping.
"""