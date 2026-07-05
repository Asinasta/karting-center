"""Integration adapter to the existing karting-center backend.

MVP status: NOT IMPLEMENTED. The dev/test API runs on the fixtures adapter.
This class documents the port surface a production integration must satisfy
and the state-ownership decisions from BE_IMPLEMENTATION_PLAN.md:

- Auth OTP / attempts / rate-limit: delegate to existing backend.
- Refresh token lifecycle: delegate to existing backend or a persistent store.
- Idempotency records for createBooking: existing backend idempotency or TTL store.
- Push tokens: existing backend push registry.
- BookingSlotSnapshot: existing backend returns the snapshot per API contract.
"""

from __future__ import annotations

from datetime import datetime
from uuid import UUID

from ..contracts.bookings import Booking, BookingList, CreateBookingRequest, CreateMarshalRatingRequest
from ..contracts.marshals import Marshal
from ..contracts.profile import Profile
from ..contracts.slots import Slot
from ..domain.models import ClientRecord
from ..ports import Backend, SlotFilters


class _NotImplementedBackend(Backend):
    def _todo(self, method: str):
        raise NotImplementedError(
            f"existing adapter method '{method}' is not implemented for MVP; "
            "use BACKEND_ADAPTER=fixtures"
        )


class ExistingBackendAdapter(_NotImplementedBackend):
    def request_otp(self, phone: str, now: datetime) -> None:
        self._todo("request_otp")

    def verify_otp(self, phone: str, code: str, name: str | None, now: datetime) -> ClientRecord:
        self._todo("verify_otp")

    def get_client(self, client_id: UUID) -> ClientRecord | None:
        self._todo("get_client")

    def store_refresh(self, client_id: UUID, jti: str) -> None:
        self._todo("store_refresh")

    def is_refresh_valid(self, client_id: UUID, jti: str) -> bool:
        self._todo("is_refresh_valid")

    def rotate_refresh(self, client_id: UUID, old_jti: str, new_jti: str) -> None:
        self._todo("rotate_refresh")

    def list_slots(self, filters: SlotFilters, now: datetime) -> list[Slot]:
        self._todo("list_slots")

    def get_slot(self, slot_id: UUID) -> Slot | None:
        self._todo("get_slot")

    def list_marshals(self) -> list[Marshal]:
        self._todo("list_marshals")

    def create_booking(
        self, client_id: UUID, req: CreateBookingRequest, idempotency_key: str, now: datetime
    ) -> Booking:
        self._todo("create_booking")

    def list_bookings(self, client_id: UUID, limit: int, offset: int) -> BookingList:
        self._todo("list_bookings")

    def get_booking(self, client_id: UUID, booking_id: UUID) -> Booking:
        self._todo("get_booking")

    def cancel_booking(self, client_id: UUID, booking_id: UUID, now: datetime) -> Booking:
        self._todo("cancel_booking")

    def rate_marshal(
        self,
        client_id: UUID,
        booking_id: UUID,
        req: CreateMarshalRatingRequest,
        now: datetime,
    ) -> Booking:
        self._todo("rate_marshal")

    def update_marshal_rating(
        self,
        client_id: UUID,
        booking_id: UUID,
        req: CreateMarshalRatingRequest,
        now: datetime,
    ) -> Booking:
        self._todo("update_marshal_rating")

    def delete_marshal_rating(
        self, client_id: UUID, booking_id: UUID, now: datetime
    ) -> Booking:
        self._todo("delete_marshal_rating")

    def get_profile(self, client_id: UUID) -> Profile:
        self._todo("get_profile")

    def update_profile(self, client_id: UUID, name: str | None) -> Profile:
        self._todo("update_profile")

    def send_phone_change_otp(self, client_id: UUID, new_phone: str, now: datetime) -> None:
        self._todo("send_phone_change_otp")

    def verify_phone_change(
        self, client_id: UUID, new_phone: str, code: str, now: datetime
    ) -> Profile:
        self._todo("verify_phone_change")

    def delete_account(self, client_id: UUID, now: datetime) -> None:
        self._todo("delete_account")

    def register_push_token(
        self, client_id: UUID, token: str, platform: str, device_id: str | None
    ) -> None:
        self._todo("register_push_token")
