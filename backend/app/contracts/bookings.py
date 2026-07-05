"""Booking contract models (bookings/models.yaml)."""

from __future__ import annotations

from datetime import datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, Field

from .common import Money, Pagination
from .marshals import Marshal
from .slots import TrackConfig

GearChoice = Literal["own", "rental"]
BookingStatus = Literal["active", "cancelled", "late_cancel", "cancelled_by_center", "completed"]
MAX_BOOKING_SEATS = 14


class BookingSlotSnapshot(BaseModel):
    id: UUID
    track_config: TrackConfig
    marshal: Marshal
    start_at: datetime
    price: Money
    rental_price: Money
    meeting_point: str
    meeting_point_lat: float | None = Field(default=None, ge=-90, le=90)
    meeting_point_lng: float | None = Field(default=None, ge=-180, le=180)
    geometry: list[list[float]] | None = None
    status: Literal["scheduled", "cancelled"]
    cancel_reason: str | None = None


class Booking(BaseModel):
    id: UUID
    slot: BookingSlotSnapshot
    seats_count: int = Field(ge=1, le=MAX_BOOKING_SEATS)
    rental_count: int = Field(ge=0, le=MAX_BOOKING_SEATS)
    seat_gear: list[GearChoice] = Field(min_length=1, max_length=MAX_BOOKING_SEATS)
    price_total: Money
    status: BookingStatus
    created_at: datetime
    cancelled_at: datetime | None = None
    cancel_reason: str | None = None


class CreateBookingRequest(BaseModel):
    slot_id: UUID
    seat_gear: list[GearChoice] = Field(min_length=1, max_length=MAX_BOOKING_SEATS)


class BookingList(BaseModel):
    items: list[Booking]
    pagination: Pagination
