"""JWT access/refresh token issuing and verification."""

from __future__ import annotations

import uuid
from dataclasses import dataclass
from datetime import datetime, timezone

import jwt

from .config import Settings
from .errors import ApiError

ALGORITHM = "HS256"


@dataclass
class RefreshClaims:
    client_id: str
    jti: str


class TokenService:
    def __init__(self, settings: Settings) -> None:
        self._settings = settings

    def _now(self) -> int:
        return int(datetime.now(timezone.utc).timestamp())

    def issue_access(self, client_id: str) -> str:
        now = self._now()
        payload = {
            "sub": client_id,
            "type": "access",
            "iat": now,
            "exp": now + self._settings.access_token_ttl_seconds,
        }
        return jwt.encode(payload, self._settings.jwt_access_secret, algorithm=ALGORITHM)

    def issue_refresh(self, client_id: str) -> tuple[str, str]:
        """Return (refresh_token, jti). jti lets the store rotate/revoke tokens."""
        now = self._now()
        jti = uuid.uuid4().hex
        payload = {
            "sub": client_id,
            "type": "refresh",
            "jti": jti,
            "iat": now,
            "exp": now + self._settings.refresh_token_ttl_seconds,
        }
        token = jwt.encode(payload, self._settings.jwt_refresh_secret, algorithm=ALGORITHM)
        return token, jti

    def decode_access(self, token: str) -> str:
        try:
            payload = jwt.decode(
                token, self._settings.jwt_access_secret, algorithms=[ALGORITHM]
            )
        except jwt.PyJWTError as exc:
            raise ApiError("unauthorized", "Invalid or expired access token") from exc
        if payload.get("type") != "access":
            raise ApiError("unauthorized", "Wrong token type")
        client_id = payload.get("sub")
        if not client_id:
            raise ApiError("unauthorized", "Malformed token")
        return client_id

    def decode_refresh(self, token: str) -> RefreshClaims:
        try:
            payload = jwt.decode(
                token, self._settings.jwt_refresh_secret, algorithms=[ALGORITHM]
            )
        except jwt.PyJWTError as exc:
            raise ApiError("unauthorized", "Invalid or expired refresh token") from exc
        if payload.get("type") != "refresh":
            raise ApiError("unauthorized", "Wrong token type")
        client_id = payload.get("sub")
        jti = payload.get("jti")
        if not client_id or not jti:
            raise ApiError("unauthorized", "Malformed refresh token")
        return RefreshClaims(client_id=client_id, jti=jti)
