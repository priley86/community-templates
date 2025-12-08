#!/bin/bash
set -e

# Deployment script for React Frontend to Google Cloud Run

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
echo -e "${BLUE}  React Frontend Cloud Run Deployment${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Load production environment variables
BACKEND_ENV_FILE="$PROJECT_ROOT/backend/.env.production"
FRONTEND_ENV_FILE="$PROJECT_ROOT/frontend/.env.production"

# Load backend env for GCP config
if [ -f "$BACKEND_ENV_FILE" ]; then
    echo -e "${BLUE}Loading GCP configuration from $BACKEND_ENV_FILE${NC}"
    source "$BACKEND_ENV_FILE"
fi

# Load frontend env for BACKEND_URL
if [ -f "$FRONTEND_ENV_FILE" ]; then
    echo -e "${BLUE}Loading frontend configuration from $FRONTEND_ENV_FILE${NC}"
    source "$FRONTEND_ENV_FILE"
else
    echo -e "${YELLOW}Warning: $FRONTEND_ENV_FILE not found${NC}"
    echo ""
fi

# Configuration
PROJECT_ID="${GCP_PROJECT_ID}"
REGION="${GCP_REGION:-us-central1}"
SERVICE_NAME="frontend-app"
IMAGE_NAME="gcr.io/${PROJECT_ID}/${SERVICE_NAME}"

# Check required environment variables
if [ -z "$GCP_PROJECT_ID" ]; then
    echo -e "${RED}Error: GCP_PROJECT_ID is not set${NC}"
    echo "Set it in backend/.env.production or export GCP_PROJECT_ID='your-project-id'"
    exit 1
fi

# Prompt for backend URL if not in environment
if [ -z "$BACKEND_URL" ]; then
    echo -e "${YELLOW}Enter your backend Cloud Run URL (e.g., backend-api-xxx-uc.a.run.app):${NC}"
    read -p "> " BACKEND_URL
    if [ -z "$BACKEND_URL" ]; then
        echo -e "${RED}Error: Backend URL is required${NC}"
        echo "Set it in frontend/.env.production or provide it now"
        exit 1
    fi
fi

# Extract just the hostname (remove https:// if present)
BACKEND_HOST=$(echo "$BACKEND_URL" | sed 's|https://||' | sed 's|http://||')

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
cd frontend
gcloud builds submit --tag ${IMAGE_NAME} .

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to build container image${NC}"
    exit 1
fi

# Deploy to Cloud Run
echo -e "${BLUE}Deploying to Cloud Run...${NC}"
echo -e "${BLUE}Backend host: ${BACKEND_HOST}${NC}"
gcloud run deploy ${SERVICE_NAME} \
  --image ${IMAGE_NAME} \
  --platform managed \
  --region ${REGION} \
  --allow-unauthenticated \
  --port 8080 \
  --memory 512Mi \
  --cpu 1 \
  --timeout 60 \
  --max-instances 10 \
  --set-env-vars "BACKEND_HOST=${BACKEND_HOST}"

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
echo -e "${GREEN}Frontend URL:${NC}"
echo -e "${YELLOW}${SERVICE_URL}${NC}"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo ""
echo "1. Test your deployment:"
echo -e "   ${YELLOW}Open ${SERVICE_URL} in your browser${NC}"
echo ""
echo "2. Update backend/.env.production with the frontend URL:"
echo -e "   ${YELLOW}APP_BASE_URL=\"${SERVICE_URL}\"${NC}"
echo -e "   ${YELLOW}FRONTEND_HOST=\"${SERVICE_URL}\"${NC}"
echo -e "   ${YELLOW}BACKEND_CORS_ORIGINS=\"${SERVICE_URL}\"${NC}"
echo ""
echo "3. Redeploy the backend with updated configuration:"
echo -e "   ${YELLOW}./scripts/deploy-backend.sh${NC}"
echo ""
echo "4. Update Auth0 Application Settings:"
echo "   - Allowed Callback URLs: ${SERVICE_URL}/api/auth/callback"
echo "   - Allowed Logout URLs: ${SERVICE_URL}"
echo "   - Allowed Web Origins: ${SERVICE_URL}"
echo ""
echo "5. Test the complete auth flow!"
