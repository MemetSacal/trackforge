# Barkod proxy endpoint — Open Food Facts API entegrasyonu
import httpx
from fastapi import APIRouter, HTTPException
from backend.app.core.dependencies import get_current_user
from fastapi import Depends
from backend.app.application.schemas.barcode import BarcodeResponse

router = APIRouter()


@router.get("/{barcode}", response_model=BarcodeResponse)
async def get_product_by_barcode(
    barcode: str,
    current_user: str = Depends(get_current_user),
):
    """Barkod numarasına göre ürün besin değerlerini getir."""
    try:
        # Open Food Facts API — ücretsiz, kayıt gerektirmez
        url = f"https://world.openfoodfacts.org/api/v0/product/{barcode}.json"

        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(url)

        if response.status_code != 200:
            raise HTTPException(status_code=502, detail="Open Food Facts API erişilemedi.")

        data = response.json()

        # Ürün bulunamadı
        if data.get("status") != 1:
            raise HTTPException(status_code=404, detail="Bu barkoda ait ürün bulunamadı.")

        product = data.get("product", {})
        nutriments = product.get("nutriments", {})

        return BarcodeResponse(
            barcode=barcode,
            product_name=product.get("product_name") or product.get("product_name_tr") or "Bilinmiyor",
            brand=product.get("brands"),
            quantity=product.get("quantity"),
            # Besin değerleri — 100g başına
            calories_per_100g=nutriments.get("energy-kcal_100g"),
            protein_per_100g=nutriments.get("proteins_100g"),
            carbs_per_100g=nutriments.get("carbohydrates_100g"),
            fat_per_100g=nutriments.get("fat_100g"),
            fiber_per_100g=nutriments.get("fiber_100g"),
            sugar_per_100g=nutriments.get("sugars_100g"),
            # Porsiyon bilgisi
            serving_size=product.get("serving_size"),
            calories_per_serving=nutriments.get("energy-kcal_serving"),
            image_url=product.get("image_front_url"),
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Barkod sorgulanamadı: {str(e)}")


"""
DOSYA AKIŞI:
GET /barcode/{barcode} → Open Food Facts API proxy

Open Food Facts:
  - Ücretsiz, açık kaynak besin veritabanı
  - 3 milyondan fazla ürün
  - Kayıt veya API key gerektirmez
  - URL: https://world.openfoodfacts.org/api/v0/product/{barcode}.json

Flutter tarafında:
  - Kamera ile barkod okuma (mobile_scanner paketi)
  - Barkod string'i bu endpoint'e gönderilir
  - Besin değerleri alınır, kalori hesabına eklenir

Spring Boot karşılığı: @RestController + RestTemplate ile dış API proxy.
"""