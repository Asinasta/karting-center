"""Notification endpoints."""

from __future__ import annotations

from datetime import datetime
from uuid import UUID

from fastapi import APIRouter, Depends

from ..contracts.notifications import NotificationList
from ..dependencies import get_backend, get_current_client_id, get_now
from ..ports import Backend

router = APIRouter(tags=["notifications"])


@router.get("/notifications", operation_id="listNotifications", response_model=NotificationList)
def listNotifications(  # noqa: N802
    client_id: UUID = Depends(get_current_client_id),
    backend: Backend = Depends(get_backend),
    now: datetime = Depends(get_now),
) -> NotificationList:
    return backend.list_notifications(client_id, now)
