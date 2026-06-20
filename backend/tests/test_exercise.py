"""EXERCISE COMPLETION TESTS — EX-01..06, Regression #19"""
import pytest
import asyncio
from datetime import date
from tests.conftest import create_exercise_session, add_exercise_to_session


class TestExerciseCompletion:

    @pytest.mark.p0
    @pytest.mark.regression
    async def test_ex01_toggle_exercise_complete(self, client, free_user):
        """EX-01: Egzersiz completed toggle DB'ye yazılmalı."""
        sid = await create_exercise_session(client, free_user["headers"])
        eid = await add_exercise_to_session(client, free_user["headers"], sid)

        resp = await client.put(
            f"/api/v1/exercises/exercises/{eid}",
            headers=free_user["headers"],
            json={"completed": True},
        )
        assert resp.status_code == 200
        assert resp.json().get("completed") is True

    @pytest.mark.p0
    @pytest.mark.regression
    async def test_ex02_complete_session_endpoint(self, client, free_user):
        """EX-02: PATCH /sessions/{id}/complete is_completed=True dönmeli.
        Regression #19 tam fix.
        """
        sid = await create_exercise_session(client, free_user["headers"])
        resp = await client.patch(
            f"/api/v1/exercises/sessions/{sid}/complete",
            headers=free_user["headers"],
        )
        assert resp.status_code == 200, f"Complete failed: {resp.text}"
        assert resp.json().get("is_completed") is True, "Regression #19"

    @pytest.mark.p0
    @pytest.mark.regression
    async def test_ex04_is_completed_persists(self, client, free_user):
        """EX-04: Complete sonrası GET'te is_completed=True gelmeli. Migration 0002."""
        sid = await create_exercise_session(client, free_user["headers"])
        await client.patch(
            f"/api/v1/exercises/sessions/{sid}/complete",
            headers=free_user["headers"]
        )
        resp = await client.get(
            f"/api/v1/exercises/sessions/{sid}",
            headers=free_user["headers"]
        )
        assert resp.status_code == 200
        assert resp.json().get("is_completed") is True, \
            "DB persist olmadı! Migration 0002 çalıştı mı?"

    @pytest.mark.p0
    @pytest.mark.regression
    async def test_ex03_completed_shows_in_list(self, client, free_user):
        """EX-03: Tamamlanan seans listede is_completed=True göstermeli."""
        today = str(date.today())
        sid = await create_exercise_session(client, free_user["headers"], "Liste Testi")
        await client.patch(
            f"/api/v1/exercises/sessions/{sid}/complete",
            headers=free_user["headers"]
        )
        resp = await client.get(
            f"/api/v1/exercises/sessions?from={today}&to={today}",
            headers=free_user["headers"]
        )
        assert resp.status_code == 200
        sessions = resp.json()
        target = next((s for s in sessions if s["id"] == sid), None)
        assert target is not None
        assert target.get("is_completed") is True, "Regression #19"

    @pytest.mark.p1
    async def test_ex06_uncomplete_session(self, client, free_user):
        """EX-06: PUT ile is_completed=False yapılabilmeli."""
        sid = await create_exercise_session(client, free_user["headers"])
        await client.patch(f"/api/v1/exercises/sessions/{sid}/complete",
                           headers=free_user["headers"])
        resp = await client.put(
            f"/api/v1/exercises/sessions/{sid}",
            headers=free_user["headers"],
            json={"is_completed": False},
        )
        assert resp.status_code == 200
        assert resp.json().get("is_completed") is False

    @pytest.mark.p0
    @pytest.mark.security
    @pytest.mark.regression
    async def test_idor_complete_other_session(self, client, free_user, other_user):
        """IDOR: Başka kullanıcının seansı complete edilememeli."""
        other_sid = await create_exercise_session(client, other_user["headers"])
        resp = await client.patch(
            f"/api/v1/exercises/sessions/{other_sid}/complete",
            headers=free_user["headers"]
        )
        assert resp.status_code in (403, 404), f"IDOR! {resp.status_code}"

    @pytest.mark.p1
    async def test_ex05_delete_cascades(self, client, free_user):
        """EX-05: Seans silinince egzersizler de silinmeli (cascade)."""
        sid = await create_exercise_session(client, free_user["headers"])
        await add_exercise_to_session(client, free_user["headers"], sid)
        resp = await client.delete(
            f"/api/v1/exercises/sessions/{sid}",
            headers=free_user["headers"]
        )
        assert resp.status_code == 200
        ex_resp = await client.get(
            f"/api/v1/exercises/sessions/{sid}/exercises",
            headers=free_user["headers"]
        )
        if ex_resp.status_code == 200:
            assert ex_resp.json() == [], "Cascade silme çalışmadı!"

    @pytest.mark.p1
    async def test_is_completed_in_schema(self, client, free_user):
        """is_completed GET response'da olmalı. Migration 0002."""
        sid = await create_exercise_session(client, free_user["headers"])
        resp = await client.get(
            f"/api/v1/exercises/sessions/{sid}",
            headers=free_user["headers"]
        )
        assert resp.status_code == 200
        assert "is_completed" in resp.json(), \
            "is_completed schema'da yok! Migration 0002 çalıştı mı?"


class TestExerciseRaceConditions:

    @pytest.mark.p1
    @pytest.mark.xfail(reason="Race condition SQLite'da unreliable — PostgreSQL'da geçer")
    async def test_double_complete_safe(self, client, free_user):
        """RC: Aynı seansı 2 kez complete etmek güvenli olmalı."""
        sid = await create_exercise_session(client, free_user["headers"])
        r1, r2 = await asyncio.gather(
            client.patch(f"/api/v1/exercises/sessions/{sid}/complete",
                         headers=free_user["headers"]),
            client.patch(f"/api/v1/exercises/sessions/{sid}/complete",
                         headers=free_user["headers"]),
        )
        assert r1.status_code in (200, 409)
        assert r2.status_code in (200, 409)
        # Son durum: is_completed=True
        get_resp = await client.get(
            f"/api/v1/exercises/sessions/{sid}",
            headers=free_user["headers"]
        )
        assert get_resp.json().get("is_completed") is True
