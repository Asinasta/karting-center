"""Pure business policies. No I/O, unit-tested directly."""

from __future__ import annotations

from datetime import datetime, timedelta

from ..contracts.bookings import GearChoice
from ..contracts.common import Money
from ..errors import ApiError
from .models import SlotRecord

CANCEL_THRESHOLD = timedelta(hours=2)


def seats_and_rental(seat_gear: list[GearChoice]) -> tuple[int, int]:
    """seats_count is the array length; rental_count is the number of `rental` seats."""
    seats_count = len(seat_gear)
    rental_count = sum(1 for g in seat_gear if g == "rental")
    return seats_count, rental_count


def max_seats(free_seats: int, capacity_cap: int) -> int:
    """AvailabilityPolicy: min(free_seats, capacity_cap)."""
    return min(free_seats, capacity_cap)


def ensure_bookable(
    slot: SlotRecord,
    capacity_cap: int,
    seats_count: int,
    rental_count: int,
    now: datetime,
) -> None:
    """Raise the contract error if the slot cannot be booked with these seats."""
    if slot.status == "cancelled":
        raise ApiError("slot_cancelled", "Slot was cancelled by the center")

    if now >= slot.start_at:
        raise ApiError("slot_started", "Slot has already started")

    allowed_seats = min(slot.free_seats, capacity_cap)
    if seats_count < 1:
        raise ApiError(
            "validation_error",
            "seats_count must be at least 1",
            status_code=422,
        )

    if seats_count > allowed_seats or rental_count > slot.free_rental_gear:
        raise ApiError(
            "slot_full",
            "Not enough free seats or rental gear",
            details={
                "free_seats": slot.free_seats,
                "free_rental_gear": slot.free_rental_gear,
            },
        )


def price_total(price: Money, rental_price: Money, seats_count: int, rental_count: int) -> Money:
    """BookingPricePreviewCalculator (server-authoritative total)."""
    amount = price.amount * seats_count + rental_price.amount * rental_count
    return Money(amount=amount, currency=price.currency)


def cancellation_kind(start_at: datetime, now: datetime) -> str:
    """Return 'early' (>= 2h before start) or 'late' (< 2h before start).

    Caller must handle the already-started case before calling this.
    """
    return "early" if (start_at - now) >= CANCEL_THRESHOLD else "late"
