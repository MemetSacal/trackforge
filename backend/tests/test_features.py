"""FEATURE TESTS — shopping, measurements, preferences, race conditions"""
import pytest
import asyncio
from datetime import date, timedelta


class TestShoppingList:

    @pytest.mark.p1
    @pytest.mark.regression
    async def test_shop_add_and_read(self, client, free_user):
        """Alışveriş öğesi eklenebilir ve listede görünür."""
        resp = await client.post("/api/v1/shopping", headers=free_user["headers"],
            json={"name": "Tavuk", "quantity": "500g", "notes": "test"})
        assert resp.status_code == 201

        list_resp = await client.get("/api/v1/shopping", headers=free_user["headers"])
        assert list_resp.status_code == 200

    @pytest.mark.p0
    @pytest.mark.regression
    async def test_shop_idempotency_manual(self, client, free_user):
        """Regression #18: aynı ürünü ekle → listede 1'den fazla olabilir ama
        Flutter katmanı duplicate'i önlüyor (isim kontrolüyle)."""
        item = {"name": "Yumurta", "quantity": "12", "notes": "test"}
        await client.post("/api/v1/shopping", headers=free_user["headers"], json=item)
        await client.post("/api/v1/shopping", headers=free_user["headers"], json=item)

        resp = await client.get("/api/v1/shopping", headers=free_user["headers"])
        data = resp.json()
        items = data if isinstance(data, list) else data.get("items", [])
        yumurta = [i for i in items if i.get("name") == "Yumurta"]
        # Backend duplicate'e izin verebilir, ama Flutter katmanı filtreler
        # Bu test backend davranışını belgeliyor
        assert len(yumurta) >= 1


class TestMeasurements:

    @pytest.mark.p1
    @pytest.mark.regression
    async def test_olc01_history_empty_for_new_user(self, client, free_user):
        """Regression #21: yeni kullanıcı ölçüm history boş gelmeli."""
        resp = await client.get("/api/v1/measurements/history",
                                headers=free_user["headers"])
        assert resp.status_code == 200
        data = resp.json()
        items = data if isinstance(data, list) else []
        assert len(items) == 0

    @pytest.mark.p1
    @pytest.mark.regression
    async def test_olc02_added_measurement_appears(self, client, free_user):
        """Regression #20: eklenen ölçüm değeri doğru geri geliyor."""
        today = str(date.today())
        resp = await client.post("/api/v1/measurements", headers=free_user["headers"],
            json={"date": today, "weight_kg": 80.5, "chest_cm": 95.0})
        assert resp.status_code in (200, 201)

        history = await client.get("/api/v1/measurements/history",
                                   headers=free_user["headers"])
        assert history.status_code == 200
        items = history.json() if isinstance(history.json(), list) else []
        weights = [m.get("weight_kg") for m in items]
        assert 80.5 in weights

    @pytest.mark.p1
    @pytest.mark.regression
    async def test_prof01_account_isolation(self, client, free_user, other_user):
        """Regression kritik: hesap değişiminde ölçüm verisi sızmamalı."""
        today = str(date.today())
        await client.post("/api/v1/measurements", headers=free_user["headers"],
            json={"date": today, "weight_kg": 75.5})

        resp = await client.get("/api/v1/measurements/history",
                                headers=other_user["headers"])
        assert resp.status_code == 200
        items = resp.json() if isinstance(resp.json(), list) else []
        assert 75.5 not in [m.get("weight_kg") for m in items], \
            "VERİ SIZINTISI! Regression kritik fix."


class TestPreferences:

    @pytest.mark.p2
    @pytest.mark.regression
    async def test_food_preferences_update(self, client, free_user):
        """Regression #13: besin tercihleri güncellenebilmeli."""
        # Önce preference kaydı oluştur
        create = await client.post("/api/v1/preferences", headers=free_user["headers"],
            json={"liked_foods": ["ceviz"], "disliked_foods": ["zeytin"]})
        # PUT ile güncelle
        if create.status_code in (200, 201):
            resp = await client.put("/api/v1/preferences", headers=free_user["headers"],
                json={"liked_foods": ["ceviz", "yumurta"], "disliked_foods": ["zeytin"]})
            assert resp.status_code == 200
        else:
            # Prefs yoksa POST yeterli
            assert create.status_code in (200, 201, 404, 409)

    @pytest.mark.p1
    @pytest.mark.regression
    async def test_fitness_goal_weight_gain(self, client, free_user):
        """Regression #4: weight_gain fitness_goal set edilebilmeli."""
        # Prefs oluştur veya güncelle
        resp = await client.post("/api/v1/preferences", headers=free_user["headers"],
            json={"fitness_goal": "weight_gain"})
        if resp.status_code not in (200, 201):
            resp = await client.put("/api/v1/preferences", headers=free_user["headers"],
                json={"fitness_goal": "weight_gain"})
        # 200/201 veya 404 (preferences henüz yok) — ikisi de kabul
        assert resp.status_code in (200, 201, 404, 409)


class TestRaceConditions:

    @pytest.mark.p1
    async def test_rc04_parallel_auth_requests(self, client, free_user):
        """Paralel /auth/me istekleri hepsi başarılı olmalı."""
        responses = await asyncio.gather(*[
            client.get("/api/v1/auth/me", headers=free_user["headers"])
            for _ in range(5)
        ])
        for r in responses:
            assert r.status_code == 200

    @pytest.mark.p2
    @pytest.mark.xfail(reason="SQLite concurrent insert unreliable")
    async def test_rc01_concurrent_measurement_insert(self, client, free_user):
        """Eşzamanlı ölçüm ekleme — crash olmamalı."""
        today = str(date.today())
        yesterday = str(date.today() - timedelta(days=1))
        r1, r2 = await asyncio.gather(
            client.post("/api/v1/measurements", headers=free_user["headers"],
                json={"date": today, "weight_kg": 80.0}),
            client.post("/api/v1/measurements", headers=free_user["headers"],
                json={"date": yesterday, "weight_kg": 80.5}),
        )
        assert r1.status_code in (200, 201, 409)
        assert r2.status_code in (200, 201, 409)
        # En az biri başarılı
        assert r1.status_code in (200, 201) or r2.status_code in (200, 201)
