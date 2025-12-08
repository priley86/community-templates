"""
API Router with Cloud Workstation compatibility workaround.

Cloud Workstation (Firebase Studio/IDX) has a proxy that cannot properly handle
HTTP 307/302 redirects to external domains like Auth0. When the proxy encounters
such redirects, it retries the request, but by then the OAuth transaction/state
has already been consumed, causing "transaction is missing" errors.

WORKAROUND: In Cloud Workstation environments only, we override /auth/connect and
/auth/callback to return HTML pages with client-side redirects (meta refresh +
JavaScript) instead of HTTP 307 redirects. This allows the browser to handle the
redirect directly, bypassing the proxy's redirect handling.

This workaround is automatically disabled in production (Cloud Run, etc.) where
the standard library auth routes work correctly.
"""

from fastapi import APIRouter, Query, Request, Response, HTTPException
from fastapi.responses import HTMLResponse, RedirectResponse
from typing import List, Optional
import os

from app.api.routes.chat import agent_router
from app.api.routes.profile import user_router
from app.core.auth import auth_router, auth_client, auth_config

api_router = APIRouter()


def _is_cloud_workstation_env() -> bool:
    """Check if running in a Cloud Workstation environment."""
    # Check APP_BASE_URL for cloudworkstations.dev
    app_base_url = str(auth_config.app_base_url)
    if "cloudworkstations.dev" in app_base_url:
        return True
    # Check Cloud Workstation-specific environment variables
    if os.environ.get("CLOUD_WORKSTATIONS_WORKSTATION_NAME"):
        return True
    # Check if running in IDX/Firebase Studio
    if os.environ.get("IDX_CHANNEL"):
        return True
    return False


def _to_safe_redirect(return_to: str, default: str) -> str:
    """Ensure redirect URL is safe (same origin or allowed)."""
    if return_to and (return_to.startswith('/') or return_to.startswith(str(auth_config.app_base_url))):
        return return_to
    if return_to and 'cloudworkstations.dev' in return_to:
        return return_to
    return default


# Only register custom auth routes in Cloud Workstation environment
_in_cloud_workstation = _is_cloud_workstation_env()

if _in_cloud_workstation:
    
    @api_router.get("/auth/connect")
    async def connect_account_html_redirect(
        request: Request,
        response: Response,
        connection: str = Query(),
        returnTo: Optional[str] = Query(None),
        scopes: List[str] = Query(default=[]),
    ):
        """
        Custom connect account endpoint that returns an HTML redirect instead of 307.
        
        This is needed because Cloud Workstation proxy doesn't properly handle
        307/302 redirects to external domains (like Auth0).
        """
        authorization_params = {
            k: v for k, v in request.query_params.items() 
            if k not in ["connection", "returnTo", "scopes"]
        }
        
        store_options = {"request": request, "response": response}
        
        connect_account_url = await auth_client.start_connect_account(
            connection=connection,
            scopes=scopes,
            authorization_params=authorization_params,
            app_state={"returnTo": returnTo} if returnTo else None,
            store_options=store_options,
        )
        
        html_content = f'''<!DOCTYPE html>
<html>
<head>
    <meta http-equiv="refresh" content="0;url={connect_account_url}">
    <title>Redirecting...</title>
</head>
<body>
    <p>Redirecting to authorization...</p>
    <script>window.location.href = "{connect_account_url}";</script>
</body>
</html>'''
        
        return HTMLResponse(content=html_content, status_code=200)

    @api_router.get("/auth/callback")
    async def callback_html_redirect(
        request: Request,
        response: Response,
    ):
        """
        Custom callback endpoint for Cloud Workstation.
        
        - For connect_code callbacks: Use HTML redirect (Cloud Workstation fix)
        - For regular login callbacks: Use standard 307 redirect (preserves cookies)
        """
        full_callback_url = str(request.url)
        store_options = {"request": request, "response": response}
        
        if "connect_code" in request.query_params:
            # Connected accounts callback - use HTML redirect for Cloud Workstation
            try:
                connect_complete_response = await auth_client.complete_connect_account(
                    full_callback_url, 
                    store_options=store_options
                )
                app_state = connect_complete_response.app_state or {}
            except Exception as e:
                raise HTTPException(status_code=400, detail=str(e))
            
            return_to = app_state.get("returnTo")
            default_redirect = str(auth_config.app_base_url)
            safe_redirect = _to_safe_redirect(return_to, default_redirect) if return_to else default_redirect
            
            html_content = f'''<!DOCTYPE html>
<html>
<head>
    <meta http-equiv="refresh" content="0;url={safe_redirect}">
    <title>Redirecting...</title>
</head>
<body>
    <p>Authentication complete. Redirecting...</p>
    <script>window.location.href = "{safe_redirect}";</script>
</body>
</html>'''
            return HTMLResponse(content=html_content, status_code=200)
        
        else:
            # Regular login callback - use standard 307 redirect (cookies work fine)
            try:
                session_data = await auth_client.complete_login(
                    full_callback_url, 
                    store_options=store_options
                )
                app_state = session_data.get("app_state", {})
            except Exception as e:
                raise HTTPException(status_code=400, detail=str(e))
            
            return_to = app_state.get("returnTo")
            default_redirect = str(auth_config.app_base_url)
            safe_redirect = _to_safe_redirect(return_to, default_redirect) if return_to else default_redirect
            
            return RedirectResponse(url=safe_redirect, status_code=307, headers=dict(response.headers))


# Include library auth router (provides all routes in production, or routes not overridden in Cloud Workstation)
api_router.include_router(auth_router, tags=["auth"])
api_router.include_router(user_router)
api_router.include_router(agent_router)
