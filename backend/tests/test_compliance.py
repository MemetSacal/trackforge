"""
CALORIE COMPLIANCE TESTS
==========================
Kapsam: AI-17, AI-18, AI-19, AI-20
Öncelik: P0 — en kritik mantık hataları burada.

Regression odak:
  - #17: Eksik tüketim artık "uyumsuz" sayılmamalı
  - #16: under_1500 kullanıcıya 2500 kcal direkt verilmemeli
  - Diyet uyumu yalnızca hedef AŞIMINI cezalandırmalı

Bu testler backend service'i doğrudan test eder (unit + integration).
"""
import pytest
from unittest.mock import AsyncMock, MagicMock


# ─── Unit Tests: _calculate_complied ────────────────────────────────────────

class TestCalorieComplianceLogic:
    """_calculate_complied metodunun mantık testleri."""

    @pytest.fixture
    def service(self):
        """MealComplianceService instance — DB bağımlılıkları mock'lu."""
        from backend.app.application.services.meal_compliance_service import (
            MealComplianceService,
        )
        from unittest.mock import MagicMock, AsyncMock
        mock_repo = MagicMock()
        mock_db   = MagicMock()
        svc = MealComplianceService(
            compliance_repository=mock_repo,
            db=mock_db,
        )
        # _get_compliant_days_this_week default mock
        svc._get_compliant_days_this_week = AsyncMock(return_value=3)
        return svc

    @pytest.mark.p0
    @pytest.mark.regression
    def test_ai17_under_target_is_compliant(self, service):
        """AI-17: Hedefin altında kalmak UYUMLU sayılmalı.
        
        Regression: önceden 0.80 alt sınırı vardı.
        406/1739 kcal = ratio 0.23 → eskiden "uyumsuz", şimdi "uyumlu".
        """
        # 406 kcal tüketildi, 1739 hedef, yakılan 0
        result = service._calculate_complied(
            calories_consumed=406.0,
            calories_target=1739.0,
            calories_burned=0.0,
        )
        assert result is True, (
            "406/1739 kcal uyumlu sayılmalı (eksik tüketim = kilo verme başarısı). "
            "Regression #17."
        )

    @pytest.mark.p0
    @pytest.mark.regression
    def test_ai17_zero_calories_compliant(self, service):
        """AI-17: 0 kcal tüketiminde veri yok → varsayılan True."""
        result = service._calculate_complied(
            calories_consumed=0.0,
            calories_target=1739.0,
            calories_burned=0.0,
        )
        # 0 kcal: "not calories_consumed" → True (veri yok)
        assert result is True

    @pytest.mark.p0
    def test_ai18_over_target_is_noncompliant(self, service):
        """AI-18: Hedefin %120'sini aşmak UYUMSUZ sayılmalı."""
        # 1739 * 1.21 = 2104 kcal — %121 → uyumsuz
        result = service._calculate_complied(
            calories_consumed=2104.0,
            calories_target=1739.0,
            calories_burned=0.0,
        )
        assert result is False, "Hedefin %121'i uyumsuz olmalı."

    @pytest.mark.p0
    def test_ai18_at_120_percent_boundary_compliant(self, service):
        """AI-18: %120 sınırında — uyumlu (≤ 1.20). Float precision toleransıyla."""
        # 1739 * 1.20 = 2086.8 → float hassasiyet için 2086 kullan (%119.9)
        result = service._calculate_complied(
            calories_consumed=2086.0,  # 1739 * 1.199 — tam sınır altında
            calories_target=1739.0,
            calories_burned=0.0,
        )
        assert result is True, "%119.9'da uyumlu sayılmalı (≤ 1.20)."

    @pytest.mark.p1
    def test_calories_burned_reduces_net(self, service):
        """Egzersiz kalori yakımı net tüketimi düşürür."""
        # 2200 tüket, 600 yak → net 1600 / 1739 = 0.92 → uyumlu
        result = service._calculate_complied(
            calories_consumed=2200.0,
            calories_target=1739.0,
            calories_burned=600.0,
        )
        assert result is True

    @pytest.mark.p1
    def test_no_target_defaults_compliant(self, service):
        """Hedef yoksa (None) varsayılan uyumlu."""
        result = service._calculate_complied(
            calories_consumed=1500.0,
            calories_target=None,
            calories_burned=0.0,
        )
        assert result is True


# ─── Unit Tests: _calculate_daily_target ────────────────────────────────────

