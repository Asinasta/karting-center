from app.domain.loyalty import (
    LOYALTY_REGULAR_DISCOUNT_PERCENT,
    apply_loyalty_discount,
    loyalty_from_completed_rides,
)

from .conftest import login


def test_loyalty_tiers():
    assert loyalty_from_completed_rides(0) == (None, None)
    assert loyalty_from_completed_rides(2) == (None, None)
    assert loyalty_from_completed_rides(3) == ("regular", LOYALTY_REGULAR_DISCOUNT_PERCENT)
    assert loyalty_from_completed_rides(8) == ("vip", 15)


def test_apply_loyalty_discount():
    assert apply_loyalty_discount(10000, 10) == 9000
    assert apply_loyalty_discount(10000, None) == 10000


def test_profile_includes_loyalty_for_seed_client(client):
    headers = login(client, "+79990000000")
    # Seed client has several completed rides in fixtures.
    resp = client.get("/profile", headers=headers)
    assert resp.status_code == 200
    body = resp.json()
    assert body["completed_rides_count"] >= 3
    assert body["loyalty_tier"] in {"regular", "vip"}
    assert body["loyalty_discount_percent"] is not None
