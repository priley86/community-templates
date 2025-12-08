from auth0_fastapi.auth import AuthClient
from auth0_fastapi.config import Auth0Config
from auth0_fastapi.server.routes import router as auth_router, register_auth_routes

from app.core.config import settings
from app.core.transaction_store import InMemoryTransactionStore

auth_config = Auth0Config(
    domain=settings.AUTH0_DOMAIN,
    client_id=settings.AUTH0_CLIENT_ID,
    client_secret=settings.AUTH0_CLIENT_SECRET,
    secret=settings.AUTH0_SECRET,
    app_base_url=f"{settings.APP_BASE_URL}{settings.API_PREFIX}",
    mount_routes=True,
    mount_connected_account_routes=True,
    authorization_params={
        "scope": "openid profile email offline_access",
    },
)

# Use in-memory transaction store to avoid cross-site cookie issues
# This is required for Connected Accounts flow where redirects go through
# third-party identity providers (Google, etc.)
# Note: For multi-instance deployments, consider using Redis instead
transaction_store = InMemoryTransactionStore(
    secret=settings.AUTH0_SECRET,
    expiration_seconds=300  # 5 minutes
)

auth_client = AuthClient(auth_config, transaction_store=transaction_store)

register_auth_routes(auth_router, auth_config)