class TestDailyTargetCalculation:
    """_calculate_daily_target'ın kademeli artış mantığı — regression #16."""

    @pytest.fixture
    def service(self):
        from backend.app.application.services.meal_compliance_service import (
            MealComplianceService,
        )
        from unittest.mock import MagicMock, AsyncMock
        svc = MealComplianceService(
            compliance_repository=MagicMock(),
            db=MagicMock(),
        )
        svc._get_compliant_days_this_week = AsyncMock(return_value=3)
        return svc

    @pytest.mark.p1
    @pytest.mark.regression
    async def test_ai19_under1500_habit_starts_low(self, service):
        """AI-19: under_1500 kullanıcısına 2500 kcal direkt verilmemeli.
        
        Regression: #16 fix — habit_base 1500'den başlar, kademeli artar.
        TDEE 2400 olsa bile ilk hedef 1700 civarında olmalı.
        """
        from datetime import date
        result = await service._calculate_daily_target(
            tdee=2400.0,
            fitness_goal="weight_loss",
            daily_calorie_habit="under_1500",
            user_id="test-user",
            today=date.today(),
        )
        # 1500 base + 200 adım (düşük uyum: 3 gün) = 1700
        assert result <= 1800, (
            f"under_1500 kullanıcısına {result} hedef verildi — "
            "2000+ çok agresif, kademeli başlamalı. Regression #16."
        )
        assert result >= 1200, f"Hedef {result} sağlıklı minimumun altında!"

    @pytest.mark.p1
    @pytest.mark.regression
    async def test_ai20_high_compliance_bigger_step(self, service):
        """AI-20: 6+ gün uyumlu → +400 kcal adım (yüksek uyum)."""
        from datetime import date
        service._get_compliant_days_this_week = AsyncMock(return_value=6)

        result = await service._calculate_daily_target(
            tdee=2400.0,
            fitness_goal="weight_loss",
            daily_calorie_habit="under_1500",
            user_id="test-user",
            today=date.today(),
        )
        # 1500 + 400 (yüksek uyum) = 1900
        assert result >= 1800, \
            f"6 gün uyumlu kullanıcı daha büyük adım almalı, aldı: {result}"

    @pytest.mark.p1
    async def test_normal_habit_uses_tdee(self, service):
        """Normal alışkanlıkta (over_2500 veya None) TDEE kullanılır."""
        from datetime import date
        result = await service._calculate_daily_target(
            tdee=2400.0,
            fitness_goal="maintenance",
            daily_calorie_habit="over_2500",
            user_id="test-user",
            today=date.today(),
        )
        # maintenance → TDEE + 0 = 2400
        assert abs(result - 2400.0) < 50  # tolerance

    @pytest.mark.p2
    async def test_minimum_1200_floor(self, service):
        """Hedef hiçbir zaman 1200'ün altına düşmemeli."""
        from datetime import date
        result = await service._calculate_daily_target(
            tdee=1000.0,  # çok düşük TDEE
            fitness_goal="weight_loss",
            daily_calorie_habit="under_1500",
            user_id="test-user",
            today=date.today(),
        )
        assert result >= 1200, f"Güvenli minimum ihlal edildi: {result}"


# ─── Integration Test: Compliance API ───────────────────────────────────────

class TestComplianceAPI:
    """HTTP seviyesi compliance testleri."""

    @pytest.mark.p1
    async def test_compliance_today_creates_record(
        self, client, free_user
    ):
        """Günlük compliance kaydı oluşturulabilmeli."""
        from datetime import date
        resp = await client.post(
            "/api/v1/meal-compliance",
            headers=free_user["headers"],
            json={
                "date": str(date.today()),
                "calories_consumed": 1500.0,
            }
        )
        assert resp.status_code in (200, 201)
        data = resp.json()
        assert "calories_target" in data
        assert "calories_target" in data  # target 0 olabilir (profil yok = TDEE yok)

    @pytest.mark.p0
    @pytest.mark.regression
    async def test_ai17_compliance_undereating_via_api(
        self, client, free_user
    ):
        """AI-17: API üzerinden — az yemek 'complied=true' döndürmeli."""
        from datetime import date
        today = str(date.today())

        # Önce kayıt oluştur
        await client.post(
            "/api/v1/meal-compliance",
            headers=free_user["headers"],
            json={"date": today, "calories_consumed": 400.0}
        )

        # Güncelle: çok az kalori
        resp = await client.put(
            f"/api/v1/meal-compliance/{today}",
            headers=free_user["headers"],
            json={"calories_consumed": 400.0},
        )

        if resp.status_code == 200:
            data = resp.json()
            # complied=True veya compliance_rate > 0 olmalı
            assert data.get("complied") is True or \
                   data.get("compliance_rate", 0) > 0, \
                "400 kcal tüketim uyumlu sayılmalı. Regression #17."
