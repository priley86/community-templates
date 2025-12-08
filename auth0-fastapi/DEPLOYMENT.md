# Production Deployment Guide

This guide covers deploying your AI assistant to production using Google Cloud Run for all services.

## Architecture Overview

All components are deployed to Google Cloud Run:
- **Frontend**: React SPA with nginx proxy (forwards /api/** to backend)
- **Backend**: FastAPI server with Auth0 authentication
- **LangGraph**: AI agent runtime

### Deployment Components

1. **LangGraph Server** → Google Cloud Run (AI agent runtime)
2. **FastAPI Backend** → Google Cloud Run (API server with Auth0)
3. **React Frontend** → Google Cloud Run (Static site with nginx proxy)

## Prerequisites

### Required Accounts
- [Google Cloud Platform](https://console.cloud.google.com/) account
- [Auth0](https://auth0.com/) account (already configured)

### Required Tools
- [gcloud CLI](https://cloud.google.com/sdk/docs/install) installed and configured

### Enable Google Cloud APIs

```bash
# Set your project ID
gcloud config set project your-project-id

# Enable required APIs
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com
```

## Deployment Steps Overview

Deployment follows these steps:

1. **Configure Environment** - Set up `backend/.env.production` with initial credentials
2. **Deploy LangGraph** - Get LangGraph URL, add to `backend/.env.production`
3. **Deploy Backend** - Get backend URL, update nginx config in frontend
4. **Deploy Frontend** - Build and deploy to Cloud Run with nginx proxy
5. **Update Backend Config** - Add frontend URL to `backend/.env.production` and redeploy
6. **Update Auth0** - Configure callback URLs with frontend URL

**Note:** The backend requires redeployment after frontend deployment because `APP_BASE_URL` and `CORS` must be configured with the frontend URL for Auth0 callback handling to work correctly.

## Deployment Steps

### Step 1: Configure Production Environment

Create and configure your production environment file:

```bash
# Copy the example file
cd backend
cp .env.production.example .env.production
```

Edit `backend/.env.production` with your credentials:

```bash
# Google Cloud Platform
GCP_PROJECT_ID="your-project-id"
GCP_REGION="us-central1"

# Auth0 (from your Auth0 Dashboard)
AUTH0_DOMAIN="your-tenant.auth0.com"
AUTH0_CLIENT_ID="your-client-id"
AUTH0_CLIENT_SECRET="your-client-secret"
AUTH0_SECRET="generate-with-openssl-rand-hex-32"

# LLM Provider
GOOGLE_API_KEY="your-google-ai-api-key"

# Optional: LangSmith tracing
LANGCHAIN_API_KEY="your-langsmith-api-key"
LANGCHAIN_TRACING_V2="true"
```

**Note:** The deployment scripts will automatically load variables from this file.

### Step 2: Deploy LangGraph Server

The LangGraph server hosts your AI agents and needs to be externally accessible.

```bash
# Make script executable (first time only)
chmod +x scripts/deploy-langgraph.sh

# Run deployment
./scripts/deploy-langgraph.sh
```

The script will:
1. Build a Docker image with your LangGraph server
2. Push it to Google Container Registry
3. Deploy it to Cloud Run
4. Output the service URL

#### Save the LangGraph URL

After deployment completes, you'll see:
```
LangGraph Server URL: https://langgraph-server-xxx-uc.a.run.app
```

**Add this URL to `backend/.env.production`:**
```bash
LANGGRAPH_EXTERNAL_URL="https://langgraph-server-xxx-uc.a.run.app"
```

### Step 3: Deploy FastAPI Backend

The backend API handles authentication and connects to your LangGraph server.

```bash
# Make script executable (first time only)
chmod +x scripts/deploy-backend.sh

# Run deployment (uses backend/.env.production)
./scripts/deploy-backend.sh
```

**Note:** The initial deployment will succeed with `APP_BASE_URL` defaulting to localhost. You'll need to redeploy after frontend deployment to set the correct frontend URL.

#### Save the Backend URL

After deployment completes, you'll see:
```
Backend API URL: https://backend-api-xxx-uc.a.run.app
```

**Add this URL to `frontend/.env.production`:**
```bash
BACKEND_URL="https://backend-api-xxx-uc.a.run.app"
```

### Step 4: Deploy Frontend to Cloud Run

The frontend is a React SPA served by nginx, which also proxies API requests to the backend.

```bash
# Make script executable (first time only)
chmod +x scripts/deploy-frontend.sh

# Run deployment (will prompt for backend URL)
./scripts/deploy-frontend.sh
```

The script will:
1. Read `BACKEND_URL` from `frontend/.env.production` (or prompt if not set)
2. Build a Docker image with your React app and nginx
3. Configure nginx to proxy `/api/**` to your backend
4. Push the image to Google Container Registry
5. Deploy to Cloud Run with the `BACKEND_HOST` environment variable
6. Output the service URL

#### Save the Frontend URL

After deployment completes, you'll see:
```
Frontend URL: https://frontend-app-xxx-uc.a.run.app
```

**Copy this URL** - you'll need it for the next steps.

### Step 5: Update Backend Configuration and Redeploy

**⚠️ Critical Step:** Now that you have your frontend URL, update `backend/.env.production`:

```bash
# Set all three to your frontend URL
APP_BASE_URL="https://frontend-app-xxx-uc.a.run.app"
FRONTEND_HOST="https://frontend-app-xxx-uc.a.run.app"
BACKEND_CORS_ORIGINS="https://frontend-app-xxx-uc.a.run.app"
```

**Redeploy the backend** to apply these settings:
```bash
./scripts/deploy-backend.sh
```

This second deployment ensures:
- Auth0 callbacks work correctly (via `APP_BASE_URL`)
- CORS allows requests from your frontend
- Your application is fully connected

### Step 6: Update Auth0 Configuration

Go to your [Auth0 Dashboard](https://manage.auth0.com/) and update with your frontend Cloud Run URL:

**Allowed Callback URLs:**
```
https://frontend-app-xxx-uc.a.run.app/api/auth/callback
```

**Allowed Logout URLs:**
```
https://frontend-app-xxx-uc.a.run.app
```

**Allowed Web Origins:**
```
https://frontend-app-xxx-uc.a.run.app
```

## Verification

### Test Your Deployment

1. **Open your frontend:** `https://frontend-app-xxx-uc.a.run.app`
2. **Click "Login" and authenticate with Auth0**
3. **Send a message to the AI assistant**
4. **Verify you get a response**

### Check Service Health

```bash
# LangGraph health check
curl https://langgraph-server-xxx-uc.a.run.app/health

# Backend health check
curl https://backend-api-xxx-uc.a.run.app/health
```

## Monitoring and Logs

### View Logs

```bash
# LangGraph logs
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=langgraph-server" --limit 50

# Backend logs
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=backend-api" --limit 50

# Or use the scripts
gcloud run services logs langgraph-server --region $GCP_REGION
gcloud run services logs backend-api --region $GCP_REGION
```

### View Metrics

Visit Cloud Console:
- LangGraph: `https://console.cloud.google.com/run/detail/$GCP_REGION/langgraph-server/metrics`
- Backend: `https://console.cloud.google.com/run/detail/$GCP_REGION/backend-api/metrics`

## Cost Optimization

Cloud Run pricing is based on:
- **CPU:** Only charged when handling requests
- **Memory:** Only charged when handling requests
- **Requests:** $0.40 per million requests
- **Free tier:** 2 million requests/month, 360,000 GB-seconds/month

### Tips to Reduce Costs

1. **Set resource limits:**
   ```bash
   --memory 512Mi    # Reduce if possible
   --cpu 1           # Sufficient for most workloads
   ```

2. **Limit maximum instances:**
   ```bash
   --max-instances 10  # Prevent runaway scaling
   ```

3. **Set minimum instances to 0:**
   ```bash
   --min-instances 0  # Scale to zero when idle
   ```

4. **Use appropriate timeouts:**
   ```bash
   --timeout 60  # Backend doesn't need long timeouts
   --timeout 300 # LangGraph may need more time for complex queries
   ```

## Troubleshooting

### Frontend Not Proxying to Backend

**Issue:** API calls fail or CORS errors

**Solution:**
1. Check the `BACKEND_HOST` environment variable in Cloud Run:
   ```bash
   gcloud run services describe frontend-app --region us-central1 \
     --format="value(spec.template.spec.containers[0].env)"
   ```
2. Verify it contains the correct backend hostname (without https://)
3. Redeploy frontend with correct `BACKEND_URL`:
   ```bash
   export BACKEND_URL="https://your-backend-url"
   ./scripts/deploy-frontend.sh
   ```

### Cookies Not Working

**Issue:** Auth0 login redirects work but subsequent API calls fail

**Solution:**
1. Verify nginx is forwarding cookies (check `proxy_pass_header Set-Cookie`)
2. Verify `proxy_cookie_domain` is rewriting backend domain to frontend domain
3. Check that `withCredentials: true` is set in frontend axios client

### Container Fails to Start

**Check logs:**
```bash
gcloud run services logs langgraph-server --limit 50
```

**Common issues:**
- Missing environment variables
- Port mismatch (make sure Dockerfile EXPOSE matches --port)
- Insufficient memory/CPU

**Solution:**
```bash
# Increase resources
gcloud run services update langgraph-server \
  --memory 2Gi \
  --cpu 2
```

### High Latency

**Check cold start times:**
- Cloud Run instances may take 1-2 seconds to start
- Consider using `--min-instances 1` to keep one warm

**Optimize:**
```bash
# Keep at least one instance running
gcloud run services update langgraph-server --min-instances 1
```

### Authentication Errors

**Verify Auth0 configuration:**
- Callback URLs match exactly (including https://)
- CORS origins include your frontend domain
- Client Secret is correct

**Check backend logs:**
```bash
gcloud run services logs backend-api --limit 50
```

### LangGraph Connection Issues

**Verify URL is correct:**
```bash
# Test from local machine
curl https://langgraph-server-xxx-uc.a.run.app/health
```

**Check backend environment:**
```bash
gcloud run services describe backend-api \
  --format="value(spec.template.spec.containers[0].env)"
```

## Updating Deployments

### Update Code

After making code changes, simply redeploy:

```bash
# Redeploy LangGraph
./scripts/deploy-langgraph.sh

# Redeploy Backend
./scripts/deploy-backend.sh

# Redeploy Frontend
./scripts/deploy-frontend.sh
```

### Update Environment Variables

```bash
# Update single variable
gcloud run services update backend-api \
  --update-env-vars NEW_VAR=value

# Update multiple variables
gcloud run services update backend-api \
  --update-env-vars VAR1=value1,VAR2=value2
```

### Rollback to Previous Version

```bash
# List revisions
gcloud run revisions list --service backend-api

# Rollback to specific revision
gcloud run services update-traffic backend-api \
  --to-revisions=backend-api-00001-abc=100
```

## CI/CD Setup (Optional)

### GitHub Actions

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Cloud Run

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - id: auth
        uses: google-github-actions/auth@v1
        with:
          credentials_json: ${{ secrets.GCP_CREDENTIALS }}
      
      - name: Deploy LangGraph
        run: |
          export GCP_PROJECT_ID=${{ secrets.GCP_PROJECT_ID }}
          export GOOGLE_API_KEY=${{ secrets.GOOGLE_API_KEY }}
          ./scripts/deploy-langgraph.sh
      
      - name: Deploy Backend
        run: |
          export GCP_PROJECT_ID=${{ secrets.GCP_PROJECT_ID }}
          export AUTH0_DOMAIN=${{ secrets.AUTH0_DOMAIN }}
          # ... other secrets
          ./scripts/deploy-backend.sh
```

## Getting Help

- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Firebase Hosting Documentation](https://firebase.google.com/docs/hosting)
- [GitHub Issues](https://github.com/firebase-studio/community-templates/issues)
