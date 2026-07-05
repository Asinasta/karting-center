"""Slot contract models (slots/models.yaml)."""

from __future__ import annotations

from datetime import datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, Field

from .common import Money
from .marshals import Marshal

TrackConfigType = Literal["novice", "experienced"]
SlotStatus = Literal["scheduled", "cancelled"]


class TrackConfig(BaseModel):
    id: UUID
    name: str
    description: str | None = None
    type: TrackConfigType
    capacity_cap: int = Field(ge=1)
    duration_min: int | None = Field(default=None, ge=1)
    geometry: list[list[float]] | None = None


class Slot(BaseModel):
    id: UUID
    track_config: TrackConfig
    marshal: Marshal
    start_at: datetime
    total_seats: int = Field(ge=0)
    free_seats: int = Field(ge=0)
    free_rental_gear: int = Field(ge=0)
    price: Money
    rental_price: Money
    meeting_point: str
    meeting_point_lat: float | None = Field(default=None, ge=-90, le=90)
    meeting_point_lng: float | None = Field(default=None, ge=-180, le=180)
    status: SlotStatus
    cancel_reason: str | None = None
