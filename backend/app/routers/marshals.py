"""Public marshal directory: listMarshals (BE-05). No bearer auth."""

from __future__ import annotations

from fastapi import APIRouter, Depends

from ..contracts.marshals import Marshal
from ..dependencies import get_backend
from ..ports import Backend

router = APIRouter(tags=["marshals"])


@router.get("/marshals", operation_id="listMarshals", response_model=list[Marshal])
def listMarshals(  # noqa: N802
    backend: Backend = Depends(get_backend),
) -> list[Marshal]:
    return backend.list_marshals()
