import pytest

PROTECTED = [
    ("get", "/bookings"),
    ("post", "/bookings"),
    ("get", "/bookings/00000000-0000-0000-0000-000000000000"),
    ("post", "/bookings/00000000-0000-0000-0000-000000000000/cancel"),
    ("get", "/profile"),
    ("patch", "/profile"),
    ("delete", "/profile"),
    ("post", "/profile/phone-change/otp"),
    ("post", "/profile/phone-change/verify"),
    ("post", "/profile/push-token"),
]

PUBLIC = [
    ("get", "/slots"),
    ("get", "/marshals"),
]


@pytest.mark.parametrize("method,path", PROTECTED)
def test_protected_requires_token(client, method, path):
    resp = client.request(method, path, json={})
    assert resp.status_code == 401
    assert resp.json()["code"] == "unauthorized"


@pytest.mark.parametrize("method,path", PUBLIC)
def test_public_no_token(client, method, path):
    resp = client.request(method, path)
    assert resp.status_code == 200


def test_bad_bearer_token(client):
    resp = client.get("/profile", headers={"Authorization": "Bearer garbage"})
    assert resp.status_code == 401
