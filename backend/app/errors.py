"""Domain error model and error-code registry (common/models.yaml)."""

from __future__ import annotations

from typing import Any

# The only error codes allowed anywhere in the API (common/models.yaml Error.enum).
ERROR_CODES = {
    "slot_full",
    "double_booking",
    "slot_cancelled",
    "slot_started",
    "already_cancelled",
    "invalid_code",
    "rate_limit",
    "phone_already_used",
    "unauthorized",
    "forbidden",
    "not_found",
    "validation_error",
    "server_error",
}

# Default HTTP status for each error code (per 01-analysis/api operation responses).
DEFAULT_STATUS = {
    "slot_full": 409,
    "double_booking": 409,
    "slot_cancelled": 410,
    "slot_started": 422,
    "already_cancelled": 409,
    "invalid_code": 400,
    "rate_limit": 429,
    "phone_already_used": 409,
    "unauthorized": 401,
    "forbidden": 403,
    "not_found": 404,
    "validation_error": 400,
    "server_error": 500,
}


class ApiError(Exception):
    """Raised anywhere in the app and rendered as the contract Error body."""

    def __init__(
        self,
        code: str,
        message: str | None = None,
        *,
        status_code: int | None = None,
        details: dict[str, Any] | None = None,
        retry_after: int | None = None,
    ) -> None:
        if code not in ERROR_CODES:
            raise ValueError(f"Undocumented error code: {code}")
        self.code = code
        self.message = message or code.replace("_", " ")
        self.status_code = status_code or DEFAULT_STATUS[code]
        self.details = details
        self.retry_after = retry_after
        super().__init__(self.message)

    def to_body(self) -> dict[str, Any]:
        body: dict[str, Any] = {"code": self.code, "message": self.message}
        if self.details is not None:
            body["details"] = self.details
        if self.retry_after is not None:
            body["retry_after"] = self.retry_after
        return body
