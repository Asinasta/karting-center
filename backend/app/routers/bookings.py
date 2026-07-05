"""Booking endpoints (BE-06..BE-08). All require bearer auth + owner check."""

from __future__ import annotations

from datetime import datetime
from uuid import UUID

from fastapi import APIRouter, Depends, Header, Query

from ..contracts.bookings import Booking, BookingList, CreateBookingRequest, CreateMarshalRatingRequest
from ..dependencies import get_backend, get_current_client_id, get_now
from ..ports import Backend

router = APIRouter(tags=["bookings"])


@router.post("/bookings", operation_id="createBooking", response_model=Booking, status_code=201)
def createBooking(  # noqa: N802
    body: CreateBookingRequest,
    idempotency_key: str = Header(alias="Idempotency-Key", min_length=8, max_length=128),
    client_id: UUID = Depends(get_current_client_id),
    backend: Backend = Depends(get_backend),
    now: datetime = Depends(get_now),
) -> Booking:
    return backend.create_booking(client_id, body, idempotency_key, now)


@router.get("/bookings", operation_id="listBookings", response_model=BookingList)
def listBookings(  # noqa: N802
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    client_id: UUID = Depends(get_current_client_id),
    backend: Backend = Depends(get_backend),
) -> BookingList:
    return backend.list_bookings(client_id, limit, offset)


@router.get("/bookings/{booking_id}", operation_id="getBooking", response_model=Booking)
def getBooking(  # noqa: N802
    booking_id: UUID,
    client_id: UUID = Depends(get_current_client_id),
    backend: Backend = Depends(get_backend),
) -> Booking:
    return backend.get_booking(client_id, booking_id)


@router.post(
    "/bookings/{booking_id}/cancel", operation_id="cancelBooking", response_model=Booking
)
def cancelBooking(  # noqa: N802
    booking_id: UUID,
    client_id: UUID = Depends(get_current_client_id),
    backend: Backend = Depends(get_backend),
    now: datetime = Depends(get_now),
) -> Booking:
    return backend.cancel_booking(client_id, booking_id, now)


@router.post(
    "/bookings/{booking_id}/marshal-rating",
    operation_id="rateMarshal",
    response_model=Booking,
)
def rateMarshal(  # noqa: N802
    booking_id: UUID,
    body: CreateMarshalRatingRequest,
    client_id: UUID = Depends(get_current_client_id),
    backend: Backend = Depends(get_backend),
    now: datetime = Depends(get_now),
) -> Booking:
    return backend.rate_marshal(client_id, booking_id, body, now)


@router.patch(
    "/bookings/{booking_id}/marshal-rating",
    operation_id="updateMarshalRating",
    response_model=Booking,
)
def updateMarshalRating(  # noqa: N802
    booking_id: UUID,
    body: CreateMarshalRatingRequest,
    client_id: UUID = Depends(get_current_client_id),
    backend: Backend = Depends(get_backend),
    now: datetime = Depends(get_now),
) -> Booking:
    return backend.update_marshal_rating(client_id, booking_id, body, now)


@router.delete(
    "/bookings/{booking_id}/marshal-rating",
    operation_id="deleteMarshalRating",
    response_model=Booking,
)
def deleteMarshalRating(  # noqa: N802
    booking_id: UUID,
    client_id: UUID = Depends(get_current_client_id),
    backend: Backend = Depends(get_backend),
    now: datetime = Depends(get_now),
) -> Booking:
    return backend.delete_marshal_rating(client_id, booking_id, now)
