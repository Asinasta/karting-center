"""FastAPI dependency wiring: backend adapter, clock, token service, auth."""

from __future__ import annotations

from datetime import datetime
from uuid import UUID

from fastapi import Depends, Header, Request

from .config import Settings
from .domain.clock import Clock
from .errors import ApiError
from .ports import Backend
from .security import TokenService


def get_settings_dep(request: Request) -> Settings:
    return request.app.state.settings


def get_backend(request: Request) -> Backend:
    return request.app.state.backend


def get_clock(request: Request) -> Clock:
    return request.app.state.clock


def get_token_service(request: Request) -> TokenService:
    return request.app.state.token_service


def get_now(clock: Clock = Depends(get_clock)) -> datetime:
    return clock.now()


def get_current_client_id(
    authorization: str | None = Header(default=None),
    backend: Backend = Depends(get_backend),
    token_service: TokenService = Depends(get_token_service),
) -> UUID:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise ApiError("unauthorized", "Missing bearer token")
    token = authorization[len("bearer ") :].strip()
    client_id_str = token_service.decode_access(token)
    try:
        client_id = UUID(client_id_str)
    except ValueError as exc:
        raise ApiError("unauthorized", "Malformed subject") from exc
    if backend.get_client(client_id) is None:
        raise ApiError("unauthorized", "Client no longer exists")
    return client_id
