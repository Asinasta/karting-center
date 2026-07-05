"""Profile contract models (profile/models.yaml)."""

from __future__ import annotations

from typing import Literal
from uuid import UUID

from typing import Literal

from pydantic import BaseModel, Field

from .common import PHONE_PATTERN

LoyaltyTier = Literal["regular", "vip"]


class Profile(BaseModel):
    id: UUID
    name: str = Field(min_length=1, max_length=80)
    phone: str = Field(pattern=PHONE_PATTERN)
    completed_rides_count: int = Field(default=0, ge=0)
    loyalty_tier: LoyaltyTier | None = None
    loyalty_discount_percent: int | None = Field(default=None, ge=1, le=100)


class UpdateProfileRequest(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=80)


class PhoneChangeOtpRequest(BaseModel):
    new_phone: str = Field(pattern=PHONE_PATTERN)


class VerifyPhoneChangeRequest(BaseModel):
    new_phone: str = Field(pattern=PHONE_PATTERN)
    code: str = Field(min_length=4, max_length=8)


class PushTokenRequest(BaseModel):
    token: str = Field(min_length=16, max_length=4096)
    platform: Literal["ios", "android"]
    device_id: str | None = None
