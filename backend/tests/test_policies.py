from datetime import datetime, timedelta, timezone

import pytest

from app.contracts.common import Money
from app.domain.models import SlotRecord
from app.domain.policies import (
    cancellation_kind,
    ensure_bookable,
    max_seats,
    price_total,
    seats_and_rental,
)
from app.errors import ApiError

NOW = datetime(2026, 1, 1, 12, 0, 0, tzinfo=timezone.utc)


def _slot(free_seats=6, free_rental_gear=4, status="scheduled", start_delta_h=24) -> SlotRecord:
    from uuid import uuid4

    return SlotRecord(
        id=uuid4(),
        track_config_id=uuid4(),
        marshal_id=uuid4(),
        start_at=NOW + timedelta(hours=start_delta_h),
        total_seats=8,
        free_seats=free_seats,
        free_rental_gear=free_rental_gear,
        price=Money(amount=150000),
        rental_price=Money(amount=50000),
        meeting_point="x",
        status=status,
    )


def test_seats_and_rental():
    assert seats_and_rental(["own", "rental", "rental"]) == (3, 2)
    assert seats_and_rental(["own"]) == (1, 0)


def test_max_seats_min_rule():
    assert max_seats(free_seats=10, capacity_cap=14) == 3
    assert max_seats(free_seats=2, capacity_cap=14) == 2
    assert max_seats(free_seats=10, capacity_cap=1) == 1


def test_price_total():
    total = price_total(Money(amount=150000), Money(amount=50000), seats_count=3, rental_count=2)
    assert total.amount == 150000 * 3 + 50000 * 2
    assert total.currency == "RUB"


def test_ensure_bookable_ok():
    ensure_bookable(_slot(), capacity_cap=14, seats_count=2, rental_count=1, now=NOW)


def test_ensure_bookable_cancelled():
    with pytest.raises(ApiError) as exc:
        ensure_bookable(_slot(status="cancelled"), 14, 1, 0, NOW)
    assert exc.value.code == "slot_cancelled"


def test_ensure_bookable_started():
    with pytest.raises(ApiError) as exc:
        ensure_bookable(_slot(start_delta_h=-1), 14, 1, 0, NOW)
    assert exc.value.code == "slot_started"


def test_ensure_bookable_full_seats():
    with pytest.raises(ApiError) as exc:
        ensure_bookable(_slot(free_seats=1), 14, 2, 0, NOW)
    assert exc.value.code == "slot_full"
    assert exc.value.details == {"free_seats": 1, "free_rental_gear": 4}


def test_ensure_bookable_full_gear():
    with pytest.raises(ApiError) as exc:
        ensure_bookable(_slot(free_rental_gear=0), 14, 1, 1, NOW)
    assert exc.value.code == "slot_full"


@pytest.mark.parametrize(
    "delta,expected",
    [
        (timedelta(hours=2, seconds=1), "early"),
        (timedelta(hours=2), "early"),
        (timedelta(hours=1, minutes=59, seconds=59), "late"),
    ],
)
def test_cancellation_boundary(delta, expected):
    assert cancellation_kind(NOW + delta, NOW) == expected
