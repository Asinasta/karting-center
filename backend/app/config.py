"""Application configuration loaded from environment variables."""

from __future__ import annotations

from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict

DEV_SECRETS = {"dev-access-secret", "dev-refresh-secret"}


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore", populate_by_name=True)

    app_env: str = Field(default="dev", alias="APP_ENV")
    http_addr: str = Field(default=":8080", alias="HTTP_ADDR")
    jwt_access_secret: str = Field(default="dev-access-secret", alias="JWT_ACCESS_SECRET")
    jwt_refresh_secret: str = Field(default="dev-refresh-secret", alias="JWT_REFRESH_SECRET")
    backend_adapter: str = Field(default="fixtures", alias="BACKEND_ADAPTER")

    access_token_ttl_seconds: int = 15 * 60
    refresh_token_ttl_seconds: int = 30 * 24 * 60 * 60

    @property
    def is_dev(self) -> bool:
        return self.app_env.lower() == "dev"

    @property
    def host(self) -> str:
        host, _, _ = self.http_addr.rpartition(":")
        return host or "0.0.0.0"

    @property
    def port(self) -> int:
        _, _, port = self.http_addr.rpartition(":")
        return int(port) if port else 8080

    @property
    def dev_otp_enabled(self) -> bool:
        return self.is_dev and self.backend_adapter == "fixtures"

    def validate_startup(self) -> None:
        """Refuse to start a non-dev environment with dev JWT secrets."""
        if self.is_dev:
            return
        if self.jwt_access_secret in DEV_SECRETS or self.jwt_refresh_secret in DEV_SECRETS:
            raise RuntimeError(
                "Refusing to start: dev JWT secrets are set while APP_ENV is not 'dev'. "
                "Provide strong JWT_ACCESS_SECRET and JWT_REFRESH_SECRET."
            )


@lru_cache
def get_settings() -> Settings:
    return Settings()
