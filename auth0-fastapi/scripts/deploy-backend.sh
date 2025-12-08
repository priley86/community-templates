#!/bin/bash
set -e

# Deployment script for FastAPI Backend to Google Cloud Run

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  FastAPI Backend Cloud Run Deployment${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Load production environment variables
ENV_FILE="$PROJECT_ROOT/backend/.env.production"
if [ -f "$ENV_FILE" ]; then
    echo -e "${BLUE}Loading environment variables from $ENV_FILE${NC}"
    source "$ENV_FILE"
else
    echo -e "${YELLOW}Warning: $ENV_FILE not found${NC}"
    echo "Create it from backend/.env.production.example or set environment variables manually"
    echo ""
fi

# Configuration
PROJECT_ID="${GCP_PROJECT_ID}"
REGION="${GCP_REGION:-us-central1}"
SERVICE_NAME="backend-api"
IMAGE_NAME="gcr.io/${PROJECT_ID}/${SERVICE_NAME}"

# Check required environment variables
REQUIRED_VARS=("GCP_PROJECT_ID" "AUTH0_DOMAIN" "AUTH0_CLIENT_ID" "AUTH0_CLIENT_SECRET" "AUTH0_SECRET" "GOOGLE_API_KEY")

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo -e "${RED}Error: ${var} is not set${NC}"
        echo "Set it in backend/.env.production or export ${var}='your-value'"
        exit 1
    fi
done

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}Error: gcloud CLI is not installed${NC}"
    echo "Install it from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Set the project
echo -e "${BLUE}Setting GCP project to ${PROJECT_ID}...${NC}"
gcloud config set project ${PROJECT_ID}

# Enable required APIs
echo -e "${BLUE}Enabling required Google Cloud APIs...${NC}"
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com

# Build the container image
echo -e "${BLUE}Building container image...${NC}"
echo "This may take a few minutes..."
cd backend
gcloud builds submit --tag ${IMAGE_NAME} .

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to build container image${NC}"
    exit 1
fi

# Deploy to Cloud Run
echo -e "${BLUE}Deploying to Cloud Run...${NC}"
gcloud run deploy ${SERVICE_NAME} \
  --image ${IMAGE_NAME} \
  --platform managed \
  --region ${REGION} \
  --allow-unauthenticated \
  --port 8000 \
  --memory 512Mi \
  --cpu 1 \
  --timeout 60 \
  --max-instances 10 \
  --set-env-vars "AUTH0_DOMAIN=${AUTH0_DOMAIN},AUTH0_CLIENT_ID=${AUTH0_CLIENT_ID},AUTH0_CLIENT_SECRET=${AUTH0_CLIENT_SECRET},AUTH0_SECRET=${AUTH0_SECRET},GOOGLE_API_KEY=${GOOGLE_API_KEY}" \
  --set-env-vars "APP_BASE_URL=${APP_BASE_URL},LANGGRAPH_EXTERNAL_URL=${LANGGRAPH_EXTERNAL_URL},FRONTEND_HOST=${FRONTEND_HOST},BACKEND_CORS_ORIGINS=${BACKEND_CORS_ORIGINS}"

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to deploy to Cloud Run${NC}"
    exit 1
fi

# Get the service URL
SERVICE_URL=$(gcloud run services describe ${SERVICE_NAME} --region ${REGION} --format 'value(status.url)')

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  ✓ Deployment Successful!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${GREEN}Backend API URL:${NC}"
echo -e "${YELLOW}${SERVICE_URL}${NC}"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo ""
echo "1. Test your deployment:"
echo -e "   ${YELLOW}curl ${SERVICE_URL}/health${NC}"
echo ""
echo "2. Update your frontend/.env.production with:"
echo -e "   ${YELLOW}VITE_API_URL=${SERVICE_URL}${NC}"
echo ""
echo "3. Deploy your frontend to Firebase and update your Auth0 Application Settings:"
echo "   - Allowed Callback URLs: https://your-frontend-app.a.run.app/api/auth/callback"
echo "   - Allowed Logout URLs: https://your-frontend-app.a.run.app"
echo "   - Allowed Web Origins: https://your-frontend-app.a.run.app"
echo ""
echo "4. Deploy frontend, then update backend/.env.production:"
echo "   - Set APP_BASE_URL to your frontend URL (e.g., https://your-frontend-app.a.run.app)"
echo "   - Set FRONTEND_HOST to your frontend URL"
echo "   - Set BACKEND_CORS_ORIGINS to your frontend URL"
echo "   - Then redeploy: ./scripts/deploy-backend.sh"
echo ""
echo "5. Test your application."
