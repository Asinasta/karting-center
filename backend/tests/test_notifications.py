from .conftest import SEED_PHONE, login


def test_list_notifications_includes_rate_marshal(client):
    headers = login(client, SEED_PHONE)
    resp = client.get("/notifications", headers=headers)
    assert resp.status_code == 200, resp.text
    items = resp.json()["items"]
    assert any(item["type"] == "rate_marshal" for item in items)


def test_notifications_require_auth(client):
    resp = client.get("/notifications")
    assert resp.status_code == 401
