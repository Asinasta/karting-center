"""Ports: abstract interfaces between handlers and backend adapters (BE-03).

State ownership (MVP fixtures adapter owns all of this in-memory; a production
`existing` adapter must either delegate to the existing backend or persist it):

- AuthPort      -> OTP login state, attempts/rate-limit, client identity.
- SlotPort      -> read-only slot catalog (existing backend is source of truth).
- MarshalPort   -> read-only marshal directory.
- BookingPort   -> bookings, availability decrement, idempotency records.
- ProfilePort   -> client profile, phone-change OTP, refresh-token invalidation.
- PushTokenPort -> push token registry (upsert by client+platform+device).
"""

from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from datetime import datetime
from uuid import UUID

from .contracts.bookings import Booking, BookingList, CreateBookingRequest, CreateMarshalRatingRequest
from .contracts.marshals import Marshal
from .contracts.profile import Profile
from .contracts.slots import Slot
from .domain.models import ClientRecord


@dataclass
class SlotFilters:
    date_from: datetime | None = None
    date_to: datetime | None = None
    track_config_type: list[str] = field(default_factory=list)
    marshal_id: list[UUID] = field(default_factory=list)
    only_available: bool = False


class AuthPort(ABC):
    @abstractmethod
    def request_otp(self, phone: str, now: datetime) -> None: ...

    @abstractmethod
    def verify_otp(
        self, phone: str, code: str, name: str | None, now: datetime
    ) -> ClientRecord: ...

    @abstractmethod
    def get_client(self, client_id: UUID) -> ClientRecord | None: ...

    @abstractmethod
    def store_refresh(self, client_id: UUID, jti: str) -> None: ...

    @abstractmethod
    def is_refresh_valid(self, client_id: UUID, jti: str) -> bool: ...

    @abstractmethod
    def rotate_refresh(self, client_id: UUID, old_jti: str, new_jti: str) -> None: ...


class SlotPort(ABC):
    @abstractmethod
    def list_slots(self, filters: SlotFilters, now: datetime) -> list[Slot]: ...

    @abstractmethod
    def get_slot(self, slot_id: UUID) -> Slot | None: ...


class MarshalPort(ABC):
    @abstractmethod
    def list_marshals(self) -> list[Marshal]: ...


class BookingPort(ABC):
    @abstractmethod
    def create_booking(
        self, client_id: UUID, req: CreateBookingRequest, idempotency_key: str, now: datetime
    ) -> Booking: ...

    @abstractmethod
    def list_bookings(self, client_id: UUID, limit: int, offset: int) -> BookingList: ...

    @abstractmethod
    def get_booking(self, client_id: UUID, booking_id: UUID) -> Booking: ...

    @abstractmethod
    def cancel_booking(self, client_id: UUID, booking_id: UUID, now: datetime) -> Booking: ...

    @abstractmethod
    def rate_marshal(
        self,
        client_id: UUID,
        booking_id: UUID,
        req: CreateMarshalRatingRequest,
        now: datetime,
    ) -> Booking: ...

    @abstractmethod
    def update_marshal_rating(
        self,
        client_id: UUID,
        booking_id: UUID,
        req: CreateMarshalRatingRequest,
        now: datetime,
    ) -> Booking: ...


class ProfilePort(ABC):
    @abstractmethod
    def get_profile(self, client_id: UUID) -> Profile: ...

    @abstractmethod
    def update_profile(self, client_id: UUID, name: str | None) -> Profile: ...

    @abstractmethod
    def send_phone_change_otp(self, client_id: UUID, new_phone: str, now: datetime) -> None: ...

    @abstractmethod
    def verify_phone_change(
        self, client_id: UUID, new_phone: str, code: str, now: datetime
    ) -> Profile: ...

    @abstractmethod
    def delete_account(self, client_id: UUID, now: datetime) -> None: ...


class PushTokenPort(ABC):
    @abstractmethod
    def register_push_token(
        self, client_id: UUID, token: str, platform: str, device_id: str | None
    ) -> None: ...


class Backend(AuthPort, SlotPort, MarshalPort, BookingPort, ProfilePort, PushTokenPort, ABC):
    """A single object that implements every port (fixtures / existing)."""
