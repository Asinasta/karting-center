"""FastAPI application factory, middleware and error handlers (BE-00, BE-02)."""

from __future__ import annotations

import logging
import time
import uuid

from fastapi import FastAPI, Request
from fastapi.routing import APIRoute
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware

from .config import Settings, get_settings
from .domain.clock import Clock, SystemClock
from .errors import ApiError
from .logging_config import configure_logging, log
from .ports import Backend
from .routers import auth, bookings, marshals, profile, slots
from .security import TokenService

logger = logging.getLogger("apex.api")


def _build_backend(settings: Settings, clock: Clock) -> Backend:
    if settings.backend_adapter == "fixtures":
        from .adapters.fixtures import FixturesAdapter

        return FixturesAdapter(clock=clock, dev_otp_enabled=settings.dev_otp_enabled)
    if settings.backend_adapter == "existing":
        from .adapters.existing import ExistingBackendAdapter

        return ExistingBackendAdapter()
    raise RuntimeError(f"Unknown BACKEND_ADAPTER: {settings.backend_adapter}")


def create_app(
    settings: Settings | None = None,
    backend: Backend | None = None,
    clock: Clock | None = None,
) -> FastAPI:
    configure_logging()
    settings = settings or get_settings()
    settings.validate_startup()
    clock = clock or SystemClock()
    backend = backend or _build_backend(settings, clock)

    app = FastAPI(
        title="Apex Client API",
        version="0.1.0",
        generate_unique_id_function=_operation_id_from_handler_name,
    )
    app.state.settings = settings
    app.state.clock = clock
    app.state.backend = backend
    app.state.token_service = TokenService(settings)

    _register_cors(app, settings)
    _register_middleware(app)
    _register_error_handlers(app)

    for module in (auth, slots, marshals, bookings, profile):
        app.include_router(module.router)

    @app.get("/healthz", include_in_schema=False)
    def healthz() -> dict[str, str]:
        return {"status": "ok"}

    return app


def _operation_id_from_handler_name(route: APIRoute) -> str:
    """OpenAPI operationId is part of the contract: keep it equal to handler name."""
    return route.name


def _register_cors(app: FastAPI, settings: Settings) -> None:
    if not settings.is_dev:
        return
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=False,
        allow_methods=["*"],
        allow_headers=["*"],
    )


def _register_middleware(app: FastAPI) -> None:
    @app.middleware("http")
    async def request_context(request: Request, call_next):
        request_id = request.headers.get("X-Request-ID") or uuid.uuid4().hex
        request.state.request_id = request_id
        started = time.perf_counter()
        try:
            response = await call_next(request)
        except Exception:  # panic recovery
            elapsed_ms = round((time.perf_counter() - started) * 1000, 2)
            log(
                logger,
                logging.ERROR,
                "unhandled_exception",
                request_id=request_id,
                method=request.method,
                path=request.url.path,
                elapsed_ms=elapsed_ms,
            )
            body = ApiError("server_error", "Internal server error").to_body()
            response = JSONResponse(status_code=500, content=body)
            response.headers["X-Request-ID"] = request_id
            return response

        elapsed_ms = round((time.perf_counter() - started) * 1000, 2)
        log(
            logger,
            logging.INFO,
            "request",
            request_id=request_id,
            method=request.method,
            path=request.url.path,
            status=response.status_code,
            elapsed_ms=elapsed_ms,
        )
        response.headers["X-Request-ID"] = request_id
        return response


def _register_error_handlers(app: FastAPI) -> None:
    @app.exception_handler(ApiError)
    async def handle_api_error(request: Request, exc: ApiError) -> JSONResponse:
        return JSONResponse(status_code=exc.status_code, content=exc.to_body())

    @app.exception_handler(RequestValidationError)
    async def handle_validation(request: Request, exc: RequestValidationError) -> JSONResponse:
        err = ApiError(
            "validation_error",
            "Request validation failed",
            status_code=400,
            details={"errors": _safe_errors(exc)},
        )
        return JSONResponse(status_code=err.status_code, content=err.to_body())

    @app.exception_handler(Exception)
    async def handle_unexpected(request: Request, exc: Exception) -> JSONResponse:
        body = ApiError("server_error", "Internal server error").to_body()
        return JSONResponse(status_code=500, content=body)


def _safe_errors(exc: RequestValidationError) -> list[dict]:
    out: list[dict] = []
    for e in exc.errors():
        out.append({"loc": [str(p) for p in e.get("loc", [])], "msg": e.get("msg", "")})
    return out


app = create_app()
