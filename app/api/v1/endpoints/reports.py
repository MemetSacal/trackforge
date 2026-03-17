# HTTP katmanı — rapor endpoint'leri
from datetime import date

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.application.schemas.report import WeeklyReportResponse, MonthlyReportResponse
from app.application.services.report_service import ReportService
from app.infrastructure.db.session import get_db
from app.core.dependencies import get_current_user

router = APIRouter()


def get_report_service(db: AsyncSession = Depends(get_db)) -> ReportService:
    return ReportService(db)


@router.get("/weekly", response_model=WeeklyReportResponse)
async def get_weekly_report(
    # Query parametresi — verilmezse bugünün tarihi kullanılır
    reference_date: date = Query(default=None, description="Haftadaki herhangi bir gün (varsayılan: bugün)"),
    current_user: str = Depends(get_current_user),
    service: ReportService = Depends(get_report_service),
):
    """
    Haftalık özet raporu getir.
    reference_date → o haftanın Pazartesi-Pazar aralığını döndürür.
    Örn: 2026-03-17 → 16-22 Mart 2026 haftasının raporu
    """
    # reference_date verilmemişse bugünü kullan
    if reference_date is None:
        reference_date = date.today()
    return await service.get_weekly_report(current_user, reference_date)


@router.get("/monthly", response_model=MonthlyReportResponse)
async def get_monthly_report(
    # year ve month ayrı query parametresi olarak alınır
    year: int = Query(..., ge=2020, le=2100, description="Yıl — örn: 2026"),
    month: int = Query(..., ge=1, le=12, description="Ay — 1-12 arası"),
    current_user: str = Depends(get_current_user),
    service: ReportService = Depends(get_report_service),
):
    """
    Aylık özet raporu getir.
    Örn: year=2026&month=3 → Mart 2026 raporu
    """
    return await service.get_monthly_report(current_user, year, month)


"""
DOSYA AKIŞI:
GET /reports/weekly                          → bu haftanın raporu
GET /reports/weekly?reference_date=2026-03-10 → o haftanın raporu
GET /reports/monthly?year=2026&month=3       → Mart 2026 raporu

reference_date opsiyonel — verilmezse date.today() kullanılır
year/month zorunlu — ge/le ile validasyon yapılır

Spring Boot karşılığı: @RestController + @GetMapping + @RequestParam.
"""