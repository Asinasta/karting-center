"""Notification contract models."""

from __future__ import annotations

from typing import Literal
from uuid import UUID

from pydantic import BaseModel, Field

NotificationType = Literal["rate_marshal"]


class AppNotification(BaseModel):
    id: str
    type: NotificationType
    title: str
    body: str
    booking_id: UUID
    created_at: str = Field(description="ISO-8601 instant when the notification became due")


class NotificationList(BaseModel):
    items: list[AppNotification]
