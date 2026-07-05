from .conftest import SEED_PHONE, login


def test_existing_client_login(client):
    resp = client.post("/auth/verify", json={"phone": SEED_PHONE, "code": "0000"})
    assert resp.status_code == 200
    body = resp.json()
    assert body["access_token"] and body["refresh_token"]
    assert body["expires_in"] == 15 * 60


def test_new_client_requires_name(client):
    resp = client.post("/auth/verify", json={"phone": "+79995550000", "code": "0000"})
    assert resp.status_code == 400
    assert resp.json()["code"] == "validation_error"
    # OTP stays valid: registration can finish on the next verify with the same code.
    second = client.post(
        "/auth/verify",
        json={"phone": "+79995550000", "code": "0000", "name": "Новый"},
    )
    assert second.status_code == 200


def test_new_client_with_name(client):
    resp = client.post(
        "/auth/verify", json={"phone": "+79995550001", "code": "0000", "name": "Новый"}
    )
    assert resp.status_code == 200


def test_invalid_code(client, settings, clock):
    # dev OTP bypass accepts 0000; a non-dev-like wrong code must be rejected.
    from app.adapters.fixtures import FixturesAdapter
    from app.main import create_app
    from fastapi.testclient import TestClient

    backend = FixturesAdapter(clock=clock, dev_otp_enabled=False)
    app = create_app(settings=settings, backend=backend, clock=clock)
    c = TestClient(app)
    c.post("/auth/otp", json={"phone": "+79995550002"})
    real_code = backend._otps["+79995550002"].code
    wrong_code = "0000" if real_code != "0000" else "1234"
    resp = c.post(
        "/auth/verify", json={"phone": "+79995550002", "code": wrong_code, "name": "X"}
    )
    assert resp.status_code == 400
    assert resp.json()["code"] == "invalid_code"


def test_send_otp_rate_limit(client):
    first = client.post("/auth/otp", json={"phone": "+79995550003"})
    assert first.status_code == 204
    second = client.post("/auth/otp", json={"phone": "+79995550003"})
    assert second.status_code == 429
    body = second.json()
    assert body["code"] == "rate_limit"
    assert body["retry_after"] >= 1


def test_refresh_flow(client):
    tokens = client.post("/auth/verify", json={"phone": SEED_PHONE, "code": "0000"}).json()
    resp = client.post("/auth/refresh", json={"refresh_token": tokens["refresh_token"]})
    assert resp.status_code == 200
    new_tokens = resp.json()
    assert new_tokens["refresh_token"] != tokens["refresh_token"]

    # Old refresh token is rotated out and no longer valid.
    reused = client.post("/auth/refresh", json={"refresh_token": tokens["refresh_token"]})
    assert reused.status_code == 401


def test_refresh_invalid(client):
    resp = client.post("/auth/refresh", json={"refresh_token": "not-a-token"})
    assert resp.status_code == 401
    assert resp.json()["code"] == "unauthorized"


def test_invalid_phone_format(client):
    resp = client.post("/auth/otp", json={"phone": "12345"})
    assert resp.status_code == 400
    assert resp.json()["code"] == "validation_error"
