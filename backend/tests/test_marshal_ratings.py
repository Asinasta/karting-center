from .conftest import SEED_PHONE, login


def _bookings(client, headers):
    resp = client.get("/bookings", headers=headers)
    assert resp.status_code == 200
    return resp.json()["items"]


def test_rate_marshal_on_completed_booking(client):
    headers = login(client, SEED_PHONE)
    booking = next(
        item
        for item in _bookings(client, headers)
        if item["status"] == "completed" and item.get("marshal_rating") is None
    )

    resp = client.post(
        f"/bookings/{booking['id']}/marshal-rating",
        json={"stars": 5, "comment": "Супер маршал"},
        headers=headers,
    )
    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert body["marshal_rating"]["stars"] == 5
    assert body["marshal_rating"]["comment"] == "Супер маршал"

    updated = client.patch(
        f"/bookings/{booking['id']}/marshal-rating",
        json={"stars": 4, "comment": "Обновлённый комментарий"},
        headers=headers,
    )
    assert updated.status_code == 200, updated.text
    patched = updated.json()
    assert patched["marshal_rating"]["stars"] == 4
    assert patched["marshal_rating"]["comment"] == "Обновлённый комментарий"

    deleted = client.delete(
        f"/bookings/{booking['id']}/marshal-rating",
        headers=headers,
    )
    assert deleted.status_code == 200, deleted.text
    assert deleted.json().get("marshal_rating") is None

    recreated = client.post(
        f"/bookings/{booking['id']}/marshal-rating",
        json={"stars": 3},
        headers=headers,
    )
    assert recreated.status_code == 200, recreated.text

    duplicate = client.post(
        f"/bookings/{booking['id']}/marshal-rating",
        json={"stars": 4},
        headers=headers,
    )
    assert duplicate.status_code == 409
    assert duplicate.json()["code"] == "already_rated"


def test_rate_marshal_rejects_upcoming_booking(client):
    headers = login(client, SEED_PHONE)
    upcoming = next(item for item in _bookings(client, headers) if item["status"] == "active")
    denied = client.post(
        f"/bookings/{upcoming['id']}/marshal-rating",
        json={"stars": 5},
        headers=headers,
    )
    assert denied.status_code == 422
    assert denied.json()["code"] == "rating_not_eligible"


def test_marshals_expose_average_rating(client):
    resp = client.get("/marshals")
    assert resp.status_code == 200
    rated = [m for m in resp.json() if m["rating_count"] > 0]
    assert rated, "seed should include marshal ratings"
    assert rated[0]["average_rating"] is not None
