from datetime import datetime, timedelta

from .conftest import login, pick_available_slot


def _book(client, headers, slot_id, seat_gear, key):
    return client.post(
        "/bookings",
        json={"slot_id": slot_id, "seat_gear": seat_gear},
        headers={**headers, "Idempotency-Key": key},
    )


def _slot_free(client, slot_id):
    return client.get(f"/slots/{slot_id}").json()["free_seats"]


def test_early_cancel_releases_seats(client, clock):
    headers = login(client, "+79992220001", name="Гонщик")
    slot = pick_available_slot(client)
    base_free = slot["free_seats"]

    created = _book(client, headers, slot["id"], ["rental"], "idem-cancel-early").json()
    assert _slot_free(client, slot["id"]) == base_free - 1

    resp = client.post(f"/bookings/{created['id']}/cancel", headers=headers)
    assert resp.status_code == 200
    assert resp.json()["status"] == "cancelled"
    assert _slot_free(client, slot["id"]) == base_free


def test_late_cancel_keeps_seats(client, clock):
    headers = login(client, "+79992220002", name="Гонщик")
    slot = pick_available_slot(client)
    created = _book(client, headers, slot["id"], ["rental"], "idem-cancel-late").json()
    free_after_book = _slot_free(client, slot["id"])

    start = datetime.fromisoformat(slot["start_at"])
    clock.set(start - timedelta(hours=1))
    resp = client.post(f"/bookings/{created['id']}/cancel", headers=headers)
    assert resp.status_code == 200
    assert resp.json()["status"] == "late_cancel"
    assert _slot_free(client, slot["id"]) == free_after_book


def test_exact_two_hours_is_early(client, clock):
    headers = login(client, "+79992220003", name="Гонщик")
    slot = pick_available_slot(client)
    created = _book(client, headers, slot["id"], ["own"], "idem-cancel-2h").json()

    start = datetime.fromisoformat(slot["start_at"])
    clock.set(start - timedelta(hours=2))
    resp = client.post(f"/bookings/{created['id']}/cancel", headers=headers)
    assert resp.status_code == 200
    assert resp.json()["status"] == "cancelled"


def test_cancel_after_start_returns_slot_started(client, clock):
    headers = login(client, "+79992220004", name="Гонщик")
    slot = pick_available_slot(client)
    created = _book(client, headers, slot["id"], ["own"], "idem-cancel-started").json()

    start = datetime.fromisoformat(slot["start_at"])
    clock.set(start + timedelta(minutes=1))
    resp = client.post(f"/bookings/{created['id']}/cancel", headers=headers)
    assert resp.status_code == 422
    assert resp.json()["code"] == "slot_started"


def test_double_cancel_returns_already_cancelled(client, clock):
    headers = login(client, "+79992220005", name="Гонщик")
    slot = pick_available_slot(client)
    created = _book(client, headers, slot["id"], ["own"], "idem-cancel-twice").json()

    first = client.post(f"/bookings/{created['id']}/cancel", headers=headers)
    assert first.status_code == 200
    second = client.post(f"/bookings/{created['id']}/cancel", headers=headers)
    assert second.status_code == 409
    assert second.json()["code"] == "already_cancelled"
