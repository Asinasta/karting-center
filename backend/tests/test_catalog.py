from datetime import datetime, timedelta

from .conftest import get_slots, pick_available_slot, pick_cancelled_slot


def test_list_slots_public_no_token(client):
    resp = client.get("/slots")
    assert resp.status_code == 200
    assert isinstance(resp.json(), list)
    assert len(resp.json()) > 0


def test_list_slots_sorted_by_start(client):
    slots = get_slots(client)
    starts = [s["start_at"] for s in slots]
    assert starts == sorted(starts)


def test_default_period_is_seven_days(client, clock):
    week = get_slots(client)
    assert week, "fixtures should expose slots within the default week window"
    for slot in week:
        start = datetime.fromisoformat(slot["start_at"])
        assert start >= clock.now()
        assert start <= clock.now() + timedelta(days=7)

    extended = get_slots(
        client,
        date_from=clock.now().isoformat(),
        date_to=(clock.now() + timedelta(days=30)).isoformat(),
    )
    assert len(extended) > len(week)


def test_only_available_hides_full_and_cancelled(client):
    available = get_slots(client, only_available="true")
    for slot in available:
        assert slot["status"] == "scheduled"
        assert slot["free_seats"] > 0


def test_only_available_false_includes_cancelled(client):
    all_slots = get_slots(client, only_available="false")
    assert any(s["status"] == "cancelled" for s in all_slots)


def test_get_slot_public(client):
    slot = pick_available_slot(client)
    resp = client.get(f"/slots/{slot['id']}")
    assert resp.status_code == 200
    assert resp.json()["id"] == slot["id"]


def test_get_slot_not_found(client):
    resp = client.get("/slots/00000000-0000-0000-0000-000000000000")
    assert resp.status_code == 404
    assert resp.json()["code"] == "not_found"


def test_marshals_public(client):
    resp = client.get("/marshals")
    assert resp.status_code == 200
    assert len(resp.json()) >= 1


def test_filter_by_track_type(client):
    novice = get_slots(client, track_config_type="novice")
    assert all(s["track_config"]["type"] == "novice" for s in novice)


def test_cancelled_slot_present(client):
    slot = pick_cancelled_slot(client)
    assert slot["cancel_reason"]
