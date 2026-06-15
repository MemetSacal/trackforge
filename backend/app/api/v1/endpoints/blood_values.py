from datetime import date, datetime, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import select, delete as sa_delete
from sqlalchemy.ext.asyncio import AsyncSession

from backend.app.core.dependencies import get_current_user
from backend.app.infrastructure.db.session import get_db
from backend.app.infrastructure.db.models.blood_value_model import BloodValueModel

router = APIRouter()

# Bilinen markerlar — mobil tarafta seçim listesi için referans.
# Serbest marker da kabul edilir; bu sadece öneri/etiket sözlüğü.
KNOWN_MARKERS = {
    "hemoglobin": {"label": "Hemoglobin", "unit": "g/dL"},
    "ferritin": {"label": "Ferritin", "unit": "ng/mL"},
    "iron": {"label": "Demir", "unit": "µg/dL"},
    "vitamin_d": {"label": "D Vitamini", "unit": "ng/mL"},
    "vitamin_b12": {"label": "B12 Vitamini", "unit": "pg/mL"},
    "tsh": {"label": "TSH", "unit": "mIU/L"},
    "glucose": {"label": "Açlık Şekeri", "unit": "mg/dL"},
    "hba1c": {"label": "HbA1c", "unit": "%"},
    "cholesterol_total": {"label": "Total Kolesterol", "unit": "mg/dL"},
    "hdl": {"label": "HDL", "unit": "mg/dL"},
    "ldl": {"label": "LDL", "unit": "mg/dL"},
    "triglycerides": {"label": "Trigliserit", "unit": "mg/dL"},
}


class BloodValueCreate(BaseModel):
    marker: str = Field(..., max_length=60)
    value: float
    unit: Optional[str] = None
    test_date: date


class BloodValueResponse(BaseModel):
    id: str
    marker: str
    value: float
    unit: Optional[str] = None
    test_date: str
    label: Optional[str] = None  # bilinen marker'sa Türkçe etiket


def _to_response(row: BloodValueModel) -> BloodValueResponse:
    known = KNOWN_MARKERS.get(row.marker)
    return BloodValueResponse(
        id=row.id,
        marker=row.marker,
        value=row.value,
        unit=row.unit or (known["unit"] if known else None),
        test_date=str(row.test_date),
        label=known["label"] if known else None,
    )


# ── GET /blood-values/markers — bilinen marker sözlüğü ──
@router.get("/markers")
async def get_known_markers(user_id: str = Depends(get_current_user)):
    """Mobil seçim listesi için bilinen marker'lar (anahtar + etiket + birim)."""
    return [
        {"marker": k, "label": v["label"], "unit": v["unit"]}
        for k, v in KNOWN_MARKERS.items()
    ]


# ── POST /blood-values ──
@router.post("", response_model=BloodValueResponse, status_code=201)
async def create_blood_value(
    body: BloodValueCreate,
    user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    row = BloodValueModel(
        user_id=user_id,
        marker=body.marker.strip(),
        value=body.value,
        unit=body.unit,
        test_date=body.test_date,
    )
    db.add(row)
    await db.commit()
    await db.refresh(row)
    return _to_response(row)


# ── GET /blood-values — tüm kayıtlar veya tek marker trendi ──
@router.get("")
async def list_blood_values(
    marker: Optional[str] = None,
    user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """marker verilirse o markerin tarihe göre trendi; yoksa hepsi
    marker'a göre gruplanmış döner."""
    q = select(BloodValueModel).where(BloodValueModel.user_id == user_id)
    if marker:
        q = q.where(BloodValueModel.marker == marker)
    q = q.order_by(BloodValueModel.test_date.asc())
    rows = (await db.execute(q)).scalars().all()

    if marker:
        return {"marker": marker, "values": [_to_response(r).model_dump() for r in rows]}

    # Gruplanmış: {marker: [kayıtlar]}
    grouped: dict = {}
    for r in rows:
        grouped.setdefault(r.marker, []).append(_to_response(r).model_dump())
    return {"grouped": grouped}


# ── DELETE /blood-values/{id} ──
@router.delete("/{value_id}")
async def delete_blood_value(
    value_id: str,
    user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # IDOR: sadece kendi kaydını silebilir
    row = (await db.execute(
        select(BloodValueModel).where(
            BloodValueModel.id == value_id,
            BloodValueModel.user_id == user_id,
        )
    )).scalar_one_or_none()
    if not row:
        raise HTTPException(status_code=404, detail="Kayıt bulunamadı")
    await db.execute(
        sa_delete(BloodValueModel).where(BloodValueModel.id == value_id)
    )
    await db.commit()
    return {"message": "Silindi"}
