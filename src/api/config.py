import os
from pydantic_settings import BaseSettings
from azure.identity import DefaultAzureCredential
import logging

logger = logging.getLogger(__name__)


class Settings(BaseSettings):
    """Application configuration"""
    
    # Database
    database_type: str = os.getenv("DATABASE_TYPE", "sqlite")  # sqlite or postgresql
    
    # PostgreSQL
    postgres_server: str = os.getenv("POSTGRES_SERVER", "localhost")
    postgres_port: int = int(os.getenv("POSTGRES_PORT", "5432"))
    postgres_db: str = os.getenv("POSTGRES_DB", "tododb")
    postgres_user: str = os.getenv("POSTGRES_USER", "postgres")
    postgres_password: str = os.getenv("POSTGRES_PASSWORD", "")
    
    # Environment
    environment: str = os.getenv("ENVIRONMENT", "development")
    debug: bool = environment == "development"
    
    # API
    api_title: str = "Todo Management API"
    api_version: str = "2.0.0"

    @property
    def cors_allowed_origins(self) -> list[str]:
        """Return normalized CORS allowlist from CORS_ALLOWED_ORIGINS env var."""
        raw_value = os.getenv("CORS_ALLOWED_ORIGINS", "*")
        origins = [origin.strip() for origin in raw_value.split(",") if origin.strip()]
        return origins or ["*"]

    @property
    def cors_allow_credentials(self) -> bool:
        """Wildcard origins cannot be used with credentials in browser CORS checks."""
        return "*" not in self.cors_allowed_origins
    
    def get_database_token(self) -> str:
        """Get Entra ID token for PostgreSQL authentication"""
        try:
            credential = DefaultAzureCredential()
            token = credential.get_token("https://ossrdbms-aad.database.windows.net/.default")
            return token.token
        except Exception as e:
            logger.warning(f"Failed to get Entra ID token: {e}. Falling back to password authentication.")
            return None

    @property
    def database_url(self) -> str:
        """Build database connection string"""
        if self.database_type == "sqlite":
            # Local SQLite for development
            return "sqlite:///./todos.db"
        else:
            # PostgreSQL with Entra ID authentication
            if self.postgres_password:
                # Use password if explicitly provided (local development)
                return f"postgresql+psycopg2://{self.postgres_user}:{self.postgres_password}@{self.postgres_server}:{self.postgres_port}/{self.postgres_db}?sslmode=require"
            else:
                # Azure Entra ID authentication - password will be retrieved dynamically
                # Username should be the AAD user email or app ID
                return f"postgresql+psycopg2://{self.postgres_user}@{self.postgres_server}:{self.postgres_port}/{self.postgres_db}?sslmode=require"


settings = Settings()
