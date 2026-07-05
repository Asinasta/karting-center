"""Marshal contract models (marshals/models.yaml)."""

from __future__ import annotations

from uuid import UUID

from pydantic import BaseModel


class Marshal(BaseModel):
    id: UUID
    name: str
