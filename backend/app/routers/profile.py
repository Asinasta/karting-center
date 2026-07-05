"""Profile endpoints (BE-09). All require bearer auth."""

from __future__ import annotations

from datetime import datetime
from uuid import UUID

from fastapi import APIRouter, Depends, Response

from ..contracts.profile import (
    PhoneChangeOtpRequest,
    Profile,
    PushTokenRequest,
    UpdateProfileRequest,
    VerifyPhoneChangeRequest,
)
from ..dependencies import get_backend, get_current_client_id, get_now
from ..ports import Backend

router = APIRouter(tags=["profile"])


@router.get("/profile", operation_id="getProfile", response_model=Profile)
def getProfile(  # noqa: N802
    client_id: UUID = Depends(get_current_client_id),
    backend: Backend = Depends(get_backend),
) -> Profile:
    return backend.get_profile(client_id)


@router.patch("/profile", operation_id="updateProfile", response_model=Profile)
def updateProfile(  # noqa: N802
    body: UpdateProfileRequest,
    client_id: UUID = Depends(get_current_client_id),
    backend: Backend = Depends(get_backend),
) -> Profile:
    return backend.update_profile(client_id, body.name)


@router.delete("/profile", operation_id="deleteAccount", status_code=204)
def deleteAccount(  # noqa: N802
    client_id: UUID = Depends(get_current_client_id),
    backend: Backend = Depends(get_backend),
    now: datetime = Depends(get_now),
) -> Response:
    backend.delete_account(client_id, now)
    return Response(status_code=204)


@router.post("/profile/phone-change/otp", operation_id="sendPhoneChangeOtp", status_code=204)
def sendPhoneChangeOtp(  # noqa: N802
    body: PhoneChangeOtpRequest,
    client_id: UUID = Depends(get_current_client_id),
    backend: Backend = Depends(get_backend),
    now: datetime = Depends(get_now),
) -> Response:
    backend.send_phone_change_otp(client_id, body.new_phone, now)
    return Response(status_code=204)


@router.post(
    "/profile/phone-change/verify", operation_id="verifyPhoneChange", response_model=Profile
)
def verifyPhoneChange(  # noqa: N802
    body: VerifyPhoneChangeRequest,
    client_id: UUID = Depends(get_current_client_id),
    backend: Backend = Depends(get_backend),
    now: datetime = Depends(get_now),
) -> Profile:
    return backend.verify_phone_change(client_id, body.new_phone, body.code, now)


@router.post("/profile/push-token", operation_id="registerPushToken", status_code=204)
def registerPushToken(  # noqa: N802
    body: PushTokenRequest,
    client_id: UUID = Depends(get_current_client_id),
    backend: Backend = Depends(get_backend),
) -> Response:
    backend.register_push_token(client_id, body.token, body.platform, body.device_id)
    return Response(status_code=204)
