from .conftest import login, pick_available_slot, pick_cancelled_slot, pick_no_gear_slot


def _book(client, headers, slot_id, seat_gear, key):
    return client.post(
        "/bookings",
        json={"slot_id": slot_id, "seat_gear": seat_gear},
        headers={**headers, "Idempotency-Key": key},
    )


def test_create_booking_success(client):
    headers = login(client, "+79991110001", name="Гонщик")
    slot = pick_available_slot(client)
    resp = _book(client, headers, slot["id"], ["own", "rental"], "idem-key-0001")
    assert resp.status_code == 201, resp.text
    body = resp.json()
    assert body["status"] == "active"
    assert body["seats_count"] == 2
    assert body["rental_count"] == 1
    # Server-authoritative total = price*seats + rental_price*rental.
    expected = slot["price"]["amount"] * 2 + slot["rental_price"]["amount"] * 1
    assert body["price_total"]["amount"] == expected
    # Snapshot must not expose live availability fields.
    assert "free_seats" not in body["slot"]
    assert "free_rental_gear" not in body["slot"]


def test_create_requires_idempotency_key(client):
    headers = login(client, "+79991110002", name="Гонщик")
    slot = pick_available_slot(client)
    resp = client.post(
        "/bookings",
        json={"slot_id": slot["id"], "seat_gear": ["own"]},
        headers=headers,
    )
    assert resp.status_code == 400
    assert resp.json()["code"] == "validation_error"


def test_idempotent_replay_returns_same_booking(client):
    headers = login(client, "+79991110003", name="Гонщик")
    slot = pick_available_slot(client)
    first = _book(client, headers, slot["id"], ["own"], "idem-replay-1")
    second = _book(client, headers, slot["id"], ["own"], "idem-replay-1")
    assert first.status_code == 201
    assert second.status_code == 201
    assert first.json()["id"] == second.json()["id"]


def test_idempotency_conflict_on_changed_payload(client):
    headers = login(client, "+79991110004", name="Гонщик")
    slot = pick_available_slot(client)
    _book(client, headers, slot["id"], ["own"], "idem-conflict-1")
    changed = _book(client, headers, slot["id"], ["own", "own"], "idem-conflict-1")
    assert changed.status_code == 422
    assert changed.json()["code"] == "validation_error"


def test_double_booking(client):
    headers = login(client, "+79991110005", name="Гонщик")
    slot = pick_available_slot(client)
    first = _book(client, headers, slot["id"], ["own"], "idem-double-a")
    assert first.status_code == 201
    second = _book(client, headers, slot["id"], ["own"], "idem-double-b")
    assert second.status_code == 409
    body = second.json()
    assert body["code"] == "double_booking"
    assert body["details"]["booking_id"] == first.json()["id"]


def test_slot_full(client):
    from .conftest import pick_full_slot

    headers = login(client, "+79991110006", name="Гонщик")
    slot = pick_full_slot(client)
    resp = _book(client, headers, slot["id"], ["own"], "idem-full-1")
    assert resp.status_code == 409
    assert resp.json()["code"] == "slot_full"


def test_slot_cancelled(client):
    headers = login(client, "+79991110007", name="Гонщик")
    slot = pick_cancelled_slot(client)
    resp = _book(client, headers, slot["id"], ["own"], "idem-cancel-1")
    assert resp.status_code == 410
    assert resp.json()["code"] == "slot_cancelled"


def test_no_rental_gear_available(client):
    headers = login(client, "+79991110008", name="Гонщик")
    slot = pick_no_gear_slot(client)
    resp = _book(client, headers, slot["id"], ["rental"], "idem-nogear-1")
    assert resp.status_code == 409
    assert resp.json()["code"] == "slot_full"


def test_list_bookings_pagination(client):
    headers = login(client, "+79991110009", name="Гонщик")
    slot = pick_available_slot(client)
    _book(client, headers, slot["id"], ["own"], "idem-list-1")
    resp = client.get("/bookings", headers=headers)
    assert resp.status_code == 200
    body = resp.json()
    assert "items" in body and "pagination" in body
    assert body["pagination"]["total"] >= 1


def test_get_booking_owner_only(client):
    owner = login(client, "+79991110010", name="Владелец")
    slot = pick_available_slot(client)
    created = _book(client, owner, slot["id"], ["own"], "idem-owner-1").json()

    other = login(client, "+79991110011", name="Другой")
    resp = client.get(f"/bookings/{created['id']}", headers=other)
    assert resp.status_code == 403
    assert resp.json()["code"] == "forbidden"


def test_get_booking_not_found(client):
    headers = login(client, "+79991110012", name="Гонщик")
    resp = client.get(
        "/bookings/00000000-0000-0000-0000-000000000000", headers=headers
    )
    assert resp.status_code == 404
