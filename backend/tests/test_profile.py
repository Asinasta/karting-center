from fastapi.testclient import TestClient

from app.adapters.fixtures import FixturesAdapter
from app.main import create_app

from .conftest import SEED_PHONE, login


def test_get_profile(client):
    headers = login(client, SEED_PHONE)
    resp = client.get("/profile", headers=headers)
    assert resp.status_code == 200
    assert resp.json()["phone"] == SEED_PHONE


def test_update_profile_name_only(client):
    headers = login(client, "+79993330001", name="Старое")
    resp = client.patch("/profile", json={"name": "Новое Имя"}, headers=headers)
    assert resp.status_code == 200
    assert resp.json()["name"] == "Новое Имя"
    assert resp.json()["phone"] == "+79993330001"


def test_patch_ignores_phone(client):
    headers = login(client, "+79993330002", name="Имя")
    resp = client.patch(
        "/profile", json={"name": "Имя2", "phone": "+79993339000"}, headers=headers
    )
    assert resp.status_code == 200
    assert resp.json()["phone"] == "+79993330002"


def test_phone_change_success(client):
    headers = login(client, "+79993330003", name="Имя")
    otp = client.post("/profile/phone-change/otp", json={"new_phone": "+79993339999"}, headers=headers)
    assert otp.status_code == 204
    verify = client.post(
        "/profile/phone-change/verify",
        json={"new_phone": "+79993339999", "code": "0000"},
        headers=headers,
    )
    assert verify.status_code == 200
    assert verify.json()["phone"] == "+79993339999"


def test_phone_change_already_used(client):
    headers = login(client, "+79993330004", name="Имя")
    resp = client.post(
        "/profile/phone-change/otp", json={"new_phone": SEED_PHONE}, headers=headers
    )
    assert resp.status_code == 409
    assert resp.json()["code"] == "phone_already_used"


def test_phone_change_invalid_code(settings, clock):
    backend = FixturesAdapter(clock=clock, dev_otp_enabled=False)
    app = create_app(settings=settings, backend=backend, clock=clock)
    c = TestClient(app)
    # Login the seed client through the non-dev backend (needs the real OTP).
    c.post("/auth/otp", json={"phone": SEED_PHONE})
    otp_code = backend._otps[SEED_PHONE].code
    tokens = c.post("/auth/verify", json={"phone": SEED_PHONE, "code": otp_code}).json()
    headers = {"Authorization": f"Bearer {tokens['access_token']}"}

    c.post("/profile/phone-change/otp", json={"new_phone": "+79993338888"}, headers=headers)
    resp = c.post(
        "/profile/phone-change/verify",
        json={"new_phone": "+79993338888", "code": "9999"},
        headers=headers,
    )
    assert resp.status_code == 400
    assert resp.json()["code"] == "invalid_code"


def test_delete_account_invalidates_session(client):
    tokens = client.post(
        "/auth/verify", json={"phone": "+79993330005", "code": "0000", "name": "Имя"}
    ).json()
    headers = {"Authorization": f"Bearer {tokens['access_token']}"}

    resp = client.delete("/profile", headers=headers)
    assert resp.status_code == 204

    # Access token now maps to a deleted client.
    after = client.get("/profile", headers=headers)
    assert after.status_code == 401

    # Refresh token was revoked.
    refresh = client.post("/auth/refresh", json={"refresh_token": tokens["refresh_token"]})
    assert refresh.status_code == 401


def test_register_push_token(client):
    headers = login(client, "+79993330006", name="Имя")
    resp = client.post(
        "/profile/push-token",
        json={"token": "a" * 32, "platform": "android", "device_id": "dev-1"},
        headers=headers,
    )
    assert resp.status_code == 204
