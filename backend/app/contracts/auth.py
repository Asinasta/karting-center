"""Auth contract models (auth/models.yaml)."""

from __future__ import annotations

from pydantic import BaseModel, Field

from .common import PHONE_PATTERN


class SendOtpRequest(BaseModel):
    phone: str = Field(pattern=PHONE_PATTERN)


class VerifyOtpRequest(BaseModel):
    phone: str = Field(pattern=PHONE_PATTERN)
    code: str = Field(min_length=4, max_length=8)
    name: str | None = Field(default=None, min_length=1, max_length=80)


class RefreshTokenRequest(BaseModel):
    refresh_token: str


class TokenPair(BaseModel):
    access_token: str
    refresh_token: str
    expires_in: int | None = Field(default=None, ge=1)
