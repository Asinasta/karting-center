"""In-memory fixtures adapter (dev/test). Owns all client-API state.

Thread-safe: create/cancel booking run under a single re-entrant lock so
concurrent requests cannot overbook or double-release seats.
"""

from __future__ import annotations

import random
import threading
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from uuid import UUID, uuid4

from ..contracts.bookings import Booking, BookingList, BookingSlotSnapshot, CreateBookingRequest
from ..contracts.common import Money, Pagination
from ..contracts.marshals import Marshal
from ..contracts.profile import Profile
from ..contracts.slots import Slot, TrackConfig
from ..domain.clock import Clock, SystemClock
from ..domain.models import (
    BookingRecord,
    ClientRecord,
    MarshalRecord,
    OtpRecord,
    PushTokenRecord,
    SlotRecord,
    TrackConfigRecord,
)
from ..domain.policies import (
    cancellation_kind,
    ensure_bookable,
    price_total,
    seats_and_rental,
)
from ..errors import ApiError
from ..ports import Backend, SlotFilters

OTP_TTL = timedelta(minutes=5)
OTP_RESEND_INTERVAL = timedelta(seconds=60)
OTP_MAX_ATTEMPTS = 5
DEV_OTP_CODE = "0000"

MSK = timezone(timedelta(hours=3))  # Moscow is UTC+3 year-round (no DST).
CATALOG_YEAR = 2026
CATALOG_MONTH = 7
CATALOG_DAY_FROM = 10
CATALOG_DAY_TO = 20
CATALOG_SLOT_MINUTES = (0, 15, 30, 45)


@dataclass
class _IdempotencyRecord:
    client_id: UUID
    fingerprint: tuple
    booking_id: UUID


@dataclass
class _PhoneChangeOtp:
    new_phone: str
    code: str
    expires_at: datetime
    attempts: int = 0
    last_sent_at: datetime | None = None


def _money(amount: int) -> Money:
    return Money(amount=amount, currency="RUB")


def _catalog_moment(day: int, hour: int, minute: int) -> datetime:
    return datetime(CATALOG_YEAR, CATALOG_MONTH, day, hour, minute, tzinfo=MSK)


def _catalog_range() -> tuple[datetime, datetime]:
    start = _catalog_moment(CATALOG_DAY_FROM, 0, 0)
    end = _catalog_moment(CATALOG_DAY_TO, 23, 59)
    return start, end


