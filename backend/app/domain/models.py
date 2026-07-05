"""Internal domain records (storage-side), distinct from API contract DTOs."""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
from uuid import UUID

from ..contracts.bookings import BookingSlotSnapshot, GearChoice
from ..contracts.common import Money


@dataclass
class ClientRecord:
    id: UUID
    name: str
    phone: str
    deleted: bool = False


@dataclass
class MarshalRecord:
    id: UUID
    name: str


@dataclass
class TrackConfigRecord:
    id: UUID
    name: str
    type: str  # novice | experienced
    capacity_cap: int
    description: str | None = None
    duration_min: int | None = None
    geometry: list[list[float]] | None = None


@dataclass
class SlotRecord:
    id: UUID
    track_config_id: UUID
    marshal_id: UUID
    start_at: datetime
    total_seats: int
    free_seats: int
    free_rental_gear: int
    price: Money
    rental_price: Money
    meeting_point: str
    status: str  # scheduled | cancelled
    meeting_point_lat: float | None = None
    meeting_point_lng: float | None = None
    cancel_reason: str | None = None


@dataclass
class BookingRecord:
    id: UUID
    client_id: UUID
    slot_id: UUID
    slot_snapshot: BookingSlotSnapshot
    seats_count: int
    rental_count: int
    seat_gear: list[GearChoice]
    price_total: Money
    status: str  # active | cancelled | late_cancel | cancelled_by_center | completed
    created_at: datetime
    cancelled_at: datetime | None = None
    cancel_reason: str | None = None


@dataclass
class OtpRecord:
    phone: str
    code: str
    expires_at: datetime
    attempts: int = 0
    last_sent_at: datetime | None = None


@dataclass
class PushTokenRecord:
    client_id: UUID
    platform: str
    device_id: str | None
    token: str


@dataclass
class RefreshTokenRecord:
    client_id: UUID
    valid_jtis: set[str] = field(default_factory=set)
