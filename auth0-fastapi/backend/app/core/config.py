from typing import Annotated, Any, Optional
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import computed_field, AnyUrl, BeforeValidator


def parse_cors(v: Any) -> list[str] | str:
    if isinstance(v, str) and not v.startswith("["):
        return [i.strip() for i in v.split(",")]
    elif isinstance(v, list | str):
        return v
    raise ValueError(v)


class Settings(BaseSettings):
    APP_NAME: str = "Assistant0"
    API_PREFIX: str = "/api"
    AUTH0_DOMAIN: str = ""
    AUTH0_CLIENT_ID: str = ""
    AUTH0_CLIENT_SECRET: str = ""
    AUTH0_SECRET: str = ""
    # Optional during initial deployment (defaults to localhost)
    APP_BASE_URL: str = "http://localhost:8000"

    OPENAI_API_KEY: str = ""

    # LangGraph Configuration
    LANGGRAPH_API_URL: str = "http://localhost:54367"
    LANGGRAPH_EXTERNAL_URL: Optional[str] = None  # For production deployment
    LANGGRAPH_API_KEY: str = ""

    FRONTEND_HOST: str = "http://localhost:9000"
    BACKEND_CORS_ORIGINS: Annotated[list[AnyUrl] | str, BeforeValidator(parse_cors)] = [
        "http://localhost:8000"
    ]

    @computed_field  # type: ignore[prop-decorator]
    @property
    def ALL_CORS_ORIGINS(self) -> list[str]:
        return [str(origin).rstrip("/") for origin in self.BACKEND_CORS_ORIGINS] + [
            self.FRONTEND_HOST
        ]

    @computed_field  # type: ignore[prop-decorator]
    @property
    def langgraph_url(self) -> str:
        """Returns the appropriate LangGraph URL based on environment.
        
        Uses LANGGRAPH_EXTERNAL_URL if set (for production deployments),
        otherwise falls back to LANGGRAPH_API_URL (for local development).
        """
        return self.LANGGRAPH_EXTERNAL_URL or self.LANGGRAPH_API_URL

    @computed_field  # type: ignore[prop-decorator]
    @property
    def langgraph_headers(self) -> dict[str, str]:
        """Returns headers for LangGraph API requests.
        
        Includes authentication if LANGGRAPH_API_KEY is set.
        """
        headers: dict[str, str] = {}
        if self.LANGGRAPH_API_KEY:
            headers["Authorization"] = f"Bearer {self.LANGGRAPH_API_KEY}"
        return headers

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")


settings = Settings()
