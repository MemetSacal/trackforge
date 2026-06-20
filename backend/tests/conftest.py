"""
TrackForge Test Suite — conftest.py
"""
import os, uuid
os.environ.setdefault("DATABASE_URL", "sqlite+aiosqlite:///:memory:")
os.environ.setdefault("SECRET_KEY", "test-secret-trackforge-2026-qa")
os.environ.setdefault("ALGORITHM", "HS256")
os.environ.setdefault("ACCESS_TOKEN_EXPIRE_MINUTES", "15")
os.environ.setdefault("REFRESH_TOKEN_EXPIRE_DAYS", "7")
os.environ.setdefault("ANTHROPIC_API_KEY", "test")
os.environ.setdefault("RESEND_API_KEY", "")
os.environ.setdefault("APP_BASE_URL", "http://test")
os.environ.setdefault("SENTRY_DSN", "")
os.environ.setdefault("ENVIRONMENT", "test")

import sqlalchemy.ext.asyncio as _sa_async
_orig_create = _sa_async.create_async_engine
def _patched_create(url, **kwargs):
    if "sqlite" in str(url):
        kwargs.pop("pool_size", None)
        kwargs.pop("max_overflow", None)
    return _orig_create(url, **kwargs)
_sa_async.create_async_engine = _patched_create

import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker

from backend.app.main import app
from backend.app.infrastructure.db.base import Base
from backend.app.infrastructure.db.session import get_db

TEST_DB = "sqlite+aiosqlite:///:memory:"
test_engine = _orig_create(TEST_DB, connect_args={"check_same_thread": False})
TestingSession = async_sessionmaker(test_engine, class_=AsyncSession, expire_on_commit=False)


@pytest_asyncio.fixture(scope="session", autouse=True)
async def create_tables():
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest_asyncio.fixture
async def db_session():
    """Her test için izole session — test sonunda rollback."""
    async with TestingSession() as session:
        yield session
        await session.rollback()


@pytest_asyncio.fixture
async def client(db_session):
    async def override_get_db():
        yield db_session
    app.dependency_overrides[get_db] = override_get_db
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as c:
        yield c
    app.dependency_overrides.clear()


def _uid() -> str:
    """Her fixture çağrısında unique suffix üretir — email çakışmasını önler."""
    return uuid.uuid4().hex[:8]


@pytest_asyncio.fixture
async def free_user(client):
    """Free tier kullanıcı — her test için unique email."""
    uid = _uid()
    email = f"free_{uid}@example.com"
    resp = await client.post("/api/v1/auth/register", json={
        "email": email,
        "password": "Test1234",
        "full_name": "Free User",
    })
    assert resp.status_code in (200, 201), f"Register failed: {resp.text}"
    data = resp.json()
    return {
        "email": email,
        "password": "Test1234",
        "user_id": data.get("user_id"),
        "access_token": data.get("access_token"),
        "headers": {"Authorization": f"Bearer {data['access_token']}"},
    }


@pytest_asyncio.fixture
async def pro_user(client, db_session):
    """PRO tier kullanıcı — DB'de is_premium=True yapılır."""
    uid = _uid()
    email = f"pro_{uid}@example.com"
    resp = await client.post("/api/v1/auth/register", json={
        "email": email,
        "password": "Test1234",
        "full_name": "Pro User",
    })
    assert resp.status_code in (200, 201)
    data = resp.json()
    user_id = data.get("user_id")

    from sqlalchemy import update
    from backend.app.infrastructure.db.models.user_model import UserModel
    await db_session.execute(
        update(UserModel).where(UserModel.id == user_id).values(is_premium=True)
    )
    await db_session.commit()

    login = await client.post("/api/v1/auth/login", json={
        "email": email, "password": "Test1234"
    })
    token = login.json().get("access_token")
    return {
        "email": email,
        "user_id": user_id,
        "access_token": token,
        "headers": {"Authorization": f"Bearer {token}"},
    }


@pytest_asyncio.fixture
async def other_user(client):
    """IDOR testleri için farklı kullanıcı."""
    uid = _uid()
    email = f"other_{uid}@example.com"
    resp = await client.post("/api/v1/auth/register", json={
        "email": email,
        "password": "Test1234",
        "full_name": "Other User",
    })
    data = resp.json()
    return {
        "email": email,
        "user_id": data.get("user_id"),
        "access_token": data.get("access_token"),
        "headers": {"Authorization": f"Bearer {data['access_token']}"},
    }


async def create_exercise_session(client, headers, notes="Test Seans"):
    from datetime import date
    resp = await client.post("/api/v1/exercises/sessions", headers=headers, json={
        "date": str(date.today()),
        "duration_minutes": 45,
        "notes": notes,
    })
    assert resp.status_code in (200, 201), f"Session create failed: {resp.text}"
    return resp.json()["id"]


async def add_exercise_to_session(client, headers, session_id):
    resp = await client.post(
        f"/api/v1/exercises/sessions/{session_id}/exercises",
        headers=headers,
        json={
            "exercise_name": "Squat",
            "sets": 3, "reps": 10,
            "weight_kg": 60.0,
            "muscle_group": "legs",
        }
    )
    assert resp.status_code in (200, 201), f"Exercise add failed: {resp.text}"
    return resp.json()["id"]
