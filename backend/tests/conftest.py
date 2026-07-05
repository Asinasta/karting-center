"""Shared test fixtures: fixed-clock app, TestClient and auth helpers."""

from __future__ import annotations

from datetime import datetime, timezone

import pytest
from fastapi.testclient import TestClient

from app.adapters.fixtures import FixturesAdapter
from app.config import Settings
from app.domain.clock import FixedClock
from app.main import create_app

SEED_PHONE = "+79990000000"
FIXED_NOW = datetime(2026, 7, 5, 6, 15, 0, tzinfo=timezone.utc)  # 09:15 MSK, before first slot


@pytest.fixture
def clock() -> FixedClock:
    return FixedClock(FIXED_NOW)


@pytest.fixture
def settings() -> Settings:
    return Settings(
        app_env="dev",
        backend_adapter="fixtures",
        jwt_access_secret="test-access-secret",
        jwt_refresh_secret="test-refresh-secret",
    )


@pytest.fixture
def backend(clock) -> FixturesAdapter:
    return FixturesAdapter(clock=clock, dev_otp_enabled=True)


@pytest.fixture
def app(settings, backend, clock):
    return create_app(settings=settings, backend=backend, clock=clock)


@pytest.fixture
def client(app) -> TestClient:
    return TestClient(app)


def login(client: TestClient, phone: str, name: str | None = None) -> dict[str, str]:
    payload: dict[str, str] = {"phone": phone, "code": "0000"}
    if name is not None:
        payload["name"] = name
    resp = client.post("/auth/verify", json=payload)
    assert resp.status_code == 200, resp.text
    token = resp.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


def get_slots(client: TestClient, **params) -> list[dict]:
    resp = client.get("/slots", params=params)
    assert resp.status_code == 200, resp.text
    return resp.json()


def pick_available_slot(client: TestClient) -> dict:
    for slot in get_slots(client):
        if slot["status"] == "scheduled" and slot["free_seats"] > 0 and slot["free_rental_gear"] > 0:
            return slot
    raise AssertionError("no available slot in fixtures")


def pick_full_slot(client: TestClient) -> dict:
    for slot in get_slots(client, only_available="false"):
        if slot["free_seats"] == 0 and slot["status"] == "scheduled":
            return slot
    raise AssertionError("no full slot in fixtures")


def pick_cancelled_slot(client: TestClient) -> dict:
    for slot in get_slots(client, only_available="false"):
        if slot["status"] == "cancelled":
            return slot
    raise AssertionError("no cancelled slot in fixtures")


def pick_no_gear_slot(client: TestClient) -> dict:
    for slot in get_slots(client):
        if slot["status"] == "scheduled" and slot["free_seats"] > 0 and slot["free_rental_gear"] == 0:
            return slot
    raise AssertionError("no zero-gear slot in fixtures")