class FixturesAdapter(Backend):
    def __init__(self, clock: Clock | None = None, dev_otp_enabled: bool = True) -> None:
        self._clock = clock or SystemClock()
        self._dev_otp_enabled = dev_otp_enabled
        self._lock = threading.RLock()

        self._clients: dict[UUID, ClientRecord] = {}
        self._phone_index: dict[str, UUID] = {}
        self._marshals: dict[UUID, MarshalRecord] = {}
        self._track_configs: dict[UUID, TrackConfigRecord] = {}
        self._slots: dict[UUID, SlotRecord] = {}
        self._bookings: dict[UUID, BookingRecord] = {}
        self._otps: dict[str, OtpRecord] = {}
        self._phone_change_otps: dict[UUID, _PhoneChangeOtp] = {}
        self._idempotency: dict[str, _IdempotencyRecord] = {}
        self._refresh_jtis: dict[UUID, set[str]] = {}
        self._push_tokens: dict[tuple[UUID, str, str | None], PushTokenRecord] = {}
        self._late_cancel_events: list[UUID] = []

        self._seed()

    # ------------------------------------------------------------------ seed
    def _seed(self) -> None:
        now = self._clock.now()

        marshal_a = MarshalRecord(id=uuid4(), name="Иван Гонщиков")
        marshal_b = MarshalRecord(id=uuid4(), name="Пётр Скоростной")
        marshal_c = MarshalRecord(id=uuid4(), name="Алексей Трекмастер")
        marshal_d = MarshalRecord(id=uuid4(), name="Мария Быстрая")
        marshal_e = MarshalRecord(id=uuid4(), name="Сергей Дрифт")
        for m in (marshal_a, marshal_b, marshal_c, marshal_d, marshal_e):
            self._marshals[m.id] = m

        novice = TrackConfigRecord(
            id=uuid4(),
            name="Новичковая конфигурация",
            type="novice",
            capacity_cap=8,
            description="Безопасная трасса для начинающих",
            duration_min=15,
            geometry=[[55.75, 37.61], [55.76, 37.62], [55.75, 37.63]],
        )
        experienced = TrackConfigRecord(
            id=uuid4(),
            name="Профессиональная конфигурация",
            type="experienced",
            capacity_cap=14,
            description="Скоростная трасса для опытных пилотов",
            duration_min=20,
            geometry=[[55.70, 37.50], [55.71, 37.52], [55.70, 37.54]],
        )
        for t in (novice, experienced):
            self._track_configs[t.id] = t

        marshals = [marshal_a, marshal_b, marshal_c, marshal_d, marshal_e]

        # --- Catalog: 10–20 July 2026, 12:00–20:00 every 15 minutes (MSK). ---
        slot_available: SlotRecord | None = None
        slot_cancelled: SlotRecord | None = None
        catalog_slots: list[SlotRecord] = []

        for day in range(CATALOG_DAY_FROM, CATALOG_DAY_TO + 1):
            for hour in range(12, 21):
                for minute in CATALOG_SLOT_MINUTES:
                    if hour == 20 and minute > 0:
                        continue

                    start_at = _catalog_moment(day, hour, minute)
                    key = (day, hour, minute)

                    if key == (10, 13, 15):
                        track = novice
                        marshal = marshal_a
                        total_seats = 8
                        free_seats = 6
                        free_rental_gear = 4
                        price = _money(150000)
                        rental_price = _money(50000)
                        meeting_point = "Главный вход, стойка регистрации"
                        meeting_lat, meeting_lng = 55.751, 37.618
                        status = "scheduled"
                        cancel_reason = None
                    elif key == (11, 14, 15):
                        track = novice
                        marshal = marshal_b
                        total_seats = 8
                        free_seats = 8
                        free_rental_gear = 4
                        price = _money(150000)
                        rental_price = _money(50000)
                        meeting_point = "Главный вход"
                        meeting_lat, meeting_lng = None, None
                        status = "cancelled"
                        cancel_reason = "Техническое обслуживание трассы"
                    elif key == (12, 15, 30):
                        track = experienced
                        marshal = marshal_b
                        total_seats = 14
                        free_seats = 0
                        free_rental_gear = 0
                        price = _money(250000)
                        rental_price = _money(70000)
                        meeting_point = "Бокс №2"
                        meeting_lat, meeting_lng = None, None
                        status = "scheduled"
                        cancel_reason = None
                    elif key == (13, 16, 45):
                        track = experienced
                        marshal = marshal_d
                        total_seats = 14
                        free_seats = 10
                        free_rental_gear = 0
                        price = _money(250000)
                        rental_price = _money(70000)
                        meeting_point = "Бокс №1"
                        meeting_lat, meeting_lng = None, None
                        status = "scheduled"
                        cancel_reason = None
                    else:
                        idx = day * 100 + hour * 4 + minute // 15
                        track = novice if idx % 2 == 0 else experienced
                        marshal = marshals[idx % len(marshals)]
                        total_seats = 8 if track.type == "novice" else 14
                        free_seats = total_seats - (idx % 4)
                        free_rental_gear = max(0, (total_seats // 2) - (idx % 3))
                        price = _money(150000 if track.type == "novice" else 250000)
                        rental_price = _money(50000 if track.type == "novice" else 70000)
                        meeting_point = (
                            "Главный вход, стойка регистрации"
                            if track.type == "novice"
                            else "Бокс №2"
                        )
                        meeting_lat = 55.751 if track.type == "novice" else None
                        meeting_lng = 37.618 if track.type == "novice" else None
                        status = "scheduled"
                        cancel_reason = None

                    slot = SlotRecord(
                        id=uuid4(),
                        track_config_id=track.id,
                        marshal_id=marshal.id,
                        start_at=start_at,
                        total_seats=total_seats,
                        free_seats=free_seats,
                        free_rental_gear=free_rental_gear,
                        price=price,
                        rental_price=rental_price,
                        meeting_point=meeting_point,
                        meeting_point_lat=meeting_lat,
                        meeting_point_lng=meeting_lng,
                        status=status,
                        cancel_reason=cancel_reason,
                    )
                    catalog_slots.append(slot)

                    if key == (10, 13, 15):
                        slot_available = slot
                    if key == (11, 14, 15):
                        slot_cancelled = slot

        assert slot_available is not None and slot_cancelled is not None
        for s in catalog_slots:
            self._slots[s.id] = s

        # Seed client that owns the sample bookings.
        client = ClientRecord(id=uuid4(), name="Тестовый Гонщик", phone="+79990000000")
        self._clients[client.id] = client
        self._phone_index[client.phone] = client.id

        # Active booking (future slot).
        self._new_booking(
            client_id=client.id,
            slot=slot_available,
            seat_gear=["rental", "own"],
            status="active",
            created_at=now - timedelta(hours=5),
        )

        # Completed booking (past slot snapshot).
        past_slot = SlotRecord(
            id=uuid4(),
            track_config_id=novice.id,
            marshal_id=marshal_a.id,
            start_at=now - timedelta(days=2),
            total_seats=8,
            free_seats=5,
            free_rental_gear=3,
            price=_money(150000),
            rental_price=_money(50000),
            meeting_point="Главный вход",
            status="scheduled",
        )
        self._slots[past_slot.id] = past_slot
        self._new_booking(
            client_id=client.id,
            slot=past_slot,
            seat_gear=["own"],
            status="completed",
            created_at=now - timedelta(days=3),
        )

        # Booking cancelled by the center.
        cancelled_by_center_booking = self._new_booking(
            client_id=client.id,
            slot=slot_cancelled,
            seat_gear=["rental"],
            status="cancelled_by_center",
            created_at=now - timedelta(days=1),
        )
        rec = self._bookings[cancelled_by_center_booking]
        rec.cancelled_at = now - timedelta(hours=10)
        rec.cancel_reason = "Техническое обслуживание трассы"
        rec.slot_snapshot.status = "cancelled"
        rec.slot_snapshot.cancel_reason = "Техническое обслуживание трассы"

    def _new_booking(
        self,
        client_id: UUID,
        slot: SlotRecord,
        seat_gear: list[str],
        status: str,
        created_at: datetime,
    ) -> UUID:
        seats_count, rental_count = seats_and_rental(seat_gear)
        record = BookingRecord(
            id=uuid4(),
            client_id=client_id,
            slot_id=slot.id,
            slot_snapshot=self._snapshot(slot),
            seats_count=seats_count,
            rental_count=rental_count,
            seat_gear=list(seat_gear),
            price_total=price_total(slot.price, slot.rental_price, seats_count, rental_count),
            status=status,
            created_at=created_at,
        )
        self._bookings[record.id] = record
        return record.id

    # --------------------------------------------------------------- mappers
    def _track_contract(self, track_id: UUID) -> TrackConfig:
        t = self._track_configs[track_id]
        return TrackConfig(
            id=t.id,
            name=t.name,
            description=t.description,
            type=t.type,  # type: ignore[arg-type]
            capacity_cap=t.capacity_cap,
            duration_min=t.duration_min,
            geometry=t.geometry,
        )

    def _marshal_contract(self, marshal_id: UUID) -> Marshal:
        m = self._marshals[marshal_id]
        return Marshal(id=m.id, name=m.name)

    def _slot_contract(self, s: SlotRecord) -> Slot:
        return Slot(
            id=s.id,
            track_config=self._track_contract(s.track_config_id),
            marshal=self._marshal_contract(s.marshal_id),
            start_at=s.start_at,
            total_seats=s.total_seats,
            free_seats=s.free_seats,
            free_rental_gear=s.free_rental_gear,
            price=s.price,
            rental_price=s.rental_price,
            meeting_point=s.meeting_point,
            meeting_point_lat=s.meeting_point_lat,
            meeting_point_lng=s.meeting_point_lng,
            status=s.status,  # type: ignore[arg-type]
            cancel_reason=s.cancel_reason,
        )

    def _snapshot(self, s: SlotRecord) -> BookingSlotSnapshot:
        t = self._track_configs[s.track_config_id]
        return BookingSlotSnapshot(
            id=s.id,
            track_config=self._track_contract(s.track_config_id),
            marshal=self._marshal_contract(s.marshal_id),
            start_at=s.start_at,
            price=s.price,
            rental_price=s.rental_price,
            meeting_point=s.meeting_point,
            meeting_point_lat=s.meeting_point_lat,
            meeting_point_lng=s.meeting_point_lng,
            geometry=t.geometry,
            status=s.status,  # type: ignore[arg-type]
            cancel_reason=s.cancel_reason,
        )

    def _booking_contract(self, b: BookingRecord) -> Booking:
        return Booking(
            id=b.id,
            slot=b.slot_snapshot,
            seats_count=b.seats_count,
            rental_count=b.rental_count,
            seat_gear=list(b.seat_gear),  # type: ignore[arg-type]
            price_total=b.price_total,
            status=b.status,  # type: ignore[arg-type]
            created_at=b.created_at,
            cancelled_at=b.cancelled_at,
            cancel_reason=b.cancel_reason,
        )

    def _profile_contract(self, c: ClientRecord) -> Profile:
        return Profile(id=c.id, name=c.name, phone=c.phone)

    # ------------------------------------------------------------- AuthPort
    def _gen_code(self) -> str:
        if self._dev_otp_enabled:
            return DEV_OTP_CODE
        return f"{random.randint(0, 9999):04d}"

    def request_otp(self, phone: str, now: datetime) -> None:
        with self._lock:
            existing = self._otps.get(phone)
            if existing and existing.last_sent_at is not None:
                elapsed = now - existing.last_sent_at
                if elapsed < OTP_RESEND_INTERVAL:
                    retry_after = int((OTP_RESEND_INTERVAL - elapsed).total_seconds())
                    raise ApiError(
                        "rate_limit",
                        "OTP was requested too recently",
                        retry_after=max(retry_after, 1),
                    )
            self._otps[phone] = OtpRecord(
                phone=phone,
                code=self._gen_code(),
                expires_at=now + OTP_TTL,
                attempts=0,
                last_sent_at=now,
            )

    def _check_code(self, record: OtpRecord | None, code: str, now: datetime) -> bool:
        if self._dev_otp_enabled and code == DEV_OTP_CODE:
            return True
        if record is None or now > record.expires_at:
            return False
        return code == record.code

    def verify_otp(
        self, phone: str, code: str, name: str | None, now: datetime
    ) -> ClientRecord:
        with self._lock:
            record = self._otps.get(phone)
            if record is not None and record.attempts >= OTP_MAX_ATTEMPTS:
                raise ApiError(
                    "rate_limit", "Too many attempts", retry_after=60
                )
            if not self._check_code(record, code, now):
                if record is not None:
                    record.attempts += 1
                raise ApiError("invalid_code", "Invalid OTP code")

            client_id = self._phone_index.get(phone)
            if client_id is not None:
                self._otps.pop(phone, None)
                return self._clients[client_id]

            if not name:
                raise ApiError(
                    "validation_error", "name is required for a new client", status_code=400
                )
            client = ClientRecord(id=uuid4(), name=name, phone=phone)
            self._clients[client.id] = client
            self._phone_index[phone] = client.id
            self._otps.pop(phone, None)
            return client

    def get_client(self, client_id: UUID) -> ClientRecord | None:
        with self._lock:
            client = self._clients.get(client_id)
            if client is None or client.deleted:
                return None
            return client

    def store_refresh(self, client_id: UUID, jti: str) -> None:
        with self._lock:
            self._refresh_jtis.setdefault(client_id, set()).add(jti)

    def is_refresh_valid(self, client_id: UUID, jti: str) -> bool:
        with self._lock:
            return jti in self._refresh_jtis.get(client_id, set())

    def rotate_refresh(self, client_id: UUID, old_jti: str, new_jti: str) -> None:
        with self._lock:
            jtis = self._refresh_jtis.setdefault(client_id, set())
            jtis.discard(old_jti)
            jtis.add(new_jti)

    # ------------------------------------------------------------- SlotPort
    def list_slots(self, filters: SlotFilters, now: datetime) -> list[Slot]:
        with self._lock:
            date_from = filters.date_from
            date_to = filters.date_to
            if date_from is None and date_to is None:
                catalog_start, catalog_end = _catalog_range()
                date_from = now if now > catalog_start else catalog_start
                date_to = catalog_end

            result: list[SlotRecord] = []
            for s in self._slots.values():
                if date_from is not None and s.start_at < date_from:
                    continue
                if date_to is not None and s.start_at > date_to:
                    continue
                if filters.track_config_type:
                    t = self._track_configs[s.track_config_id]
                    if t.type not in filters.track_config_type:
                        continue
                if filters.marshal_id and s.marshal_id not in filters.marshal_id:
                    continue
                if filters.only_available and (s.status == "cancelled" or s.free_seats <= 0):
                    continue
                result.append(s)

            result.sort(key=lambda s: s.start_at)
            return [self._slot_contract(s) for s in result]

    def get_slot(self, slot_id: UUID) -> Slot | None:
        with self._lock:
            s = self._slots.get(slot_id)
            return self._slot_contract(s) if s else None

    # ---------------------------------------------------------- MarshalPort
    def list_marshals(self) -> list[Marshal]:
        with self._lock:
            return [Marshal(id=m.id, name=m.name) for m in self._marshals.values()]

    # ---------------------------------------------------------- BookingPort
    def create_booking(
        self, client_id: UUID, req: CreateBookingRequest, idempotency_key: str, now: datetime
    ) -> Booking:
        fingerprint = (str(req.slot_id), tuple(req.seat_gear))
        with self._lock:
            existing = self._idempotency.get(idempotency_key)
            if existing is not None:
                if existing.client_id == client_id and existing.fingerprint == fingerprint:
                    return self._booking_contract(self._bookings[existing.booking_id])
                raise ApiError(
                    "validation_error",
                    "Idempotency-Key reused with a different payload",
                    status_code=422,
                )

            slot = self._slots.get(req.slot_id)
            if slot is None:
                raise ApiError("validation_error", "Unknown slot_id", status_code=422)

            for b in self._bookings.values():
                if b.client_id == client_id and b.slot_id == slot.id and b.status == "active":
                    raise ApiError(
                        "double_booking",
                        "Client already has an active booking for this slot",
                        details={"booking_id": str(b.id)},
                    )

            seats_count, rental_count = seats_and_rental(list(req.seat_gear))
            capacity_cap = self._track_configs[slot.track_config_id].capacity_cap
            ensure_bookable(slot, capacity_cap, seats_count, rental_count, now)

            slot.free_seats -= seats_count
            slot.free_rental_gear -= rental_count

            record = BookingRecord(
                id=uuid4(),
                client_id=client_id,
                slot_id=slot.id,
                slot_snapshot=self._snapshot(slot),
                seats_count=seats_count,
                rental_count=rental_count,
                seat_gear=list(req.seat_gear),
                price_total=price_total(
                    slot.price, slot.rental_price, seats_count, rental_count
                ),
                status="active",
                created_at=now,
            )
            self._bookings[record.id] = record
            self._idempotency[idempotency_key] = _IdempotencyRecord(
                client_id=client_id, fingerprint=fingerprint, booking_id=record.id
            )
            return self._booking_contract(record)

    def list_bookings(self, client_id: UUID, limit: int, offset: int) -> BookingList:
        with self._lock:
            mine = [b for b in self._bookings.values() if b.client_id == client_id]
            mine.sort(key=lambda b: b.created_at, reverse=True)
            total = len(mine)
            page = mine[offset : offset + limit]
            return BookingList(
                items=[self._booking_contract(b) for b in page],
                pagination=Pagination(limit=limit, offset=offset, total=total),
            )

    def _owned_booking(self, client_id: UUID, booking_id: UUID) -> BookingRecord:
        record = self._bookings.get(booking_id)
        if record is None:
            raise ApiError("not_found", "Booking not found")
        if record.client_id != client_id:
            raise ApiError("forbidden", "Booking belongs to another client")
        return record

    def get_booking(self, client_id: UUID, booking_id: UUID) -> Booking:
        with self._lock:
            return self._booking_contract(self._owned_booking(client_id, booking_id))

    def cancel_booking(self, client_id: UUID, booking_id: UUID, now: datetime) -> Booking:
        with self._lock:
            record = self._owned_booking(client_id, booking_id)

            if record.status in ("cancelled", "late_cancel", "cancelled_by_center"):
                raise ApiError("already_cancelled", "Booking is already cancelled")
            if record.status != "active":
                raise ApiError("slot_started", "Slot has already started")
            if now >= record.slot_snapshot.start_at:
                raise ApiError("slot_started", "Slot has already started")

            kind = cancellation_kind(record.slot_snapshot.start_at, now)
            record.cancelled_at = now
            if kind == "early":
                record.status = "cancelled"
                slot = self._slots.get(record.slot_id)
                if slot is not None:
                    slot.free_seats = min(slot.total_seats, slot.free_seats + record.seats_count)
                    slot.free_rental_gear += record.rental_count
            else:
                record.status = "late_cancel"
                self._late_cancel_events.append(record.id)
            return self._booking_contract(record)

    # ---------------------------------------------------------- ProfilePort
    def get_profile(self, client_id: UUID) -> Profile:
        with self._lock:
            client = self.get_client(client_id)
            if client is None:
                raise ApiError("not_found", "Client not found")
            return self._profile_contract(client)

    def update_profile(self, client_id: UUID, name: str | None) -> Profile:
        with self._lock:
            client = self.get_client(client_id)
            if client is None:
                raise ApiError("not_found", "Client not found")
            if name is not None:
                client.name = name
            return self._profile_contract(client)

    def send_phone_change_otp(self, client_id: UUID, new_phone: str, now: datetime) -> None:
        with self._lock:
            owner = self._phone_index.get(new_phone)
            if owner is not None and owner != client_id:
                raise ApiError("phone_already_used", "Phone already used by another account")

            existing = self._phone_change_otps.get(client_id)
            if existing and existing.last_sent_at is not None:
                elapsed = now - existing.last_sent_at
                if elapsed < OTP_RESEND_INTERVAL:
                    retry_after = int((OTP_RESEND_INTERVAL - elapsed).total_seconds())
                    raise ApiError(
                        "rate_limit", "OTP requested too recently", retry_after=max(retry_after, 1)
                    )

            self._phone_change_otps[client_id] = _PhoneChangeOtp(
                new_phone=new_phone,
                code=self._gen_code(),
                expires_at=now + OTP_TTL,
                attempts=0,
                last_sent_at=now,
            )

    def verify_phone_change(
        self, client_id: UUID, new_phone: str, code: str, now: datetime
    ) -> Profile:
        with self._lock:
            client = self.get_client(client_id)
            if client is None:
                raise ApiError("not_found", "Client not found")

            record = self._phone_change_otps.get(client_id)
            if record is not None and record.attempts >= OTP_MAX_ATTEMPTS:
                raise ApiError("rate_limit", "Too many attempts", retry_after=60)

            code_ok = self._dev_otp_enabled and code == DEV_OTP_CODE
            if not code_ok:
                if (
                    record is None
                    or record.new_phone != new_phone
                    or now > record.expires_at
                    or record.code != code
                ):
                    if record is not None:
                        record.attempts += 1
                    raise ApiError("invalid_code", "Invalid OTP code")

            owner = self._phone_index.get(new_phone)
            if owner is not None and owner != client_id:
                raise ApiError("phone_already_used", "Phone already used by another account")

            self._phone_index.pop(client.phone, None)
            client.phone = new_phone
            self._phone_index[new_phone] = client.id
            self._phone_change_otps.pop(client_id, None)
            return self._profile_contract(client)

    def delete_account(self, client_id: UUID, now: datetime) -> None:
        with self._lock:
            client = self.get_client(client_id)
            if client is None:
                raise ApiError("not_found", "Client not found")

            for b in self._bookings.values():
                if b.client_id != client_id:
                    continue
                if b.status == "active":
                    if now < b.slot_snapshot.start_at:
                        kind = cancellation_kind(b.slot_snapshot.start_at, now)
                        b.cancelled_at = now
                        if kind == "early":
                            b.status = "cancelled"
                            slot = self._slots.get(b.slot_id)
                            if slot is not None:
                                slot.free_seats = min(
                                    slot.total_seats, slot.free_seats + b.seats_count
                                )
                                slot.free_rental_gear += b.rental_count
                        else:
                            b.status = "late_cancel"
                            self._late_cancel_events.append(b.id)

            self._phone_index.pop(client.phone, None)
            client.deleted = True
            client.name = "Удалённый пользователь"
            self._refresh_jtis.pop(client_id, None)

    # -------------------------------------------------------- PushTokenPort
    def register_push_token(
        self, client_id: UUID, token: str, platform: str, device_id: str | None
    ) -> None:
        with self._lock:
            key = (client_id, platform, device_id)
            self._push_tokens[key] = PushTokenRecord(
                client_id=client_id, platform=platform, device_id=device_id, token=token
            )
