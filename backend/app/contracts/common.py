"""Common contract models: Money, Pagination, Error (common/models.yaml)."""

from __future__ import annotations

from typing import Any, Literal

from pydantic import BaseModel, Field

PHONE_PATTERN = r"^\+[1-9]\d{7,14}$"


class Money(BaseModel):
    amount: int = Field(description="Amount in kopecks")
    currency: Literal["RUB"] = "RUB"


class Pagination(BaseModel):
    limit: int | None = None
    offset: int | None = None
    total: int | None = None


class ErrorResponse(BaseModel):
    code: str
    message: str
    details: dict[str, Any] | None = None
    # Present only for rate_limit responses (allOf Error + RetryAfter).
    retry_after: int | None = None
