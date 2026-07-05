"""Public catalog endpoints: listSlots, getSlot (BE-05). No bearer auth."""

from __future__ import annotations

from datetime import datetime
from uuid import UUID

from fastapi import APIRouter, Depends, Query

from ..contracts.slots import Slot
from ..dependencies import get_backend, get_now
from ..errors import ApiError
from ..ports import Backend, SlotFilters

router = APIRouter(tags=["slots"])


@router.get("/slots", operation_id="listSlots", response_model=list[Slot])
def listSlots(  # noqa: N802
    date_from: datetime | None = Query(default=None),
    date_to: datetime | None = Query(default=None),
    track_config_type: list[str] | None = Query(default=None),
    marshal_id: list[UUID] | None = Query(default=None),
    only_available: bool = Query(default=False),
    backend: Backend = Depends(get_backend),
    now: datetime = Depends(get_now),
) -> list[Slot]:
    filters = SlotFilters(
        date_from=date_from,
        date_to=date_to,
        track_config_type=track_config_type or [],
        marshal_id=marshal_id or [],
        only_available=only_available,
    )
    return backend.list_slots(filters, now)


@router.get("/slots/{slot_id}", operation_id="getSlot", response_model=Slot)
def getSlot(  # noqa: N802
    slot_id: UUID,
    backend: Backend = Depends(get_backend),
) -> Slot:
    slot = backend.get_slot(slot_id)
    if slot is None:
        raise ApiError("not_found", "Slot not found")
    return slot
