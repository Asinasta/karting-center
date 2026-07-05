"""Auth endpoints: sendOtp, verifyOtp, refreshToken (BE-04)."""

from __future__ import annotations

from datetime import datetime
from uuid import UUID

from fastapi import APIRouter, Depends, Response

from ..config import Settings
from ..contracts.auth import RefreshTokenRequest, SendOtpRequest, TokenPair, VerifyOtpRequest
from ..dependencies import get_backend, get_now, get_settings_dep, get_token_service
from ..errors import ApiError
from ..ports import Backend
from ..security import TokenService

router = APIRouter(tags=["auth"])


def _issue_pair(
    backend: Backend, token_service: TokenService, settings: Settings, client_id: UUID
) -> TokenPair:
    access = token_service.issue_access(str(client_id))
    refresh, jti = token_service.issue_refresh(str(client_id))
    backend.store_refresh(client_id, jti)
    return TokenPair(
        access_token=access,
        refresh_token=refresh,
        expires_in=settings.access_token_ttl_seconds,
    )


@router.post("/auth/otp", operation_id="sendOtp", status_code=204)
def sendOtp(  # noqa: N802 - name mirrors operationId
    body: SendOtpRequest,
    backend: Backend = Depends(get_backend),
    now: datetime = Depends(get_now),
) -> Response:
    backend.request_otp(body.phone, now)
    return Response(status_code=204)


@router.post("/auth/verify", operation_id="verifyOtp", response_model=TokenPair)
def verifyOtp(  # noqa: N802
    body: VerifyOtpRequest,
    backend: Backend = Depends(get_backend),
    token_service: TokenService = Depends(get_token_service),
    settings: Settings = Depends(get_settings_dep),
    now: datetime = Depends(get_now),
) -> TokenPair:
    client = backend.verify_otp(body.phone, body.code, body.name, now)
    return _issue_pair(backend, token_service, settings, client.id)


@router.post("/auth/refresh", operation_id="refreshToken", response_model=TokenPair)
def refreshToken(  # noqa: N802
    body: RefreshTokenRequest,
    backend: Backend = Depends(get_backend),
    token_service: TokenService = Depends(get_token_service),
    settings: Settings = Depends(get_settings_dep),
) -> TokenPair:
    claims = token_service.decode_refresh(body.refresh_token)
    try:
        client_id = UUID(claims.client_id)
    except ValueError as exc:
        raise ApiError("unauthorized", "Malformed refresh subject") from exc

    if not backend.is_refresh_valid(client_id, claims.jti):
        raise ApiError("unauthorized", "Refresh token revoked or unknown")
    if backend.get_client(client_id) is None:
        raise ApiError("unauthorized", "Client no longer exists")

    access = token_service.issue_access(str(client_id))
    new_refresh, new_jti = token_service.issue_refresh(str(client_id))
    backend.rotate_refresh(client_id, claims.jti, new_jti)
    return TokenPair(
        access_token=access,
        refresh_token=new_refresh,
        expires_in=settings.access_token_ttl_seconds,
    )
