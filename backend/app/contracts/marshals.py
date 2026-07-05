"""Marshal contract models (marshals/models.yaml)."""

from __future__ import annotations

from uuid import UUID

from pydantic import BaseModel, Field


class Marshal(BaseModel):
    id: UUID
    name: str
    average_rating: float | None = Field(default=None, ge=1, le=5)
    rating_count: int = Field(default=0, ge=0)
