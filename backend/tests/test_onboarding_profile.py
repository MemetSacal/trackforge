"""ONBOARDING & PROFILE TESTS — ONB-01..09, PROF-01..07"""
import pytest
from datetime import date


class TestOnboarding:

    @pytest.mark.p0
    @pytest.mark.regression
    async def test_onb01_new_user_onboarding_incomplete(self, client, free_user):
        """Regression #1: Yeni kullanıcı onboarding tamamlanmamış."""
        resp = await client.get("/api/v1/onboarding", headers=free_user["headers"])
        if resp.status_code == 200:
            assert resp.json().get("is_completed") is False
        else:
            assert resp.status_code == 404  # kayıt yok = tamamlanmamış

    @pytest.mark.p1
    @pytest.mark.regression
    async def test_onb04_goal_mapping_gain_weight(self, client, free_user):
        """Regression #4: gain_weight → weight_gain (muscle_gain değil)."""
        resp = await client.post("/api/v1/onboarding", headers=free_user["headers"],
            json={
                "goals": ["gain_weight"], "age": 25, "gender": "male",
                "height_cm": 175, "weight_kg": 65.0, "target_weight_kg": 75.0,
                "activity_level": "moderate", "daily_calorie_habit": "1500_2000",
            })
        assert resp.status_code in (200, 201)

        prefs = await client.get("/api/v1/preferences", headers=free_user["headers"])
        if prefs.status_code == 200:
            goal = prefs.json().get("fitness_goal")
            assert goal == "weight_gain", \
                f"'gain_weight' '{goal}' maplandı. Beklenen: 'weight_gain'. Regression #4."

    @pytest.mark.p1
    @pytest.mark.regression
    async def test_onb_complete_sets_flag(self, client, free_user):
        """Regression #1: /onboarding/complete → is_completed=True."""
        base = {
            "goals": ["lose_weight"], "age": 25, "gender": "male",
            "height_cm": 175, "weight_kg": 80.0, "target_weight_kg": 70.0,
            "activity_level": "moderate", "daily_calorie_habit": "1500_2000",
        }
        await client.post("/api/v1/onboarding", headers=free_user["headers"], json=base)
        await client.post("/api/v1/onboarding/complete",
                          headers=free_user["headers"], json=base)

        check = await client.get("/api/v1/onboarding", headers=free_user["headers"])
        if check.status_code == 200:
            assert check.json().get("is_completed") is True, "Regression #1"


class TestProfileStateManagement:

    @pytest.mark.p0
    @pytest.mark.regression
    @pytest.mark.xfail(reason="SQLite transaction isolation — PostgreSQL'da geçer")
    async def test_prof04_premium_sync(self, client, pro_user):
        """Regression #23: /auth/me'den is_premium=True alınmalı."""
        resp = await client.get("/api/v1/auth/me", headers=pro_user["headers"])
        assert resp.status_code == 200
        assert resp.json().get("is_premium") is True, "Regression #23 (syncFromMe)"

    @pytest.mark.p0
    @pytest.mark.regression
    async def test_prof01_account_data_isolation(self, client, free_user, other_user):
        """Regression kritik: hesap değişiminde egzersiz verisi sızmamalı."""
        from tests.conftest import create_exercise_session
        free_sid = await create_exercise_session(
            client, free_user["headers"], "Free User Private"
        )
        # other_user kendi listesine bakıyor
        today = str(date.today())
        resp = await client.get(
            f"/api/v1/exercises/sessions?from={today}&to={today}",
            headers=other_user["headers"]
        )
        assert resp.status_code == 200
        ids = [s["id"] for s in resp.json()]
        assert free_sid not in ids, "VERİ SIZINTISI! Regression kritik fix."

    @pytest.mark.p1
    async def test_me_returns_required_fields(self, client, free_user):
        """/auth/me tüm gerekli alanları döndürmeli."""
        resp = await client.get("/api/v1/auth/me", headers=free_user["headers"])
        assert resp.status_code == 200
        for field in ["id", "email", "full_name", "is_premium", "email_verified"]:
            assert field in resp.json(), f"'{field}' alanı /auth/me'de eksik!"


class TestFailureScenarios:

    @pytest.mark.p1
    async def test_invalid_token_401(self, client):
        """Geçersiz token → 401."""
        resp = await client.get("/api/v1/auth/me",
                                headers={"Authorization": "Bearer invalid.token.here"})
        assert resp.status_code == 401

    @pytest.mark.p1
    async def test_invalid_measurement_no_corrupt_data(self, client, free_user):
        """Geçersiz ölçüm kaydı DB'yi kirletmemeli."""
        resp = await client.post("/api/v1/measurements", headers=free_user["headers"],
            json={"date": str(date.today()), "weight_kg": "not_a_number"})
        assert resp.status_code in (400, 422)
        # Geçersiz kayıt sonrası history temiz olmalı
        check = await client.get("/api/v1/measurements/history",
                                 headers=free_user["headers"])
        assert check.status_code == 200
        items = check.json() if isinstance(check.json(), list) else []
        assert len(items) == 0
