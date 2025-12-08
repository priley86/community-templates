from fastapi import FastAPI
from starlette.middleware.cors import CORSMiddleware
from starlette.middleware.sessions import SessionMiddleware

from app.core.auth import auth_client
from app.core.config import settings
from app.api.api_router import api_router

app = FastAPI(
    title=settings.APP_NAME,
)

# Set all CORS enabled origins
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALL_CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix=settings.API_PREFIX)

# Set the session middleware
app.add_middleware(SessionMiddleware, secret_key=settings.AUTH0_SECRET)

# Save auth state
app.state.auth_client = auth_client


@app.get("/health")
async def health_check():
    """Health check endpoint for Cloud Run and monitoring."""
    return {
        "status": "healthy",
        "service": settings.APP_NAME,
        "langgraph_url": settings.langgraph_url,
    }